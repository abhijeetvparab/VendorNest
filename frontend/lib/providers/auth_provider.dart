import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  User?   _user;
  String? _accessToken;
  String? _refreshToken;
  bool    _loading = false;
  String? _error;

  User?   get user         => _user;
  String? get accessToken  => _accessToken;
  bool    get loading      => _loading;
  String? get error        => _error;
  bool    get isLoggedIn   => _user != null;
  String  get role         => _user?.role ?? '';

  // ── Bootstrap ────────────────────────────────────────────────────────────────
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken  = prefs.getString('access_token');
    _refreshToken = prefs.getString('refresh_token');
    if (_accessToken != null) {
      try {
        final data = await ApiService.get(ApiConfig.usersMe, token: _accessToken);
        _user = User.fromJson(data);
      } catch (_) {
        await _clearSession();
      }
    }
    notifyListeners();
  }

  // ── Login ─────────────────────────────────────────────────────────────────
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      final data = await ApiService.post(ApiConfig.login, {
        'email': email,
        'password': password,
      });
      await _saveSession(data);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Network error — is the server running?';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Register ──────────────────────────────────────────────────────────────
  Future<bool> register(Map<String, dynamic> payload) async {
    _setLoading(true);
    try {
      await ApiService.post(ApiConfig.register, payload);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Forgot password ───────────────────────────────────────────────────────
  Future<bool> forgotPassword(String email) async {
    _setLoading(true);
    try {
      await ApiService.post('${ApiConfig.forgotPassword}?email=${Uri.encodeComponent(email)}', {});
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Update own profile ────────────────────────────────────────────────────
  Future<bool> updateProfile(Map<String, dynamic> payload) async {
    if (_user == null) return false;
    _setLoading(true);
    try {
      final data = await ApiService.put(
        ApiConfig.userById(_user!.id), payload, token: _accessToken);
      _user = User.fromJson(data);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    await _clearSession();
    notifyListeners();
  }

  void clearError() { _error = null; notifyListeners(); }

  // ── Internal ──────────────────────────────────────────────────────────────
  Future<void> _saveSession(Map<String, dynamic> data) async {
    _accessToken  = data['access_token']  as String;
    _refreshToken = data['refresh_token'] as String;
    _user         = User.fromJson(data['user']);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token',  _accessToken!);
    await prefs.setString('refresh_token', _refreshToken!);
    notifyListeners();
  }

  Future<void> _clearSession() async {
    _user = _accessToken = _refreshToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }

  void _setLoading(bool v) { _loading = v; if (v) _error = null; notifyListeners(); }
}
