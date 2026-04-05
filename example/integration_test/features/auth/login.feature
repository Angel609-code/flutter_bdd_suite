@auth @regression
Feature: User Authentication
  As a user
  I want to be able to log in to the application
  So that I can access my personalized dashboard

  Scenario Outline: Logging in with various credentials
    Given I fill the "username_field" field with "<username>"
    And I fill the "password_field" field with "<password>"
    When I click in input with key "login_button"
    Then I should see "<expected_message>"

    Examples:
      | username | password    | expected_message                   |
      | wrong    | pass        | Invalid credentials.               |
      |          |             | Username and password are required.|
      | admin    | password123 | Welcome to the Dashboard!          |
