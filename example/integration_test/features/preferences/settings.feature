@preferences
Feature: User Preferences and Settings
  As an authenticated user
  I want to customize my settings
  So that the app reflects my preferences

  Background:
    Given I fill the "username_field" field with "admin"
    And I fill the "password_field" field with "password123"
    And I click in input with key "login_button"
    And I click in input with key "settings_action"
    Then I should see "Enable Notifications"

  @doc_string
  Scenario: Reading terms and conditions
    When I click in input with key "view_terms_button"
    Then I see text:
      """
      Please read our terms and conditions...
      """
    And I click in input with key "close_terms"
    Then I should not see "Please read our terms and conditions..."
