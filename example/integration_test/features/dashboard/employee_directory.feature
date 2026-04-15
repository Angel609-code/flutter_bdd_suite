@dashboard @smoke
Feature: Employee Directory Dashboard
  As an authenticated admin user
  I want to view and manage employees
  So that I can maintain an accurate team roster

  Background:
    Given the application is launched
    And I fill the username field with "admin"
    And I fill the password field with "password123"
    And I tap the login button
    Then I should see "Welcome to the Dashboard!"

  Scenario: Dashboard shows welcome message and employee table
    Then I should see "Welcome to the Dashboard!"
    And the employee table should be visible
    And I should see "Alice Johnson"
    And I should see "Bob Martinez"
    And I should see "Carol White"

  Scenario: Dashboard stat cards reflect employee data
    Then I should see multiple "3" texts
    And I should see "Total Employees"
    And I should see "Average Age"

  Rule: Employee records must pass validation
    @docString
    Scenario: Adding employee with valid data adds a table row
      When I tap the add employee button
      Then the employee dialog title should be visible
      And I should see "Add Employee"
      When I fill the employee name field with "David Kim"
      And I fill the employee role field with "Analyst"
      And I fill the employee age field with "35"
      And I fill the employee bio field with:
        """
        Business analyst with expertise in data.
        Six years experience.
        """
      And I tap the save employee button
      Then the employee dialog title should not be visible
      And I should see "David Kim"
      And I should see "Analyst"
      And I print table to test output:
        | Name      | Role    | Age | Biography                                |
        | David Kim | Analyst | 35  | Business analyst with expertise in data. |

    Scenario Outline: Adding employees with boundary ages
      When I tap the add employee button
      And I fill the employee name field with "<name>"
      And I fill the employee role field with "Tester"
      And I fill the employee age field with "<age>"
      And I tap the save employee button
      Then the employee dialog title <dialog_state>
      And I should see "<expected_text>"

      Examples:
        | name         | age | dialog_state          | expected_text                          |
        | Under18Test  | 17  | should be visible     | Employee must be at least 18 years old |
        | Adult18Test  | 18  | should not be visible | Adult18Test                            |
        | Adult100Test | 100 | should not be visible | Adult100Test                           |

    Scenario: Empty name shows validation error
      When I tap the add employee button
      And I fill the employee role field with "Developer"
      And I fill the employee age field with "25"
      And I tap the save employee button
      Then I should see "Name is required"
      And the employee dialog title should be visible

    Scenario: Non-numeric age shows validation error
      When I tap the add employee button
      And I fill the employee name field with "Test User"
      And I fill the employee role field with "QA"
      And I fill the employee age field with "abc"
      And I tap the save employee button
      Then I should see "Age must be a number"

  Rule: Employees can be removed from the directory
    Scenario: Deleting an employee removes them from the table
      Given I should see "Alice Johnson"
      When I tap the delete button for "Alice Johnson"
      Then the delete confirm message should be visible
      And I should see "Delete Employee"
      When I tap the delete confirm button
      Then I should not see "Alice Johnson"

    Scenario: Cancelling delete keeps the employee in the table
      Given I should see "Alice Johnson"
      When I tap the delete button for "Alice Johnson"
      Then the delete confirm message should be visible
      When I tap the delete cancel button
      Then the delete confirm message should not be visible
      And I should see "Alice Johnson"

  Rule: Employee records can be updated via the edit dialog
    Scenario: Editing an employee updates the table row
      Given I should see "Bob Martinez"
      When I tap the edit button for "Bob Martinez"
      Then I should see "Edit Employee"
      When I fill the employee name field with "Robert Martinez"
      And I tap the save employee button
      Then I should see "Robert Martinez"
      And I should not see "Bob Martinez"

  Rule: Search filters visible employees
    Scenario Outline: Searching by name narrows the displayed employees
      When I fill the search field with "<query>"
      Then I should see "<expected_visible>"
      And I should not see "<expected_hidden>"

      Examples:
        | query   | expected_visible | expected_hidden |
        | Alice   | Alice Johnson    | Bob Martinez    |
        | Manager | Carol White      | Alice Johnson   |

    Scenario: Searching by name narrows the displayed employees empty state
      When I fill the search field with "xyznotfound"
      Then I should not see "Alice Johnson"
      And the empty employee text should be visible

    Scenario: Employee table displays all required columns
      Then I should see "ID"
      And I should see "Name"
      And I should see "Role"
      And I should see "Age"
      And I should see "Biography"
      And I should see "Actions"

    Scenario: Cancelling the Add Employee dialog saves nothing
      Given I should see "Alice Johnson"
      When I tap the add employee button
      And I fill the employee name field with "Ghost Employee"
      And I tap the cancel employee button
      Then the employee dialog title should not be visible
      And I should not see "Ghost Employee"