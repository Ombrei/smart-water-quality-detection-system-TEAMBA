import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'water_quality_screen.dart';
import 'filter_management_screen.dart';
import 'settings_screen.dart';

// ─── Data Model ──────────────────────────────────────────────────────────────

class SensorReading {
  final String label;
  final String unit;
  final IconData icon;
  final Color color;

  double value;

  // Thresholds to auto-compute status
  final double goodMin;
  final double goodMax;
  final double warnMin;
  final double warnMax;

  SensorReading({
    required this.label,
    required this.unit,
    required this.icon,
    required this.color,
    required this.value,
    required this.goodMin,
    required this.goodMax,
    required this.warnMin,
    required this.warnMax,
  });

  // Auto-derived from value vs thresholds
  SensorStatus get status {
    if (value >= goodMin && value <= goodMax) return SensorStatus.good;
    if (value >= warnMin && value <= warnMax) return SensorStatus.warning;
    return SensorStatus.danger;
  }

  String get statusLabel {
    switch (label) {
      case 'Turbidity':
        if (status == SensorStatus.good) return 'Excellent';
        if (status == SensorStatus.warning) return 'Moderate';
        return 'High';
      case 'pH Level':
        if (status == SensorStatus.good) return 'Optimal';
        if (status == SensorStatus.warning) return 'Off Range';
        return 'Unsafe';
      case 'TDS':
        if (status == SensorStatus.good) return 'Good';
        if (status == SensorStatus.warning) return 'Moderate';
        return 'High';
      case 'Temperature':
        if (status == SensorStatus.good) return 'Stable';
        if (status == SensorStatus.warning) return 'Warm';
        return 'Hot';
      default:
        return status.name;
    }
  }

  String get displayValue =>
      value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(1);

  String get safeRange => '${goodMin}–${goodMax} $unit';
}

enum SensorStatus { good, warning, danger }

