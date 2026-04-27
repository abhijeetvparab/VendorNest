import 'package:flutter_test/flutter_test.dart';
import 'package:vendorapp/models/user.dart';

void main() {
  const Map<String, dynamic> sampleJson = {
    'id': 'user-123',
    'first_name': 'John',
    'last_name': 'Doe',
    'email': 'john@example.com',
    'phone_number': '9876543210',
    'address': '123 Main Street',
    'gst_number': null,
    'role': 'Vendor',
    'status': 'Active',
    'created_at': '2024-01-15T10:00:00.000000',
  };

  // ── fromJson ───────────────────────────────────────────────────────────────

  group('User.fromJson', () {
    test('parses all required fields correctly', () {
      final user = User.fromJson(sampleJson);
      expect(user.id, 'user-123');
      expect(user.firstName, 'John');
      expect(user.lastName, 'Doe');
      expect(user.email, 'john@example.com');
      expect(user.phoneNumber, '9876543210');
      expect(user.role, 'Vendor');
      expect(user.status, 'Active');
    });

    test('parses null gstNumber', () {
      final user = User.fromJson(sampleJson);
      expect(user.gstNumber, isNull);
    });

    test('parses non-null gstNumber', () {
      final user = User.fromJson({...sampleJson, 'gst_number': '29ABCDE1234F1Z5'});
      expect(user.gstNumber, '29ABCDE1234F1Z5');
    });

    test('truncates createdAt to date-only string', () {
      final user = User.fromJson(sampleJson);
      expect(user.createdAt, '2024-01-15');
    });

    test('parses Admin role', () {
      final user = User.fromJson({...sampleJson, 'role': 'Admin'});
      expect(user.role, 'Admin');
    });

    test('parses Pending status', () {
      final user = User.fromJson({...sampleJson, 'status': 'Pending'});
      expect(user.status, 'Pending');
    });
  });

  // ── Getters ────────────────────────────────────────────────────────────────

  group('User getters', () {
    test('fullName combines first and last name', () {
      final user = User.fromJson(sampleJson);
      expect(user.fullName, 'John Doe');
    });

    test('initials are first letters of first and last name', () {
      final user = User.fromJson(sampleJson);
      expect(user.initials, 'JD');
    });

    test('initials are uppercase regardless of input case', () {
      final user = User.fromJson({...sampleJson, 'first_name': 'alice', 'last_name': 'brown'});
      expect(user.initials, 'AB');
    });

    test('initials handle single-char names', () {
      final user = User.fromJson({...sampleJson, 'first_name': 'A', 'last_name': 'B'});
      expect(user.initials, 'AB');
    });
  });

  // ── toJson ─────────────────────────────────────────────────────────────────

  group('User.toJson', () {
    test('serialises id and email correctly', () {
      final json = User.fromJson(sampleJson).toJson();
      expect(json['id'], 'user-123');
      expect(json['email'], 'john@example.com');
    });

    test('serialises role and status', () {
      final json = User.fromJson(sampleJson).toJson();
      expect(json['role'], 'Vendor');
      expect(json['status'], 'Active');
    });

    test('serialises null gstNumber as null', () {
      final json = User.fromJson(sampleJson).toJson();
      expect(json['gst_number'], isNull);
    });

    test('round-trips through fromJson without data loss', () {
      final original = User.fromJson(sampleJson);
      final json = original.toJson();
      expect(json['first_name'], original.firstName);
      expect(json['last_name'], original.lastName);
      expect(json['phone_number'], original.phoneNumber);
      expect(json['address'], original.address);
    });
  });
}
