import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vendorapp/providers/auth_provider.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

Map<String, dynamic> _mockUserJson({
  String role = 'Customer',
  String status = 'Active',
}) =>
    {
      'id': 'user-123',
      'first_name': 'John',
      'last_name': 'Doe',
      'email': 'john@example.com',
      'phone_number': '9876543210',
      'address': '123 Main Street City',
      'gst_number': null,
      'role': role,
      'status': status,
      'created_at': '2024-01-15T10:00:00',
    };

Map<String, dynamic> _mockTokenResponse({String role = 'Customer'}) => {
      'access_token': 'mock_access_token',
      'refresh_token': 'mock_refresh_token',
      'token_type': 'bearer',
      'user': _mockUserJson(role: role),
    };

MockClient _clientThatReturns(int status, Map<String, dynamic> body) =>
    MockClient((_) async => http.Response(
          jsonEncode(body),
          status,
          headers: {'content-type': 'application/json'},
        ));

MockClient _clientThatThrows() =>
    MockClient((_) async => throw Exception('Connection refused'));

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // ── Initial state ──────────────────────────────────────────────────────────

  group('AuthProvider initial state', () {
    test('isLoggedIn is false before login', () {
      expect(AuthProvider().isLoggedIn, false);
    });

    test('user is null before login', () {
      expect(AuthProvider().user, isNull);
    });

    test('role returns empty string before login', () {
      expect(AuthProvider().role, '');
    });

    test('loading is false initially', () {
      expect(AuthProvider().loading, false);
    });

    test('error is null initially', () {
      expect(AuthProvider().error, isNull);
    });
  });

  // ── login ──────────────────────────────────────────────────────────────────

  group('AuthProvider.login', () {
    test('returns true and stores user on success', () async {
      final client = _clientThatReturns(200, _mockTokenResponse());
      final provider = AuthProvider();

      final result = await http.runWithClient(
        () => provider.login('john@example.com', 'TestPass1!'),
        () => client,
      );

      expect(result, true);
      expect(provider.isLoggedIn, true);
      expect(provider.user?.email, 'john@example.com');
      expect(provider.accessToken, 'mock_access_token');
    });

    test('stores correct role after login', () async {
      final client = _clientThatReturns(200, _mockTokenResponse(role: 'Admin'));
      final provider = AuthProvider();

      await http.runWithClient(
        () => provider.login('admin@example.com', 'TestPass1!'),
        () => client,
      );

      expect(provider.role, 'Admin');
    });

    test('returns false and sets error on 401', () async {
      final client = _clientThatReturns(401,
          {'detail': 'Invalid credentials. Please check email and password.'});
      final provider = AuthProvider();

      final result = await http.runWithClient(
        () => provider.login('bad@example.com', 'wrong'),
        () => client,
      );

      expect(result, false);
      expect(provider.isLoggedIn, false);
      expect(provider.error, contains('Invalid credentials'));
    });

    test('returns false with pending approval message on 403', () async {
      final client = _clientThatReturns(403, {
        'detail':
            'Your account is pending admin approval. You will be notified once approved.'
      });
      final provider = AuthProvider();

      final result = await http.runWithClient(
        () => provider.login('vendor@example.com', 'TestPass1!'),
        () => client,
      );

      expect(result, false);
      expect(provider.error, contains('pending admin approval'));
    });

    test('returns false with deactivated message on 403 for inactive user', () async {
      final client = _clientThatReturns(403, {
        'detail': 'Your account has been deactivated. Please contact support.'
      });
      final provider = AuthProvider();

      final result = await http.runWithClient(
        () => provider.login('inactive@example.com', 'TestPass1!'),
        () => client,
      );

      expect(result, false);
      expect(provider.error, contains('deactivated'));
    });

    test('returns false and sets network error on connection failure', () async {
      final provider = AuthProvider();

      final result = await http.runWithClient(
        () => provider.login('john@example.com', 'TestPass1!'),
        _clientThatThrows,
      );

      expect(result, false);
      expect(provider.error, contains('Network error'));
    });

    test('loading is false after successful login', () async {
      final client = _clientThatReturns(200, _mockTokenResponse());
      final provider = AuthProvider();

      await http.runWithClient(
        () => provider.login('john@example.com', 'TestPass1!'),
        () => client,
      );

      expect(provider.loading, false);
    });
  });

  // ── logout ─────────────────────────────────────────────────────────────────

  group('AuthProvider.logout', () {
    test('clears user and tokens after logout', () async {
      final client = _clientThatReturns(200, _mockTokenResponse());
      final provider = AuthProvider();

      await http.runWithClient(
        () => provider.login('john@example.com', 'TestPass1!'),
        () => client,
      );
      expect(provider.isLoggedIn, true);

      await provider.logout();

      expect(provider.isLoggedIn, false);
      expect(provider.user, isNull);
      expect(provider.accessToken, isNull);
    });

    test('isLoggedIn is false after logout', () async {
      final client = _clientThatReturns(200, _mockTokenResponse());
      final provider = AuthProvider();

      await http.runWithClient(
        () => provider.login('john@example.com', 'TestPass1!'),
        () => client,
      );
      await provider.logout();

      expect(provider.isLoggedIn, false);
    });
  });

  // ── init ───────────────────────────────────────────────────────────────────

  group('AuthProvider.init', () {
    test('restores session when valid token in SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'access_token': 'stored_token',
        'refresh_token': 'stored_refresh',
      });
      final client = _clientThatReturns(200, _mockUserJson());
      final provider = AuthProvider();

      await http.runWithClient(() => provider.init(), () => client);

      expect(provider.isLoggedIn, true);
      expect(provider.accessToken, 'stored_token');
    });

    test('clears session when token fetch returns 401', () async {
      SharedPreferences.setMockInitialValues({
        'access_token': 'expired_token',
        'refresh_token': 'expired_refresh',
      });
      final client = _clientThatReturns(401, {'detail': 'Unauthorized'});
      final provider = AuthProvider();

      await http.runWithClient(() => provider.init(), () => client);

      expect(provider.isLoggedIn, false);
      expect(provider.user, isNull);
    });

    test('is not logged in with no stored token', () async {
      final provider = AuthProvider();
      await provider.init();
      expect(provider.isLoggedIn, false);
    });
  });

  // ── register ───────────────────────────────────────────────────────────────

  group('AuthProvider.register', () {
    test('returns true on successful registration', () async {
      final client = _clientThatReturns(201, _mockUserJson());
      final provider = AuthProvider();

      final result = await http.runWithClient(
        () => provider.register({
          'email': 'new@example.com',
          'password': 'TestPass1!',
          'role': 'Customer',
        }),
        () => client,
      );

      expect(result, true);
    });

    test('returns false and sets error on duplicate email', () async {
      final client =
          _clientThatReturns(400, {'detail': 'Email already registered'});
      final provider = AuthProvider();

      final result = await http.runWithClient(
        () => provider.register({'email': 'dup@example.com'}),
        () => client,
      );

      expect(result, false);
      expect(provider.error, contains('Email already registered'));
    });
  });

  // ── clearError ─────────────────────────────────────────────────────────────

  group('AuthProvider.clearError', () {
    test('resets error to null', () async {
      final client =
          _clientThatReturns(401, {'detail': 'Invalid credentials.'});
      final provider = AuthProvider();

      await http.runWithClient(
        () => provider.login('x@x.com', 'wrong'),
        () => client,
      );
      expect(provider.error, isNotNull);

      provider.clearError();

      expect(provider.error, isNull);
    });
  });
}
