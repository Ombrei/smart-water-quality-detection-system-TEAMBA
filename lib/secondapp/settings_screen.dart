import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../auth/login_page.dart';
import '../models/user_session.dart';
import '../secondapp/dashboard_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;


class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Read live from UserSession — never hardcoded
  UserSession get _session => UserSession();

  // ── Profile photo picker ───────────────────────────────────────────────────
  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final source = await _showImageSourceDialog();
    if (source == null) return;

    final picked = await picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 600,
    );
    
    if (picked != null) {
      _showSnack('Uploading image... Please wait.');
      try {
        // Read the image as bytes (Works on Web and Mobile!)
        final bytes = await picked.readAsBytes();
        final base64Image = base64Encode(bytes);

        // ImgBB free API (You can get your own key at api.imgbb.com later)
        const apiKey = 'ff16fb5486819745941f20159217b221'; 
        
        final response = await http.post(
          Uri.parse('https://api.imgbb.com/1/upload'),
          body: {
            'key': apiKey,
            'image': base64Image,
          },
        );

        if (response.statusCode == 200) {
          final jsonData = jsonDecode(response.body);
          final imageUrl = jsonData['data']['url']; // The direct link to the image
          
          _session.updateProfileImage(imageUrl);
          setState(() {});
          _showSnack('Profile photo updated successfully!');
        } else {
          _showSnack('Upload failed. Try again.');
        }
      } catch (e) {
        _showSnack('Network error while uploading.');
      }
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 18),
            const Text('Choose Photo',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _imageSourceBtn(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    onTap: () => Navigator.pop(ctx, ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _imageSourceBtn(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageSourceBtn(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primary.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primary, size: 28),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }

  // ── Edit profile sheet ─────────────────────────────────────────────────────
  void _showEditProfileSheet() {
    final nameCtrl = TextEditingController(text: _session.name);
    final emailCtrl = TextEditingController(text: _session.email);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: AppTheme.divider,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Edit Profile',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 20),
            _sheetField('Full Name', Icons.person_outline_rounded, nameCtrl),
            const SizedBox(height: 14),
            _sheetField('Email Address', Icons.email_outlined, emailCtrl,
                keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
                onPressed: () {
                  _session.updateProfile(
                    name: nameCtrl.text,
                    email: emailCtrl.text,
                  );
                  setState(() {});
                  Navigator.pop(ctx);
                  _showSnack('Profile updated!');
                },
                child: const Text('Save Changes',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sheetField(String hint, IconData icon, TextEditingController ctrl,
      {TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 15, color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: hint,
        prefixIcon: Icon(icon, color: AppTheme.textSecondary, size: 21),
        filled: true,
        fillColor: AppTheme.background,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide:
                const BorderSide(color: AppTheme.primary, width: 1.8)),
      ),
    );
  }

  // ── Temperature unit picker ────────────────────────────────────────────────
  void _showUnitPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 18),
            const Text('Temperature Unit',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 16),
            for (final unit in ['Celsius (°C)', 'Fahrenheit (°F)'])
              ListTile(
                title: Text(unit,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _session.temperatureUnit == unit
                            ? AppTheme.primary
                            : AppTheme.textPrimary)),
                trailing: _session.temperatureUnit == unit
                    ? const Icon(Icons.check_rounded, color: AppTheme.primary)
                    : null,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                onTap: () {
                  _session.updatePreferences(temperatureUnit: unit);
                  setState(() {});
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    );
  }

  // ── Device info sheet ──────────────────────────────────────────────────────
  void _showDeviceInfoSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: AppTheme.divider,
                    borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: AppTheme.statusGood.withOpacity(0.1),
                    shape: BoxShape.circle),
                child: const Icon(Icons.router_rounded,
                    color: AppTheme.statusGood, size: 32),
              ),
              const SizedBox(height: 14),
              Text(_session.deviceId,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                    color: AppTheme.statusGood.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20)),
                child: const Text('Online',
                    style: TextStyle(
                        color: AppTheme.statusGood,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ),
              const SizedBox(height: 24),
              _deviceRow(Icons.memory_rounded, 'Firmware',
                  _session.firmwareVersion),
              _divider(),
              _deviceRow(Icons.wifi_rounded, 'Connection', 'Wi-Fi 2.4GHz'),
              _divider(),
              _deviceRow(
                  Icons.auto_fix_high_rounded,
                  'Auto-Calibration',
                  _session.autoCalibrate ? 'Enabled' : 'Disabled'),
              _divider(),
              // System section note
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppTheme.primary.withOpacity(0.15)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: AppTheme.primary, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Device status and firmware updates will be automatic once IoT sensors are connected.',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                            height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _deviceRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary, size: 20),
          const SizedBox(width: 12),
          Text(label,
              style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  // ── Privacy Policy page ────────────────────────────────────────────────────
  void _showPrivacyPolicy() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const _ContentPage(
        title: 'Privacy Policy',
        icon: Icons.shield_outlined,
        sections: [
          _Section('Introduction',
              'SmartPure Home is committed to protecting your personal information. This Privacy Policy explains how we collect, use, and safeguard your data when you use the SmartPure Home mobile application.'),
          _Section('Information We Collect',
              '• Account Information: Name and email address you provide during registration.\n\n• Device Data: Information from your SmartPure water filter unit including sensor readings (pH, turbidity, temperature, TDS), device ID, and firmware version.\n\n• Usage Data: How you interact with the app, including settings preferences and alert configurations.\n\n• Profile Photo: If you choose to upload a profile picture, it is stored locally on your device.'),
          _Section('How We Use Your Information',
              '• To provide real-time water quality monitoring and alerts.\n\n• To maintain your account and preferences.\n\n• To display historical water quality data and filter status.\n\n• To send push notifications when water quality parameters are outside safe ranges.\n\n• To improve the app based on usage patterns.'),
          _Section('Data Storage',
              'Sensor readings and account data are stored using Firebase (Google Cloud). Your profile photo is stored locally on your device only and is never uploaded to our servers.'),
          _Section('Data Sharing',
              'We do not sell, trade, or share your personal information with third parties, except as required by law or to provide the core functionality of the application (e.g., Firebase for cloud storage).'),
          _Section('Data Security',
              'We implement appropriate technical and organizational measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction.'),
          _Section('Your Rights',
              'You have the right to access, correct, or delete your personal information at any time through the Settings screen. You may also withdraw consent by deleting your account.'),
          _Section('Contact Us',
              'If you have any questions about this Privacy Policy, please contact the TEAMBA development team at teamba@tip.edu.ph.'),
          _Section('Last Updated', 'April 2026'),
        ],
      )),
    );
  }

  // ── Help & Support page ────────────────────────────────────────────────────
  void _showHelpAndSupport() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const _ContentPage(
        title: 'Help & Support',
        icon: Icons.help_outline_rounded,
        sections: [
          _Section('Getting Started',
              'Welcome to SmartPure Home! To begin monitoring your water quality:\n\n1. Connect your SmartPure IoT device to your home Wi-Fi network.\n2. Log in or create an account in the app.\n3. The dashboard will automatically display live sensor readings once the device is paired.'),
          _Section('Dashboard',
              'The main dashboard shows your real-time water quality score and four key sensor readings:\n\n• Turbidity – Water clarity (safe: < 1 NTU)\n• pH Level – Acidity/alkalinity (safe: 6.5–8.5 pH)\n• TDS – Total dissolved solids (safe: < 300 ppm)\n• Temperature – Water temperature (safe: 10–25 °C)\n\nTap any sensor card to manually enter a test value while sensors are not yet connected.'),
          _Section('Alerts',
              'The app automatically shows a warning banner when any reading goes outside the safe range. You will also receive a push notification if notifications are enabled in Settings.\n\n• Yellow banner = approaching unsafe levels\n• Red banner = unsafe, immediate attention needed'),
          _Section('Filter Management',
              'The Filter Management screen shows the estimated remaining life of each filter cartridge. Tap "Simulate Water Usage" to test how the indicator responds. Tap "Order Replacements" when a filter is running low.'),
          _Section('Water Quality Charts',
              'Tap the Quality tab in the bottom navigation to see detailed trend charts for each sensor. Toggle the switch to view historical data from the last 24 hours versus live readings.'),
          _Section('Profile & Settings',
              '• Tap the edit icon on your profile card to update your name and email.\n• Tap your profile photo to upload a new one from your camera or gallery.\n• Toggle notifications, alert sounds, and auto-calibration in Preferences.\n• Change the temperature unit between Celsius and Fahrenheit.'),
          _Section('Frequently Asked Questions',
              'Q: Why is my sensor showing "--"?\nA: The IoT device may not be connected yet. Check your Wi-Fi and device power.\n\nQ: Can I use the app without the physical device?\nA: Yes! You can manually enter sensor readings by tapping any card on the dashboard to test the app.\n\nQ: How often does the data update?\nA: Once IoT sensors are connected, readings update in real time via Firebase.\n\nQ: What do I do if my water quality is red?\nA: Stop consuming the water immediately and check your filter status. Replace filters if they are below 20%.'),
          _Section('Contact Support',
              'For technical assistance, reach out to the TEAMBA development team:\n\n📧 teamba@tip.edu.ph\n🏫 Technological Institute of the Philippines – Quezon City'),
        ],
      )),
    );
  }

  // ── Logout ─────────────────────────────────────────────────────────────────
  void _showLogoutDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: AppTheme.statusDanger.withOpacity(0.1),
                  shape: BoxShape.circle),
              child: const Icon(Icons.logout_rounded,
                  color: AppTheme.statusDanger, size: 30),
            ),
            const SizedBox(height: 14),
            const Text('Sign Out?',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            const Text(
              'Are you sure you want to sign out of SmartPure Home?',
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.divider),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Cancel',
                        style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _session.logout(); // clears all user data
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const LoginPage()),
                        (_) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.statusDanger,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Sign Out',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppTheme.statusGood,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white),
          onPressed: () {
              if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      // If there's no history, push them back to the Dashboard instead
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (context) => const DashboardScreen())
      );
    }
  },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileCard(),
            const SizedBox(height: 24),

            // ── PREFERENCES ─────────────────────────────────────────────────
            _sectionLabel('PREFERENCES'),
            const SizedBox(height: 10),
            _buildCard(children: [
              _toggleTile(
                icon: Icons.notifications_outlined,
                title: 'Push Notifications',
                subtitle: 'Get alerts when water quality changes',
                value: _session.notifications,
                onChanged: (v) {
                  _session.updatePreferences(notifications: v);
                  setState(() {});
                  _showSnack(
                      v ? 'Notifications enabled' : 'Notifications disabled');
                },
              ),
              _divider(),
              _toggleTile(
                icon: Icons.volume_up_outlined,
                title: 'Alert Sound',
                subtitle: 'Play sound for critical alerts',
                value: _session.alertSound,
                onChanged: (v) {
                  _session.updatePreferences(alertSound: v);
                  setState(() {});
                  _showSnack(v ? 'Alert sound on' : 'Alert sound off');
                },
              ),
              _divider(),
              _tapTile(
                icon: Icons.thermostat_rounded,
                title: 'Temperature Unit',
                trailing: Text(_session.temperatureUnit,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13)),
                onTap: _showUnitPicker,
              ),
            ]),

            const SizedBox(height: 20),

            // ── SYSTEM ──────────────────────────────────────────────────────
            _sectionLabel('SYSTEM'),
            const SizedBox(height: 10),
            _buildCard(children: [
              _toggleTile(
                icon: Icons.auto_fix_high_rounded,
                title: 'Auto-Calibration',
                subtitle: 'Automatically calibrate sensors daily',
                value: _session.autoCalibrate,
                onChanged: (v) {
                  _session.updatePreferences(autoCalibrate: v);
                  setState(() {});
                  _showSnack(v
                      ? 'Auto-calibration enabled'
                      : 'Auto-calibration disabled');
                },
              ),
              _divider(),
              // Device tile — tapping opens the device info sheet
              _tapTile(
                icon: Icons.router_rounded,
                iconColor: _session.deviceOnline
                    ? AppTheme.statusGood
                    : AppTheme.statusDanger,
                title: _session.deviceId,
                subtitle: 'Firmware ${_session.firmwareVersion}',
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: (_session.deviceOnline
                              ? AppTheme.statusGood
                              : AppTheme.statusDanger)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(
                      _session.deviceOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                          color: _session.deviceOnline
                              ? AppTheme.statusGood
                              : AppTheme.statusDanger,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
                onTap: _showDeviceInfoSheet,
              ),
            ]),

            const SizedBox(height: 20),

            // ── ABOUT ────────────────────────────────────────────────────────
            _sectionLabel('ABOUT'),
            const SizedBox(height: 10),
            _buildCard(children: [
              _tapTile(
                icon: Icons.info_outline_rounded,
                title: 'App Version',
                trailing: const Text('1.0.2',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13)),
                onTap: () => _showSnack('SmartPure Home v1.0.2 • TEAMBA'),
              ),
              _divider(),
              _tapTile(
                icon: Icons.shield_outlined,
                title: 'Privacy Policy',
                trailing: const Icon(Icons.chevron_right_rounded,
                    color: AppTheme.textSecondary),
                onTap: _showPrivacyPolicy,
              ),
              _divider(),
              _tapTile(
                icon: Icons.help_outline_rounded,
                title: 'Help & Support',
                trailing: const Icon(Icons.chevron_right_rounded,
                    color: AppTheme.textSecondary),
                onTap: _showHelpAndSupport,
              ),
            ]),

            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _showLogoutDialog,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                      color: AppTheme.statusDanger.withOpacity(0.4)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  foregroundColor: AppTheme.statusDanger,
                ),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Sign Out',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text('SmartPure Home v1.0.2 • TEAMBA',
                  style: TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── Profile card ───────────────────────────────────────────────────────────
  Widget _buildProfileCard() {
    

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [AppTheme.primary, AppTheme.primaryLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: AppTheme.primary.withOpacity(0.25),
              blurRadius: 16,
              offset: const Offset(0, 6))
        ],
      ),
      child: Row(
        children: [
          // Profile photo (tappable to change)
          GestureDetector(
            onTap: _pickProfileImage,
            child: Stack(
              children: [
                Container(
                  width: 62, height: 62,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withOpacity(0.4), width: 2),
                  ),
                  child: ClipOval(
                    child: _session.profileImageUrl != null
                        ? Image.network(_session.profileImageUrl!, fit: BoxFit.cover)
                        : Center(
                            child: Text(
                              _session.initials,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800),
                            ),
                          ),
                  ),
                ),
                // Camera badge
                Positioned(
                  right: 0, bottom: 0,
                  child: Container(
                    width: 20, height: 20,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppTheme.primary.withOpacity(0.3),
                          width: 1),
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        size: 11, color: AppTheme.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name — live from session
                Text(_session.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                // Email — live from session
                Text(_session.email,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          // Edit button
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle),
              child: const Icon(Icons.edit_rounded,
                  color: Colors.white, size: 16),
            ),
            onPressed: _showEditProfileSheet,
          ),
        ],
      ),
    );
  }

  // ── Shared helpers ─────────────────────────────────────────────────────────

  Widget _sectionLabel(String label) => Text(label,
      style: const TextStyle(
          fontSize: 11,
          color: AppTheme.textSecondary,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2));

  Widget _buildCard({required List<Widget> children}) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 3))
          ],
        ),
        child: Column(children: children),
      );

  Widget _toggleTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) =>
      SwitchListTile(
        secondary: Icon(icon, color: AppTheme.primary, size: 22),
        title: Text(title,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary)),
        subtitle: subtitle != null
            ? Text(subtitle,
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary))
            : null,
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primary,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      );

  Widget _tapTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? iconColor,
  }) =>
      ListTile(
        leading: Icon(icon, color: iconColor ?? AppTheme.primary, size: 22),
        title: Text(title,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary)),
        subtitle: subtitle != null
            ? Text(subtitle,
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary))
            : null,
        trailing: trailing,
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      );

  Widget _divider() =>
      const Divider(height: 1, indent: 54, color: AppTheme.divider);
}

// ── Content page (Privacy Policy & Help & Support) ────────────────────────────

class _Section {
  final String title;
  final String body;
  const _Section(this.title, this.body);
}

class _ContentPage extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<_Section> sections;

  const _ContentPage({
    required this.title,
    required this.icon,
    required this.sections,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header icon
          Center(
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.primary, size: 36),
            ),
          ),
          // Sections
          ...sections.map((s) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.title,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary)),
                    const SizedBox(height: 8),
                    Text(s.body,
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                            height: 1.6)),
                  ],
                ),
              )),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}