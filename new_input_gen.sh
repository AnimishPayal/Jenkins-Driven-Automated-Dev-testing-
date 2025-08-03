#!/bin/bash
set -e
if ! command -v jq &> /dev/null; then
  echo "Error: jq is required. Install with: sudo apt-get install jq"
  exit 1
fi
# Initialize variables
event_type=""
first_filename=""
input_dir="$HOME/my_inputs"
test_files_dir="$HOME/my_tests"
history_file="$HOME/input_history.json"
mkdir -p "$input_dir" "$test_files_dir"
[ ! -f "$history_file" ] && echo "[]" > "$history_file"
if [ $# -ne 1 ] || [ ! -f "$1" ]; then
  echo "Usage: $0 <template.json>"
  exit 1
fi
# User type selection
echo "Are you a basic or advanced user?"
select user_type in "basic" "advanced"; do
  case $user_type in
    basic|advanced) break ;;
    *) echo "Please select 1 or 2." ;;
  esac
done
# Prompt for event type
echo "Select event type:"
echo " 1) File Ready"
echo " 2) New SR"
echo " 3) Interactive"
while true; do
  read -p "Enter option (1/2/3): " event_option
  case $event_option in
    1) event_type="file ready"; break ;;
    2) event_type="new sr"; break ;;
    3) event_type="interactive"; break ;;
    *) echo "Invalid option. Please enter 1, 2, or 3." ;;
  esac
done
# Map event_type to the correct event_i string
case "$event_type" in
  "file ready") event_i="com.oracle.mos.fm.status.file.ready" ;;
  "new sr") event_i="com.oracle.mos.sr.new" ;;
  "interactive") event_i="com.oracle.mos.ext.oia.agentinteractive" ;;
esac
template_file="$1"
working_json=$(jq --arg event_i "$event_i" '.Event.type = $event_i' "$template_file")
# Default values associative array
declare -A aliases
aliases["ServiceRequest.Headers.ProductVersion_c"]="Product Version"
aliases["ServiceRequest.Headers.Title"]="SR Summary"
aliases["ServiceRequest.Headers.SRDescription_c"]="SR Description"
aliases["ServiceRequest.Headers.SRLanguage_c"]="SR Language"
aliases["ServiceRequest.Headers.Substatus_c"]="Sub Status"
aliases["ServiceRequest.Headers.SourceCd"]="SR Source"
aliases["ServiceRequest.Headers.ProductItemDescription"]="Product Description"
aliases["ServiceRequest.Headers.ResourceURL_c"]="Resource URL"
aliases["Event.comoraclesrproduct"]="Product"
aliases["Event.comoraclesrcat"]="Category"
aliases["Event.comoraclesrsubcat"]="Sub Category"

declare -A default_values
default_values["ServiceRequest.Headers.Title"]="Default SR Title"
default_values["Event.data.data.priority"]="Medium"
default_values["Event.data.data.description"]="No description provided"
default_values["Event.comoraclesrproduct"]="Q14156"
default_values["Event.comoraclesrcat"]="Q14156_0_INSTANCE_MAINTENANCE"
default_values["Event.comoraclesrsubcat"]="Q14156_1_CREATION_Q14156_0_INSTANCE_MAINTENANCE"
default_values["ServiceRequest.Headers.ProductVersion_c"]=""
default_values["ServiceRequest.Headers.SRLanguage_c"]="English"
default_values["ServiceRequest.Headers.SourceCd"]="ORA_SVC_CUSTOMER_UI"
default_values["ServiceRequest.Headers.ProductItemDescription"]="SOA on Marketplace"
default_values["ServiceRequest.Headers.ResourceURL_c"]="https://www.google.com"
default_values["ServiceRequest.Headers.SRDescription_c"]="AUTO-UI-SR-This is Service Request Description with IAAS Service"
default_values["ServiceRequest.Headers.Substatus_c"]="NEW"

