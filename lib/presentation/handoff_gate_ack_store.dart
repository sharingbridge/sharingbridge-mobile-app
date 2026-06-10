import 'package:shared_preferences/shared_preferences.dart';

/// Remembers that the donor completed the Help a seeker read-through gate.
///
/// Cleared on sign-out so the next login sees the gate again.
class HandoffGateAckStore {
  static const String _key = 'sharingbridge_handoff_gate_ack_user_v1';

  Future<bool> hasAcknowledgedForUser(String userId) async {
    final normalized = userId.trim();
    if (normalized.isEmpty) {
      return false;
    }
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_key)?.trim() ?? '';
    return stored == normalized;
  }

  Future<void> markAcknowledgedForUser(String userId) async {
    final normalized = userId.trim();
    if (normalized.isEmpty) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, normalized);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
