README: How the Menu-Driven Interface Works
Overview
This project includes a menu-driven interface that allows users to interactively manage Dev Testing tasks for Oracle Middleware tools—like creating, viewing, staging, or running test plans—without needing to remember complex commands or file paths. The script guides users step-by-step using clear menus, making the process efficient and user-friendly for both new and experienced team members.

How the Menu-Driven Interface Works
1. Main Menu Display
When the script starts, it presents a main menu with a list of high-level options—such as:

Create Test Plan

View Test Plans (with filter and search)

Stage & Run Test Plan

Delete Test Plan

Exit

2. User Makes a Selection
Users enter the number or letter matching their choice (e.g., 1 for Create Test Plan).

The selection is processed automatically and leads to the corresponding sub-menu or workflow.

3. Sub-menus and Guided Prompts
For each main option, the interface displays dedicated menus or step-by-step prompts:

Create Test Plan: Prompts for test plan details and generates input files using easy questions and default values.

View Test Plans: Lets users filter/search by name, status, owner, or date, making plan management and retrieval simple.

Stage & Run: Shows available test plans, helps with staging files, and can launch automated execution via Jenkins.

Delete: Prompts confirmation before removing records to prevent accidental loss.

4. Input and Validation
The script validates each user input and guides users to fix mistakes before moving forward.

Where possible, default values are suggested for faster entry.

5. Loop and Exit
After completing a task, the script returns users to the main menu, where they can perform another action or exit at any time.

The menu remains active in a loop until the user chooses to exit.

Example (Shell Script Menu)
bash
#!/bin/bash

while true; do
  echo "===== Test Plan Manager ====="
  echo "1. Create Test Plan"
  echo "2. View Test Plans"
  echo "3. Stage & Run Test Plan"
  echo "4. Delete Test Plan"
  echo "5. Exit"
  read -p "Select option [1-5]: " choice

  case $choice in
    1) ./create_test_plan.sh ;;
    2) ./view_test_plans.sh ;;
    3) ./stage_run_test.sh ;;
    4) ./delete_test_plan.sh ;;
    5) echo "Exiting..."; break ;;
    *) echo "Invalid choice. Try again." ;;
  esac
done
Key Benefits
User-Friendly: No commands to memorize—just follow the menus.

Error-Resistant: All user inputs are validated; mistakes are caught and explained.

Efficient: Default values, shortcuts, and clear navigation help speed up daily tasks.

Consistent: Every action—create, view, stage, delete—is traceable and repeatable.

Try It Out
Clone the repository, run the main script (./menu_main.sh), and follow the on-screen options to manage your Dev Testing workflow!

Menu-driven interfaces are ideal for making automation accessible and reducing learning curves, while still offering powerful functionality as needs grow