// ─── Dashboard Screen ─────────────────────────────────────────────────────────

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  DateTime _lastUpdated = DateTime.now();

  late AnimationController _gaugeController;
  late Animation<double> _gaugeAnim;

  // ── Sensor data — swap these values when IoT sends real readings ───────────
  late List<SensorReading> _sensors;

  @override
  void initState() {
    super.initState();

    _sensors = [
      SensorReading(
        label: 'Turbidity', unit: 'NTU', icon: Icons.water_drop_rounded,
        color: const Color(0xFF1A6B8A), value: 0.5,
        goodMin: 0, goodMax: 1.0, warnMin: 0, warnMax: 4.0,
      ),
      SensorReading(
        label: 'TDS', unit: 'ppm', icon: Icons.bar_chart_rounded,
        color: const Color(0xFF3F8DA8), value: 120,
        goodMin: 0, goodMax: 300, warnMin: 0, warnMax: 500,
      ),
      SensorReading(
        label: 'Temperature', unit: '°C', icon: Icons.thermostat_rounded,
        color: const Color(0xFFFFB300), value: 18,
        goodMin: 10, goodMax: 25, warnMin: 5, warnMax: 35,
      ),
    ];

    _gaugeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));
    _refreshGauge(animate: true);
  }

  @override
  void dispose() {
    _gaugeController.dispose();
    super.dispose();
  }

  // ── Computed overall health score (0.0–1.0) ─────────────────────────────
  double get _healthScore {
    if (_sensors.isEmpty) return 0.0; 

    int good = _sensors.where((s) => s.status == SensorStatus.good).length;
    int warn = _sensors.where((s) => s.status == SensorStatus.warning).length;
    return (good * 1.0 + warn * 0.5) / _sensors.length;
  }

  Color get _healthColor {
    if (_healthScore >= 0.75) return AppTheme.statusGood;
    if (_healthScore >= 0.5) return AppTheme.statusWarn;
    return AppTheme.statusDanger;
  }

  String get _healthLabel {
    if (_healthScore >= 0.75) return 'All Good';
    if (_healthScore >= 0.5) return 'Needs Attention';
    return 'Check Required';
  }

  // ── Active alerts derived from real sensor values ────────────────────────
  List<_Alert> get _activeAlerts {
    final List<_Alert> alerts = [];
    for (final s in _sensors) {
      if (s.status == SensorStatus.danger) {
        alerts.add(_Alert(
          message: '${s.label} is out of safe range (${s.displayValue} ${s.unit})',
          level: AlertLevel.danger,
        ));
      } else if (s.status == SensorStatus.warning) {
        alerts.add(_Alert(
          message: '${s.label} is approaching unsafe levels (${s.displayValue} ${s.unit})',
          level: AlertLevel.warning,
        ));
      }
    }
    return alerts;
  }

  void _refreshGauge({bool animate = false}) {
    final target = _healthScore;
    _gaugeAnim = Tween<double>(
      begin: animate ? 0 : target,
      end: target,
    ).animate(CurvedAnimation(parent: _gaugeController, curve: Curves.easeOutCubic));
    if (animate) {
      _gaugeController.forward(from: 0);
    } else {
      _gaugeController.value = 1;
    }
  }

  // ── Manual update dialog (simulates IoT reading update) ──────────────────
  void _showManualUpdateDialog(SensorReading sensor) {
    final controller = TextEditingController(text: sensor.displayValue);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 24, right: 24, top: 24,
        ),
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: sensor.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(sensor.icon, color: sensor.color, size: 22),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Update ${sensor.label}',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary)),
                    Text('Safe range: ${sensor.safeRange}',
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary)),
                            
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary),
              decoration: InputDecoration(
                labelText: '${sensor.label} value',
                suffixText: sensor.unit,
                suffixStyle: const TextStyle(
                    color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
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
            ),
            const SizedBox(height: 10),
            // Threshold hint chips
            Row(
              children: [
                _thresholdChip(
                    'Good', '${sensor.goodMin}–${sensor.goodMax}', AppTheme.statusGood),
                const SizedBox(width: 8),
                _thresholdChip(
                    'Warn', '${sensor.warnMin}–${sensor.warnMax}', AppTheme.statusWarn),
                const SizedBox(width: 8),
                _thresholdChip('Danger', 'outside range', AppTheme.statusDanger),
              ],
            ),
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
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  final newVal = double.tryParse(controller.text);
                  if (newVal != null) {
                    setState(() {
                      sensor.value = newVal;
                      _lastUpdated = DateTime.now();
                      _refreshGauge();
                    });
                  }
                  Navigator.pop(ctx);
                },
                child: const Text('Update Reading',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      ).whenComplete(() => controller.dispose());
  }

  Widget _thresholdChip(String label, String range, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8)),
        child: Column(
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w700, color: color)),
            Text(range,
                style: TextStyle(fontSize: 9, color: color.withOpacity(0.8))),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────
  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning 🌤';
    if (hour < 17) return 'Good afternoon ☀️';
    if (hour < 21) return 'Good evening 🌙';
    return 'Good night 🌙';
  }

  String get _lastUpdatedText {
    final diff = DateTime.now().difference(_lastUpdated);
    if (diff.inSeconds < 60) return 'Updated just now';
    if (diff.inMinutes < 60) return 'Updated ${diff.inMinutes}m ago';
    return 'Updated ${diff.inHours}h ago';
  }

  void _onNavTap(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    Widget? page;
    if (index == 1) page = const WaterQualityScreen();
    if (index == 2) page = const FilterManagementScreen();
    if (index == 3) page = const SettingsScreen();
    if (page != null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => page!))
          .then((_) => setState(() => _currentIndex = 0));
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final alerts = _activeAlerts;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(child: _buildHeader()),

          // Alert banners
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: alerts.isEmpty
                  ? _buildAllGoodBanner()
                  : Column(
                      children: alerts
                          .map((a) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _buildAlertBanner(a),
                              ))
                          .toList(),
                    ),
            ),
          ),

          // Section title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Live Readings',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary)),
                  Text(_lastUpdatedText,
                      style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary.withOpacity(0.7))),
                ],
              ),
            ),
          ),

          // Sensor grid — scrolls with the rest of the page
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.45,
              ),
              delegate: SliverChildBuilderDelegate(
                (_, i) => _buildSensorCard(_sensors[i]),
                childCount: _sensors.length,
              ),
            ),
          ),

          // Tap hint
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.touch_app_rounded,
                        size: 13,
                        color: AppTheme.textSecondary.withOpacity(0.4)),
                    const SizedBox(width: 5),
                    Text('Tap a card to update reading manually',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary.withOpacity(0.4))),
                  ],
                ),
              ),
            ),
          ),

          // Device footer
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7, height: 7,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: AppTheme.statusGood),
                    ),
                    const SizedBox(width: 6),
                    Text('SmartPure-Unit-01 • Online',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary.withOpacity(0.55))),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 56, bottom: 28, left: 20, right: 20),
      decoration: const BoxDecoration(
        gradient: AppTheme.headerGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: Stack(
        children: [
          Positioned(top: -20, right: -10, child: _bubble(130, 0.06)),
          Positioned(bottom: -10, left: -10, child: _bubble(85, 0.05)),
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_greeting,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.75),
                              fontSize: 14)),
                      const SizedBox(height: 2),
                      const Text('SmartPure Home',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: const Icon(Icons.notifications_outlined,
                        color: Colors.white, size: 22),
                  ),
                ],
              ),
              const SizedBox(height: 26),

              // Gauge + side stats
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                  animation: _gaugeAnim,
                  builder: (_, __) => SizedBox(
                    width: 125,
                    height: 125,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // 1. ADD SIZEDBOX.EXPAND RIGHT HERE 👇
                        SizedBox.expand(
                          child: CircularProgressIndicator(
                            value: _gaugeAnim.value,
                            strokeWidth: 10,
                            strokeCap: StrokeCap.round,
                            backgroundColor: Colors.white.withOpacity(0.12),
                            valueColor: AlwaysStoppedAnimation(_healthColor),
                          ),
                        ),
                        
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${(_gaugeAnim.value * 100).toInt()}%',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800),
                            ),
                            Text(
                              _healthLabel,
                              style: TextStyle(
                                  color: _healthColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                  const SizedBox(width: 28),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _statChip(
                        Icons.water_drop_rounded,
                        'Sensors',
                        '${_sensors.where((s) => s.status == SensorStatus.good).length}/${_sensors.length} OK',
                        AppTheme.accent,
                      ),
                      const SizedBox(height: 14),
                      _statChip(
                        Icons.warning_amber_rounded,
                        'Alerts',
                        _activeAlerts.isEmpty
                            ? 'None'
                            : '${_activeAlerts.length} active',
                        _activeAlerts.isEmpty
                            ? AppTheme.accent
                            : AppTheme.statusWarn,
                      ),
                      const SizedBox(height: 14),
                      _statChip(
                          Icons.wifi_rounded, 'Device', 'Online', AppTheme.accent),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 15),
        const SizedBox(width: 7),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.55), fontSize: 10)),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }

  // ─── Alert widgets ────────────────────────────────────────────────────────

  Widget _buildAlertBanner(_Alert alert) {
    final isDanger = alert.level == AlertLevel.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDanger
            ? const Color(0xFFFFEBEE)
            : const Color(0xFFFFF8E7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isDanger
                ? const Color(0xFFFFCDD2)
                : const Color(0xFFFFE082)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: (isDanger ? AppTheme.statusDanger : AppTheme.statusWarn)
                    .withOpacity(0.12),
                shape: BoxShape.circle),
            child: Icon(
              isDanger
                  ? Icons.error_outline_rounded
                  : Icons.warning_amber_rounded,
              color: isDanger ? AppTheme.statusDanger : AppTheme.statusWarn,
              size: 17,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(alert.message,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDanger
                        ? const Color(0xFF7B1B1B)
                        : const Color(0xFF7A5800))),
          ),
        ],
      ),
    );
  }

  Widget _buildAllGoodBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.statusGood.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.statusGood.withOpacity(0.25)),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle_rounded,
              color: AppTheme.statusGood, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'All parameters within safe ranges. Water quality is good.',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1B5E20)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Sensor card (tappable) ───────────────────────────────────────────────

  Widget _buildSensorCard(SensorReading s) {
    final statusColor = s.status == SensorStatus.good
        ? AppTheme.statusGood
        : s.status == SensorStatus.warning
            ? AppTheme.statusWarn
            : AppTheme.statusDanger;

    return GestureDetector(
      onTap: () => _showManualUpdateDialog(s),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: s.color.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
          border: s.status != SensorStatus.good
              ? Border.all(color: statusColor.withOpacity(0.35), width: 1.2)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: s.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10)),
                  child: Icon(s.icon, color: s.color, size: 17),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(s.statusLabel,
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: statusColor)),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.label,
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                RichText(
                  text: TextSpan(children: [
                    TextSpan(
                        text: s.displayValue,
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary)),
                    TextSpan(
                        text: ' ${s.unit}',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textSecondary.withOpacity(0.7))),
                  ]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Bottom nav ───────────────────────────────────────────────────────────

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, -4))
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: AppTheme.textSecondary.withOpacity(0.5),
        showUnselectedLabels: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
        onTap: _onNavTap,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.water_drop_rounded), label: 'Quality'),
          BottomNavigationBarItem(
              icon: Icon(Icons.filter_alt_rounded), label: 'Filters'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings_rounded), label: 'Settings'),
        ],
      ),
    );
  }

  Widget _bubble(double size, double opacity) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(opacity)),
      );
}

// ─── Alert model ──────────────────────────────────────────────────────────────

enum AlertLevel { warning, danger }

class _Alert {
  final String message;
  final AlertLevel level;
  const _Alert({required this.message, required this.level});
}