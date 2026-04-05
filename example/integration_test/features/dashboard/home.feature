@dashboard @smoke
Feature: Dashboard and Data Tables
  As an authenticated user
  I want to view my dashboard
  So that I can see recent items and manage users

  Background:
    Given I fill the "username_field" field with "admin"
    And I fill the "password_field" field with "password123"
    And I click in input with key "login_button"
    And I should see "Welcome to the Dashboard!"

  @dialog
  Scenario: Adding a new user via dialog
    When I click in input with key "add_user_fab"
    Then I should see "Do you want to add a new user?"
    When I click in input with key "dialog_confirm"
    Then I should not see "Do you want to add a new user?"

  @data_table
  Example: Verifying user management data table with escaping
    * I print table
      | ID | Name        | Info                 |
      | 1  | John Doe    | Role: Admin\nActive  |
      | 2  | Jane Smith  | Role: User\|Inactive |
      | 3  | Bob Johnson | Dir: C:\\Users\\Bob  |
    Then I should see "Bob Johnson"

  Rule: Admin Dashboard Rules
    Background:
      Given I should see "Welcome to the Dashboard!"

    Scenario Outline: Verifying quick links
      When I click in input with key "<link_key>"
      Then I should see "<expected_page>"

      Scenarios:
        | link_key     | expected_page   |
        | settings_btn | Settings        |
        | files_action | File Management |
