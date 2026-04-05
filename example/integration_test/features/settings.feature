Feature: User Settings
  As an authenticated user
  I want to customize my preferences
  So that the app behaves according to my liking

  Background:
    Given I fill the "username_field" field with "admin"
    And I fill the "password_field" field with "password123"
    And I click in input with key "login_button"
    And I click in input with key "settings_action"
    Then I should see "Enable Notifications"

  Scenario: Toggling settings
    When I click in input with key "notifications_switch"
    And I click in input with key "dark_mode_checkbox"
    And I click in input with key "view_terms_button"
    Then I see text:
      """
      Please read our terms and conditions...
      """
    And I click in input with key "close_terms"
    Then I should not see "Please read our terms and conditions..."
