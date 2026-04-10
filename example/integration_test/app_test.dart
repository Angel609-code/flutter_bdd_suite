// =============================================================================
// @desktop @mobile @web @employee_management @teamsync
//
// Feature: TeamSync — Comprehensive Employee Directory Integration Tests
//
// As a user of the TeamSync application
// I want to manage employee records, use dialogs, import/export CSV files
// And configure application settings
// So that I can efficiently manage my team's information
//
// NOTE: This file uses VANILLA Flutter integration tests (testWidgets) only.
// It does NOT depend on any BDD, Cucumber, or Gherkin parsing packages.
// Gherkin keywords are used exclusively as comments for clarity and mapping.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:example/main.dart';
import 'package:example/app_theme.dart';

// =============================================================================
// Helper utilities — reusable pump+action shortcuts used across all tests
// =============================================================================

/// Pump the full application fresh from the login screen.
///
/// Also resets global state (theme) so tests don't interfere with each other.
Future<void> launchApp(WidgetTester tester) async {
  themeNotifier.value = ThemeMode.light;
  await tester.pumpWidget(const BddExampleApp());
  await tester.pumpAndSettle();
}

/// Perform a login with the supplied [username] and [password].
Future<void> loginWith(
  WidgetTester tester, {
  required String username,
  required String password,
}) async {
  // Clear any previous text before typing
  final usernameField = find.byKey(const Key('username_field'));
  final passwordField = find.byKey(const Key('password_field'));

  await tester.tap(usernameField);
  await tester.pump();
  await tester.enterText(usernameField, username);
  await tester.pump();

  await tester.tap(passwordField);
  await tester.pump();
  await tester.enterText(passwordField, password);
  await tester.pump();

  await tester.tap(find.byKey(const Key('login_button')));
  await tester.pumpAndSettle();
}

/// Log in as the default admin user and land on the Dashboard.
Future<void> loginAsAdmin(WidgetTester tester) async {
  await loginWith(tester, username: 'admin', password: 'password123');
}

/// Navigate to a named screen from the Dashboard app-bar actions.
Future<void> navigateTo(WidgetTester tester, String routeKey) async {
  await tester.tap(find.byKey(Key(routeKey)));
  await tester.pumpAndSettle();
}

