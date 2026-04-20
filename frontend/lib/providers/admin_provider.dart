import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/user.dart';
import '../models/vendor_profile.dart';
import '../services/api_service.dart';

class AdminProvider extends ChangeNotifier {
  List<User>          _users   = [];
  List<VendorProfile> _vendors = [];
  bool    _loading = false;
  String? _error;

  List<User>          get users   => _users;
  List<VendorProfile> get vendors => _vendors;
  bool    get loading => _loading;
  String? get error   => _error;

  int get pendingCount => _vendors.where((v) => v.onboardingStatus == 'Pending').length;

  // ── Users ──────────────────────────────────────────────────────────────────
  Future<void> loadUsers(String token, {String? role, String? status, String? search}) async {
    _setLoading(true);
    try {
      final query = <String, String>{};
      if (role   != null && role   != 'All') query['role']   = role;
      if (status != null && status != 'All') query['status'] = status;
      if (search != null && search.isNotEmpty) query['search'] = search;
      final data = await ApiService.get(ApiConfig.users, token: token, query: query);
      _users = (data as List).map((e) => User.fromJson(e)).toList();
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateUser(String token, String id, Map<String, dynamic> payload) async {
    try {
      final data = await ApiService.put(ApiConfig.userById(id), payload, token: token);
      final updated = User.fromJson(data);
      _users = _users.map((u) => u.id == id ? updated : u).toList();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message; notifyListeners(); return false;
    }
  }

  Future<bool> toggleUserStatus(String token, String id, String newStatus) async {
    try {
      final data = await ApiService.patch(
        ApiConfig.userStatus(id), {'status': newStatus}, token: token);
      final updated = User.fromJson(data);
      _users = _users.map((u) => u.id == id ? updated : u).toList();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message; notifyListeners(); return false;
    }
  }

  Future<bool> deleteUser(String token, String id) async {
    try {
      await ApiService.delete(ApiConfig.userById(id), token: token);
      _users = _users.where((u) => u.id != id).toList();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message; notifyListeners(); return false;
    }
  }

  Future<bool> createAdmin(String token, Map<String, dynamic> payload) async {
    try {
      final data = await ApiService.post(ApiConfig.createAdmin, payload, token: token);
      _users = [..._users, User.fromJson(data)];
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message; notifyListeners(); return false;
    }
  }

  // ── Vendors ────────────────────────────────────────────────────────────────
  Future<void> loadVendors(String token, {String? status}) async {
    _setLoading(true);
    try {
      final query = status != null && status != 'All' ? {'status': status} : null;
      final data = await ApiService.get(ApiConfig.vendorOnboarding, token: token, query: query);
      _vendors = (data as List).map((e) => VendorProfile.fromJson(e)).toList();
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> approveVendor(String token, String profileId) async {
    try {
      final data = await ApiService.patch(
        ApiConfig.vendorApprove(profileId), {}, token: token);
      _updateVendor(VendorProfile.fromJson(data));
      return true;
    } on ApiException catch (e) {
      _error = e.message; notifyListeners(); return false;
    }
  }

  Future<bool> rejectVendor(String token, String profileId, String reason) async {
    try {
      final data = await ApiService.patch(
        ApiConfig.vendorReject(profileId), {'reason': reason}, token: token);
      _updateVendor(VendorProfile.fromJson(data));
      return true;
    } on ApiException catch (e) {
      _error = e.message; notifyListeners(); return false;
    }
  }

  void _updateVendor(VendorProfile updated) {
    _vendors = _vendors.map((v) => v.id == updated.id ? updated : v).toList();
    notifyListeners();
  }

  void clearError() { _error = null; notifyListeners(); }
  void _setLoading(bool v) { _loading = v; notifyListeners(); }
}
