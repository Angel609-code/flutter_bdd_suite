@interactions
Feature: Dialogs and Interactions
  As a user
  I want to interact with various types of dialogs
  So that I can confirm actions and view alerts

  Background:
    Given I fill the "username_field" field with "admin"
    And I fill the "password_field" field with "password123"
    And I click in input with key "login_button"
    And I click in input with key "dialogs_action"
    Then I should see "Interactions & Dialogs"

  Scenario: Interacting with an alert dialog
    When I click in input with key "show_alert_button"
    Then I should see "This is a simple alert dialog."
    When I click in input with key "alert_ok_button"
    Then I should not see "This is a simple alert dialog."

  Scenario: Interacting with a confirmation dialog
    When I click in input with key "show_confirm_button"
    Then I should see "Are you sure you want to proceed?"
    When I click in input with key "confirm_cancel_button"
    Then I should not see "Are you sure you want to proceed?"

  Scenario: Interacting with a bottom sheet
    When I click in input with key "show_bottom_sheet_button"
    Then I should see "Bottom Sheet Options"
    When I click in input with key "bottom_sheet_option_1"
    Then I should not see "Bottom Sheet Options"

  Scenario: Interacting with a snackbar
    When I click in input with key "show_snackbar_button"
    Then I should see "This is a snackbar message!"
