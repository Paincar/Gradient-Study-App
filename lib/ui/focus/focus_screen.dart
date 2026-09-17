import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/native_service.dart';
import '../../core/theme/rose_pine_theme.dart';
import '../../data/datasources/local_store.dart';
import '../../data/models/models.dart';
import 'spotify_player.dart';
import '../../providers.dart';
import '../common/responsive_wrapper.dart';
import '../settings/app_blocking_screen.dart';

class FocusScreen extends ConsumerStatefulWidget {
  final String? initialSubjectId;
  const FocusScreen({super.key, this.initialSubjectId});

  @override
  ConsumerState<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends ConsumerState<FocusScreen> {
  Timer? _timer;
  int _totalSeconds = 25 * 60;
  int _remainingSeconds = 25 * 60;
  bool _isRunning = false;
  bool _isBreak = false;
  String _selectedMode = 'Pomodoro (25m)';
  String _selectedSound = 'None';
  AudioPlayer? _audioPlayer;

  String? _selectedSubjectId;
  int _selectedUnitNumber = 1;

  // Spotify Study Music Integration
  SpotifyStudyPlaylist? _selectedSpotifyPlaylist;
  final TextEditingController _customSpotifyController = TextEditingController();
  bool _showCustomSpotifyInput = false;

  final Map<String, String> _soundFiles = {
    'None': '',
    '🌧️ Rain': 'assets/sounds/Rain.m4a',
    '📚 Library': 'assets/sounds/Library.m4a',
    '☕ Café': 'assets/sounds/CofficeShop.m4a',
    '🌊 Stream': 'assets/sounds/Stream.m4a',
    '🔥 Fireplace': 'assets/sounds/FireBurning.m4a',
    '⚪ White Noise': 'assets/sounds/Whitenoise.m4a',
  };

  @override
  void initState() {
    super.initState();
    _selectedSubjectId = widget.initialSubjectId;
    _audioPlayer = AudioPlayer();
    _totalSeconds = 25 * 60;
    _remainingSeconds = _totalSeconds;
    if (SpotifyStudyPlaylist.defaultPlaylists.isNotEmpty) {
      _selectedSpotifyPlaylist = SpotifyStudyPlaylist.defaultPlaylists.first;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final savedUri = ref.read(localStoreProvider).savedCustomSpotifyUri;
    if (savedUri.isNotEmpty && _customSpotifyController.text.isEmpty) {
      _customSpotifyController.text = savedUri;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer?.dispose();
    _customSpotifyController.dispose();
    NativeService.setDnd(false);
    super.dispose();
  }

  void _toggleTimer() async {
    final profile = ref.read(userProfileNotifierProvider);
    if (_isRunning) {
      _timer?.cancel();
      _audioPlayer?.pause();
      setState(() => _isRunning = false);
      if (profile.dndEnabled) {
        NativeService.setDnd(false);
      }
    } else {
      _startTimer();
      _playSelectedSound();
      setState(() => _isRunning = true);
      if (profile.dndEnabled && !_isBreak) {
        _handleDndActivation();
      }
    }
  }

  Future<void> _handleDndActivation() async {
    final hasDnd = await NativeService.checkDndPermission();
    if (hasDnd) {
      await NativeService.setDnd(true);
    } else if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Do Not Disturb Access'),
          content: const Text(
            'To automatically silence distracting notifications while your study timer is running, Gradient requires Do Not Disturb access in Android settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Not Now'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                NativeService.openDndSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
    }
  }

  DateTime? _expectedEndTime;

  int _distractionCheckTicks = 0;
  
  void _startTimer() {
    _timer?.cancel();
    _expectedEndTime = DateTime.now().add(Duration(seconds: _remainingSeconds));
    
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted) return;
      
      final now = DateTime.now();
      
      // Actively enforce app blocking every 2 seconds (4 ticks) during focus mode
      if (!_isBreak) {
        _distractionCheckTicks++;
        if (_distractionCheckTicks >= 4) {
          _distractionCheckTicks = 0;
          _enforceActiveAppBlock();
        }
      }

      if (_expectedEndTime != null && now.isBefore(_expectedEndTime!)) {
        setState(() {
          _remainingSeconds = _expectedEndTime!.difference(now).inSeconds;
        });
      } else {
        setState(() {
          _remainingSeconds = 0;
        });
        _handleSessionCompletion();
      }
    });
  }

