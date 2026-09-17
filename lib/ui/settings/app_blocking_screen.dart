import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/native_service.dart';
import '../../core/theme/rose_pine_theme.dart';
import '../../data/models/models.dart';
import '../../providers.dart';
import '../common/responsive_wrapper.dart';

class AppBlockingScreen extends ConsumerStatefulWidget {
  const AppBlockingScreen({super.key});

  @override
  ConsumerState<AppBlockingScreen> createState() => _AppBlockingScreenState();
}

class _AppBlockingScreenState extends ConsumerState<AppBlockingScreen> with WidgetsBindingObserver {
  final List<String> _popularApps = [
    'Instagram',
    'YouTube',
    'Snapchat',
    'Reddit',
    'Netflix',
    'WhatsApp',
    'Discord',
    'Twitter / X',
    'Telegram',
    'TikTok',
    'Mobile Games',
  ];

  bool _hasUsagePermission = false;
  bool _hasOverlayPermission = false;
  bool _isScanning = false;
  bool _isLoadingApps = false;
  List<Map<String, String>> _installedApps = [];
  Map<String, dynamic>? _lastScanResult;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermission();
    }
  }

  Future<void> _checkPermission() async {
    final usageGranted = await NativeService.checkUsageStatsPermission();
    final overlayGranted = await NativeService.checkOverlayPermission();
    if (mounted) {
      setState(() {
        _hasUsagePermission = usageGranted;
        _hasOverlayPermission = overlayGranted;
      });
    }
  }

  Future<void> _scanUsageNow(List<String> blockedApps, int threshold) async {
    setState(() {
      _isScanning = true;
    });

    final result = await NativeService.checkDistractionUsage(
      appNames: blockedApps,
      thresholdMinutes: threshold,
    );

    if (mounted) {
      setState(() {
        _isScanning = false;
        _lastScanResult = result;
      });

      final totalMins = (result['totalMinutes'] as num?)?.toInt() ?? 0;
      final app = (result['mostUsedApp'] as String?) ?? '';
      final exceeded = result['exceededThreshold'] == true;

      if (exceeded) {
        await NativeService.showNotification(
          title: '⚠️ Focus Shield Alert',
          body: 'You have spent $totalMins min on $app. Return to your SPPU Engineering study block!',
          channelId: 'focuspath_distraction_alerts',
        );
      }
    }
  }

  Future<void> _showInstalledAppsPicker(BuildContext context, UserProfile profile) async {
    List<Map<String, String>> apps = _installedApps;
    if (apps.isEmpty) {
      setState(() => _isLoadingApps = true);
      apps = await NativeService.getInstalledApps();
      if (mounted) {
        setState(() {
          _installedApps = apps;
          _isLoadingApps = false;
        });
      }
    }

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        String query = '';
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final filtered = apps.where((app) {
              final name = (app['name'] ?? '').toLowerCase();
              final pkg = (app['packageName'] ?? '').toLowerCase();
              return name.contains(query.toLowerCase()) || pkg.contains(query.toLowerCase());
            }).toList();

            final currentBlocked = ref.watch(userProfileNotifierProvider).blockedApps;

            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (_, scrollController) => Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Installed Apps on Device',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    Text(
                      'Select any installed app to monitor or restrict during study blocks.',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search installed apps...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      onChanged: (val) {
                        setModalState(() => query = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(child: Text('No matching apps found.'))
                          : ListView.builder(
                              controller: scrollController,
                              itemCount: filtered.length,
                              itemBuilder: (_, index) {
                                final app = filtered[index];
                                final name = app['name'] ?? '';
                                final pkg = app['packageName'] ?? '';
                                final isSelected = currentBlocked.contains(name) || currentBlocked.contains(pkg);

                                return CheckboxListTile(
                                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                  subtitle: Text(pkg, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                  value: isSelected,
                                  onChanged: (checked) {
                                    final current = List<String>.from(ref.read(userProfileNotifierProvider).blockedApps);
                                    if (checked == true) {
                                      if (!current.contains(name)) current.add(name);
                                    } else {
                                      current.remove(name);
                                      current.remove(pkg);
                                    }
                                    ref.read(userProfileNotifierProvider.notifier).updateProfile(
                                      profile.copyWith(blockedApps: current),
                                    );
                                    setModalState(() {});
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = ref.watch(userProfileNotifierProvider);
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textPrimary = isDark ? RosePineColors.darkText : RosePineColors.dawnText;
    final textSubtle = isDark ? RosePineColors.darkSubtle : RosePineColors.dawnSubtle;
    final goldAccent = isDark ? RosePineColors.darkGold : RosePineColors.dawnGold;
    final loveAccent = isDark ? RosePineColors.darkLove : RosePineColors.dawnLove;
    final pineAccent = isDark ? RosePineColors.darkPine : RosePineColors.dawnPine;

    final tiers = [
      {'title': 'Off', 'desc': 'No distraction detection or blocking active.'},
      {'title': 'Nudge Only', 'desc': 'Tier 1: Sends real heads-up notification when continuous usage exceeds limit.'},
      {'title': 'Full-screen Overlay', 'desc': 'Tier 2: System notification + focus mode lock screen reminder.'},
      {'title': 'Strict Mode', 'desc': 'Tier 3: Aggressive alarms and study reminders until timer ends.'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('App Blocking & Shield'),
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // Hero Banner
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      goldAccent.withValues(alpha: isDark ? 0.25 : 0.18),
                      primaryColor.withValues(alpha: isDark ? 0.2 : 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: goldAccent.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: goldAccent.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.shield_rounded, color: goldAccent, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Distraction-Free Study Zone',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Native Android UsageStats shield keeps distracting social apps at bay during your SPPU revision.',
                            style: TextStyle(fontSize: 12, color: textSubtle, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Real Android Permission Status Card: Usage Access
              Card(
                elevation: 0,
                color: _hasUsagePermission
                    ? pineAccent.withValues(alpha: isDark ? 0.15 : 0.1)
                    : loveAccent.withValues(alpha: isDark ? 0.15 : 0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(
                    color: _hasUsagePermission
                        ? pineAccent.withValues(alpha: 0.4)
                        : loveAccent.withValues(alpha: 0.4),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _hasUsagePermission ? Icons.check_circle_rounded : Icons.lock_clock_outlined,
                            color: _hasUsagePermission ? pineAccent : loveAccent,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _hasUsagePermission
                                  ? 'Android Usage Access: Granted'
                                  : 'Android Usage Access: Required',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: _hasUsagePermission ? pineAccent : loveAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _hasUsagePermission
                            ? 'Gradient can natively monitor distracting app screen-time and trigger real alert nudges during your Pomodoro.'
                            : 'To detect Instagram, YouTube, or TikTok usage in the background, Android requires granting Usage Access permission.',
                        style: TextStyle(fontSize: 12, color: textSubtle, height: 1.3),
                      ),
                      if (!_hasUsagePermission) ...[
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => NativeService.openUsageAccessSettings(),
                          icon: const Icon(Icons.settings_outlined, size: 16),
                          label: const Text('Open Android Usage Settings', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: loveAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Real Android Overlay Permission Card
              Card(
                elevation: 0,
                color: _hasOverlayPermission
                    ? pineAccent.withValues(alpha: isDark ? 0.15 : 0.1)
                    : goldAccent.withValues(alpha: isDark ? 0.15 : 0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(
                    color: _hasOverlayPermission
                        ? pineAccent.withValues(alpha: 0.4)
                        : goldAccent.withValues(alpha: 0.4),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _hasOverlayPermission ? Icons.layers_rounded : Icons.layers_outlined,
                            color: _hasOverlayPermission ? pineAccent : goldAccent,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _hasOverlayPermission
                                  ? 'Display Over Other Apps: Granted'
                                  : 'Display Over Other Apps: Recommended',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: _hasOverlayPermission ? pineAccent : goldAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _hasOverlayPermission
                            ? 'Gradient can display full-screen focus lock overlays if you open distracting apps during study blocks (Tier 2/3).'
                            : 'To enforce full-screen lock screen blockers when distraction apps open, grant Display Over Other Apps permission.',
                        style: TextStyle(fontSize: 12, color: textSubtle, height: 1.3),
                      ),
                      if (!_hasOverlayPermission) ...[
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => NativeService.openOverlaySettings(),
                          icon: const Icon(Icons.open_in_new_rounded, size: 16),
                          label: const Text('Open Overlay Permission Settings', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: goldAccent,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'ENFORCEMENT TIER',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: primaryColor),
              ),
              const SizedBox(height: 10),

              // 4 Tier Radios
              ...tiers.map((t) {
                final isSelected = profile.appBlockingTier == t['title'];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () {
                      ref.read(userProfileNotifierProvider.notifier).updateProfile(
                            profile.copyWith(appBlockingTier: t['title']!),
                          );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? primaryColor : textSubtle.withValues(alpha: 0.5),
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? Center(
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: primaryColor,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t['title']!,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isSelected ? primaryColor : textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  t['desc']!,
                                  style: TextStyle(fontSize: 12, color: textSubtle),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 24),

              Text(
                'DISTRACTION THRESHOLD',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: primaryColor),
              ),
              const SizedBox(height: 10),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Nudge after continuous use:', style: TextStyle(fontSize: 13, color: textSubtle)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${profile.distractionThresholdMinutes} minutes',
                              style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [5, 10, 15, 20, 30].map((mins) {
                          final isSel = profile.distractionThresholdMinutes == mins;
                          return ChoiceChip(
                            label: Text('$mins min'),
                            selected: isSel,
                            selectedColor: primaryColor.withValues(alpha: 0.25),
                            onSelected: (_) {
                              ref.read(userProfileNotifierProvider.notifier).updateProfile(
                                    profile.copyWith(distractionThresholdMinutes: mins),
                                  );
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Live Usage Scan Card
              if (_hasUsagePermission) ...[
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.analytics_outlined, color: primaryColor, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Live Distraction Scan',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary),
                            ),
                            const Spacer(),
                            if (_isScanning)
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            else
                              TextButton.icon(
                                onPressed: () => _scanUsageNow(
                                  profile.blockedApps,
                                  profile.distractionThresholdMinutes,
                                ),
                                icon: const Icon(Icons.refresh_rounded, size: 16),
                                label: const Text('Scan Now', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                        if (_lastScanResult != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: (_lastScanResult!['exceededThreshold'] == true ? loveAccent : pineAccent)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _lastScanResult!['exceededThreshold'] == true
                                      ? Icons.warning_amber_rounded
                                      : Icons.verified_user_outlined,
                                  color: _lastScanResult!['exceededThreshold'] == true ? loveAccent : pineAccent,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _lastScanResult!['exceededThreshold'] == true
                                        ? '⚠️ High Distraction: ${_lastScanResult!['totalMinutes']} min on ${_lastScanResult!['mostUsedApp']}! Heads-up alert fired.'
                                        : '✨ All clear: Only ${_lastScanResult!['totalMinutes']} min spent on monitored apps in the last 3 hours.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _lastScanResult!['exceededThreshold'] == true ? loveAccent : pineAccent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 4),
                          Text(
                            'Tap "Scan Now" to query Android UsageStats for tracked apps in the last 3 hours.',
                            style: TextStyle(fontSize: 12, color: textSubtle),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'MONITORED APPS (${profile.blockedApps.length})',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: primaryColor),
                  ),
                  TextButton.icon(
                    onPressed: () => _showInstalledAppsPicker(context, profile),
                    icon: _isLoadingApps
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.add_to_home_screen_rounded, size: 16),
                    label: const Text('Add Installed App', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Gradient monitors these apps and triggers real system alerts when threshold is exceeded:',
                style: TextStyle(fontSize: 12, color: textSubtle),
              ),
              const SizedBox(height: 12),

              // Currently Monitored Apps Card
              Card(
                child: profile.blockedApps.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.check_circle_outline_rounded, size: 36, color: pineAccent),
                              const SizedBox(height: 8),
                              Text('No apps blocked', style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary)),
                              const SizedBox(height: 4),
                              Text('Tap "Add Installed App" or select quick presets below.', style: TextStyle(fontSize: 12, color: textSubtle)),
                            ],
                          ),
                        ),
                      )
                    : Column(
                        children: profile.blockedApps.map((appName) {
                          return ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: loveAccent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.block_rounded, color: loveAccent, size: 18),
                            ),
                            title: Text(appName, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
                            subtitle: Text('Monitored during focus blocks', style: TextStyle(fontSize: 11, color: textSubtle)),
                            trailing: IconButton(
                              icon: Icon(Icons.remove_circle_outline_rounded, color: loveAccent, size: 20),
                              tooltip: 'Remove from monitored list',
                              onPressed: () {
                                final current = List<String>.from(profile.blockedApps)..remove(appName);
                                ref.read(userProfileNotifierProvider.notifier).updateProfile(
                                      profile.copyWith(blockedApps: current),
                                    );
                              },
                            ),
                          );
                        }).toList(),
                      ),
              ),

              const SizedBox(height: 16),

              Text(
                'QUICK PRESET SHORTCUTS',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: textSubtle),
              ),
              const SizedBox(height: 8),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _popularApps.map((appName) {
                  final isBlocked = profile.blockedApps.contains(appName);
                  return FilterChip(
                    avatar: Icon(
                      isBlocked ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                      size: 16,
                      color: isBlocked ? loveAccent : textSubtle,
                    ),
                    label: Text(appName),
                    selected: isBlocked,
                    selectedColor: loveAccent.withValues(alpha: 0.2),
                    checkmarkColor: loveAccent,
                    onSelected: (selected) {
                      final current = List<String>.from(profile.blockedApps);
                      if (selected) {
                        if (!current.contains(appName)) current.add(appName);
                      } else {
                        current.remove(appName);
                      }
                      ref.read(userProfileNotifierProvider.notifier).updateProfile(
                            profile.copyWith(blockedApps: current),
                          );
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Real Test Nudge Action Button
              ElevatedButton.icon(
                icon: const Icon(Icons.notifications_active_outlined),
                label: const Text('Send Test System Distraction Notification', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: goldAccent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () async {
                  final appTarget = profile.blockedApps.isNotEmpty ? profile.blockedApps.first : "Instagram";
                  final success = await NativeService.showNotification(
                    id: 2002,
                    title: '⚠️ Focus Shield Alert',
                    body: 'You\'ve spent ${profile.distractionThresholdMinutes} min on $appTarget — your SPPU study session is waiting! 📖',
                    channelId: 'focuspath_distraction_alerts',
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: success ? pineAccent : loveAccent,
                        content: Row(
                          children: [
                            Icon(success ? Icons.notifications_active : Icons.error_outline, color: Colors.white),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                success
                                    ? '🔔 Real Android heads-up notification sent with sound & vibration!'
                                    : '⚠️ Could not trigger system notification. Check Android notification permissions.',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                },
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
