import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/vendor_profile.dart';
import '../services/api_service.dart';

class VendorProvider extends ChangeNotifier {
  VendorProfile?      _myProfile;
  List<VendorProfile> _approvedVendors = [];
  bool    _loading = false;
  String? _error;

  VendorProfile?      get myProfile       => _myProfile;
  List<VendorProfile> get approvedVendors => _approvedVendors;
  bool    get loading => _loading;
  String? get error   => _error;

  // ── Vendor: own profile ───────────────────────────────────────────────────
  Future<void> loadMyProfile(String token) async {
    _setLoading(true);
    try {
      final data = await ApiService.get(ApiConfig.vendorOnboardingMine, token: token);
      _myProfile = VendorProfile.fromJson(data);
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        _myProfile = null;
      } else {
        _error = e.message;
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> submitOnboarding(String token, Map<String, dynamic> payload) async {
    _setLoading(true);
    try {
      final data = await ApiService.post(ApiConfig.vendorOnboarding, payload, token: token);
      _myProfile = VendorProfile.fromJson(data);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message; notifyListeners(); return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Customer: browse approved vendors ─────────────────────────────────────
  Future<void> loadApprovedVendors({String? search, String? businessType}) async {
    _setLoading(true);
    try {
      final query = <String, String>{};
      if (search != null && search.isNotEmpty) query['search'] = search;
      if (businessType != null && businessType != 'All') query['business_type'] = businessType;
      final data = await ApiService.get(ApiConfig.vendorsApproved, query: query);
      _approvedVendors = (data as List).map((e) => VendorProfile.fromJson(e)).toList();
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _setLoading(false);
    }
  }

  void clearError() { _error = null; notifyListeners(); }
  void _setLoading(bool v) { _loading = v; notifyListeners(); }
}
