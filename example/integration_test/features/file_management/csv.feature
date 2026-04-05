@file_management
Feature: File Management and CSV Operations
  As a data manager
  I want to import and export CSV files
  So that I can analyze offline data

  Background:
    Given I fill the "username_field" field with "admin"
    And I fill the "password_field" field with "password123"
    And I click in input with key "login_button"
    And I click in input with key "files_action"
    Then I should see "File Management"

  Scenario: Importing and Exporting CSV files
    Given I should see "No files imported yet."
    When I click in input with key "import_csv_button"
    Then I should see "CSV file imported successfully."
    And I should not see "Empty list"
    When I click in input with key "export_csv_button"
    Then I should see "Data exported to CSV successfully."
