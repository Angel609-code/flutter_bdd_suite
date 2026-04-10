import 'dart:io';

void main() {
  var file = File('example/integration_test/app_test.dart');
  var content = file.readAsStringSync();

  var replacements = {
    '// Background: Given the app is freshly launched at the login screen': '// Background: Given the application is launched',
    '// Background: Given the app is freshly launched': '// Background: Given the application is launched',
    '// Given the login screen is visible': '// Given the login screen is visible',
    '// When I enter the username "<username>"': '// When I fill the "Username" field with "<username>"',
    '// And I enter the password "<password>"': '// And I fill the "Password" field with "<password>"',
    '// And I tap the login button': '// And I tap the "Login" button',
    '// And the dashboard reachability matches the expected outcome': '// And I should reach the dashboard based on expected outcome',
    '// Then I am redirected to the Dashboard': '// Then I should reach the dashboard',
    '// Then I remain on the login screen': '// Then I should not reach the dashboard',
    '// Then I should see the app name': '// Then I should see the text "TeamSync"',
    '// And I should see the subtitle': '// And I should see the text "Employee Directory"',
    '// And the login form fields are present': '// And the "Username" field is visible\n      // And the "Password" field is visible',
    '// Background: Given the user is logged in as admin': '// Background: Given the application is launched\n    // And I fill the "Username" field with "admin"\n    // And I fill the "Password" field with "password123"\n    // And I tap the "Login" button\n    // Then I should see the text "Welcome to the Dashboard!"',
    '// Given the user is logged in': '// Given the application is launched\n        // And I fill the "Username" field with "admin"\n        // And I fill the "Password" field with "password123"\n        // And I tap the "Login" button',
    '// Then I should see the welcome message': '// Then I should see the text "Welcome to the Dashboard!"',
    '// And the employee DataTable should be visible': '// And the employee table is visible',
    '// And the initial employees are displayed': '// And I should see the text "Alice Johnson"\n        // And I should see the text "Bob Martinez"\n        // And I should see the text "Carol White"',
    '// Then the "Total Employees" stat card shows 3': '// Then I should see the text "3"',
    '// And the stat card label "Total Employees" is present': '// And I should see the text "Total Employees"',
    '// And "Average Age" label is present': '// And I should see the text "Average Age"',
    '// Background: Given the user is logged in and on the Dashboard': '// Background: Given the application is launched\n          // And I fill the "Username" field with "admin"\n          // And I fill the "Password" field with "password123"\n          // And I tap the "Login" button',
    '// When I tap the "Add Employee" FAB': '// When I tap the "Add Employee" button',
    '// Then the "Add Employee" dialog opens': '// Then the employee dialog opens\n          // And I should see the text "Add Employee"',
    '// When I fill "employee_name_field" with "David Kim"': '// When I fill the "Employee Name" field with "David Kim"',
    '// And I fill "employee_role_field" with "Analyst"': '// And I fill the "Employee Role" field with "Analyst"',
    '// And I fill "employee_age_field" with "35"': '// And I fill the "Employee Age" field with "35"',
    '// And I fill "employee_bio_field" with a multi-line biography': '// And I fill the "Employee Bio" field with "Business analyst with expertise in data.\\nSix years experience."',
    '// And I tap "save_employee_button"': '// And I tap the "Save Employee" button',
    '// Then the dialog is dismissed': '// Then the employee dialog is hidden',
    '// And "David Kim" now appears in the employee table': '// And I should see the text "David Kim"\n          // And I should see the text "Analyst"',
    '// When I open the Add Employee dialog': '// When I tap the "Add Employee" button',
    '// And I fill the required fields': '// And I fill the "Employee Name" field with "<name>"\n            // And I fill the "Employee Role" field with "Tester"\n            // And I fill the "Employee Age" field with "<age>"',
    '// And I tap the Save button': '// And I tap the "Save Employee" button',
    '// Then the dialog closes and the employee is visible': '// Then the employee dialog is hidden\n              // And I should see the text "<name>"',
    '// Then the dialog remains open with a validation error': '// Then the employee dialog is visible\n              // And I should see the text "Employee must be at least 18 years old"',
    '// And I leave the name field empty but fill in other fields': '// And I fill the "Employee Role" field with "Developer"\n        // And I fill the "Employee Age" field with "25"',
    '// When I tap Save': '// When I tap the "Save Employee" button',
    '// Then I see "Name is required" validation message': '// Then I should see the text "Name is required"',
    '// And the dialog is still open': '// And the employee dialog is visible',
    '// And I fill the name and role': '// And I fill the "Employee Name" field with "Test User"\n        // And I fill the "Employee Role" field with "QA"',
    '// And I enter a non-numeric age': '// And I fill the "Employee Age" field with "abc"',
    '// Then I see "Age must be a number"': '// Then I should see the text "Age must be a number"',
    '// And "Alice Johnson" is visible in the table': '// And I should see the text "Alice Johnson"',
    '// When I tap the delete button for the first employee (index 0)': '// When I scroll to the "Delete Employee 0" button\n          // And I tap the "Delete Employee 0" button',
    '// Then a confirmation dialog appears': '// Then the delete confirmation dialog appears\n          // And I should see the text "Delete Employee"',
    '// When I tap "Delete" to confirm': '// When I tap the "Confirm Delete" button',
    '// Then "Alice Johnson" is no longer in the table': '// Then I should not see the text "Alice Johnson"',
    '// And "Alice Johnson" is visible': '// And I should see the text "Alice Johnson"',
    '// When I tap the delete button for the first employee': '// When I scroll to the "Delete Employee 0" button\n          // And I tap the "Delete Employee 0" button',
    '// Then the confirmation dialog appears': '// Then the delete confirmation dialog appears',
    '// When I tap "Cancel"': '// When I tap the "Cancel Delete" button',
    '// And "Alice Johnson" is still present': '// And I should see the text "Alice Johnson"',
    '// And "Bob Martinez" is visible': '// And I should see the text "Bob Martinez"',
    '// When I tap the edit button for the second employee (index 1)': '// When I scroll to the "Edit Employee 1" button\n        // And I tap the "Edit Employee 1" button',
    '// Then the "Edit Employee" dialog opens with pre-filled data': '// Then I should see the text "Edit Employee"',
    '// When I clear and update the name field': '// When I tap the "Employee Name" field\n        // And I fill the "Employee Name" field with "Robert Martinez"',
    '// And I tap Save': '// And I tap the "Save Employee" button',
    '// Then the updated name "Robert Martinez" appears in the table': '// Then I should see the text "Robert Martinez"',
    '// And the old name "Bob Martinez" is no longer present': '// And I should not see the text "Bob Martinez"',
    '// When I type the query into the search field': '// When I fill the "Search" field with "<query>"',
    '// Then only matching employees are shown': '// Then I should see the text "<visibleName>" if applicable',
    '// And non-matching employees are hidden': '// And I should not see the text "<hiddenName>"',
    '// And the empty state message is shown': '// And the empty employee message is visible',
    '// Then the DataTable column headers are visible': '// Then I should see the text "ID"\n      // And I should see the text "Name"\n      // And I should see the text "Role"\n      // And I should see the text "Age"\n      // And I should see the text "Biography"\n      // And I should see the text "Actions"',
    '// And I fill in a name': '// And I fill the "Employee Name" field with "Ghost Employee"',
    '// When I tap Cancel': '// When I tap the "Cancel Employee" button',
    '// Then the dialog is closed': '// Then the employee dialog is hidden',
    '// And "Ghost Employee" was NOT added': '// And I should not see the text "Ghost Employee"',
    '// Background: Given the user is logged in and has navigated to Dialogs': '// Background: Given the application is launched\n    // And I fill the "Username" field with "admin"\n    // And I fill the "Password" field with "password123"\n    // And I tap the "Login" button\n    // And I tap the "Dialogs Action" button\n    // Then I should see the text "Interactions & Dialogs"',
    '// Then the Dialogs screen title is visible': '// Then I should see the text "Interactions & Dialogs"',
    '// When I tap "Show Alert Dialog"': '// When I tap the "Show Alert" button',
    '// Then the alert dialog content is visible': '// Then I should see the text "This is a simple alert dialog."',
    '// When I tap "OK"': '// When I tap the "Alert OK" button',
    '// Then the alert dialog is dismissed': '// Then I should not see the text "This is a simple alert dialog."',
    '// When I tap "Show Confirmation Dialog"': '// When I tap the "Show Confirmation" button',
    '// Then the confirmation prompt is visible': '// Then I should see the text "Are you sure you want to proceed?"',
    '// When I tap "Yes"': '// When I tap the "Confirm Yes" button',
    '// Then the dialog is gone': '// Then I should not see the text "Are you sure you want to proceed?"',
    '// Then the confirmation prompt is shown': '// Then I should see the text "Are you sure you want to proceed?"',
    '// When I tap "Show Bottom Sheet"': '// When I tap the "Show Bottom Sheet" button',
    '// Then the bottom sheet title is visible': '// Then I should see the text "Bottom Sheet Options"',
    '// And both options are present': '// And the "Bottom Sheet Option 1" button is visible\n      // And the "Bottom Sheet Option 2" button is visible',
    '// When I tap option 1 (Share)': '// When I tap the "Bottom Sheet Option 1" button',
    '// Then the bottom sheet is dismissed': '// Then I should not see the text "Bottom Sheet Options"',
    '// When I tap "Show Snackbar"': '// When I tap the "Show Snackbar" button',
    '// Then the snackbar message is visible': '// Then I should see the text "This is a snackbar message!"',
    '// When I tap the trigger button': '// When I tap the "<triggerKey>" button',
    '// Then the dialog content is visible': '// Then I should see the text "<contentText>"',
    '// When I tap the dismiss button': '// When I tap the "<dismissKey>" button',
    '// Then the dialog content is gone': '// Then I should not see the text "<contentText>"',
    '// Background: Given the user is logged in and on the Files screen': '// Background: Given the application is launched\n    // And I fill the "Username" field with "admin"\n    // And I fill the "Password" field with "password123"\n    // And I tap the "Login" button\n    // And I tap the "Files Action" button\n    // Then I should see the text "File Management"',
    '// Then the screen title is visible': '// Then I should see the text "File Management"',
    '// And the status message says no files imported yet': '// And I should see the text "No files imported yet."',
    '// And the empty files list placeholder is shown': '// And I should see the text "Empty list"',
    '// Given the status message shows no files imported': '// Given I should see the text "No files imported yet."',
    '// When I tap "Import CSV"': '// When I tap the "Import CSV" button',
    '// Then the status message updates': '// Then I should see the text "CSV file imported successfully."',
    '// And the imported files list is no longer empty': '// And I should not see the text "Empty list"\n        // And the imported files list is visible',
    '// And the parsed CSV DataTable is shown': '// And the parsed CSV table is visible',
    '// And the CSV column headers are visible': '// And I should see the text "name"\n        // And I should see the text "role"\n        // And I should see "age"\n        // And I should see the text "email"',
    '// And sample data rows are visible': '// And I should see the text "Alice Johnson"\n        // And I should see the text "Engineer"',
    '// Given I have imported a CSV file': '// Given I tap the "Import CSV" button',
    '// And the table view is shown': '// And the parsed CSV table is visible',
    '// When I tap "Raw View"': '// When I tap the "Toggle Raw" button',
    '// Then the raw CSV text is visible': '// Then the raw CSV content is visible',
    '// And the raw text contains the CSV header line': '// And I should see the text "name,role,age,email"',
    '// And the table view is hidden': '// And the parsed CSV table is hidden',
    '// When I tap "Table View" to toggle back': '// When I tap the "Toggle Raw" button',
    '// Then the table view is restored': '// Then the parsed CSV table is visible',
    '// And the raw content is hidden': '// And the raw CSV content is hidden',
    '// When I tap "Export CSV"': '// When I tap the "Export CSV" button',
    '// Then the status message confirms the export': '// Then I should see the text "Data exported to CSV successfully."',
    '// When I tap "Import CSV" the first time': '// When I tap the "Import CSV" button',
    '// Then one file entry is in the list': '// Then the "File Item 0" element is visible',
    '// When I tap "Import CSV" again': '// When I tap the "Import CSV" button',
    '// Then two file entries are in the list': '// Then the "File Item 0" element is visible\n        // And the "File Item 1" element is visible',
    '// Background: Given the user is logged in and on the Settings screen': '// Background: Given the application is launched\n    // And I fill the "Username" field with "admin"\n    // And I fill the "Password" field with "password123"\n    // And I tap the "Login" button\n    // And I tap the "Settings Action" button\n    // Then I should see the text "Enable Notifications"',
    '// Then the notifications switch is present': '// Then the "Notifications" switch is visible',
    '// And it is initially ON (the SwitchListTile value is true)': '// And the "Notifications" switch is ON',
    '// When I tap the switch to disable notifications': '// When I tap the "Notifications" switch',
    '// Then the switch is now OFF': '// Then the "Notifications" switch is OFF',
    '// When I tap the switch again to re-enable': '// When I tap the "Notifications" switch',
    '// Then the switch is ON again': '// Then the "Notifications" switch is ON',
    '// Then the dark mode checkbox is present': '// Then the "Dark Mode" checkbox is visible',
    '// And it is initially unchecked': '// And the "Dark Mode" checkbox is OFF',
    '// When I tap the checkbox to enable dark mode': '// When I tap the "Dark Mode" checkbox',
    '// Then the checkbox is checked': '// Then the "Dark Mode" checkbox is ON',
    '// Then the volume slider is present': '// Then the volume slider is visible',
    '// And the volume label shows the initial value "50"': '// And I should see the text "Current Volume: 50"',
    '// When I tap "View Terms & Conditions"': '// When I tap the "View Terms" button',
    '// Then the Terms dialog opens': '// Then I should see the text "Terms & Conditions"',
    '// And the terms content is visible (doc-string style verification)': '// And the terms text is visible\n        // And I should see the text "Please read our terms and conditions"',
    '// When I tap "Close"': '// When I tap the "Close Terms" button',
    '// Then the terms dialog is dismissed': '// Then I should not see the text "Terms & Conditions"',
    '// And the settings screen is still visible': '// And I should see the text "Enable Notifications"',
    '//   Given the user is logged in\n    //   And they are on the Dashboard': '// Background: Given the application is launched\n    // And I fill the "Username" field with "admin"\n    // And I fill the "Password" field with "password123"\n    // And I tap the "Login" button\n    // Then I should see the text "Welcome to the Dashboard!"',
    '// When I tap the navigation action': '// When I tap the "<actionKey>" button',
    '// Then I see the expected screen content': '// Then I should see the text "<expectedText>"',
    '// And I can navigate back to the Dashboard using the back button': '// And I tap the OS back button',
    '// Then the Dashboard welcome message is visible again': '// Then I should see the text "Welcome to the Dashboard!"',
    '// When I navigate to Settings': '// When I tap the "Settings Action" button',
    '// And I tap the OS back button (simulated via Navigator.pop)': '// And I tap the OS back button',
    '// Then I am back on the Dashboard': '// Then I should see the text "Welcome to the Dashboard!"\n        // And the "Add Employee" button is visible',
    '// Given I launch the app and log in as admin': '// Given the application is launched\n      // And I fill the "Username" field with "admin"\n      // And I fill the "Password" field with "password123"\n      // And I tap the "Login" button',
    '// Then I am on the Dashboard': '// Then I should see the text "Welcome to the Dashboard!"',
    '// When I tap "Add Employee"': '// When I tap the "Add Employee" button',
    '// And I fill in all fields': '// And I fill the "Employee Name" field with "Eve Torres"\n      // And I fill the "Employee Role" field with "DevOps"\n      // And I fill the "Employee Age" field with "29"\n      // And I fill the "Employee Bio" field with "Infrastructure engineer specialising in CI/CD pipelines."',
    '// And I save the employee': '// And I tap the "Save Employee" button',
    '// Then "Eve Torres" appears in the employee table': '// Then I should see the text "Eve Torres"\n      // And I should see the text "DevOps"',
    '// When I search for "Eve"': '// When I fill the "Search" field with "Eve"',
    '// Then only "Eve Torres" is visible': '// Then I should see the text "Eve Torres"\n      // And I should not see the text "Alice Johnson"',
    '// When I clear the search': '// When I fill the "Search" field with ""',
    '// Then all employees are shown again': '// Then I should see the text "Alice Johnson"\n      // And I should see the text "Eve Torres"',
    '// When I tap the edit button for "Eve Torres" (she is last = index 3)': '// When I scroll to the "Edit Employee 3" button\n      // And I tap the "Edit Employee 3" button',
    '// Then the edit dialog opens': '// Then I should see the text "Edit Employee"',
    '// When I update the role': '// When I fill the "Employee Role" field with "Senior DevOps"',
    '// And I save': '// And I tap the "Save Employee" button',
    '// Then the updated role is visible': '// Then I should see the text "Senior DevOps"',
    '// When I tap the delete button for "Eve Torres" (still index 3)': '// When I scroll to the "Delete Employee 3" button\n      // And I tap the "Delete Employee 3" button',
    '// Then the confirmation dialog appears': '// Then the delete confirmation dialog appears\n      // And I should see the text "Delete Employee"',
    '// When I confirm deletion': '// When I tap the "Confirm Delete" button',
    '// Then "Eve Torres" is no longer in the table': '// Then I should not see the text "Eve Torres"',
    '// And the original employees are still present': '// And I should see the text "Alice Johnson"\n      // And I should see the text "Bob Martinez"\n      // And I should see the text "Carol White"',
  };

  replacements.forEach((key, value) {
    content = content.replaceAll(key, value);
  });

  // Hand written replaces that need Regex
  content = content.replaceAllMapped(
    RegExp(r'// When I enter the username "([^"]+)"'),
    (m) => '// When I fill the "Username" field with "${m.group(1)}"'
  );

  content = content.replaceAllMapped(
    RegExp(r'// And I enter the password "([^"]+)"'),
    (m) => '// And I fill the "Password" field with "${m.group(1)}"'
  );

  content = content.replaceAll(
    RegExp(r'// And I tap the login button'),
    '// And I tap the "Login" button'
  );

  content = content.replaceAll(
    RegExp(r'// Then I should see "([^"]+)"'),
    r'// Then I should see the text "$1"'
  );

  content = content.replaceAll(
    RegExp(r'// Background: Given the user is logged in\n'),
    ''
  );

  content = content.replaceAll(
    RegExp(r'//   Given I launch the TeamSync app\n    //   And I log in as "admin" / "password123"\n    //   And I tap the "dialogs_action" icon\n    //   Then I should see "Interactions & Dialogs"'),
    ''
  );

  content = content.replaceAll(
    RegExp(r'//   Given I launch the TeamSync app\n    //   And I log in as "admin"\n    //   And I tap "files_action"\n    //   Then I should see "File Management"'),
    ''
  );

  content = content.replaceAll(
    RegExp(r'//   Given I launch the TeamSync app\n    //   And I log in as "admin"\n    //   And I tap "settings_action"\n    //   Then I should see the Settings screen'),
    ''
  );

  content = content.replaceAll(
    RegExp(r'// When I tap the "Import CSV" button the first time'),
    '// When I tap the "Import CSV" button'
  );

  content = content.replaceAll(
    RegExp(r'// When I tap the "Import CSV" button again'),
    '// When I tap the "Import CSV" button'
  );

  content = content.replaceAll(
    RegExp(r'// When I tap the "Cancel Delete" button\n\s+await tester.tap\(find.byKey\(const Key\(\x27delete_cancel_button\x27\)\)\);\n\s+await tester.pumpAndSettle\(\);\n\n\s+// Then the employee dialog is hidden'),
    '// When I tap the "Cancel Delete" button\n          await tester.tap(find.byKey(const Key(\'delete_cancel_button\')));\n          await tester.pumpAndSettle();\n\n          // Then the delete confirmation dialog is hidden'
  );

  content = content.replaceAll(
    RegExp(r'// When I tap the "Cancel Delete" button\n\s+await tester.tap\(find.byKey\(const Key\(\x27confirm_cancel_button\x27\)\)\);\n\s+await tester.pumpAndSettle\(\);\n\n\s+// Then the employee dialog is hidden'),
    '// When I tap the "Cancel Delete" button\n        await tester.tap(find.byKey(const Key(\'confirm_cancel_button\')));\n        await tester.pumpAndSettle();\n\n        // Then I should not see the text "Are you sure you want to proceed?"'
  );

  file.writeAsStringSync(content);
}
