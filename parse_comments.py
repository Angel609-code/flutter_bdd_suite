import re

with open('example/integration_test/app_test.dart', 'r') as f:
    text = f.read()

# Custom mappings
mappings = [
    # Taps
    (r'I tap the login button', 'I tap the "login" button'),
    (r'I tap "login_button"', 'I tap the "login" button'),
    (r'I tap the "Add Employee" FAB', 'I tap the "add employee" button'),
    (r'I tap "save_employee_button"', 'I tap the "save employee" button'),
    (r'I tap the Save button', 'I tap the "save employee" button'),
    (r'I tap Save', 'I tap the "save employee" button'),
    (r'I tap the delete button for the first employee \(index 0\)', 'I tap the "delete employee 0" button'),
    (r'I tap "Delete" to confirm', 'I tap the "delete confirm" button'),
    (r'I tap the delete button for the first employee', 'I tap the "delete employee 0" button'),
    (r'I tap "Cancel"', 'I tap the "delete cancel" button'),
    (r'I tap the edit button for the second employee \(index 1\)', 'I tap the "edit employee 1" button'),
    (r'I tap Cancel', 'I tap the "cancel employee" button'),
    (r'I tap the delete button for "Eve Torres" \(still index 3\)', 'I tap the "delete employee 3" button'),
    (r'I tap the edit button for "Eve Torres" \(she is last = index 3\)', 'I tap the "edit employee 3" button'),
    (r'I tap "Add Employee"', 'I tap the "add employee" button'),
    (r'I confirm deletion', 'I tap the "delete confirm" button'),

    # Inputs
    (r'I enter the username "(.*?)"', 'I fill the "username" field with "\\1"'),
    (r'I enter the password "(.*?)"', 'I fill the "password" field with "\\1"'),
    (r'I fill "username_field" with "admin"', 'I fill the "username" field with "admin"'),
    (r'I fill "password_field" with "password123"', 'I fill the "password" field with "password123"'),
    (r'I fill "employee_name_field" with "David Kim"', 'I fill the "employee name" field with "David Kim"'),
    (r'I fill "employee_role_field" with "Analyst"', 'I fill the "employee role" field with "Analyst"'),
    (r'I fill "employee_age_field" with "35"', 'I fill the "employee age" field with "35"'),
    (r'I fill "employee_bio_field" with a multi-line biography', r'I fill the "employee bio" field with "Business analyst with expertise in data.\\nSix years experience."'),
    (r'I enter a non-numeric age', 'I fill the "employee age" field with "abc"'),
    (r'I fill in a name', 'I fill the "employee name" field with "Ghost Employee"'),
    (r'I update the role', 'I fill the "employee role" field with "Senior DevOps"'),
    (r'I clear the search', 'I fill the "search" field with ""'),
    (r'I search for "Eve"', 'I fill the "search" field with "Eve"'),
    (r'I clear and update the name field', 'I fill the "employee name" field with "Robert Martinez"'),
]

for old, new in mappings:
    text = re.sub(old, new, text)

# Visibility
text = re.sub(r'I should see the app name', r'I should see "TeamSync"', text)
text = re.sub(r'I should see the subtitle', r'I should see "Employee Directory"', text)
text = re.sub(r'I should see the welcome message', r'I should see "Welcome to the Dashboard!"', text)
text = re.sub(r'the employee DataTable should be visible', r'I should see the "employee table" element', text)
text = re.sub(r'the initial employees are displayed', r'I should see "Alice Johnson"\n        // And I should see "Bob Martinez"\n        // And I should see "Carol White"', text)

with open('example/integration_test/app_test_modified.dart', 'w') as f:
    f.write(text)
