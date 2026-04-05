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
  Scenario: Verifying user management data table
    Given I print table
      | ID | Name        | Status  |
      | 1  | John Doe    | Active  |
      | 2  | Jane Smith  | Inactive|
      | 3  | Bob Johnson | Active  |
    Then I should see "Bob Johnson"
