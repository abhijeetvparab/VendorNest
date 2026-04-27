import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vendorapp/providers/auth_provider.dart';
import 'package:vendorapp/screens/auth/login_screen.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

Widget _buildApp(AuthProvider provider) => ChangeNotifierProvider<AuthProvider>.value(
      value: provider,
      child: MaterialApp(
        routes: {
          '/home': (_) => const Scaffold(body: Text('Home Screen')),
        },
        home: const LoginScreen(),
      ),
    );

MockClient _clientReturning(int status, Map<String, dynamic> body) =>
    MockClient((_) async => http.Response(
          jsonEncode(body),
          status,
          headers: {'content-type': 'application/json'},
        ));

Map<String, dynamic> _tokenResponse({String role = 'Customer'}) => {
      'access_token': 'token',
      'refresh_token': 'refresh',
      'token_type': 'bearer',
      'user': {
        'id': 'u1',
        'first_name': 'Test',
        'last_name': 'User',
        'email': 'test@example.com',
        'phone_number': '9876543210',
        'address': '123 Main Street',
        'gst_number': null,
        'role': role,
        'status': 'Active',
        'created_at': '2024-01-01T00:00:00',
      },
    };

Future<void> _selectRole(WidgetTester tester, String role) async {
  await tester.tap(find.byType(DropdownButtonFormField<String>));
  await tester.pumpAndSettle();
  await tester.tap(find.text(role).last);
  await tester.pumpAndSettle();
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // ── Layout ─────────────────────────────────────────────────────────────────

  group('LoginScreen layout', () {
    testWidgets('renders email and password fields', (tester) async {
      await tester.pumpWidget(_buildApp(AuthProvider()));
      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    testWidgets('renders role dropdown', (tester) async {
      await tester.pumpWidget(_buildApp(AuthProvider()));
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    });

    testWidgets('renders Sign In button', (tester) async {
      await tester.pumpWidget(_buildApp(AuthProvider()));
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('dropdown contains Admin, Vendor and Customer options',
        (tester) async {
      await tester.pumpWidget(_buildApp(AuthProvider()));
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      expect(find.text('Admin'), findsWidgets);
      expect(find.text('Vendor'), findsWidgets);
      expect(find.text('Customer'), findsWidgets);
    });
  });

  // ── Form validation ────────────────────────────────────────────────────────

  group('LoginScreen form validation', () {
    testWidgets('shows all validation errors when submitted empty',
        (tester) async {
      await tester.pumpWidget(_buildApp(AuthProvider()));
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Enter valid email'), findsOneWidget);
      expect(find.text('Enter password'), findsOneWidget);
      expect(find.text('Please select a role'), findsOneWidget);
    });

    testWidgets('shows email error for invalid email format', (tester) async {
      await tester.pumpWidget(_buildApp(AuthProvider()));
      await tester.enterText(find.byType(TextFormField).at(0), 'notanemail');
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Enter valid email'), findsOneWidget);
    });

    testWidgets('shows password error when password is empty', (tester) async {
      await tester.pumpWidget(_buildApp(AuthProvider()));
      await tester.enterText(
          find.byType(TextFormField).at(0), 'user@example.com');
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Enter password'), findsOneWidget);
    });

    testWidgets('shows role error when no role selected', (tester) async {
      await tester.pumpWidget(_buildApp(AuthProvider()));
      await tester.enterText(
          find.byType(TextFormField).at(0), 'user@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'TestPass1!');
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Please select a role'), findsOneWidget);
    });
  });

  // ── Login outcomes ─────────────────────────────────────────────────────────

  group('LoginScreen login outcomes', () {
    testWidgets('shows error snackbar on invalid credentials', (tester) async {
      final client = _clientReturning(401, {
        'detail': 'Invalid credentials. Please check email and password.'
      });

      await http.runWithClient<Future<void>>(() async {
        await tester.pumpWidget(_buildApp(AuthProvider()));
        await tester.enterText(
            find.byType(TextFormField).at(0), 'bad@example.com');
        await tester.enterText(find.byType(TextFormField).at(1), 'WrongPass1!');
        await _selectRole(tester, 'Customer');

        await tester.tap(find.text('Sign In'));
        await tester.pumpAndSettle();

        expect(find.textContaining('Invalid credentials'), findsOneWidget);
      }, () => client);
    });

    testWidgets('shows pending approval message for pending vendor',
        (tester) async {
      final client = _clientReturning(403, {
        'detail':
            'Your account is pending admin approval. You will be notified once approved.'
      });

      await http.runWithClient<Future<void>>(() async {
        await tester.pumpWidget(_buildApp(AuthProvider()));
        await tester.enterText(
            find.byType(TextFormField).at(0), 'vendor@example.com');
        await tester.enterText(find.byType(TextFormField).at(1), 'TestPass1!');
        await _selectRole(tester, 'Vendor');

        await tester.tap(find.text('Sign In'));
        await tester.pumpAndSettle();

        expect(find.textContaining('pending admin approval'), findsOneWidget);
      }, () => client);
    });

    testWidgets('shows deactivated message for inactive user', (tester) async {
      final client = _clientReturning(403, {
        'detail':
            'Your account has been deactivated. Please contact support.'
      });

      await http.runWithClient<Future<void>>(() async {
        await tester.pumpWidget(_buildApp(AuthProvider()));
        await tester.enterText(
            find.byType(TextFormField).at(0), 'inactive@example.com');
        await tester.enterText(find.byType(TextFormField).at(1), 'TestPass1!');
        await _selectRole(tester, 'Customer');

        await tester.tap(find.text('Sign In'));
        await tester.pumpAndSettle();

        expect(find.textContaining('deactivated'), findsOneWidget);
      }, () => client);
    });

    testWidgets('shows role mismatch error when wrong role selected',
        (tester) async {
      // API returns Admin user but Vendor is selected in the dropdown
      final client = _clientReturning(200, _tokenResponse(role: 'Admin'));

      await http.runWithClient<Future<void>>(() async {
        await tester.pumpWidget(_buildApp(AuthProvider()));
        await tester.enterText(
            find.byType(TextFormField).at(0), 'admin@example.com');
        await tester.enterText(find.byType(TextFormField).at(1), 'TestPass1!');
        await _selectRole(tester, 'Vendor');

        await tester.tap(find.text('Sign In'));
        await tester.pumpAndSettle();

        expect(find.textContaining('Incorrect role selected'), findsOneWidget);
      }, () => client);
    });

    testWidgets('navigates to /home on successful login', (tester) async {
      final client = _clientReturning(200, _tokenResponse(role: 'Customer'));

      await http.runWithClient<Future<void>>(() async {
        await tester.pumpWidget(_buildApp(AuthProvider()));
        await tester.enterText(
            find.byType(TextFormField).at(0), 'cust@example.com');
        await tester.enterText(find.byType(TextFormField).at(1), 'TestPass1!');
        await _selectRole(tester, 'Customer');

        await tester.tap(find.text('Sign In'));
        await tester.pumpAndSettle();

        expect(find.text('Home Screen'), findsOneWidget);
      }, () => client);
    });
  });
}
