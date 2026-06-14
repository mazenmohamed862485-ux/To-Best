// lib/core/network/api_client.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../storage/secure_storage.dart';
import '../storage/local_db.dart';

class ApiClient {
  static const int _timeoutMs = 14000;
  final SecureStorage _secureStorage;
  final LocalDb _localDb;

  ApiClient({required SecureStorage secureStorage, required LocalDb localDb})
      : _secureStorage = secureStorage,
        _localDb = localDb;

  // ── Core fetch — form-urlencoded (no CORS preflight for GAS) ──
  Future<Map<String, dynamic>?> _fetch(Map<String, dynamic> payload) async {
    final url = await _localDb.getSetting('webAppUrl') ?? '';
    if (url.isEmpty) return null;

    final secretKey = await _secureStorage.getSecretKey();
    final sessionToken = await _localDb.getSetting('sessionToken') ?? '';

    final fullPayload = {
      ...payload,
      'secret': secretKey,
      if (sessionToken.isNotEmpty) 'sessionToken': sessionToken,
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'payload': jsonEncode(fullPayload)},
      ).timeout(Duration(milliseconds: _timeoutMs));

      if (response.statusCode != 200) return null;
      final result = jsonDecode(response.body) as Map<String, dynamic>;

      // Store session token if returned
      if (result['sessionToken'] != null) {
        await _localDb.setSetting('sessionToken', result['sessionToken'].toString());
      }
      return result;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _fetchPublic(Map<String, dynamic> payload) async {
    final url = await _localDb.getSetting('webAppUrl') ?? '';
    if (url.isEmpty) return null;
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'payload': jsonEncode(payload)},
      ).timeout(Duration(milliseconds: _timeoutMs));
      if (response.statusCode != 200) return null;
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<bool> get isConfigured async {
    final url = await _localDb.getSetting('webAppUrl') ?? '';
    return url.isNotEmpty;
  }

  // ══ Auth ══════════════════════════════════════════════════
  Future<Map<String, dynamic>> login(String email, String password) async {
    if (!await isConfigured) return {'ok': false, 'err': 'not_configured'};
    return (await _fetch({'action': 'LOGIN', 'email': email, 'password': password})) ??
        {'ok': false, 'err': 'network'};
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    if (!await isConfigured) return {'ok': false, 'err': 'not_configured'};
    return (await _fetch({'action': 'REGISTER', ...userData})) ??
        {'ok': false, 'err': 'network'};
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    return (await _fetchPublic({'action': 'FORGOT_PASSWORD', 'email': email})) ??
        {'ok': false, 'err': 'network'};
  }

  Future<Map<String, dynamic>> verifyResetCode(String email, String code) async {
    return (await _fetchPublic({'action': 'VERIFY_RESET', 'email': email, 'code': code})) ??
        {'ok': false};
  }

  Future<bool> changePassword(String uid, String oldPwd, String newPwd) async {
    final res = await _fetch({'action': 'CHANGE_PASSWORD', 'uid': uid, 'oldPwd': oldPwd, 'newPwd': newPwd});
    return res?['ok'] == true;
  }

  Future<Map<String, dynamic>> loginGuest(String code) async {
    return (await _fetchPublic({'action': 'GUEST_LOGIN', 'code': code})) ??
        {'ok': false, 'err': 'network'};
  }

  Future<void> clearSessionToken() async {
    await _localDb.setSetting('sessionToken', '');
  }

  // ══ Data Sync ══════════════════════════════════════════════
  Future<Map<String, dynamic>?> fetchUserData(String uid) async {
    if (!await isConfigured) return null;
    final res = await _fetch({'action': 'FETCH_USER_DATA', 'uid': uid});
    return res?['ok'] == true ? res!['data'] as Map<String, dynamic>? : null;
  }

  Future<List<Map<String, dynamic>>?> fetchAllUsers() async {
    final res = await _fetch({'action': 'FETCH_ALL_USERS'});
    if (res?['ok'] != true) return null;
    final users = res!['users'];
    if (users is List) return users.cast<Map<String, dynamic>>();
    return null;
  }

  Future<bool> pushToCloud(Map<String, dynamic> item) async {
    if (!await isConfigured) return false;
    final res = await _fetch({
      'action': item['action'],
      'key': item['key'],
      'data': item['data'],
      'uid': item['uid'] ?? item['key'],
    });
    return res?['ok'] == true;
  }

  Future<Map<String, dynamic>?> fetchFullData(String uid) async {
    if (!await isConfigured) return null;
    final res = await _fetch({'action': 'FULL_SYNC_PULL', 'uid': uid});
    return res?['ok'] == true ? res!['data'] as Map<String, dynamic>? : null;
  }

  Future<bool> pushUserSheet(String uid, Map<String, dynamic> snapshot) async {
    if (!await isConfigured) return false;
    final res = await _fetch({'action': 'UPDATE_USER_SHEET', 'uid': uid, 'snapshot': snapshot});
    return res?['ok'] == true;
  }

  // ══ Admin ══════════════════════════════════════════════════
  Future<bool> adminUpdateUser(String uid, Map<String, dynamic> fields) async {
    final res = await _fetch({'action': 'ADMIN_UPDATE_USER', 'uid': uid, 'fields': fields});
    return res?['ok'] == true;
  }

  Future<bool> adminApproveUser(String uid, bool approved) async {
    final res = await _fetch({'action': 'ADMIN_APPROVE', 'uid': uid, 'approved': approved});
    return res?['ok'] == true;
  }

  Future<bool> adminDeleteUser(String uid) async {
    final res = await _fetch({'action': 'ADMIN_DELETE_USER', 'uid': uid});
    return res?['ok'] == true;
  }

  Future<bool> adminAddUser(Map<String, dynamic> userData) async {
    final res = await _fetch({'action': 'ADMIN_ADD_USER', ...userData});
    return res?['ok'] == true;
  }

  Future<bool> approveProgram(String uid, String programId, int programDays) async {
    final res = await _fetch({
      'action': 'APPROVE_PROGRAM',
      'uid': uid,
      'programId': programId,
      'programDays': programDays,
    });
    return res?['ok'] == true;
  }

  Future<List<Map<String, dynamic>>> getAuditLog() async {
    final res = await _fetch({'action': 'GET_AUDIT_LOG'});
    if (res?['ok'] != true) return [];
    final log = res!['log'];
    if (log is List) return log.cast<Map<String, dynamic>>();
    return [];
  }

  // ══ Subscription ══════════════════════════════════════════
  Future<Map<String, dynamic>> submitSubscriptionPayment(
      String uid, Map<String, dynamic> data) async {
    if (!await isConfigured) return {'ok': false, 'err': 'not_configured'};
    return (await _fetch({'action': 'SUB_REQUEST', 'uid': uid, 'data': data})) ??
        {'ok': false, 'err': 'network'};
  }

  Future<List<Map<String, dynamic>>> getSubscriptionRequests() async {
    final res = await _fetch({'action': 'GET_SUB_REQUESTS'});
    if (res?['ok'] != true) return [];
    final requests = res!['requests'];
    if (requests is List) return requests.cast<Map<String, dynamic>>();
    return [];
  }

  Future<bool> updateSubscriptionRequest(
      String id, String status, Map<String, dynamic> fields) async {
    final res = await _fetch({
      'action': 'UPDATE_SUB_REQUEST',
      'id': id,
      'status': status,
      'fields': fields,
    });
    return res?['ok'] == true;
  }

  Future<bool> saveSubscriptionConfig(Map<String, dynamic> cfg) async {
    final res = await _fetch({'action': 'SUB_CONFIG', 'data': cfg});
    return res?['ok'] == true;
  }

  Future<Map<String, dynamic>?> getSubscriptionConfig() async {
    final res = await _fetch({'action': 'GET_SUB_CONFIG'});
    return res?['ok'] == true ? res!['config'] as Map<String, dynamic>? : null;
  }

  // ══ Chat ══════════════════════════════════════════════════
  Future<List<Map<String, dynamic>>> fetchNewMessages(
      String roomId, String since) async {
    final res = await _fetch({'action': 'FETCH_MSGS', 'roomId': roomId, 'since': since});
    if (res?['ok'] != true) return [];
    final msgs = res!['messages'];
    if (msgs is List) return msgs.cast<Map<String, dynamic>>();
    return [];
  }

  Future<bool> sendMessage(String roomId, Map<String, dynamic> msg) async {
    final res = await _fetch({'action': 'SEND_MSG', 'roomId': roomId, 'msg': msg});
    return res?['ok'] == true;
  }

  Future<bool> deleteMessage(String roomId, String msgId) async {
    final res = await _fetch({'action': 'DELETE_MSG', 'roomId': roomId, 'msgId': msgId});
    return res?['ok'] == true;
  }

  Future<bool> editMessage(String roomId, String msgId, String newText) async {
    final res = await _fetch({
      'action': 'EDIT_MSG',
      'roomId': roomId,
      'msgId': msgId,
      'newText': newText,
    });
    return res?['ok'] == true;
  }

  Future<bool> pinMessage(String roomId, Map<String, dynamic> msg) async {
    final res = await _fetch({'action': 'PIN_MSG', 'roomId': roomId, 'msg': msg});
    return res?['ok'] == true;
  }

  Future<bool> unpinMessage(String roomId) async {
    final res = await _fetch({'action': 'UNPIN_MSG', 'roomId': roomId});
    return res?['ok'] == true;
  }

  Future<Map<String, dynamic>?> fetchPinnedMessage(String roomId) async {
    final res = await _fetch({'action': 'GET_PINNED', 'roomId': roomId});
    return res?['ok'] == true ? res!['pinned'] as Map<String, dynamic>? : null;
  }

  Future<bool> banUserFromChat(String uid, bool ban) async {
    final res = await _fetch({'action': 'CHAT_BAN', 'uid': uid, 'ban': ban});
    return res?['ok'] == true;
  }

  Future<bool> muteUserInChat(String uid, String muteUntil) async {
    final res = await _fetch({'action': 'CHAT_MUTE', 'uid': uid, 'muteUntil': muteUntil});
    return res?['ok'] == true;
  }

  Future<bool> sendFileMessage(String roomId, Map<String, dynamic> msg) async {
    final res = await _fetch({'action': 'SEND_FILE_MSG', 'roomId': roomId, 'msg': msg});
    return res?['ok'] == true;
  }

  // ══ Promo Codes ════════════════════════════════════════════
  Future<Map<String, dynamic>> checkPromo(String code) async {
    if (!await isConfigured || code.isEmpty) return {'ok': false};
    return (await _fetch({'action': 'PROMO_CHECK', 'code': code})) ?? {'ok': false};
  }

  Future<bool> createPromo(String code, double discount, int maxUses) async {
    final res = await _fetch({
      'action': 'PROMO_CREATE',
      'code': code,
      'discount': discount,
      'maxUses': maxUses,
    });
    return res?['ok'] == true;
  }

  Future<Map<String, dynamic>> listPromos() async {
    return (await _fetch({'action': 'PROMO_LIST'})) ?? {'ok': false, 'codes': []};
  }

  Future<bool> deletePromo(String code) async {
    final res = await _fetch({'action': 'PROMO_DELETE', 'code': code});
    return res?['ok'] == true;
  }

  // ══ Guest Codes ════════════════════════════════════════════
  Future<Map<String, dynamic>> createGuestCode(String code) async {
    return (await _fetch({'action': 'GUEST_CREATE', 'code': code})) ?? {'ok': false};
  }

  Future<Map<String, dynamic>> listGuestCodes() async {
    return (await _fetch({'action': 'GUEST_LIST'})) ?? {'ok': false, 'codes': []};
  }

  Future<bool> deleteGuestCode(String code) async {
    final res = await _fetch({'action': 'GUEST_DELETE', 'code': code});
    return res?['ok'] == true;
  }

  // ══ Profile & Pictures ════════════════════════════════════
  Future<Map<String, dynamic>> saveProfilePicture(String uid, String imageData) async {
    if (!await isConfigured) return {'ok': false, 'err': 'not_configured'};
    return (await _fetch({'action': 'SAVE_PROFILE_PIC', 'uid': uid, 'imageData': imageData})) ??
        {'ok': false};
  }

  // ══ Ban / Force Logout ════════════════════════════════════
  Future<Map<String, dynamic>> forceLogoutUser(String uid, String token) async {
    final res = (await _fetch({'action': 'FORCE_LOGOUT_USER', 'uid': uid, 'token': token})) ??
        {'ok': false};
    if (res['ok'] == true) await clearSessionToken();
    return res;
  }

  Future<Map<String, dynamic>> forceLogoutAllUsers(String token) async {
    return (await _fetch({'action': 'FORCE_LOGOUT_ALL', 'token': token})) ?? {'ok': false};
  }

  Future<Map<String, dynamic>> banIdentity(Map<String, dynamic> banEntry) async {
    return (await _fetch({'action': 'BAN_IDENTITY', 'banEntry': banEntry})) ?? {'ok': false};
  }

  Future<Map<String, dynamic>> unbanIdentity(String banId) async {
    return (await _fetch({'action': 'UNBAN_IDENTITY', 'banId': banId})) ?? {'ok': false};
  }

  Future<Map<String, dynamic>> listBanned() async {
    return (await _fetch({'action': 'LIST_BANNED'})) ?? {'ok': false, 'list': []};
  }

  Future<Map<String, dynamic>> checkBan(String email, String phone) async {
    return (await _fetch({'action': 'CHECK_BAN', 'email': email, 'phone': phone})) ??
        {'banned': false};
  }

  // ══ Referral ══════════════════════════════════════════════
  Future<Map<String, dynamic>> getReferralStats(String code) async {
    return (await _fetch({'action': 'GET_REFERRAL_STATS', 'code': code})) ?? {'ok': false};
  }

  Future<Map<String, dynamic>> getAllReferralStats() async {
    return (await _fetch({'action': 'GET_ALL_REFERRAL_STATS'})) ?? {'ok': false};
  }

  // ══ Device Lock ════════════════════════════════════════════
  Future<List<Map<String, dynamic>>> getUserDevices(String uid) async {
    final res = await _fetch({'action': 'GET_USER_DEVICES', 'uid': uid});
    if (res?['ok'] != true) return [];
    final devices = res!['devices'];
    if (devices is List) return devices.cast<Map<String, dynamic>>();
    return [];
  }

  Future<bool> removeDevice(String uid, String deviceId) async {
    final res = await _fetch({'action': 'REMOVE_DEVICE', 'uid': uid, 'deviceId': deviceId});
    return res?['ok'] == true;
  }

  // ══ AI Chat ════════════════════════════════════════════════
  Future<Map<String, dynamic>> sendAIMessage(
      String uid, String message, List<Map<String, dynamic>> history) async {
    return (await _fetch({
          'action': 'AI_CHAT',
          'uid': uid,
          'message': message,
          'history': history,
        })) ??
        {'ok': false};
  }

  Future<Map<String, dynamic>> getAILimitRequests() async {
    return (await _fetch({'action': 'GET_AI_LIMIT_REQUESTS'})) ?? {'ok': false};
  }

  // ══ Connection ════════════════════════════════════════════
  Future<bool> testConnection() async {
    final res = await _fetch({'action': 'PING'});
    return res?['ok'] == true;
  }

  Future<bool> saveWebAppUrl(String url) async {
    await _localDb.setSetting('webAppUrl', url);
    return true;
  }

  Future<bool> saveSecretKey(String key) async {
    await _secureStorage.saveSecretKey(key);
    return true;
  }

  // ══ Notifications ══════════════════════════════════════════
  Future<List<Map<String, dynamic>>> fetchNotifications(String uid) async {
    final res = await _fetch({'action': 'GET_NOTIFICATIONS', 'uid': uid});
    if (res?['ok'] != true) return [];
    final notifs = res!['notifications'];
    if (notifs is List) return notifs.cast<Map<String, dynamic>>();
    return [];
  }

  Future<bool> markNotificationRead(String uid, String notifId) async {
    final res = await _fetch({
      'action': 'MARK_NOTIF_READ',
      'uid': uid,
      'notifId': notifId,
    });
    return res?['ok'] == true;
  }
}