  Future<void> _enforceActiveAppBlock() async {
    final profile = ref.read(userProfileNotifierProvider);
    if (profile.appBlockingTier == 'Off' || profile.blockedApps.isEmpty) return;

    final result = await NativeService.checkAndEnforceAppBlock(profile.blockedApps);
    if (result['blocked'] == true && mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: RosePineColors.dawnLove,
          content: Text(
            '🛡️ Focus Shield: ${result['appName']} blocked! Study session in progress.',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _handleSessionCompletion() async {
    if (!_isBreak) {
      // 1 Focus Session completed -> Start Break AUTOMATICALLY!
      // 5 min break for 25 min timer, 10 min break for 50 min timer
      final breakMinutes = (_selectedMode == 'Deep (50m)') ? 10 : 5;
      final focusMinutes = (_selectedMode == 'Deep (50m)') ? 50 : 25;

      // Log study time to the selected subject
      if (_selectedSubjectId != null) {
        await ref.read(localStoreProvider).logStudyTime(_selectedSubjectId!, focusMinutes);
      }

      // Turn off DND for break
      NativeService.setDnd(false);

      setState(() {
        _isBreak = true;
        _totalSeconds = breakMinutes * 60;
        _remainingSeconds = _totalSeconds;
        _isRunning = true; // KEEP RUNNING AUTOMATICALLY!
      });

      // Ensure timer is ticking for the break
      _startTimer();

      // Play success chime
      _playCompletionSound('assets/sounds/Success.wav');

      final store = ref.read(localStoreProvider);
      final profile = ref.read(userProfileNotifierProvider);
      final semSubjects = store.subjects.where((s) => s.semester == profile.semester).toList();
      final subjectName = semSubjects.cast<Subject?>().firstWhere(
        (s) => s?.id == _selectedSubjectId,
        orElse: () => null,
      )?.name ?? 'Subject';

      NativeService.showNotification(
        id: 1002,
        title: '🎉 Focus Block Complete!',
        body: 'Logged $focusMinutes mins for $subjectName (Unit $_selectedUnitNumber). Your $breakMinutes-min break has started.',
        channelId: 'focuspath_timer',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: RosePineColors.dawnFoam,
            content: Text(
              '🎉 Focus block complete! Logged $focusMinutes mins for $subjectName (Unit $_selectedUnitNumber). $breakMinutes-min break started automatically.',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        );
      }
    } else {
      // Break session completed -> Transition back to focus!
      final focusMinutes = (_selectedMode == 'Deep (50m)') ? 50 : 25;

      _timer?.cancel();

      setState(() {
        _isBreak = false;
        _totalSeconds = focusMinutes * 60;
        _remainingSeconds = _totalSeconds;
        _isRunning = false; // Pause so student can prepare or auto-start
      });

      _audioPlayer?.pause();
      _playCompletionSound('assets/sounds/Bell1.mp3');

      NativeService.showNotification(
        id: 1003,
        title: '🔔 Break Finished!',
        body: 'Ready for your next deep focus block. Let\'s continue mastering SPPU syllabus!',
        channelId: 'focuspath_timer',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: RosePineColors.dawnPine,
            content: Text(
              '🔔 Break over! Ready for your next deep focus block.',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        );
      }
    }
  }

  Future<void> _playCompletionSound(String path) async {
    try {
      final player = AudioPlayer();
      await player.setAsset(path);
      await player.play();
      player.dispose();
    } catch (_) {}
  }

  void _resetTimer() {
    _timer?.cancel();
    _audioPlayer?.stop();
    NativeService.setDnd(false);
    setState(() {
      _isRunning = false;
      _isBreak = false;
      _totalSeconds = (_selectedMode == 'Deep (50m)') ? 50 * 60 : 25 * 60;
      _remainingSeconds = _totalSeconds;
    });
  }

  Future<void> _playSelectedSound() async {
    final path = _soundFiles[_selectedSound];
    if (path == null || path.isEmpty) {
      await _audioPlayer?.stop();
      return;
    }

    try {
      await _audioPlayer?.setAsset(path);
      await _audioPlayer?.setLoopMode(LoopMode.one);
      await _audioPlayer?.play();
    } catch (_) {}
  }

  Future<void> _launchSpotifyUri(String spotifyUri, String webUrl) async {
    try {
      final nativeUri = Uri.parse(spotifyUri);
      if (await canLaunchUrl(nativeUri)) {
        await launchUrl(nativeUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}

    try {
      final fallbackUri = Uri.parse(webUrl);
      if (await canLaunchUrl(fallbackUri)) {
        await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open Spotify: $e')),
        );
      }
    }
  }

  Future<void> _launchCustomSpotify(String input) async {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return;
    await ref.read(localStoreProvider).saveCustomSpotifyUri(trimmed);

    String spotifyUri = trimmed;
    String webUrl = trimmed;

    if (trimmed.startsWith('spotify:')) {
      final parts = trimmed.split(':');
      if (parts.length >= 3) {
        webUrl = 'https://open.spotify.com/${parts[1]}/${parts[2]}';
      }
    } else if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      webUrl = trimmed;
      try {
        final uri = Uri.parse(trimmed);
        final segments = uri.pathSegments;
        if (segments.length >= 2) {
          spotifyUri = 'spotify:${segments[0]}:${segments[1]}';
        }
      } catch (_) {}
    } else {
      spotifyUri = 'spotify:playlist:$trimmed';
      webUrl = 'https://open.spotify.com/playlist/$trimmed';
    }

    await _launchSpotifyUri(spotifyUri, webUrl);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textPrimary = isDark ? RosePineColors.darkText : RosePineColors.dawnText;
    final textSubtle = isDark ? RosePineColors.darkSubtle : RosePineColors.dawnSubtle;
    final foamAccent = isDark ? RosePineColors.darkFoam : RosePineColors.dawnFoam;
    final goldAccent = isDark ? RosePineColors.darkGold : RosePineColors.dawnGold;

    final store = ref.watch(localStoreProvider);
    final profile = ref.watch(userProfileNotifierProvider);
    final semSubjects = store.subjects
        .where((s) => s.semester == profile.semester && !s.isExcluded)
        .toList();

    if (_selectedSubjectId == null && semSubjects.isNotEmpty) {
      _selectedSubjectId = semSubjects.first.id;
    }

    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    final progress = _totalSeconds > 0 ? (_totalSeconds - _remainingSeconds) / _totalSeconds : 0.0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        
        if (!_isRunning && _remainingSeconds == _totalSeconds) {
          navigator.pop();
          return;
        }

        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('End Focus Session?'),
            content: const Text('Your current timer will be stopped and progress will be lost. Are you sure?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('End Session'),
              ),
            ],
          ),
        );
        if (shouldPop == true && mounted) {
          navigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Focus Sanctuary'),
          actions: [
          IconButton(
            icon: const Icon(Icons.shield_outlined),
            tooltip: 'Distraction Shield & App Blocking',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AppBlockingScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Subject & Unit Selection Card (User Request: Let user choose subject & unit)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? RosePineColors.darkSurface : RosePineColors.dawnSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: primaryColor.withValues(alpha: isDark ? 0.35 : 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.menu_book_rounded, color: primaryColor, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Study Subject & Target Unit',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary),
                              ),
                            ],
                          ),
                          if (_selectedSubjectId != null && (store.subjectStudyMinutes[_selectedSubjectId] ?? 0) > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '⏱️ ${store.subjectStudyMinutes[_selectedSubjectId]}m logged',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryColor),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: semSubjects.any((s) => s.id == _selectedSubjectId)
                            ? _selectedSubjectId
                            : (semSubjects.isNotEmpty ? semSubjects.first.id : null),
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Choose Subject to Focus On',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        items: semSubjects.map((sub) {
                          return DropdownMenuItem(
                            value: sub.id,
                            child: Text('${sub.emoji} ${sub.name}', overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedSubjectId = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text('Unit: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textSubtle)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [1, 2, 3, 4, 5].map((u) {
                                  final isSel = _selectedUnitNumber == u;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: ChoiceChip(
                                      label: Text('Unit $u'),
                                      selected: isSel,
                                      selectedColor: primaryColor.withValues(alpha: 0.25),
                                      onSelected: (_) => setState(() => _selectedUnitNumber = u),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Mode Selector with vibrant pill styling
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: isDark ? RosePineColors.darkSurface : RosePineColors.dawnSurface,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: primaryColor.withValues(alpha: isDark ? 0.3 : 0.2),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.08),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ModeTab(
                        label: 'Pomodoro (25m)',
                        subLabel: '5m break',
                        isSelected: _selectedMode == 'Pomodoro (25m)',
                        onTap: () => _selectMode('Pomodoro (25m)', 25 * 60),
                      ),
                      _ModeTab(
                        label: 'Deep Focus (50m)',
                        subLabel: '10m break',
                        isSelected: _selectedMode == 'Deep (50m)',
                        onTap: () => _selectMode('Deep (50m)', 50 * 60),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Status Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: (_isBreak ? foamAccent : primaryColor).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: (_isBreak ? foamAccent : primaryColor).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    _isBreak
                        ? '☕ Active Break Mode (${_totalSeconds ~/ 60}m)'
                        : '🎯 Deep Focus Mode (${_totalSeconds ~/ 60}m)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _isBreak ? foamAccent : primaryColor,
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Circular Countdown Visual with vibrant styling
                SizedBox(
                  width: 250,
                  height: 250,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 240,
                        height: 240,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 12,
                          strokeCap: StrokeCap.round,
                          backgroundColor: isDark ? RosePineColors.darkOverlay : RosePineColors.dawnOverlay,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _isBreak ? foamAccent : primaryColor,
                          ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$minutes:$seconds',
                            style: TextStyle(
                              fontSize: 58,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'DINCond',
                              letterSpacing: 2,
                              color: textPrimary,
                            ),
                          ),
                          Text(
                            _isRunning
                                ? (_isBreak ? 'Rest & Recharge' : 'Stay in the Flow')
                                : (_isBreak ? 'Break Ready' : 'Ready to Start'),
                            style: TextStyle(fontSize: 14, color: textSubtle, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Play / Pause / Reset Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      iconSize: 32,
                      icon: Icon(Icons.refresh_rounded, color: textSubtle),
                      tooltip: 'Reset Timer',
                      onPressed: _resetTimer,
                    ),
                    const SizedBox(width: 24),
                    ElevatedButton(
                      onPressed: _toggleTimer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isBreak ? foamAccent : primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 28),
                          const SizedBox(width: 8),
                          Text(
                            _isRunning ? 'Pause' : (_isBreak ? 'Resume Break' : 'Start Focus'),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // Ambient Sound Dropdown Picker
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? RosePineColors.darkSurface : RosePineColors.dawnSurface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.headphones_rounded, size: 22, color: primaryColor),
                          const SizedBox(width: 10),
                          Text('Ambient Audio:', style: TextStyle(fontSize: 13, color: textPrimary, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      DropdownButton<String>(
                        value: _selectedSound,
                        underline: const SizedBox(),
                        dropdownColor: isDark ? RosePineColors.darkSurface : RosePineColors.dawnSurface,
                        items: _soundFiles.keys.map((s) {
                          return DropdownMenuItem(value: s, child: Text(s, style: TextStyle(color: textPrimary, fontSize: 13)));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedSound = val);
                            if (_isRunning) _playSelectedSound();
                          }
                        },
                      ),
                    ],
                  ),
                ),

                // Spotify Study Audio Integration Card
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? RosePineColors.darkSurface : RosePineColors.dawnSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF1DB954).withValues(alpha: isDark ? 0.45 : 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1DB954).withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.music_note_rounded, color: Color(0xFF1DB954), size: 20),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Study Soundtracks (Spotify)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: textPrimary,
                                ),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              if (_selectedSpotifyPlaylist != null) {
                                _launchSpotifyUri(
                                  _selectedSpotifyPlaylist!.spotifyUri,
                                  _selectedSpotifyPlaylist!.webUrl,
                                );
                              }
                            },
                            icon: const Icon(Icons.open_in_new_rounded, size: 14),
                            label: const Text('Open App', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1DB954),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              minimumSize: const Size(60, 32),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Curated beats and acoustic frequencies for engineering focus:',
                        style: TextStyle(fontSize: 12, color: textSubtle),
                      ),
                      const SizedBox(height: 10),
                      const SizedBox(height: 10),
                      if (_selectedSpotifyPlaylist != null) ...[
                        SpotifyPlayer(webUrl: _selectedSpotifyPlaylist!.webUrl),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () => setState(() => _selectedSpotifyPlaylist = null),
                            icon: const Icon(Icons.close_rounded, size: 16),
                            label: const Text('Close Player'),
                          ),
                        ),
                      ] else ...[
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: SpotifyStudyPlaylist.defaultPlaylists.map((pl) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ActionChip(
                                  label: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(pl.emoji, style: const TextStyle(fontSize: 13)),
                                      const SizedBox(width: 5),
                                      Text(
                                        pl.title,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: const Color(0xFF1DB954).withValues(alpha: 0.15),
                                  onPressed: () {
                                    setState(() {
                                      _selectedSpotifyPlaylist = pl;
                                    });
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: () => setState(() => _showCustomSpotifyInput = !_showCustomSpotifyInput),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Icon(
                                _showCustomSpotifyInput ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                size: 18,
                                color: textSubtle,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _showCustomSpotifyInput ? 'Hide custom playlist link' : 'Or paste custom Spotify link / URI',
                                style: TextStyle(fontSize: 12, color: primaryColor, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_showCustomSpotifyInput) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _customSpotifyController,
                                decoration: InputDecoration(
                                  hintText: 'https://open.spotify.com/playlist/...',
                                  hintStyle: TextStyle(fontSize: 11, color: textSubtle),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  isDense: true,
                                ),
                                style: TextStyle(fontSize: 12, color: textPrimary),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                _launchCustomSpotify(_customSpotifyController.text);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1DB954),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Play', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // DND and App Blocking Banner (Interactive)
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AppBlockingScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: goldAccent.withValues(alpha: isDark ? 0.18 : 0.12),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: goldAccent.withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.shield_rounded, color: goldAccent, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Auto-Break & Distraction Shield',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: goldAccent),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Break automatically starts after each pomodoro. Tap here to configure app blocking tiers & limits.',
                                  style: TextStyle(fontSize: 12, color: textSubtle),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios_rounded, size: 14, color: textSubtle),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
      ), // Close PopScope
    );
  }

  void _selectMode(String mode, int seconds) {
    setState(() {
      _selectedMode = mode;
      _isBreak = false;
      _totalSeconds = seconds;
      _remainingSeconds = seconds;
      _isRunning = false;
      _timer?.cancel();
      _audioPlayer?.stop();
    });
  }
}

class _ModeTab extends StatelessWidget {
  final String label;
  final String subLabel;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeTab({
    required this.label,
    required this.subLabel,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primary : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : (isDark ? RosePineColors.darkSubtle : RosePineColors.dawnSubtle),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
            Text(
              subLabel,
              style: TextStyle(
                color: isSelected ? Colors.white70 : Colors.grey,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
