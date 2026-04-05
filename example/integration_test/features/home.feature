Feature: Home Dashboard Features
  As an authenticated user
  I want to view and manage my data on the home screen
  So that I can keep track of items and users

  Background:
    Given I fill the "username_field" field with "admin"
    And I fill the "password_field" field with "password123"
    And I click in input with key "login_button"
    And I should see "Welcome to the Dashboard!"

  Scenario: Interacting with lists and dialogs
    When I scroll until "list_item_15" is visible
    And I should see "Item 15"
    And I click in input with key "add_user_fab"
    Then I should see "Do you want to add a new user?"
    When I click in input with key "dialog_confirm"
    Then I should not see "Do you want to add a new user?"

  Scenario: Printing and verifying table data
    Given I print table
      | ID | Name        | Status  |
      | 1  | John Doe    | Active  |
      | 2  | Jane Smith  | Inactive|
      | 3  | Bob Johnson | Active  |
    Then I should see "Bob Johnson"
