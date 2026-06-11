import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class StoredAuthSession {
  const StoredAuthSession({
    required this.userId,
    required this.token,
    required this.role,
    this.email,
    this.name,
  });

  final String userId;
  final String token;
  final String role;
  final String? email;
  final String? name;
}

class AuthSessionStore {
  static const String _key = 'sharingbridge_auth_session_v1';

  Future<StoredAuthSession?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final userId = map['userId']?.toString() ?? '';
      final token = map['token']?.toString() ?? '';
      final role = map['role']?.toString() ?? 'initiator';
      if (userId.isEmpty || token.isEmpty) {
        return null;
      }
      return StoredAuthSession(
        userId: userId,
        token: token,
        role: role,
        email: map['email']?.toString(),
        name: map['name']?.toString(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> save(StoredAuthSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(<String, dynamic>{
        'userId': session.userId,
        'token': session.token,
        'role': session.role,
        if (session.email != null) 'email': session.email,
        if (session.name != null) 'name': session.name,
      }),
    );
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
