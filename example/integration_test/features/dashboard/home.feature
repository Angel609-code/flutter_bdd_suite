@dashboard @smoke
Feature: Employee Directory Dashboard
  As an authenticated user
  I want to view the TeamSync employee dashboard
  So that I can see employee records and manage staff

  Background:
    Given I fill the "username_field" field with "admin"
    And I fill the "password_field" field with "password123"
    And I click in input with key "login_button"
    And I should see "Welcome to the Dashboard!"

  @dialog
  Scenario: Adding a new employee via the Add Employee dialog
    When I click in input with key "add_employee_fab"
    Then I should see "Add Employee"
    When I fill the "employee_name_field" field with "Eve Torres"
    And I fill the "employee_role_field" field with "DevOps"
    And I fill the "employee_age_field" field with "29"
    And I click in input with key "save_employee_button"
    Then I should see "Eve Torres"

  @data_table
  Example: Verifying employee data table columns
    * I print table
      | ID | Name          | Role     | Age |
      | 1  | Alice Johnson | Engineer | 30  |
      | 2  | Bob Martinez  | Designer | 27  |
      | 3  | Carol White   | Manager  | 42  |
    Then I should see "Alice Johnson"

  Rule: Admin Dashboard Navigation Rules
    Background:
      Given I should see "Welcome to the Dashboard!"

    Scenario Outline: Verifying quick links from the dashboard
      When I click in input with key "<link_key>"
      Then I should see "<expected_page>"

      Scenarios:
        | link_key        | expected_page          |
        | settings_action | Enable Notifications   |
        | files_action    | File Management        |
