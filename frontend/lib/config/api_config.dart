class ApiConfig {
  // Change this to your FastAPI server address
  // For Android emulator use: http://10.0.2.2:8000
  // For iOS simulator / web use: http://localhost:8000
  static const String baseUrl = 'http://localhost:8000';

  static const String register       = '$baseUrl/api/auth/register';
  static const String login          = '$baseUrl/api/auth/login';
  static const String refresh        = '$baseUrl/api/auth/refresh';
  static const String forgotPassword = '$baseUrl/api/auth/forgot-password';

  static const String users          = '$baseUrl/api/users';
  static const String usersMe        = '$baseUrl/api/users/me';
  static String userById(String id)  => '$baseUrl/api/users/$id';
  static String userStatus(String id)=> '$baseUrl/api/users/$id/status';
  static const String createAdmin    = '$baseUrl/api/users/admin';

  static const String vendorOnboarding     = '$baseUrl/api/vendors/onboarding';
  static const String vendorOnboardingMine = '$baseUrl/api/vendors/onboarding/mine';
  static String vendorOnboardingById(String id)  => '$baseUrl/api/vendors/onboarding/$id';
  static String vendorApprove(String id)         => '$baseUrl/api/vendors/onboarding/$id/approve';
  static String vendorReject(String id)          => '$baseUrl/api/vendors/onboarding/$id/reject';
  static const String vendorsApproved            = '$baseUrl/api/vendors/approved';
}
