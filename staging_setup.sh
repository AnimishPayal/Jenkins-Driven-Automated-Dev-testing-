#!/bin/bash
set -e
# Directory definitions
my_inputs="$HOME/my_inputs"
my_tests="$HOME/my_tests"
adx_inputs="$HOME/adx/input_files"
adx_tests="$HOME/adx/test_files"
history_json="$HOME/history.json"
# Create directories
mkdir -p "$my_inputs" "$my_tests" "$adx_inputs" "$adx_tests"
# Initialize history JSON
if [ ! -f "$history_json" ]; then
    echo "[]" > "$history_json"
fi
# Clear ADX directories option
read -p "Clear ADX input and test directories before moving? (y/n): " clear_choice
if [[ "$clear_choice" =~ ^[Yy]$ ]]; then
    rm -f "$adx_inputs"/*
    rm -rf "$adx_tests"/*
    echo "Cleared ADX directories"
fi
# Selected file tracking
selected_input=""
selected_test=""
sr_number=""
# Move input files
echo -e "\n➤ Input Files in my_inputs:"
if [ -z "$(ls -A "$my_inputs")" ]; then
    echo "No input files found"
else
    select input_file in "$my_inputs"/* "Skip"; do
        if [[ "$input_file" == "Skip" ]]; then
            break
        elif [ -n "$input_file" ]; then
            cp "$input_file" "$adx_inputs/"
            echo "Copied to ADX inputs: $(basename "$input_file")"
            selected_input="$input_file"
            break
        else
            echo "Invalid selection"
        fi
    done
fi
# Move test files
echo -e "\n➤ Test Files in my_tests:"
if [ -z "$(ls -A "$my_tests")" ]; then
    echo "No test files found"
else
    select test_file in "$my_tests"/* "Skip"; do
        if [[ "$test_file" == "Skip" ]]; then
            break
        elif [ -n "$test_file" ]; then
            # Handle directory structure
            if [ -d "$test_file" ]; then
                # Extract SR number from directory name
                sr_number=$(basename "$test_file")
                # Copy entire directory
                cp -r "$test_file" "$adx_tests/"
                echo "Copied test directory to ADX: $sr_number"
                selected_test="$test_file"
            else
                # Handle individual files
                cp "$test_file" "$adx_tests/"
                echo "Copied to ADX tests: $(basename "$test_file")"
                selected_test="$test_file"
            fi
            break
        else
            echo "Invalid selection"
        fi
    done
fi
# JSON logging
if [ -n "$selected_input" ] || [ -n "$selected_test" ]; then
    # Prepare test directory contents if selected
    test_contents="[]"
    test_structure="{}"
    if [ -n "$selected_test" ]; then
        if [ -d "$selected_test" ]; then
            # Capture directory structure
            test_structure=$(find "$selected_test" -type f -exec sh -c 'echo "\"${1#*/}\": \"$(basename $1)\""' _ {} \; |
                             jq -R -s 'split("\n") | map(select(. != "")) | map(split(": ")) | map({(.[0]): .[1]}) | add')
            # Capture file list
            test_contents=$(find "$selected_test" -type f -printf '%f\n' | jq -R -s 'split("\n") | map(select(. != ""))')
        else
            # Single file
            test_contents="[\"$(basename "$selected_test")\"]"
            test_structure="{\"$(basename "$selected_test")\": \"$(basename "$selected_test")\"}"
        fi
    fi
    # Prepare new log entry
    new_entry=$(
        jq -n \
            --arg timestamp "$(date +"%Y-%m-%d %H:%M:%S")" \
            --arg input_file "$(basename "$selected_input")" \
            --arg test_path "$selected_test" \
            --arg sr_number "$sr_number" \
            --argjson test_contents "$test_contents" \
            --argjson test_structure "$test_structure" \
            '{
                timestamp: $timestamp,
                input_file: $input_file,
                test_path: $test_path,
                sr_number: $sr_number,
                test_contents: $test_contents,
            }'
    )
    # Update history.json
    jq --argjson new_entry "$new_entry" '. += [$new_entry]' "$history_json" > "$history_json.tmp"
    mv "$history_json.tmp" "$history_json"
    echo -e "\nUpdated history JSON: $history_json"
fi
echo -e "\nOperation complete"
echo "ADX Inputs: $(ls "$adx_inputs")"
echo "ADX Tests: $(ls "$adx_tests")"