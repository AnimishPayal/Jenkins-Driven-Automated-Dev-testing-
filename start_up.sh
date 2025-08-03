#!/bin/bash
# Configuration
SCRIPT_DIR=$(dirname "$(realpath "$0")")
INPUT_DIR="$HOME/my_inputs"
TEST_DIR="$HOME/my_tests"
HISTORY_JSON="$HOME/input_history.json"
# Create directories if missing
mkdir -p "$INPUT_DIR" "$TEST_DIR"
# Main menu function
chmod +x new_input_gen.sh
chmod +x staging_setup.sh
chmod +x search_history.sh
main_menu() {
    while true; do
        echo -e "\nTest Plan Manager"
        echo "1. Create new test plan record"
        echo "2. View Previous test plan record"
        echo "3. Delete input files"
        echo "4. Delete test files"
        echo "5. Stage Test Plan "
        echo "6. Run"
        echo "7. Exit"
        read -p "Enter choice: " choice
        case $choice in
            1) create_new_plan ;;
            2) view_history ;;
            3) delete_input_files ;;
            4) delete_test_files ;;
            5) use_existing_plan ;;
            6) Running ;;
            7) exit 0 ;;
            *) echo "Invalid choice" ;;
        esac
    done
}
# Option 6: running easypodman
Running() {
        "/home/apayal/GIT/CMOS_TOOLS/mw_container/easypodman.sh"
}
# Option 1: Create new test plan
create_new_plan() {
    echo "Enter template JSON path: (blank for default)" 
    read template
    if [ -f "$template" ]; then
        "$SCRIPT_DIR/new_input_gen.sh" "$template"
    else
        "$SCRIPT_DIR/new_input_gen.sh" "$SCRIPT_DIR/sample_template.json"
    fi
}
# Option 2: Use existing test plan
use_existing_plan() {           
    "$SCRIPT_DIR/staging_setup.sh"
}
# Option 3: View history JSON
view_history() {

    echo "1. View all"
    echo "2. Search "
    read -p "Enter choice: " choice
    case $choice in
      1) view_all_plan;;
      2) view_using_filter;;
    esac
}
view_all_plan(){
     if [ -f "$HISTORY_JSON" ]; then
        if command -v jq &>/dev/null; then
            jq . "$HISTORY_JSON"
        else
            cat "$HISTORY_JSON"
        fi
    else
        echo "No history found"
    fi
}
view_using_filter(){
    "$SCRIPT_DIR/search_history.sh" "$HISTORY_JSON"
}
# Option 4: Delete input files 
delete_input_files() {
    echo -e "\nFiles in input directory ($INPUT_DIR):"
    # Check if directory exists and has files
    if [ ! -d "$INPUT_DIR" ]; then
        echo "Input directory does not exist!"
        return
    fi
    # Create array of files
    files=("$INPUT_DIR"/*)
    # Check if any files exist
    if [ ! -e "${files[0]}" ]; then
        echo "No files found in input directory"
        return
    fi
    # Set custom prompt for select
    PS3="Enter the number of the file to delete (or select Cancel): "
    select file in "${files[@]}" "Cancel"; do
        if [ "$file" == "Cancel" ]; then
            echo "Operation cancelled"
            break
        elif [ -n "$file" ] && [ -f "$file" ]; then
            echo "Selected file: $(basename "$file")"
            read -p "Are you sure you want to delete this file? (y/N): " confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                if rm "$file" 2>/dev/null; then
                    echo "Successfully deleted: $(basename "$file")"
                else
                    echo "Failed to delete: $(basename "$file")"
                fi
            else
                echo "Deletion cancelled"
            fi
            break
        else
            echo "Invalid selection. Please enter a valid number."
        fi
    done
}
# Option 5: Delete test files 
delete_test_files() {
    echo -e "\nFiles in test directory ($TEST_DIR):"
    # Check if directory exists and has files
    if [ ! -d "$TEST_DIR" ]; then
        echo "Test directory does not exist!"
        return
    fi
    # Create array of files
    files=("$TEST_DIR"/*)
    # Check if any files exist
    if [ ! -e "${files[0]}" ]; then
        echo "No files found in test directory"
        return
    fi
    # Set custom prompt for select
    PS3="Enter the number of the file to delete (or select Cancel): "
    select file in "${files[@]}" "Cancel"; do
        if [ "$file" == "Cancel" ]; then
            echo "Operation cancelled"
            break
        elif [ -n "$file" ] && [ -f "$file" ]; then
            echo "Selected file: $(basename "$file")"
            read -p "Are you sure you want to delete this file? (y/N): " confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                if rm "$file" 2>/dev/null; then
                    echo "Successfully deleted: $(basename "$file")"
                else
                    echo "Failed to delete: $(basename "$file")"
                fi
            else
                echo "Deletion cancelled"
            fi
            break
        else
            echo "Invalid selection. Please enter a valid number."
        fi
    done
}
# Alternative: Batch delete function
delete_all_input_files() {
    echo -e "\nWARNING: This will delete ALL files in $INPUT_DIR"
    read -p "Are you absolutely sure? Type 'DELETE ALL' to confirm: " confirm
    if [ "$confirm" == "DELETE ALL" ]; then
        if rm -f "$INPUT_DIR"/* 2>/dev/null; then
            echo "All input files deleted successfully"
        else
            echo "Failed to delete some or all files"
        fi
    else
        echo "Operation cancelled"
    fi
}
# Alternative: Batch delete function
delete_all_test_files() {
    echo -e "\nWARNING: This will delete ALL files in $TEST_DIR"
    read -p "Are you absolutely sure? Type 'DELETE ALL' to confirm: " confirm
    if [ "$confirm" == "DELETE ALL" ]; then
        if rm -f "$TEST_DIR"/* 2>/dev/null; then
            echo "All test files deleted successfully"
        else
            echo "Failed to delete some or all files"
        fi
    else
        echo "Operation cancelled"
    fi
}

# Start the menu
main_menu
