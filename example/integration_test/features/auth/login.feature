@auth @regression
Feature: User Authentication
  As a user of TeamSync
  I want to log in with my credentials
  So that I can access the employee directory

  Background:
    Given the application is launched
    And the login screen is visible

  Scenario Outline: Login with different credential combinations
    When I enter the username "<username>"
    And I enter the password "<password>"
    And I tap the login button
    Then I should see "<expectedText>"
    And I <dashboardOutcome> reach the dashboard

    Examples:
      | username | password    | expectedText                        | dashboardOutcome |
      | wrong    | pass        | Invalid credentials.                | should not       |
      |          |             | Username and password are required. | should not       |
      | admin    | password123 | Welcome to the Dashboard!           | should           |

  Scenario: Login screen displays the TeamSync branding
    Then I should see "TeamSync"
    And I should see "Employee Directory"
    And the login form fields are present
