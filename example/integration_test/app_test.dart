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
          // Background: Given the app is freshly launched at the login screen
          await launchApp(tester);

          // Given the login screen is visible
          expect(find.byKey(const Key('username_field')), findsOneWidget);
          expect(find.byKey(const Key('password_field')), findsOneWidget);
          expect(find.byKey(const Key('login_button')), findsOneWidget);

          // When I enter the username "<username>"
          await tester.enterText(
            find.byKey(const Key('username_field')),
            example['username'] as String,
          );
          await tester.pump();

          // And I enter the password "<password>"
          await tester.enterText(
            find.byKey(const Key('password_field')),
            example['password'] as String,
          );
          await tester.pump();

          // And I tap the login button
          await tester.tap(find.byKey(const Key('login_button')));
          await tester.pumpAndSettle();

          // Then I should see "<expectedText>"
          expect(
            find.textContaining(example['expectedText'] as String),
            findsOneWidget,
          );

          // And the dashboard reachability matches the expected outcome
          if (example['shouldReachDashboard'] == true) {
            // Then I am redirected to the Dashboard
            expect(find.byKey(const Key('add_employee_fab')), findsOneWidget);
          } else {
            // Then I remain on the login screen
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
      // Background: Given the app is freshly launched
      await launchApp(tester);

      // Then I should see the app name
      expect(find.text('TeamSync'), findsOneWidget);

      // And I should see the subtitle
      expect(find.text('Employee Directory'), findsOneWidget);

      // And the login form fields are present
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
    // Background: Given the user is logged in as admin
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
        // Given the user is logged in
        await launchApp(tester);
        await loginAsAdmin(tester);

        // Then I should see the welcome message
        expect(find.text('Welcome to the Dashboard!'), findsOneWidget);

        // And the employee DataTable should be visible
        expect(find.byKey(const Key('employee_table')), findsOneWidget);

        // And the initial employees are displayed
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
      // Given the user is logged in
      await launchApp(tester);
      await loginAsAdmin(tester);

      // Then the "Total Employees" stat card shows 3
      expect(find.text('3'), findsWidgets); // may match multiple text nodes

      // And the stat card label "Total Employees" is present
      expect(find.text('Total Employees'), findsOneWidget);

      // And "Average Age" label is present
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
          // Background: Given the user is logged in and on the Dashboard
          await launchApp(tester);
          await loginAsAdmin(tester);

          // When I tap the "Add Employee" FAB
          await tester.tap(find.byKey(const Key('add_employee_fab')));
          await tester.pumpAndSettle();

          // Then the "Add Employee" dialog opens
          expect(
            find.byKey(const Key('employee_dialog_title')),
            findsOneWidget,
          );
          expect(find.text('Add Employee'), findsWidgets);

          // When I fill "employee_name_field" with "David Kim"
          await tester.enterText(
            find.byKey(const Key('employee_name_field')),
            'David Kim',
          );
          await tester.pump();

          // And I fill "employee_role_field" with "Analyst"
          await tester.enterText(
            find.byKey(const Key('employee_role_field')),
            'Analyst',
          );
          await tester.pump();

          // And I fill "employee_age_field" with "35"
          await tester.enterText(
            find.byKey(const Key('employee_age_field')),
            '35',
          );
          await tester.pump();

          // And I fill "employee_bio_field" with a multi-line biography
          await tester.enterText(
            find.byKey(const Key('employee_bio_field')),
            'Business analyst with expertise in data.\nSix years experience.',
          );
          await tester.pump();

          // And I tap "save_employee_button"
          await tester.tap(find.byKey(const Key('save_employee_button')));
          await tester.pumpAndSettle();

          // Then the dialog is dismissed
          expect(find.byKey(const Key('employee_dialog_title')), findsNothing);

          // And "David Kim" now appears in the employee table
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
            // Background: Given the user is logged in
            await launchApp(tester);
            await loginAsAdmin(tester);

            // When I open the Add Employee dialog
            await tester.tap(find.byKey(const Key('add_employee_fab')));
            await tester.pumpAndSettle();

            // And I fill the required fields
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

            // And I tap the Save button
            await tester.tap(find.byKey(const Key('save_employee_button')));
            await tester.pumpAndSettle();

            if (ex['shouldSave'] == true) {
              // Then the dialog closes and the employee is visible
              expect(
                find.byKey(const Key('employee_dialog_title')),
                findsNothing,
              );
              expect(find.text(ex['name'] as String), findsOneWidget);
            } else {
              // Then the dialog remains open with a validation error
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
        // Background: Given the user is logged in
        await launchApp(tester);
        await loginAsAdmin(tester);

        // When I open the Add Employee dialog
        await tester.tap(find.byKey(const Key('add_employee_fab')));
        await tester.pumpAndSettle();

        // And I leave the name field empty but fill in other fields
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

        // When I tap Save
        await tester.tap(find.byKey(const Key('save_employee_button')));
        await tester.pumpAndSettle();

        // Then I see "Name is required" validation message
        expect(find.text('Name is required'), findsOneWidget);

        // And the dialog is still open
        expect(find.byKey(const Key('employee_dialog_title')), findsOneWidget);
      });

      // -----------------------------------------------------------------------
      // Scenario: Submitting a non-numeric age shows validation error
      // -----------------------------------------------------------------------
      testWidgets('Scenario: Non-numeric age shows validation error', (
        WidgetTester tester,
      ) async {
        // Background: Given the user is logged in
        await launchApp(tester);
        await loginAsAdmin(tester);

        // When I open the Add Employee dialog
        await tester.tap(find.byKey(const Key('add_employee_fab')));
        await tester.pumpAndSettle();

        // And I fill the name and role
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

        // And I enter a non-numeric age
        await tester.enterText(
          find.byKey(const Key('employee_age_field')),
          'abc',
        );
        await tester.pump();

        // When I tap Save
        await tester.tap(find.byKey(const Key('save_employee_button')));
        await tester.pumpAndSettle();

        // Then I see "Age must be a number"
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
          // Background: Given the user is logged in
          await launchApp(tester);
          await loginAsAdmin(tester);

          // And "Alice Johnson" is visible in the table
          expect(find.text('Alice Johnson'), findsOneWidget);

          // When I tap the delete button for the first employee (index 0)
          await tester.ensureVisible(
            find.byKey(const Key('delete_employee_0')),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('delete_employee_0')));
          await tester.pumpAndSettle();

          // Then a confirmation dialog appears
          expect(
            find.byKey(const Key('delete_confirm_message')),
            findsOneWidget,
          );
          expect(find.text('Delete Employee'), findsOneWidget);

          // When I tap "Delete" to confirm
          await tester.tap(find.byKey(const Key('delete_confirm_button')));
          await tester.pumpAndSettle();

          // Then "Alice Johnson" is no longer in the table
          expect(find.text('Alice Johnson'), findsNothing);
        },
      );

      // -----------------------------------------------------------------------
      // Scenario: Cancelling the delete dialog keeps the employee
      // -----------------------------------------------------------------------
      testWidgets(
        'Scenario: Cancelling delete keeps the employee in the table',
        (WidgetTester tester) async {
          // Background: Given the user is logged in
          await launchApp(tester);
          await loginAsAdmin(tester);

          // And "Alice Johnson" is visible
          expect(find.text('Alice Johnson'), findsOneWidget);

          // When I tap the delete button for the first employee
          await tester.ensureVisible(
            find.byKey(const Key('delete_employee_0')),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('delete_employee_0')));
          await tester.pumpAndSettle();

          // Then the confirmation dialog appears
          expect(
            find.byKey(const Key('delete_confirm_message')),
            findsOneWidget,
          );

          // When I tap "Cancel"
          await tester.tap(find.byKey(const Key('delete_cancel_button')));
          await tester.pumpAndSettle();

          // Then the dialog is dismissed
          expect(find.byKey(const Key('delete_confirm_message')), findsNothing);

          // And "Alice Johnson" is still present
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
        // Background: Given the user is logged in
        await launchApp(tester);
        await loginAsAdmin(tester);

        // And "Bob Martinez" is visible
        expect(find.text('Bob Martinez'), findsOneWidget);

        // When I tap the edit button for the second employee (index 1)
        await tester.ensureVisible(find.byKey(const Key('edit_employee_1')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('edit_employee_1')));
        await tester.pumpAndSettle();

        // Then the "Edit Employee" dialog opens with pre-filled data
        expect(find.text('Edit Employee'), findsOneWidget);

        // When I clear and update the name field
        final nameField = find.byKey(const Key('employee_name_field'));
        await tester.tap(nameField);
        await tester.pump();
        // Triple-tap to select all then retype
        await tester.enterText(nameField, 'Robert Martinez');
        await tester.pump();

        // And I tap Save
        await tester.tap(find.byKey(const Key('save_employee_button')));
        await tester.pumpAndSettle();

        // Then the updated name "Robert Martinez" appears in the table
        expect(find.text('Robert Martinez'), findsOneWidget);

        // And the old name "Bob Martinez" is no longer present
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
          // Background: Given the user is logged in
          await launchApp(tester);
          await loginAsAdmin(tester);

          // When I type the query into the search field
          await tester.enterText(
            find.byKey(const Key('search_field')),
            ex['query'] as String,
          );
          await tester.pump();

          // Then only matching employees are shown
          if (ex['visible'] != null) {
            expect(find.text(ex['visible'] as String), findsOneWidget);
          }

          // And non-matching employees are hidden
          expect(find.text(ex['hidden'] as String), findsNothing);

          if (ex['empty'] == true) {
            // And the empty state message is shown
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
      // Background: Given the user is logged in
      await launchApp(tester);
      await loginAsAdmin(tester);

      // Then the DataTable column headers are visible
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
      // Background: Given the user is logged in
      await launchApp(tester);
      await loginAsAdmin(tester);

      // Record the initial number of employees in the table
      // (We look for known employees as a proxy)
      expect(find.text('Alice Johnson'), findsOneWidget);

      // When I open the Add Employee dialog
      await tester.tap(find.byKey(const Key('add_employee_fab')));
      await tester.pumpAndSettle();

      // And I fill in a name
      await tester.enterText(
        find.byKey(const Key('employee_name_field')),
        'Ghost Employee',
      );
      await tester.pump();

      // When I tap Cancel
      await tester.tap(find.byKey(const Key('cancel_employee_button')));
      await tester.pumpAndSettle();

      // Then the dialog is closed
      expect(find.byKey(const Key('employee_dialog_title')), findsNothing);

      // And "Ghost Employee" was NOT added
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
    // Background: Given the user is logged in and has navigated to Dialogs
    //   Given I launch the TeamSync app
    //   And I log in as "admin" / "password123"
    //   And I tap the "dialogs_action" icon
    //   Then I should see "Interactions & Dialogs"

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

      // Then the Dialogs screen title is visible
      expect(find.text('Interactions & Dialogs'), findsOneWidget);

      // When I tap "Show Alert Dialog"
      await tester.tap(find.byKey(const Key('show_alert_button')));
      await tester.pumpAndSettle();

      // Then the alert dialog content is visible
      expect(find.text('This is a simple alert dialog.'), findsOneWidget);

      // When I tap "OK"
      await tester.tap(find.byKey(const Key('alert_ok_button')));
      await tester.pumpAndSettle();

      // Then the alert dialog is dismissed
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

      // When I tap "Show Confirmation Dialog"
      await tester.tap(find.byKey(const Key('show_confirm_button')));
      await tester.pumpAndSettle();

      // Then the confirmation prompt is visible
      expect(find.text('Are you sure you want to proceed?'), findsOneWidget);

      // When I tap "Yes"
      await tester.tap(find.byKey(const Key('confirm_yes_button')));
      await tester.pumpAndSettle();

      // Then the dialog is gone
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

        // When I tap "Show Confirmation Dialog"
        await tester.tap(find.byKey(const Key('show_confirm_button')));
        await tester.pumpAndSettle();

        // Then the confirmation prompt is shown
        expect(find.text('Are you sure you want to proceed?'), findsOneWidget);

        // When I tap "Cancel"
        await tester.tap(find.byKey(const Key('confirm_cancel_button')));
        await tester.pumpAndSettle();

        // Then the dialog is dismissed
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

      // When I tap "Show Bottom Sheet"
      await tester.tap(find.byKey(const Key('show_bottom_sheet_button')));
      await tester.pumpAndSettle();

      // Then the bottom sheet title is visible
      expect(find.text('Bottom Sheet Options'), findsOneWidget);

      // And both options are present
      expect(find.byKey(const Key('bottom_sheet_option_1')), findsOneWidget);
      expect(find.byKey(const Key('bottom_sheet_option_2')), findsOneWidget);

      // When I tap option 1 (Share)
      await tester.tap(find.byKey(const Key('bottom_sheet_option_1')));
      await tester.pumpAndSettle();

      // Then the bottom sheet is dismissed
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

      // When I tap "Show Snackbar"
      await tester.tap(find.byKey(const Key('show_snackbar_button')));
      await tester.pump(); // kick off show animation
      await tester.pump(
        const Duration(milliseconds: 750),
      ); // complete show animation

      // Then the snackbar message is visible
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

          // When I tap the trigger button
          await tester.tap(find.byKey(Key(ex['triggerKey'] as String)));
          await tester.pumpAndSettle();

          // Then the dialog content is visible
          expect(find.text(ex['contentText'] as String), findsOneWidget);

          // When I tap the dismiss button
          await tester.tap(find.byKey(Key(ex['dismissKey'] as String)));
          await tester.pumpAndSettle();

          // Then the dialog content is gone
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
    // Background: Given the user is logged in and on the Files screen
    //   Given I launch the TeamSync app
    //   And I log in as "admin"
    //   And I tap "files_action"
    //   Then I should see "File Management"

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

      // Then the screen title is visible
      expect(find.text('File Management'), findsOneWidget);

      // And the status message says no files imported yet
      expect(find.text('No files imported yet.'), findsOneWidget);

      // And the empty files list placeholder is shown
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

        // Given the status message shows no files imported
        expect(find.text('No files imported yet.'), findsOneWidget);

        // When I tap "Import CSV"
        await tester.tap(find.byKey(const Key('import_csv_button')));
        await tester.pumpAndSettle();

        // Then the status message updates
        expect(find.text('CSV file imported successfully.'), findsOneWidget);

        // And the imported files list is no longer empty
        expect(find.text('Empty list'), findsNothing);
        expect(find.byKey(const Key('imported_files_list')), findsOneWidget);

        // And the parsed CSV DataTable is shown
        expect(find.byKey(const Key('csv_content_table')), findsOneWidget);

        // And the CSV column headers are visible
        expect(find.text('name'), findsOneWidget);
        expect(find.text('role'), findsOneWidget);
        expect(find.text('age'), findsOneWidget);
        expect(find.text('email'), findsOneWidget);

        // And sample data rows are visible
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

      // Given I have imported a CSV file
      await tester.tap(find.byKey(const Key('import_csv_button')));
      await tester.pumpAndSettle();

      // And the table view is shown
      expect(find.byKey(const Key('csv_content_table')), findsOneWidget);

      // When I tap "Raw View"
      await tester.tap(find.byKey(const Key('toggle_raw_button')));
      await tester.pumpAndSettle();

      // Then the raw CSV text is visible
      expect(find.byKey(const Key('csv_raw_content')), findsOneWidget);

      // And the raw text contains the CSV header line
      expect(find.textContaining('name,role,age,email'), findsOneWidget);

      // And the table view is hidden
      expect(find.byKey(const Key('csv_content_table')), findsNothing);

      // When I tap "Table View" to toggle back
      await tester.tap(find.byKey(const Key('toggle_raw_button')));
      await tester.pumpAndSettle();

      // Then the table view is restored
      expect(find.byKey(const Key('csv_content_table')), findsOneWidget);

      // And the raw content is hidden
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

      // When I tap "Export CSV"
      await tester.tap(find.byKey(const Key('export_csv_button')));
      await tester.pumpAndSettle();

      // Then the status message confirms the export
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

        // When I tap "Import CSV" the first time
        await tester.tap(find.byKey(const Key('import_csv_button')));
        await tester.pumpAndSettle();

        // Then one file entry is in the list
        expect(find.byKey(const Key('file_item_0')), findsOneWidget);

        // When I tap "Import CSV" again
        await tester.tap(find.byKey(const Key('import_csv_button')));
        await tester.pumpAndSettle();

        // Then two file entries are in the list
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
    // Background: Given the user is logged in and on the Settings screen
    //   Given I launch the TeamSync app
    //   And I log in as "admin"
    //   And I tap "settings_action"
    //   Then I should see the Settings screen

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

      // Then the notifications switch is present
      expect(find.byKey(const Key('notifications_switch')), findsOneWidget);

      // And it is initially ON (the SwitchListTile value is true)
      final switchFinder = find.byKey(const Key('notifications_switch'));
      final switchWidget = tester.widget<SwitchListTile>(switchFinder);
      expect(switchWidget.value, isTrue);

      // When I tap the switch to disable notifications
      await tester.tap(switchFinder);
      await tester.pump();

      // Then the switch is now OFF
      final updatedSwitch = tester.widget<SwitchListTile>(switchFinder);
      expect(updatedSwitch.value, isFalse);

      // When I tap the switch again to re-enable
      await tester.tap(switchFinder);
      await tester.pump();

      // Then the switch is ON again
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

      // Then the dark mode checkbox is present
      final checkboxFinder = find.byKey(const Key('dark_mode_checkbox'));
      expect(checkboxFinder, findsOneWidget);

      // And it is initially unchecked
      final checkbox = tester.widget<CheckboxListTile>(checkboxFinder);
      expect(checkbox.value, isFalse);

      // When I tap the checkbox to enable dark mode
      await tester.tap(checkboxFinder);
      await tester.pump();

      // Then the checkbox is checked
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

      // Then the volume slider is present
      expect(find.byKey(const Key('volume_slider')), findsOneWidget);

      // And the volume label shows the initial value "50"
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

        // When I tap "View Terms & Conditions"
        await tester.tap(find.byKey(const Key('view_terms_button')));
        await tester.pumpAndSettle();

        // Then the Terms dialog opens
        expect(find.text('Terms & Conditions'), findsOneWidget);

        // And the terms content is visible (doc-string style verification)
        expect(find.byKey(const Key('terms_text')), findsOneWidget);
        expect(
          find.textContaining('Please read our terms and conditions'),
          findsOneWidget,
        );

        // When I tap "Close"
        await tester.tap(find.byKey(const Key('close_terms')));
        await tester.pumpAndSettle();

        // Then the terms dialog is dismissed
        expect(find.text('Terms & Conditions'), findsNothing);

        // And the settings screen is still visible
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
    //   Given the user is logged in
    //   And they are on the Dashboard

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
          // Background: Given the user is logged in
          await launchApp(tester);
          await loginAsAdmin(tester);

          // When I tap the navigation action
          await tester.tap(find.byKey(Key(ex['actionKey'] as String)));
          await tester.pumpAndSettle();

          // Then I see the expected screen content
          expect(find.text(ex['expectedText'] as String), findsOneWidget);

          // And I can navigate back to the Dashboard using the back button
          final NavigatorState navigator = tester.state(find.byType(Navigator));
          navigator.pop();
          await tester.pumpAndSettle();

          // Then the Dashboard welcome message is visible again
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
        // Background: Given the user is logged in
        await launchApp(tester);
        await loginAsAdmin(tester);

        // When I navigate to Settings
        await navigateTo(tester, 'settings_action');
        expect(find.text('Enable Notifications'), findsOneWidget);

        // And I tap the OS back button (simulated via Navigator.pop)
        final NavigatorState navigator = tester.state(find.byType(Navigator));
        navigator.pop();
        await tester.pumpAndSettle();

        // Then I am back on the Dashboard
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
      // Given I launch the app and log in as admin
      await launchApp(tester);
      await loginAsAdmin(tester);

      // Then I am on the Dashboard
      expect(find.text('Welcome to the Dashboard!'), findsOneWidget);

      // ── Step 2: Add ─────────────────────────────────────────────────────
      // When I tap "Add Employee"
      await tester.tap(find.byKey(const Key('add_employee_fab')));
      await tester.pumpAndSettle();

      // And I fill in all fields
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

      // And I save the employee
      await tester.tap(find.byKey(const Key('save_employee_button')));
      await tester.pumpAndSettle();

      // Then "Eve Torres" appears in the employee table
      expect(find.text('Eve Torres'), findsOneWidget);
      expect(find.text('DevOps'), findsOneWidget);

      // ── Step 3: Search / Read ────────────────────────────────────────────
      // When I search for "Eve"
      await tester.enterText(find.byKey(const Key('search_field')), 'Eve');
      await tester.pump();

      // Then only "Eve Torres" is visible
      expect(find.text('Eve Torres'), findsOneWidget);
      expect(find.text('Alice Johnson'), findsNothing);

      // When I clear the search
      await tester.enterText(find.byKey(const Key('search_field')), '');
      await tester.pump();

      // Then all employees are shown again
      expect(find.text('Alice Johnson'), findsOneWidget);
      expect(find.text('Eve Torres'), findsOneWidget);

      // ── Step 4: Edit ─────────────────────────────────────────────────────
      // When I tap the edit button for "Eve Torres" (she is last = index 3)
      await tester.ensureVisible(find.byKey(const Key('edit_employee_3')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('edit_employee_3')));
      await tester.pumpAndSettle();

      // Then the edit dialog opens
      expect(find.text('Edit Employee'), findsOneWidget);

      // When I update the role
      await tester.enterText(
        find.byKey(const Key('employee_role_field')),
        'Senior DevOps',
      );
      await tester.pump();

      // And I save
      await tester.tap(find.byKey(const Key('save_employee_button')));
      await tester.pumpAndSettle();

      // Then the updated role is visible
      expect(find.text('Senior DevOps'), findsOneWidget);

      // ── Step 5: Delete ───────────────────────────────────────────────────
      // When I tap the delete button for "Eve Torres" (still index 3)
      await tester.ensureVisible(find.byKey(const Key('delete_employee_3')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('delete_employee_3')));
      await tester.pumpAndSettle();

      // Then the confirmation dialog appears
      expect(find.byKey(const Key('delete_confirm_message')), findsOneWidget);

      // When I confirm deletion
      await tester.tap(find.byKey(const Key('delete_confirm_button')));
      await tester.pumpAndSettle();

      // Then "Eve Torres" is no longer in the table
      expect(find.text('Eve Torres'), findsNothing);

      // And the original employees are still present
      expect(find.text('Alice Johnson'), findsOneWidget);
      expect(find.text('Bob Martinez'), findsOneWidget);
      expect(find.text('Carol White'), findsOneWidget);
    });
  });
}
