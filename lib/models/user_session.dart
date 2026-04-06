import 'package:flutter/material.dart';

/// Holds the currently logged-in user's data.
/// This is a simple in-memory singleton. When you add Firebase later,
/// replace the fields here with Firebase Auth / Firestore data.
class UserSession extends ChangeNotifier {
  static final UserSession _instance = UserSession._internal();
  factory UserSession() => _instance;
  UserSession._internal();

  // ── User profile ──────────────────────────────────────────────────────────
  String _name = '';
  String _email = '';
  String? _profileImageUrl; // Now holds the web API URL!

  String get name => _name.isNotEmpty ? _name : 'User';
  String get email => _email;
  String? get profileImageUrl => _profileImageUrl;

  /// Initial display letter for avatar fallback
  String get initials {
    if (_name.trim().isEmpty) return '?';
    final parts = _name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return _name[0].toUpperCase();
  }

  // ── App preferences ───────────────────────────────────────────────────────
  bool notifications = true;
  bool alertSound = false;
  bool autoCalibrate = true;
  String temperatureUnit = 'Celsius (°C)'; // 'Celsius (°C)' | 'Fahrenheit (°F)'

  // ── Device info (static for now, will come from IoT later) ────────────────
  String deviceId = 'SmartPure-Unit-01';
  String firmwareVersion = 'v2.4.0';
  bool deviceOnline = true;

  // ── Auth ──────────────────────────────────────────────────────────────────

  void login({required String name, required String email}) {
    _name = name;
    _email = email;
    _profileImageUrl = null;
    notifyListeners();
  }

  void logout() {
    _name = '';
    _email = '';
    _profileImageUrl = null;
    notifications = true;
    alertSound = false;
    autoCalibrate = true;
    temperatureUnit = 'Celsius (°C)';
    notifyListeners();
  }

  void updateProfile({String? name, String? email}) {
    if (name != null && name.trim().isNotEmpty) _name = name.trim();
    if (email != null && email.trim().isNotEmpty) _email = email.trim();
    notifyListeners();
  }

  void updateProfileImage(String url) {
    _profileImageUrl = url;
    notifyListeners();
  }

  void updatePreferences({
    bool? notifications,
    bool? alertSound,
    bool? autoCalibrate,
    String? temperatureUnit,
  }) {
    if (notifications != null) this.notifications = notifications;
    if (alertSound != null) this.alertSound = alertSound;
    if (autoCalibrate != null) this.autoCalibrate = autoCalibrate;
    if (temperatureUnit != null) this.temperatureUnit = temperatureUnit;
    notifyListeners();
  }
}