class User {
  final String  id;
  final String  firstName;
  final String  lastName;
  final String  email;
  final String  phoneNumber;
  final String  address;
  final String? gstNumber;
  final String  role;
  final String  status;
  final String  createdAt;

  const User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.address,
    this.gstNumber,
    required this.role,
    required this.status,
    required this.createdAt,
  });

  String get fullName => '$firstName $lastName';
  String get initials => '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'.toUpperCase();

  factory User.fromJson(Map<String, dynamic> json) => User(
    id          : json['id']           as String,
    firstName   : json['first_name']   as String,
    lastName    : json['last_name']    as String,
    email       : json['email']        as String,
    phoneNumber : json['phone_number'] as String,
    address     : json['address']      as String,
    gstNumber   : json['gst_number']   as String?,
    role        : json['role']         as String,
    status      : json['status']       as String,
    createdAt   : (json['created_at'] as String).substring(0, 10),
  );

  Map<String, dynamic> toJson() => {
    'id'          : id,
    'first_name'  : firstName,
    'last_name'   : lastName,
    'email'       : email,
    'phone_number': phoneNumber,
    'address'     : address,
    'gst_number'  : gstNumber,
    'role'        : role,
    'status'      : status,
    'created_at'  : createdAt,
  };
}
