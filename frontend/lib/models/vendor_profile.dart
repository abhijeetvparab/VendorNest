import 'user.dart';

class VendorProfile {
  final String   id;
  final String   userId;
  final String   businessName;
  final String   businessType;
  final String   businessAddress;
  final String?  pincode;
  final String?  gstNumber;
  final String   pocName;
  final String   pocPhone;
  final String   pocEmail;
  final String?  description;
  final String?  documentName;
  final String   onboardingStatus;
  final String?  rejectionReason;
  final String?  reviewedBy;
  final String?  reviewedAt;
  final String   submittedAt;
  final User?    user;

  const VendorProfile({
    required this.id,
    required this.userId,
    required this.businessName,
    required this.businessType,
    required this.businessAddress,
    this.pincode,
    this.gstNumber,
    required this.pocName,
    required this.pocPhone,
    required this.pocEmail,
    this.description,
    this.documentName,
    required this.onboardingStatus,
    this.rejectionReason,
    this.reviewedBy,
    this.reviewedAt,
    required this.submittedAt,
    this.user,
  });

  factory VendorProfile.fromJson(Map<String, dynamic> json) => VendorProfile(
    id               : json['id']                as String,
    userId           : json['user_id']           as String,
    businessName     : json['business_name']     as String,
    businessType     : json['business_type']     as String,
    businessAddress  : json['business_address']  as String,
    pincode          : json['pincode']           as String?,
    gstNumber        : json['gst_number']        as String?,
    pocName          : json['poc_name']          as String,
    pocPhone         : json['poc_phone']         as String,
    pocEmail         : json['poc_email']         as String,
    description      : json['description']       as String?,
    documentName     : json['document_name']     as String?,
    onboardingStatus : json['onboarding_status'] as String,
    rejectionReason  : json['rejection_reason']  as String?,
    reviewedBy       : json['reviewed_by']       as String?,
    reviewedAt       : json['reviewed_at'] != null
        ? (json['reviewed_at'] as String).substring(0, 10) : null,
    submittedAt      : (json['submitted_at'] as String).substring(0, 10),
    user             : json['user'] != null ? User.fromJson(json['user']) : null,
  );
}