# Add more as needed
# Find all fields with relevant tokens
if [ "$user_type" = "basic" ]; then
  keys=$(jq -r 'paths(scalars) as $p | if (getpath($p) | type == "string" and (contains("%bas"))) then $p | map(tostring) | join(".") else empty end' <<< "$working_json")
else
  keys=$(jq -r 'paths(scalars) as $p | if (getpath($p) | type == "string" and ((contains("%bas")) or (contains("%adx")))) then $p | map(tostring) | join(".") else empty end' <<< "$working_json")
fi
# Prompt user for each relevant field and replace token with input (show default if present)
for key in $keys; do
  prompt_label="${aliases[$key]:-$key}"
  default="${default_values[$key]}"
  if [ -n "$default" ]; then
    read -e -i "$default" -p "Enter value for $prompt_label [$default]: " user_value
  else
    read -p "Enter value for $prompt_label: " user_value
  fi
  working_json=$(jq --arg k "$key" --arg v "$user_value" 'setpath($k | split("."); $v)' <<< "$working_json")
done
# SR Number handling (as in your original script)

sr_number=$(jq -r '.ServiceRequest.Headers.SrNumber' <<< "$working_json")
# Title handling
title=$(jq -r '.ServiceRequest.Headers.Title' <<< "$working_json")
collection=$(jq -r '.Event.data.data.collectionId' <<< "$working_json")

   if [[ "$sr_number" =~ ^[0-9]+-[0-9]+$ ]]; then
            working_json=$(jq --arg sn "$sr_number" '
                .Event.subject = $sn |
                .ServiceRequest.Headers.SrNumber = $sn |
                .Event.data.data.contextId = $sn
            ' <<< "$working_json")
    fi
# File handling only for 'file ready'
if [[ "$event_type" == "file ready" ]]; then
  echo -e "\nâž¤ Test File Management:"
  target_test_dir="$test_files_dir/$sr_number/ucr"
  mkdir -p "$target_test_dir"
  while true; do
    read -p "Enter test file path (or blank to finish): " file_path
    [ -z "$file_path" ] && break
    if [ -f "$file_path" ]; then
      file_name=$(basename "$file_path")
      [ -z "$first_filename" ] && first_filename="$file_name"
      upload_id=$((RANDOM%90000+10000))
      file_dir="$target_test_dir/${file_name}_$upload_id/extract"
      mkdir -p "$file_dir"
      if [[ "$file_name" == *.zip ]]; then
        unzip -q "$file_path" -d "$file_dir"
        echo "âœ“ ZIP file extracted to $file_dir/"
      else
        cp "$file_path" "$file_dir/"
        echo "âœ“ File copied to $file_dir/"
      fi
      working_json=$(jq --arg uid "$upload_id" \
        --arg fname "$file_name" \
        --arg col "$collection" \
        --arg sr "$sr_number" \
        --arg fdir "${file_name}_$upload_id" \
        '.Event.data.data.filename = $fname |
        .FilePaths += [{
          "channel": "AGENT_PORTAL",
          "children": $uid,
          "collectionId": $col,
          "collectionName": $fname,
          "contextId": $sr,
          "extractCollectionPathName": "/sr/\($sr)/ucr/\($fdir)/extract",
          "originalCollectionPathName": "/sr/\($sr)/ucr/\($fdir)/orig",
          "uploadId": $uid
        }]' <<< "$working_json")
    else
      echo "File not found!"
    fi
  done
fi
# Save output
output_file="$input_dir/${sr_number}_${title}_$(date +%Y%m%d%H%M%S).json"
jq . <<< "$working_json" > "$output_file"
echo -e "\n:Generated JSON file: $output_file"
ui=$(whoami)
jq --arg et "$event_type" \
   --arg sr "$sr_number" \
   --arg t "$title" \
   --arg f "$first_filename" \
   --arg ui "$ui" \
   '. += [{
     "user_id": $ui,
     "event_type": $et,
     "sr_number": $sr,
     "title": $t,
     "filename": (if $f == "" then null else $f end)
   }]' "$history_file" > tmp_history.json && mv tmp_history.json "$history_file"