// =============================================================================
// Main test entry point
// =============================================================================

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ---------------------------------------------------------------------------
  // @Tags: @auth @regression
  // Feature: User Authentication
  //   As a user of TeamSync
  //   I want to log in with my credentials
  //   So that I can access the employee directory
  // ---------------------------------------------------------------------------
  group('Feature: User Authentication', () {
    // -------------------------------------------------------------------------
    // Scenario Outline: Logging in with various credential combinations
    //   <username>  | <password>     | <expected_outcome>
    // -------------------------------------------------------------------------

    // The outline data table below is simulated as a plain Dart list.
    // Each map corresponds to one row in a Gherkin Examples table.
    //
    // Examples:
    //   | username | password    | expectedText                        | shouldReachDashboard |
    //   | wrong    | pass        | Invalid credentials.                | false                |
    //   |          |             | Username and password are required. | false                |
    //   | admin    | password123 | Welcome to the Dashboard!           | true                 |

    final loginExamples = [
      {
        'username': 'wrong',
        'password': 'pass',
        'expectedText': 'Invalid credentials.',
        'shouldReachDashboard': false,
      },
      {
        'username': '',
        'password': '',
        'expectedText': 'Username and password are required.',
        'shouldReachDashboard': false,
      },
      {
        'username': 'admin',
        'password': 'password123',
        'expectedText': 'Welcome to the Dashboard!',
        'shouldReachDashboard': true,
      },
    ];

    for (final example in loginExamples) {
      // Scenario Outline instance: "${example['username']} / ${example['password']}"
      testWidgets(
        'Scenario: Login with username="${example['username']}" password="${example['password']}"',
        (WidgetTester tester) async {
          // Background: Given the application is launched
          await launchApp(tester);

          // Given the login screen is visible
          expect(find.byKey(const Key('username_field')), findsOneWidget);
          expect(find.byKey(const Key('password_field')), findsOneWidget);
          expect(find.byKey(const Key('login_button')), findsOneWidget);

          // When I fill the "Username" field with "<username>"
          await tester.enterText(
            find.byKey(const Key('username_field')),
            example['username'] as String,
          );
          await tester.pump();

          // And I fill the "Password" field with "<password>"
          await tester.enterText(
            find.byKey(const Key('password_field')),
            example['password'] as String,
          );
          await tester.pump();

          // And I tap the "Login" button
          await tester.tap(find.byKey(const Key('login_button')));
          await tester.pumpAndSettle();

          // Then I should see the text "$1"
          expect(
            find.textContaining(example['expectedText'] as String),
            findsOneWidget,
          );

          // And I should reach the dashboard based on expected outcome
          if (example['shouldReachDashboard'] == true) {
            // Then I should reach the dashboard
            expect(find.byKey(const Key('add_employee_fab')), findsOneWidget);
          } else {
            // Then I should not reach the dashboard
            expect(find.byKey(const Key('login_button')), findsOneWidget);
          }
        },
      );
    }

    // -------------------------------------------------------------------------
    // Scenario: Login screen displays the TeamSync branding
    // -------------------------------------------------------------------------
    testWidgets('Scenario: Login screen shows TeamSync branding', (
      WidgetTester tester,
    ) async {
      // Background: Given the application is launched
      await launchApp(tester);

      // Then I should see the text "TeamSync"
      expect(find.text('TeamSync'), findsOneWidget);

      // And I should see the text "Employee Directory"
      expect(find.text('Employee Directory'), findsOneWidget);

      // And the "Username" field is visible
      // And the "Password" field is visible
      expect(find.byKey(const Key('username_field')), findsOneWidget);
      expect(find.byKey(const Key('password_field')), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // @Tags: @dashboard @smoke
  // Feature: Employee Directory Dashboard
  //   As an authenticated admin user
  //   I want to view and manage employees
  //   So that I can maintain an accurate team roster
  // ---------------------------------------------------------------------------
  group('Feature: Employee Directory Dashboard', () {
    // Background: Given the application is launched
    // And I fill the "Username" field with "admin"
    // And I fill the "Password" field with "password123"
    // And I tap the "Login" button
    // Then I should see the text "Welcome to the Dashboard!"
    setUp(() async {
      // NOTE: setUp does not receive a WidgetTester; the actual pump
      // and login steps are performed at the start of each testWidgets.
      // This comment documents the Gherkin Background intent:
      //
      // Background:
      //   Given I launch the TeamSync app
      //   And I fill "username_field" with "admin"
      //   And I fill "password_field" with "password123"
      //   And I tap "login_button"
      //   Then I should see "Welcome to the Dashboard!"
    });

    // -------------------------------------------------------------------------
    // Scenario: Dashboard displays the welcome message and employee table
    // -------------------------------------------------------------------------
    testWidgets(
      'Scenario: Dashboard shows welcome message and employee table',
      (WidgetTester tester) async {
        // Given the application is launched
        // And I fill the "Username" field with "admin"
        // And I fill the "Password" field with "password123"
        // And I tap the "Login" button
        await launchApp(tester);
        await loginAsAdmin(tester);

        // Then I should see the text "Welcome to the Dashboard!"
        expect(find.text('Welcome to the Dashboard!'), findsOneWidget);

        // And the employee table is visible
        expect(find.byKey(const Key('employee_table')), findsOneWidget);

        // And I should see the text "Alice Johnson"
        // And I should see the text "Bob Martinez"
        // And I should see the text "Carol White"
        expect(find.text('Alice Johnson'), findsOneWidget);
        expect(find.text('Bob Martinez'), findsOneWidget);
        expect(find.text('Carol White'), findsOneWidget);
      },
    );

    // -------------------------------------------------------------------------
    // Scenario: Dashboard shows summary stat cards
    // -------------------------------------------------------------------------
    testWidgets('Scenario: Dashboard stat cards reflect employee data', (
      WidgetTester tester,
    ) async {
      // Given the application is launched
        // And I fill the "Username" field with "admin"
        // And I fill the "Password" field with "password123"
        // And I tap the "Login" button
      await launchApp(tester);
      await loginAsAdmin(tester);

      // Then I should see the text "3"
      expect(find.text('3'), findsWidgets); // may match multiple text nodes

      // And I should see the text "Total Employees"
      expect(find.text('Total Employees'), findsOneWidget);

      // And I should see the text "Average Age"
      expect(find.text('Average Age'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Rule: Only valid employee records may be submitted
    //   (An employee must have a name, a role, and be at least 18 years old)
    // -------------------------------------------------------------------------

    // Rule group simulates the Gherkin `Rule:` block with nested scenarios.
    group('Rule: Employee records must pass validation', () {
      // -----------------------------------------------------------------------
      // Scenario: Adding an employee with valid data succeeds
      // -----------------------------------------------------------------------
      testWidgets(
        'Scenario: Adding employee with valid data adds a table row',
        (WidgetTester tester) async {
          // Background: Given the application is launched
          // And I fill the "Username" field with "admin"
          // And I fill the "Password" field with "password123"
          // And I tap the "Login" button
          await launchApp(tester);
          await loginAsAdmin(tester);

          // When I tap the "Add Employee" button
          await tester.tap(find.byKey(const Key('add_employee_fab')));
          await tester.pumpAndSettle();

          // Then the employee dialog opens
          // And I should see the text "Add Employee"
          expect(
            find.byKey(const Key('employee_dialog_title')),
            findsOneWidget,
          );
          expect(find.text('Add Employee'), findsWidgets);

          // When I fill the "Employee Name" field with "David Kim"
          await tester.enterText(
            find.byKey(const Key('employee_name_field')),
            'David Kim',
          );
          await tester.pump();

          // And I fill the "Employee Role" field with "Analyst"
          await tester.enterText(
            find.byKey(const Key('employee_role_field')),
            'Analyst',
          );
          await tester.pump();

          // And I fill the "Employee Age" field with "35"
          await tester.enterText(
            find.byKey(const Key('employee_age_field')),
            '35',
          );
          await tester.pump();

          // And I fill the "Employee Bio" field with "Business analyst with expertise in data.\nSix years experience."
          await tester.enterText(
            find.byKey(const Key('employee_bio_field')),
            'Business analyst with expertise in data.\nSix years experience.',
          );
          await tester.pump();

          // And I tap the "Save Employee" button
          await tester.tap(find.byKey(const Key('save_employee_button')));
          await tester.pumpAndSettle();

          // Then the employee dialog is hidden
          expect(find.byKey(const Key('employee_dialog_title')), findsNothing);

          // And I should see the text "David Kim"
          // And I should see the text "Analyst"
          expect(find.text('David Kim'), findsOneWidget);
          expect(find.text('Analyst'), findsOneWidget);
        },
      );

      // -----------------------------------------------------------------------
      // Scenario Outline: Adding employees with boundary ages
      //
      // Examples:
      //   | name     | age | shouldSave |
      //   | Under18  | 17  | false      |
      //   | Adult18  | 18  | true       |
      //   | Adult100 | 100 | true       |
      // -----------------------------------------------------------------------

      final ageExamples = [
        {'name': 'Under18Test', 'age': '17', 'shouldSave': false},
        {'name': 'Adult18Test', 'age': '18', 'shouldSave': true},
        {'name': 'Adult100Test', 'age': '100', 'shouldSave': true},
      ];

      for (final ex in ageExamples) {
        testWidgets(
          'Scenario: Add employee age="${ex['age']}" shouldSave=${ex['shouldSave']}',
          (WidgetTester tester) async {
                        await launchApp(tester);
            await loginAsAdmin(tester);

            // When I tap the "Add Employee" button
            await tester.tap(find.byKey(const Key('add_employee_fab')));
            await tester.pumpAndSettle();

            // And I fill the "Employee Name" field with "<name>"
            // And I fill the "Employee Role" field with "Tester"
            // And I fill the "Employee Age" field with "<age>"
            await tester.enterText(
              find.byKey(const Key('employee_name_field')),
              ex['name'] as String,
            );
            await tester.pump();

            await tester.enterText(
              find.byKey(const Key('employee_role_field')),
              'Tester',
            );
            await tester.pump();

            await tester.enterText(
              find.byKey(const Key('employee_age_field')),
              ex['age'] as String,
            );
            await tester.pump();

            // And I tap the "Save Employee" button
            await tester.tap(find.byKey(const Key('save_employee_button')));
            await tester.pumpAndSettle();

            if (ex['shouldSave'] == true) {
              // Then the employee dialog is hidden
              // And I should see the text "<name>"
              expect(
                find.byKey(const Key('employee_dialog_title')),
                findsNothing,
              );
              expect(find.text(ex['name'] as String), findsOneWidget);
            } else {
              // Then the employee dialog is visible
              // And I should see the text "Employee must be at least 18 years old"
              expect(
                find.byKey(const Key('employee_dialog_title')),
                findsOneWidget,
              );
              expect(
                find.text('Employee must be at least 18 years old'),
                findsOneWidget,
              );
            }
          },
        );
      }

      // -----------------------------------------------------------------------
      // Scenario: Submitting empty name shows validation error
      // -----------------------------------------------------------------------
      testWidgets('Scenario: Empty name shows validation error', (
        WidgetTester tester,
      ) async {
                await launchApp(tester);
        await loginAsAdmin(tester);

        // When I tap the "Add Employee" button
        await tester.tap(find.byKey(const Key('add_employee_fab')));
        await tester.pumpAndSettle();

        // And I fill the "Employee Role" field with "Developer"
        // And I fill the "Employee Age" field with "25"
        await tester.enterText(
          find.byKey(const Key('employee_role_field')),
          'Developer',
        );
        await tester.pump();
        await tester.enterText(
          find.byKey(const Key('employee_age_field')),
          '25',
        );
        await tester.pump();

        // When I tap the "Save Employee" button
        await tester.tap(find.byKey(const Key('save_employee_button')));
        await tester.pumpAndSettle();

        // Then I should see the text "Name is required"
        expect(find.text('Name is required'), findsOneWidget);

        // And the employee dialog is visible
        expect(find.byKey(const Key('employee_dialog_title')), findsOneWidget);
      });

      // -----------------------------------------------------------------------
      // Scenario: Submitting a non-numeric age shows validation error
      // -----------------------------------------------------------------------
      testWidgets('Scenario: Non-numeric age shows validation error', (
        WidgetTester tester,
      ) async {
                await launchApp(tester);
        await loginAsAdmin(tester);

        // When I tap the "Add Employee" button
        await tester.tap(find.byKey(const Key('add_employee_fab')));
        await tester.pumpAndSettle();

        // And I fill the "Employee Name" field with "Test User"
        // And I fill the "Employee Role" field with "QA"
        await tester.enterText(
          find.byKey(const Key('employee_name_field')),
          'Test User',
        );
        await tester.pump();
        await tester.enterText(
          find.byKey(const Key('employee_role_field')),
          'QA',
        );
        await tester.pump();

        // And I fill the "Employee Age" field with "abc"
        await tester.enterText(
          find.byKey(const Key('employee_age_field')),
          'abc',
        );
        await tester.pump();

        // When I tap the "Save Employee" button
        await tester.tap(find.byKey(const Key('save_employee_button')));
        await tester.pumpAndSettle();

        // Then I should see the text "Age must be a number"
        expect(find.text('Age must be a number'), findsOneWidget);
      });
    });

    // -------------------------------------------------------------------------
    // Rule: Employees can be deleted from the directory
    // -------------------------------------------------------------------------
    group('Rule: Employees can be removed from the directory', () {
      // -----------------------------------------------------------------------
      // Scenario: Deleting an employee with confirmation removes the row
      // -----------------------------------------------------------------------
      testWidgets(
        'Scenario: Deleting an employee removes them from the table',
        (WidgetTester tester) async {
                    await launchApp(tester);
          await loginAsAdmin(tester);

          // And I should see the text "Alice Johnson"
          expect(find.text('Alice Johnson'), findsOneWidget);

          // When I scroll to the "Delete Employee 0" button
          // And I tap the "Delete Employee 0" button
          await tester.ensureVisible(
            find.byKey(const Key('delete_employee_0')),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('delete_employee_0')));
          await tester.pumpAndSettle();

          // Then the delete confirmation dialog appears
          // And I should see the text "Delete Employee"
          expect(
            find.byKey(const Key('delete_confirm_message')),
            findsOneWidget,
          );
          expect(find.text('Delete Employee'), findsOneWidget);

          // When I tap the "Confirm Delete" button
          await tester.tap(find.byKey(const Key('delete_confirm_button')));
          await tester.pumpAndSettle();

          // Then I should not see the text "Alice Johnson"
          expect(find.text('Alice Johnson'), findsNothing);
        },
      );

      // -----------------------------------------------------------------------
      // Scenario: Cancelling the delete dialog keeps the employee
      // -----------------------------------------------------------------------
      testWidgets(
        'Scenario: Cancelling delete keeps the employee in the table',
        (WidgetTester tester) async {
                    await launchApp(tester);
          await loginAsAdmin(tester);

          // And I should see the text "Alice Johnson"
          expect(find.text('Alice Johnson'), findsOneWidget);

          // When I scroll to the "Delete Employee 0" button
          // And I tap the "Delete Employee 0" button
          await tester.ensureVisible(
            find.byKey(const Key('delete_employee_0')),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('delete_employee_0')));
          await tester.pumpAndSettle();

          // Then the delete confirmation dialog appears
      // And I should see the text "Delete Employee"
          expect(
            find.byKey(const Key('delete_confirm_message')),
            findsOneWidget,
          );

          // When I tap the "Cancel Delete" button
          await tester.tap(find.byKey(const Key('delete_cancel_button')));
          await tester.pumpAndSettle();

          // Then the delete confirmation dialog is hidden
          expect(find.byKey(const Key('delete_confirm_message')), findsNothing);

          // And I should see the text "Alice Johnson"
          expect(find.text('Alice Johnson'), findsOneWidget);
        },
      );
    });

    // -------------------------------------------------------------------------
    // Rule: Employees can be edited
    // -------------------------------------------------------------------------
    group('Rule: Employee records can be updated via the edit dialog', () {
      // -----------------------------------------------------------------------
      // Scenario: Editing an employee updates their information in the table
      // -----------------------------------------------------------------------
      testWidgets('Scenario: Editing an employee updates the table row', (
        WidgetTester tester,
      ) async {
                await launchApp(tester);
        await loginAsAdmin(tester);

        // And I should see the text "Bob Martinez"
        expect(find.text('Bob Martinez'), findsOneWidget);

        // When I scroll to the "Edit Employee 1" button
        // And I tap the "Edit Employee 1" button
        await tester.ensureVisible(find.byKey(const Key('edit_employee_1')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('edit_employee_1')));
        await tester.pumpAndSettle();

        // Then I should see the text "Edit Employee"
        expect(find.text('Edit Employee'), findsOneWidget);

        // When I tap the "Employee Name" field
        // And I fill the "Employee Name" field with "Robert Martinez"
        final nameField = find.byKey(const Key('employee_name_field'));
        await tester.tap(nameField);
        await tester.pump();
        // Triple-tap to select all then retype
        await tester.enterText(nameField, 'Robert Martinez');
        await tester.pump();

        // And I tap the "Save Employee" button
        await tester.tap(find.byKey(const Key('save_employee_button')));
        await tester.pumpAndSettle();

        // Then I should see the text "Robert Martinez"
        expect(find.text('Robert Martinez'), findsOneWidget);

        // And I should not see the text "Bob Martinez"
        expect(find.text('Bob Martinez'), findsNothing);
      });
    });

    // -------------------------------------------------------------------------
    // Rule: The search bar filters the employee table
    // -------------------------------------------------------------------------
    group('Rule: Search filters visible employees', () {
      // -----------------------------------------------------------------------
      // Scenario Outline: Searching by name narrows the displayed employees
      //
      // Examples:
      //   | query   | visibleName     | hiddenName    |
      //   | Alice   | Alice Johnson   | Bob Martinez  |
      //   | Manager | Carol White     | Alice Johnson |
      //   | xyz     | (empty message) | Alice Johnson |
      // -----------------------------------------------------------------------

      final searchExamples = [
        {
          'query': 'Alice',
          'visible': 'Alice Johnson',
          'hidden': 'Bob Martinez',
          'empty': false,
        },
        {
          'query': 'Manager',
          'visible': 'Carol White',
          'hidden': 'Alice Johnson',
          'empty': false,
        },
        {
          'query': 'xyznotfound',
          'visible': null,
          'hidden': 'Alice Johnson',
          'empty': true,
        },
      ];

      for (final ex in searchExamples) {
        testWidgets('Scenario: Searching for "${ex['query']}"', (
          WidgetTester tester,
        ) async {
                    await launchApp(tester);
          await loginAsAdmin(tester);

          // When I fill the "Search" field with "<query>"
          await tester.enterText(
            find.byKey(const Key('search_field')),
            ex['query'] as String,
          );
          await tester.pump();

          // Then I should see the text "<visibleName>" if applicable
          if (ex['visible'] != null) {
            expect(find.text(ex['visible'] as String), findsOneWidget);
          }

          // And I should not see the text "<hiddenName>"
          expect(find.text(ex['hidden'] as String), findsNothing);

          if (ex['empty'] == true) {
            // And the empty employee message is visible
            expect(
              find.byKey(const Key('empty_employee_text')),
              findsOneWidget,
            );
          }
        });
      }
    });

    // -------------------------------------------------------------------------
    // Scenario: DataTable columns are all present
    // -------------------------------------------------------------------------
    testWidgets('Scenario: Employee table displays all required columns', (
      WidgetTester tester,
    ) async {
            await launchApp(tester);
      await loginAsAdmin(tester);

      // Then I should see the text "ID"
      // And I should see the text "Name"
      // And I should see the text "Role"
      // And I should see the text "Age"
      // And I should see the text "Biography"
      // And I should see the text "Actions"
      expect(find.text('ID'), findsOneWidget);
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Role'), findsOneWidget);
      expect(find.text('Age'), findsOneWidget);
      expect(find.text('Biography'), findsOneWidget);
      expect(find.text('Actions'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Scenario: Cancel button on Add Employee dialog closes without saving
    // -------------------------------------------------------------------------
    testWidgets('Scenario: Cancelling the Add Employee dialog saves nothing', (
      WidgetTester tester,
    ) async {
            await launchApp(tester);
      await loginAsAdmin(tester);

      // Record the initial number of employees in the table
      // (We look for known employees as a proxy)
      expect(find.text('Alice Johnson'), findsOneWidget);

      // When I tap the "Add Employee" button
      await tester.tap(find.byKey(const Key('add_employee_fab')));
      await tester.pumpAndSettle();

      // And I fill the "Employee Name" field with "Ghost Employee"
      await tester.enterText(
        find.byKey(const Key('employee_name_field')),
        'Ghost Employee',
      );
      await tester.pump();

      // When I tap the "Cancel Employee" button
      await tester.tap(find.byKey(const Key('cancel_employee_button')));
      await tester.pumpAndSettle();

      // Then the employee dialog is hidden
      expect(find.byKey(const Key('employee_dialog_title')), findsNothing);

      // And I should not see the text "Ghost Employee"
      expect(find.text('Ghost Employee'), findsNothing);
    });
  });

  // ---------------------------------------------------------------------------
  // @Tags: @interactions @dialogs
  // Feature: Dialogs and Interactions
  //   As an authenticated user
  //   I want to interact with various dialog types
  //   So that I can confirm actions and receive feedback
  // ---------------------------------------------------------------------------
  group('Feature: Dialogs and Interactions', () {
    // Background: Given the application is launched
    // And I fill the "Username" field with "admin"
    // And I fill the "Password" field with "password123"
    // And I tap the "Login" button
    // And I tap the "Dialogs Action" button
    // Then I should see the text "Interactions & Dialogs"


    // -------------------------------------------------------------------------
    // Scenario: Alert dialog can be shown and dismissed
    // -------------------------------------------------------------------------
    testWidgets('Scenario: Alert dialog opens and closes with OK button', (
      WidgetTester tester,
    ) async {
      // Background
      await launchApp(tester);
      await loginAsAdmin(tester);
      await navigateTo(tester, 'dialogs_action');

      // Then I should see the text "Interactions & Dialogs"
      expect(find.text('Interactions & Dialogs'), findsOneWidget);

      // When I tap the "Show Alert" button
      await tester.tap(find.byKey(const Key('show_alert_button')));
      await tester.pumpAndSettle();

      // Then I should see the text "This is a simple alert dialog."
      expect(find.text('This is a simple alert dialog.'), findsOneWidget);

      // When I tap the "Alert OK" button
      await tester.tap(find.byKey(const Key('alert_ok_button')));
      await tester.pumpAndSettle();

      // Then I should not see the text "This is a simple alert dialog."
      expect(find.text('This is a simple alert dialog.'), findsNothing);
    });

    // -------------------------------------------------------------------------
    // Scenario: Confirmation dialog can be accepted
    // -------------------------------------------------------------------------
    testWidgets('Scenario: Confirmation dialog — tapping Yes closes dialog', (
      WidgetTester tester,
    ) async {
      // Background
      await launchApp(tester);
      await loginAsAdmin(tester);
      await navigateTo(tester, 'dialogs_action');

      // When I tap the "Show Confirmation" button
      await tester.tap(find.byKey(const Key('show_confirm_button')));
      await tester.pumpAndSettle();

      // Then I should see the text "Are you sure you want to proceed?"
      expect(find.text('Are you sure you want to proceed?'), findsOneWidget);

      // When I tap the "Confirm Yes" button
      await tester.tap(find.byKey(const Key('confirm_yes_button')));
      await tester.pumpAndSettle();

      // Then I should not see the text "Are you sure you want to proceed?"
      expect(find.text('Are you sure you want to proceed?'), findsNothing);
    });

    // -------------------------------------------------------------------------
    // Scenario: Confirmation dialog can be cancelled
    // -------------------------------------------------------------------------
    testWidgets(
      'Scenario: Confirmation dialog — tapping Cancel closes dialog',
      (WidgetTester tester) async {
        // Background
        await launchApp(tester);
        await loginAsAdmin(tester);
        await navigateTo(tester, 'dialogs_action');

        // When I tap the "Show Confirmation" button
        await tester.tap(find.byKey(const Key('show_confirm_button')));
        await tester.pumpAndSettle();

        // Then I should see the text "Are you sure you want to proceed?"
        expect(find.text('Are you sure you want to proceed?'), findsOneWidget);

        // When I tap the "Cancel Delete" button
        await tester.tap(find.byKey(const Key('confirm_cancel_button')));
        await tester.pumpAndSettle();

        // Then I should not see the text "Are you sure you want to proceed?"
        expect(find.text('Are you sure you want to proceed?'), findsNothing);
      },
    );

    // -------------------------------------------------------------------------
    // Scenario: Bottom sheet can be opened and an option selected
    // -------------------------------------------------------------------------
    testWidgets('Scenario: Bottom sheet opens and closes on option selection', (
      WidgetTester tester,
    ) async {
      // Background
      await launchApp(tester);
      await loginAsAdmin(tester);
      await navigateTo(tester, 'dialogs_action');

      // When I tap the "Show Bottom Sheet" button
      await tester.tap(find.byKey(const Key('show_bottom_sheet_button')));
      await tester.pumpAndSettle();

      // Then I should see the text "Bottom Sheet Options"
      expect(find.text('Bottom Sheet Options'), findsOneWidget);

      // And the "Bottom Sheet Option 1" button is visible
      // And the "Bottom Sheet Option 2" button is visible
      expect(find.byKey(const Key('bottom_sheet_option_1')), findsOneWidget);
      expect(find.byKey(const Key('bottom_sheet_option_2')), findsOneWidget);

      // When I tap the "Bottom Sheet Option 1" button
      await tester.tap(find.byKey(const Key('bottom_sheet_option_1')));
      await tester.pumpAndSettle();

      // Then I should not see the text "Bottom Sheet Options"
      expect(find.text('Bottom Sheet Options'), findsNothing);
    });

    // -------------------------------------------------------------------------
    // Scenario: Snackbar appears on button tap
    // -------------------------------------------------------------------------
    testWidgets('Scenario: Snackbar is displayed when triggered', (
      WidgetTester tester,
    ) async {
      // Background
      await launchApp(tester);
      await loginAsAdmin(tester);
      await navigateTo(tester, 'dialogs_action');

      // When I tap the "Show Snackbar" button
      await tester.tap(find.byKey(const Key('show_snackbar_button')));
      await tester.pump(); // kick off show animation
      await tester.pump(
        const Duration(milliseconds: 750),
      ); // complete show animation

      // Then I should see the text "This is a snackbar message!"
      expect(find.text('This is a snackbar message!'), findsOneWidget);

      // After the snackbar duration, it disappears
      await tester.pump(
        const Duration(seconds: 2),
      ); // fire the 2 s duration timer
      await tester.pump(
        const Duration(milliseconds: 750),
      ); // complete hide animation
      expect(find.text('This is a snackbar message!'), findsNothing);
    });

    // -------------------------------------------------------------------------
    // Scenario Outline: All dialog buttons dismiss their respective dialogs
    //
    // Examples:
    //   | triggerKey            | contentText                            | dismissKey             |
    //   | show_alert_button     | This is a simple alert dialog.         | alert_ok_button        |
    //   | show_confirm_button   | Are you sure you want to proceed?      | confirm_cancel_button  |
    // -------------------------------------------------------------------------

    final dialogDismissExamples = [
      {
        'triggerKey': 'show_alert_button',
        'contentText': 'This is a simple alert dialog.',
        'dismissKey': 'alert_ok_button',
      },
      {
        'triggerKey': 'show_confirm_button',
        'contentText': 'Are you sure you want to proceed?',
        'dismissKey': 'confirm_cancel_button',
      },
    ];

    for (final ex in dialogDismissExamples) {
      testWidgets(
        'Scenario Outline: Dialog triggered by "${ex['triggerKey']}" can be dismissed',
        (WidgetTester tester) async {
          // Background
          await launchApp(tester);
          await loginAsAdmin(tester);
          await navigateTo(tester, 'dialogs_action');

          // When I tap the "<triggerKey>" button
          await tester.tap(find.byKey(Key(ex['triggerKey'] as String)));
          await tester.pumpAndSettle();

          // Then I should see the text "<contentText>"
          expect(find.text(ex['contentText'] as String), findsOneWidget);

          // When I tap the "<dismissKey>" button
          await tester.tap(find.byKey(Key(ex['dismissKey'] as String)));
          await tester.pumpAndSettle();

          // Then I should not see the text "<contentText>"
          expect(find.text(ex['contentText'] as String), findsNothing);
        },
      );
    }
  });

  // ---------------------------------------------------------------------------
  // @Tags: @file_management @csv
  // Feature: File Management and CSV Operations
  //   As a data manager
  //   I want to import and export CSV files
  //   So that I can view and distribute employee data in a portable format
  // ---------------------------------------------------------------------------
  group('Feature: File Management and CSV Operations', () {
    // Background: Given the application is launched
    // And I fill the "Username" field with "admin"
    // And I fill the "Password" field with "password123"
    // And I tap the "Login" button
    // And I tap the "Files Action" button
    // Then I should see the text "File Management"


    // -------------------------------------------------------------------------
    // Scenario: File Management screen shows initial empty state
    // -------------------------------------------------------------------------
    testWidgets('Scenario: Files screen shows empty state before any import', (
      WidgetTester tester,
    ) async {
      // Background
      await launchApp(tester);
      await loginAsAdmin(tester);
      await navigateTo(tester, 'files_action');

      // Then I should see the text "File Management"
      expect(find.text('File Management'), findsOneWidget);

      // And I should see the text "No files imported yet."
      expect(find.text('No files imported yet.'), findsOneWidget);

      // And I should see the text "Empty list"
      expect(find.text('Empty list'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Scenario: Importing a CSV file parses and displays it as a DataTable
    // -------------------------------------------------------------------------
    testWidgets(
      'Scenario: Importing CSV shows parsed table and updates status',
      (WidgetTester tester) async {
        // Background
        await launchApp(tester);
        await loginAsAdmin(tester);
        await navigateTo(tester, 'files_action');

        // Given I should see the text "No files imported yet."
        expect(find.text('No files imported yet.'), findsOneWidget);

        // When I tap the "Import CSV" button
        await tester.tap(find.byKey(const Key('import_csv_button')));
        await tester.pumpAndSettle();

        // Then I should see the text "CSV file imported successfully."
        expect(find.text('CSV file imported successfully.'), findsOneWidget);

        // And I should not see the text "Empty list"
        // And the imported files list is visible
        expect(find.text('Empty list'), findsNothing);
        expect(find.byKey(const Key('imported_files_list')), findsOneWidget);

        // And the parsed CSV table is visible
        expect(find.byKey(const Key('csv_content_table')), findsOneWidget);

        // And I should see the text "name"
        // And I should see the text "role"
        // And I should see "age"
        // And I should see the text "email"
        expect(find.text('name'), findsOneWidget);
        expect(find.text('role'), findsOneWidget);
        expect(find.text('age'), findsOneWidget);
        expect(find.text('email'), findsOneWidget);

        // And I should see the text "Alice Johnson"
        // And I should see the text "Engineer"
        expect(find.text('Alice Johnson'), findsOneWidget);
        expect(find.text('Engineer'), findsOneWidget);
      },
    );

    // -------------------------------------------------------------------------
    // Scenario: Toggling to raw view shows the raw CSV text
    // -------------------------------------------------------------------------
    testWidgets('Scenario: Toggling to raw view displays raw CSV content', (
      WidgetTester tester,
    ) async {
      // Background
      await launchApp(tester);
      await loginAsAdmin(tester);
      await navigateTo(tester, 'files_action');

      // Given I tap the "Import CSV" button
      await tester.tap(find.byKey(const Key('import_csv_button')));
      await tester.pumpAndSettle();

      // And the parsed CSV table is visible
      expect(find.byKey(const Key('csv_content_table')), findsOneWidget);

      // When I tap the "Toggle Raw" button
      await tester.tap(find.byKey(const Key('toggle_raw_button')));
      await tester.pumpAndSettle();

      // Then the raw CSV content is visible
      expect(find.byKey(const Key('csv_raw_content')), findsOneWidget);

      // And I should see the text "name,role,age,email"
      expect(find.textContaining('name,role,age,email'), findsOneWidget);

      // And the parsed CSV table is hidden
      expect(find.byKey(const Key('csv_content_table')), findsNothing);

      // When I tap the "Toggle Raw" button
      await tester.tap(find.byKey(const Key('toggle_raw_button')));
      await tester.pumpAndSettle();

      // Then the parsed CSV table is visible
      expect(find.byKey(const Key('csv_content_table')), findsOneWidget);

      // And the raw CSV content is hidden
      expect(find.byKey(const Key('csv_raw_content')), findsNothing);
    });

    // -------------------------------------------------------------------------
    // Scenario: Exporting a CSV shows the success status message
    // -------------------------------------------------------------------------
    testWidgets('Scenario: Exporting CSV updates the status message', (
      WidgetTester tester,
    ) async {
      // Background
      await launchApp(tester);
      await loginAsAdmin(tester);
      await navigateTo(tester, 'files_action');

      // When I tap the "Export CSV" button
      await tester.tap(find.byKey(const Key('export_csv_button')));
      await tester.pumpAndSettle();

      // Then I should see the text "Data exported to CSV successfully."
      expect(find.text('Data exported to CSV successfully.'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Scenario: Importing CSV multiple times grows the file list
    // -------------------------------------------------------------------------
    testWidgets(
      'Scenario: Importing CSV twice results in two entries in the file list',
      (WidgetTester tester) async {
        // Background
        await launchApp(tester);
        await loginAsAdmin(tester);
        await navigateTo(tester, 'files_action');

        // When I tap the "Import CSV" button
        await tester.tap(find.byKey(const Key('import_csv_button')));
        await tester.pumpAndSettle();

        // Then the "File Item 0" element is visible
        expect(find.byKey(const Key('file_item_0')), findsOneWidget);

        // When I tap the "Import CSV" button
        await tester.tap(find.byKey(const Key('import_csv_button')));
        await tester.pumpAndSettle();

        // Then the "File Item 0" element is visible
        // And the "File Item 1" element is visible
        expect(find.byKey(const Key('file_item_0')), findsOneWidget);
        expect(find.byKey(const Key('file_item_1')), findsOneWidget);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // @Tags: @preferences @settings
  // Feature: User Preferences and Settings
  //   As an authenticated user
  //   I want to customize my application settings
  //   So that the app behaves according to my preferences
  // ---------------------------------------------------------------------------
  group('Feature: User Preferences and Settings', () {
    // Background: Given the application is launched
    // And I fill the "Username" field with "admin"
    // And I fill the "Password" field with "password123"
    // And I tap the "Login" button
    // And I tap the "Settings Action" button
    // Then I should see the text "Enable Notifications"


    // -------------------------------------------------------------------------
    // Scenario: Notifications toggle starts enabled and can be disabled
    // -------------------------------------------------------------------------
    testWidgets('Scenario: Notifications toggle can be turned off and on', (
      WidgetTester tester,
    ) async {
      // Background
      await launchApp(tester);
      await loginAsAdmin(tester);
      await navigateTo(tester, 'settings_action');

      // Then the "Notifications" switch is visible
      expect(find.byKey(const Key('notifications_switch')), findsOneWidget);

      // And the "Notifications" switch is ON
      final switchFinder = find.byKey(const Key('notifications_switch'));
      final switchWidget = tester.widget<SwitchListTile>(switchFinder);
      expect(switchWidget.value, isTrue);

      // When I tap the "Notifications" switch
      await tester.tap(switchFinder);
      await tester.pump();

      // Then the "Notifications" switch is OFF
      final updatedSwitch = tester.widget<SwitchListTile>(switchFinder);
      expect(updatedSwitch.value, isFalse);

      // When I tap the "Notifications" switch
      await tester.tap(switchFinder);
      await tester.pump();

      // Then the "Notifications" switch is ON
      final reEnabledSwitch = tester.widget<SwitchListTile>(switchFinder);
      expect(reEnabledSwitch.value, isTrue);
    });

    // -------------------------------------------------------------------------
    // Scenario: Dark mode checkbox starts disabled and can be enabled
    // -------------------------------------------------------------------------
    testWidgets('Scenario: Dark mode checkbox can be toggled', (
      WidgetTester tester,
    ) async {
      // Background
      await launchApp(tester);
      await loginAsAdmin(tester);
      await navigateTo(tester, 'settings_action');

      // Then the "Dark Mode" checkbox is visible
      final checkboxFinder = find.byKey(const Key('dark_mode_checkbox'));
      expect(checkboxFinder, findsOneWidget);

      // And the "Dark Mode" checkbox is OFF
      final checkbox = tester.widget<CheckboxListTile>(checkboxFinder);
      expect(checkbox.value, isFalse);

      // When I tap the "Dark Mode" checkbox
      await tester.tap(checkboxFinder);
      await tester.pump();

      // Then the "Dark Mode" checkbox is ON
      final updatedCheckbox = tester.widget<CheckboxListTile>(checkboxFinder);
      expect(updatedCheckbox.value, isTrue);
    });

    // -------------------------------------------------------------------------
    // Scenario: Volume slider displays and can be adjusted
    // -------------------------------------------------------------------------
    testWidgets('Scenario: Volume slider shows current volume label', (
      WidgetTester tester,
    ) async {
      // Background
      await launchApp(tester);
      await loginAsAdmin(tester);
      await navigateTo(tester, 'settings_action');

      // Then the volume slider is visible
      expect(find.byKey(const Key('volume_slider')), findsOneWidget);

      // And I should see the text "Current Volume: 50"
      expect(find.text('Current Volume: 50'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Scenario: Terms & Conditions dialog opens, shows content, and closes
    // -------------------------------------------------------------------------
    testWidgets(
      'Scenario: Terms and Conditions dialog shows content and can be closed',
      (WidgetTester tester) async {
        // Background
        await launchApp(tester);
        await loginAsAdmin(tester);
        await navigateTo(tester, 'settings_action');

        // When I tap the "View Terms" button
        await tester.tap(find.byKey(const Key('view_terms_button')));
        await tester.pumpAndSettle();

        // Then I should see the text "Terms & Conditions"
        expect(find.text('Terms & Conditions'), findsOneWidget);

        // And the terms text is visible
        // And I should see the text "Please read our terms and conditions"
        expect(find.byKey(const Key('terms_text')), findsOneWidget);
        expect(
          find.textContaining('Please read our terms and conditions'),
          findsOneWidget,
        );

        // When I tap the "Close Terms" button
        await tester.tap(find.byKey(const Key('close_terms')));
        await tester.pumpAndSettle();

        // Then I should not see the text "Terms & Conditions"
        expect(find.text('Terms & Conditions'), findsNothing);

        // And I should see the text "Enable Notifications"
        expect(find.text('Enable Notifications'), findsOneWidget);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // @Tags: @navigation @routing
  // Feature: Application Navigation
  //   As an authenticated user
  //   I want to navigate between all screens
  //   So that I can access different sections of the app
  // ---------------------------------------------------------------------------
  group('Feature: Application Navigation', () {
    // Background:
    // Background: Given the application is launched
    // And I fill the "Username" field with "admin"
    // And I fill the "Password" field with "password123"
    // And I tap the "Login" button
    // Then I should see the text "Welcome to the Dashboard!"

    // -----------------------------------------------------------------------
    // Scenario Outline: Navigating from Dashboard to each secondary screen
    //
    // Examples:
    //   | actionKey      | expectedScreenText      |
    //   | files_action   | File Management         |
    //   | dialogs_action | Interactions & Dialogs  |
    //   | settings_action| Enable Notifications    |
    // -----------------------------------------------------------------------

    final navExamples = [
      {'actionKey': 'files_action', 'expectedText': 'File Management'},
      {'actionKey': 'dialogs_action', 'expectedText': 'Interactions & Dialogs'},
      {'actionKey': 'settings_action', 'expectedText': 'Enable Notifications'},
    ];

    for (final ex in navExamples) {
      testWidgets(
        'Scenario: Navigating via "${ex['actionKey']}" reaches "${ex['expectedText']}"',
        (WidgetTester tester) async {
                    await launchApp(tester);
          await loginAsAdmin(tester);

          // When I tap the "<actionKey>" button
          await tester.tap(find.byKey(Key(ex['actionKey'] as String)));
          await tester.pumpAndSettle();

          // Then I should see the text "<expectedText>"
          expect(find.text(ex['expectedText'] as String), findsOneWidget);

          // And I tap the OS back button
          final NavigatorState navigator = tester.state(find.byType(Navigator));
          navigator.pop();
          await tester.pumpAndSettle();

          // Then I should see the text "Welcome to the Dashboard!"
          expect(find.text('Welcome to the Dashboard!'), findsOneWidget);
        },
      );
    }

    // -------------------------------------------------------------------------
    // Scenario: Back navigation from Settings returns to Dashboard
    // -------------------------------------------------------------------------
    testWidgets(
      'Scenario: Back navigation from Settings returns to Dashboard',
      (WidgetTester tester) async {
                await launchApp(tester);
        await loginAsAdmin(tester);

        // When I tap the "Settings Action" button
        await navigateTo(tester, 'settings_action');
        expect(find.text('Enable Notifications'), findsOneWidget);

        // And I tap the OS back button
        final NavigatorState navigator = tester.state(find.byType(Navigator));
        navigator.pop();
        await tester.pumpAndSettle();

        // Then I should see the text "Welcome to the Dashboard!"
        // And the "Add Employee" button is visible
        expect(find.text('Welcome to the Dashboard!'), findsOneWidget);
        expect(find.byKey(const Key('add_employee_fab')), findsOneWidget);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // @Tags: @end_to_end @full_flow
  // Feature: End-to-End Employee Management Flow
  //   As an admin user
  //   I want to perform a complete CRUD cycle on an employee record
  //   So that I can verify the full lifecycle works correctly
  // ---------------------------------------------------------------------------
  group('Feature: End-to-End Employee CRUD Lifecycle', () {
    // -------------------------------------------------------------------------
    // Scenario: Full lifecycle — add, verify, edit, verify, delete employee
    // -------------------------------------------------------------------------
    testWidgets('Scenario: Full CRUD lifecycle for an employee record', (
      WidgetTester tester,
    ) async {
      // ── Step 1: Login ───────────────────────────────────────────────────
      // Given the application is launched
      // And I fill the "Username" field with "admin"
      // And I fill the "Password" field with "password123"
      // And I tap the "Login" button
      await launchApp(tester);
      await loginAsAdmin(tester);

      // Then I should see the text "Welcome to the Dashboard!"
      expect(find.text('Welcome to the Dashboard!'), findsOneWidget);

      // ── Step 2: Add ─────────────────────────────────────────────────────
      // When I tap the "Add Employee" button
      await tester.tap(find.byKey(const Key('add_employee_fab')));
      await tester.pumpAndSettle();

      // And I fill the "Employee Name" field with "Eve Torres"
      // And I fill the "Employee Role" field with "DevOps"
      // And I fill the "Employee Age" field with "29"
      // And I fill the "Employee Bio" field with "Infrastructure engineer specialising in CI/CD pipelines."
      await tester.enterText(
        find.byKey(const Key('employee_name_field')),
        'Eve Torres',
      );
      await tester.pump();
      await tester.enterText(
        find.byKey(const Key('employee_role_field')),
        'DevOps',
      );
      await tester.pump();
      await tester.enterText(find.byKey(const Key('employee_age_field')), '29');
      await tester.pump();
      await tester.enterText(
        find.byKey(const Key('employee_bio_field')),
        'Infrastructure engineer specialising in CI/CD pipelines.',
      );
      await tester.pump();

      // And I tap the "Save Employee" button
      await tester.tap(find.byKey(const Key('save_employee_button')));
      await tester.pumpAndSettle();

      // Then I should see the text "Eve Torres"
      // And I should see the text "DevOps"
      expect(find.text('Eve Torres'), findsOneWidget);
      expect(find.text('DevOps'), findsOneWidget);

      // ── Step 3: Search / Read ────────────────────────────────────────────
      // When I fill the "Search" field with "Eve"
      await tester.enterText(find.byKey(const Key('search_field')), 'Eve');
      await tester.pump();

      // Then I should see the text "Eve Torres"
      // And I should not see the text "Alice Johnson"
      expect(find.text('Eve Torres'), findsOneWidget);
      expect(find.text('Alice Johnson'), findsNothing);

      // When I fill the "Search" field with ""
      await tester.enterText(find.byKey(const Key('search_field')), '');
      await tester.pump();

      // Then I should see the text "Alice Johnson"
      // And I should see the text "Eve Torres"
      expect(find.text('Alice Johnson'), findsOneWidget);
      expect(find.text('Eve Torres'), findsOneWidget);

      // ── Step 4: Edit ─────────────────────────────────────────────────────
      // When I scroll to the "Edit Employee 3" button
      // And I tap the "Edit Employee 3" button
      await tester.ensureVisible(find.byKey(const Key('edit_employee_3')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('edit_employee_3')));
      await tester.pumpAndSettle();

      // Then I should see the text "Edit Employee"
      expect(find.text('Edit Employee'), findsOneWidget);

      // When I fill the "Employee Role" field with "Senior DevOps"
      await tester.enterText(
        find.byKey(const Key('employee_role_field')),
        'Senior DevOps',
      );
      await tester.pump();

      // And I tap the "Save Employee" button
      await tester.tap(find.byKey(const Key('save_employee_button')));
      await tester.pumpAndSettle();

      // Then I should see the text "Senior DevOps"
      expect(find.text('Senior DevOps'), findsOneWidget);

      // ── Step 5: Delete ───────────────────────────────────────────────────
      // When I scroll to the "Delete Employee 3" button
      // And I tap the "Delete Employee 3" button
      await tester.ensureVisible(find.byKey(const Key('delete_employee_3')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('delete_employee_3')));
      await tester.pumpAndSettle();

      // Then the delete confirmation dialog appears
      // And I should see the text "Delete Employee"
      expect(find.byKey(const Key('delete_confirm_message')), findsOneWidget);

      // When I tap the "Confirm Delete" button
      await tester.tap(find.byKey(const Key('delete_confirm_button')));
      await tester.pumpAndSettle();

      // Then I should not see the text "Eve Torres"
      expect(find.text('Eve Torres'), findsNothing);

      // And I should see the text "Alice Johnson"
      // And I should see the text "Bob Martinez"
      // And I should see the text "Carol White"
      expect(find.text('Alice Johnson'), findsOneWidget);
      expect(find.text('Bob Martinez'), findsOneWidget);
      expect(find.text('Carol White'), findsOneWidget);
    });
  });
}
