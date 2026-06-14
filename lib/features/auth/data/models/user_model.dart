// lib/features/auth/data/models/user_model.dart

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String phone;
  final String role;
  final String status;
  final String program;
  final int programDays;
  final String? picture;
  final String? pictureUrl;
  final String? coachId;
  final double dailyCalories;
  final double dailyProtein;
  final double dailyCarbs;
  final double dailyFat;
  final double dailyWater;
  final String? subscriptionPlan;
  final String? subscriptionExpiry;
  final String? subscriptionStatus;
  final String? referralCode;
  final String? referredBy;
  final int referralCoins;
  final String? forceLogoutToken;
  final String? deviceId;
  final bool chatBanned;
  final DateTime? chatMuteUntil;
  final String? rejectReason;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? lastLogin;
  final bool showOldValues;
  final bool showEpley;
  final bool showRPE;
  final bool showRepSuggest;
  final List<int> gymDays;
  final Map<String, String>? sessionMap;
  final Map<String, dynamic>? customData;

  const UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.phone = '',
    this.role = 'trainee',
    this.status = 'pending',
    this.program = 'UL',
    this.programDays = 4,
    this.picture,
    this.pictureUrl,
    this.coachId,
    this.dailyCalories = 2000,
    this.dailyProtein = 150,
    this.dailyCarbs = 200,
    this.dailyFat = 70,
    this.dailyWater = 2.5,
    this.subscriptionPlan,
    this.subscriptionExpiry,
    this.subscriptionStatus,
    this.referralCode,
    this.referredBy,
    this.referralCoins = 0,
    this.forceLogoutToken,
    this.deviceId,
    this.chatBanned = false,
    this.chatMuteUntil,
    this.rejectReason,
    this.notes,
    this.createdAt,
    this.lastLogin,
    this.showOldValues = true,
    this.showEpley = false,
    this.showRPE = true,
    this.showRepSuggest = true,
    this.gymDays = const [1, 2, 3, 4],
    this.sessionMap,
    this.customData,
  });

  bool get isAdmin =>
      role == 'admin' || role == 'superadmin';
  bool get isSuperAdmin => role == 'superadmin';
  bool get isCoach => role == 'coach' || isAdmin;
  bool get isActive => status == 'active';
  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected';
  bool get isPaymentPending => status == 'payment_pending';

  bool get isSubscriptionValid {
    if (isAdmin || isCoach) return true;
    if (subscriptionExpiry == null) return false;
    try {
      final expiry = DateTime.parse(subscriptionExpiry!);
      return expiry.isAfter(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  int get subscriptionDaysLeft {
    if (subscriptionExpiry == null) return 0;
    try {
      final expiry = DateTime.parse(subscriptionExpiry!);
      final diff = expiry.difference(DateTime.now()).inDays;
      return diff > 0 ? diff : 0;
    } catch (_) {
      return 0;
    }
  }

  bool get isChatMuted {
    if (chatMuteUntil == null) return false;
    return chatMuteUntil!.isAfter(DateTime.now());
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? phone,
    String? role,
    String? status,
    String? program,
    int? programDays,
    String? picture,
    String? pictureUrl,
    String? coachId,
    double? dailyCalories,
    double? dailyProtein,
    double? dailyCarbs,
    double? dailyFat,
    double? dailyWater,
    String? subscriptionPlan,
    String? subscriptionExpiry,
    String? subscriptionStatus,
    String? referralCode,
    String? referredBy,
    int? referralCoins,
    String? forceLogoutToken,
    String? deviceId,
    bool? chatBanned,
    DateTime? chatMuteUntil,
    String? rejectReason,
    String? notes,
    DateTime? createdAt,
    DateTime? lastLogin,
    bool? showOldValues,
    bool? showEpley,
    bool? showRPE,
    bool? showRepSuggest,
    List<int>? gymDays,
    Map<String, String>? sessionMap,
    Map<String, dynamic>? customData,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      status: status ?? this.status,
      program: program ?? this.program,
      programDays: programDays ?? this.programDays,
      picture: picture ?? this.picture,
      pictureUrl: pictureUrl ?? this.pictureUrl,
      coachId: coachId ?? this.coachId,
      dailyCalories: dailyCalories ?? this.dailyCalories,
      dailyProtein: dailyProtein ?? this.dailyProtein,
      dailyCarbs: dailyCarbs ?? this.dailyCarbs,
      dailyFat: dailyFat ?? this.dailyFat,
      dailyWater: dailyWater ?? this.dailyWater,
      subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
      subscriptionExpiry: subscriptionExpiry ?? this.subscriptionExpiry,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      referralCode: referralCode ?? this.referralCode,
      referredBy: referredBy ?? this.referredBy,
      referralCoins: referralCoins ?? this.referralCoins,
      forceLogoutToken: forceLogoutToken ?? this.forceLogoutToken,
      deviceId: deviceId ?? this.deviceId,
      chatBanned: chatBanned ?? this.chatBanned,
      chatMuteUntil: chatMuteUntil ?? this.chatMuteUntil,
      rejectReason: rejectReason ?? this.rejectReason,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      showOldValues: showOldValues ?? this.showOldValues,
      showEpley: showEpley ?? this.showEpley,
      showRPE: showRPE ?? this.showRPE,
      showRepSuggest: showRepSuggest ?? this.showRepSuggest,
      gymDays: gymDays ?? this.gymDays,
      sessionMap: sessionMap ?? this.sessionMap,
      customData: customData ?? this.customData,
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    List<int> parseGymDays(dynamic raw) {
      if (raw == null) return [1, 2, 3, 4];
      if (raw is List) return raw.map((e) => int.tryParse(e.toString()) ?? 0).toList();
      if (raw is String) {
        try {
          return raw.split(',').map((e) => int.tryParse(e.trim()) ?? 0).toList();
        } catch (_) {
          return [1, 2, 3, 4];
        }
      }
      return [1, 2, 3, 4];
    }

    Map<String, String>? parseSessionMap(dynamic raw) {
      if (raw == null) return null;
      if (raw is Map) {
        return raw.map((k, v) => MapEntry(k.toString(), v.toString()));
      }
      return null;
    }

    return UserModel(
      uid: map['uid']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      role: map['role']?.toString() ?? 'trainee',
      status: map['status']?.toString() ?? 'pending',
      program: map['program']?.toString() ?? 'UL',
      programDays: int.tryParse(map['programDays']?.toString() ?? '4') ?? 4,
      picture: map['picture']?.toString(),
      pictureUrl: map['pictureUrl']?.toString(),
      coachId: map['coachId']?.toString(),
      dailyCalories: double.tryParse(map['dailyCalories']?.toString() ?? '2000') ?? 2000,
      dailyProtein: double.tryParse(map['dailyProtein']?.toString() ?? '150') ?? 150,
      dailyCarbs: double.tryParse(map['dailyCarbs']?.toString() ?? '200') ?? 200,
      dailyFat: double.tryParse(map['dailyFat']?.toString() ?? '70') ?? 70,
      dailyWater: double.tryParse(map['dailyWater']?.toString() ?? '2.5') ?? 2.5,
      subscriptionPlan: map['subscriptionPlan']?.toString(),
      subscriptionExpiry: map['subscriptionExpiry']?.toString(),
      subscriptionStatus: map['subscriptionStatus']?.toString(),
      referralCode: map['referralCode']?.toString(),
      referredBy: map['referredBy']?.toString(),
      referralCoins: int.tryParse(map['referralCoins']?.toString() ?? '0') ?? 0,
      forceLogoutToken: map['forceLogoutToken']?.toString(),
      deviceId: map['deviceId']?.toString(),
      chatBanned: map['chatBanned'] == true || map['chatBanned'] == 'true',
      chatMuteUntil: map['chatMuteUntil'] != null
          ? DateTime.tryParse(map['chatMuteUntil'].toString())
          : null,
      rejectReason: map['rejectReason']?.toString(),
      notes: map['notes']?.toString(),
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString())
          : null,
      lastLogin: map['lastLogin'] != null
          ? DateTime.tryParse(map['lastLogin'].toString())
          : null,
      showOldValues: map['showOldValues'] != false,
      showEpley: map['showEpley'] == true,
      showRPE: map['showRPE'] != false,
      showRepSuggest: map['showRepSuggest'] != false,
      gymDays: parseGymDays(map['gymDays']),
      sessionMap: parseSessionMap(map['sessionMap']),
      customData: map['customData'] is Map
          ? Map<String, dynamic>.from(map['customData'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'phone': phone,
      'role': role,
      'status': status,
      'program': program,
      'programDays': programDays,
      'picture': picture,
      'pictureUrl': pictureUrl,
      'coachId': coachId,
      'dailyCalories': dailyCalories,
      'dailyProtein': dailyProtein,
      'dailyCarbs': dailyCarbs,
      'dailyFat': dailyFat,
      'dailyWater': dailyWater,
      'subscriptionPlan': subscriptionPlan,
      'subscriptionExpiry': subscriptionExpiry,
      'subscriptionStatus': subscriptionStatus,
      'referralCode': referralCode,
      'referredBy': referredBy,
      'referralCoins': referralCoins,
      'forceLogoutToken': forceLogoutToken,
      'deviceId': deviceId,
      'chatBanned': chatBanned,
      'chatMuteUntil': chatMuteUntil?.toIso8601String(),
      'rejectReason': rejectReason,
      'notes': notes,
      'createdAt': createdAt?.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
      'showOldValues': showOldValues,
      'showEpley': showEpley,
      'showRPE': showRPE,
      'showRepSuggest': showRepSuggest,
      'gymDays': gymDays,
      'sessionMap': sessionMap,
      'customData': customData,
    };
  }

  @override
  String toString() => 'UserModel(uid: $uid, email: $email, role: $role)';
}
