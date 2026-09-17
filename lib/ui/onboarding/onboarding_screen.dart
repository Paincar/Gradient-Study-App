import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/rose_pine_theme.dart';
import '../../providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  final VoidCallback onFinish;

  const OnboardingScreen({super.key, required this.onFinish});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  late final TextEditingController _nameController;
  int _currentPage = 0;

  // Form State
  late String _name;
  late int _semester;
  late String _vocabularyStyle;
  late int _examplesCount;
  late int _dailyHours;
  late String _preferredTime;
  late String _collegeStartTime;
  late String _collegeEndTime;
  late String _peakMotivationWindow;
  late Set<String> _hardSubjects;
  late Set<String> _topApps;

  final List<String> _availableApps = [
    'Instagram', 'YouTube', 'WhatsApp', 'Snapchat', 'Reddit', 
    'Netflix', 'Twitter / X', 'Discord', 'BGMI / Games', 'Spotify'
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProfileNotifierProvider);
    _name = profile.name;
    _nameController = TextEditingController(text: _name == 'Student' ? '' : _name);
    _semester = profile.semester;
    _vocabularyStyle = profile.aiVocabularyStyle;
    _examplesCount = profile.aiExamplesCount;
    _dailyHours = profile.dailyStudyHours;
    _preferredTime = profile.preferredStudyTime;
    _collegeStartTime = profile.collegeStartTime;
    _collegeEndTime = profile.collegeEndTime;
    _peakMotivationWindow = profile.peakMotivationWindow;
    _hardSubjects = Set.from(profile.hardSubjects);
    if (_hardSubjects.isEmpty) {
      _hardSubjects = {'m1', 'mechanics'};
    }
    _topApps = Set.from(profile.topApps);
    if (_topApps.isEmpty) {
      _topApps = {'Instagram', 'YouTube', 'WhatsApp'};
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textPrimary = isDark ? RosePineColors.darkText : RosePineColors.dawnText;
    final textSubtle = isDark ? RosePineColors.darkSubtle : RosePineColors.dawnSubtle;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentPage > 0) {
          _pageController.previousPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        } else {
          Navigator.pop(context); // Allow pop if on first page
        }
      },
      child: Scaffold(
        body: SafeArea(
        child: Column(
          children: [
            // Top Progress Indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  for (int i = 0; i < 5; i++)
                    Expanded(
                      child: Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: i <= _currentPage
                              ? primaryColor
                              : (isDark ? RosePineColors.darkOverlay : RosePineColors.dawnOverlay),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Page Content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildWelcomePage(textPrimary, textSubtle, primaryColor),
                  _buildVocabularyPage(textPrimary, textSubtle, primaryColor),
                  _buildSchedulePage(textPrimary, textSubtle, primaryColor),
                  _buildSubjectsPage(textPrimary, textSubtle, primaryColor),
                  _buildAppsPage(textPrimary, textSubtle, primaryColor),
                ],
              ),
            ),

            // Bottom Navigation Buttons
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Text('Back', style: TextStyle(color: textSubtle)),
                    )
                  else
                    const SizedBox(width: 48),
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage < 4) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        // Save & Finish
                        final profile = ref.read(userProfileNotifierProvider).copyWith(
                          name: _name,
                          semester: _semester,
                          vocabularyLevel: _vocabularyStyle == 'Short & Concise'
                              ? 'Moderate'
                              : (_vocabularyStyle == 'Academic & Formal' ? 'Advanced' : 'Simple'),
                          aiVocabularyStyle: _vocabularyStyle,
                          aiExamplesCount: _examplesCount,
                          dailyStudyHours: _dailyHours,
                          preferredStudyTime: _preferredTime,
                          collegeStartTime: _collegeStartTime,
                          collegeEndTime: _collegeEndTime,
                          peakMotivationWindow: _peakMotivationWindow,
                          hardSubjects: _hardSubjects.toList(),
                          topApps: _topApps.toList(),
                        );
                        ref.read(userProfileNotifierProvider.notifier).updateProfile(profile);
                        ref.read(timetableNotifierProvider.notifier).regenerateWeeklySchedule();
                        widget.onFinish();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    child: Text(
                      _currentPage == 4 ? 'Get Started' : 'Continue',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ), // Close PopScope
    );
  }

  Widget _buildWelcomePage(Color textPrimary, Color textSubtle, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('👋', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            'Personalize your study sanctuary',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textPrimary),
          ),
          const SizedBox(height: 10),
          Text(
            'Tailored specifically for Savitribai Phule Pune University (SPPU) First Year Engineering.',
            style: TextStyle(fontSize: 15, color: textSubtle, height: 1.4),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'What should we call you?',
              hintText: 'e.g. Alex',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onChanged: (val) => _name = val.trim().isEmpty ? 'Student' : val.trim(),
          ),
          const SizedBox(height: 24),
          Text('Select Semester:', style: TextStyle(fontSize: 14, color: textSubtle, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Row(
            children: [
              _ChoiceChip(
                label: 'Semester I',
                selected: _semester == 1,
                onSelected: () => setState(() {
                  if (_semester != 1) _hardSubjects.clear();
                  _semester = 1;
                }),
              ),
              const SizedBox(width: 12),
              _ChoiceChip(
                label: 'Semester II',
                selected: _semester == 2,
                onSelected: () => setState(() {
                  if (_semester != 2) _hardSubjects.clear();
                  _semester = 2;
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVocabularyPage(Color textPrimary, Color textSubtle, Color primaryColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🧠', style: TextStyle(fontSize: 38)),
          const SizedBox(height: 10),
          Text(
            'Personalized AI Tutor Grounding',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            'We customize all AI explanations and problem breakdowns according to your learning style.',
            style: TextStyle(fontSize: 13, color: textSubtle, height: 1.3),
          ),
          const SizedBox(height: 18),
          _VocabOption(
            title: '💡 Easy & Simple (Recommended)',
            desc: 'Everyday language, relatable analogies (e.g. YouTube & Instagram systems), zero obscure jargon.',
            selected: _vocabularyStyle == 'Easy & Simple',
            onTap: () => setState(() => _vocabularyStyle = 'Easy & Simple'),
          ),
          const SizedBox(height: 10),
          _VocabOption(
            title: '⚡ Short & Concise (Compressed Info)',
            desc: 'High-density summaries, bulleted key points, core formulas only. Maximum revision efficiency.',
            selected: _vocabularyStyle == 'Short & Concise',
            onTap: () => setState(() => _vocabularyStyle = 'Short & Concise'),
          ),
          const SizedBox(height: 10),
          _VocabOption(
            title: '🏛️ Academic & Formal',
            desc: 'Standard SPPU syllabus terminology, formal mathematical derivations, and textbook rigor.',
            selected: _vocabularyStyle == 'Academic & Formal',
            onTap: () => setState(() => _vocabularyStyle = 'Academic & Formal'),
          ),
          const SizedBox(height: 20),
          Text(
            'Examples Per Concept:',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [1, 2, 3, 4].map((count) {
                final isSel = _examplesCount == count;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(count == 2 ? '2 Examples (Default)' : '$count Example${count > 1 ? 's' : ''}'),
                    selected: isSel,
                    selectedColor: primaryColor.withValues(alpha: 0.25),
                    onSelected: (_) => setState(() => _examplesCount = count),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSchedulePage(Color textPrimary, Color textSubtle, Color primaryColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('⏳', style: TextStyle(fontSize: 38)),
          const SizedBox(height: 10),
          Text(
            'Study Capacity & College Hours',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            'Your weekly timetable auto-schedules sessions outside your college lectures and during your peak focus window.',
            style: TextStyle(fontSize: 13, color: textSubtle, height: 1.3),
          ),
          const SizedBox(height: 18),

          // Daily Hours
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Target Daily Self-Study:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary)),
              Text('$_dailyHours Hours / Day', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryColor)),
            ],
          ),
          Slider(
            value: _dailyHours.toDouble(),
            min: 1,
            max: 8,
            divisions: 7,
            onChanged: (val) => setState(() => _dailyHours = val.toInt()),
          ),

          const SizedBox(height: 16),

          // College Timings Pickers
          Text(
            '🏛️ College Timings (Reserved for classes):',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.schedule_rounded, size: 16),
                  label: Text('Starts: $_collegeStartTime', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: const TimeOfDay(hour: 9, minute: 0),
                    );
                    if (time != null && mounted) {
                      setState(() {
                        _collegeStartTime = time.format(context);
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.schedule_rounded, size: 16),
                  label: Text('Ends: $_collegeEndTime', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: const TimeOfDay(hour: 16, minute: 30),
                    );
                    if (time != null && mounted) {
                      setState(() {
                        _collegeEndTime = time.format(context);
                      });
                    }
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Peak Motivation Window
          Text(
            '⚡ Peak Motivation Window:',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Your weak subjects will be scheduled during this high-energy window.',
            style: TextStyle(fontSize: 11, color: textSubtle),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              'Early Morning (06:00 AM - 09:00 AM)',
              'Morning (09:00 AM - 12:00 PM)',
              'Evening (05:00 PM - 09:00 PM)',
              'Late Night (09:00 PM - 12:00 AM)',
            ].map((win) {
              final isSel = _peakMotivationWindow == win;
              return ChoiceChip(
                label: Text(win, style: const TextStyle(fontSize: 11)),
                selected: isSel,
                selectedColor: primaryColor.withValues(alpha: 0.25),
                onSelected: (_) => setState(() => _peakMotivationWindow = win),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectsPage(Color textPrimary, Color textSubtle, Color primaryColor) {
    final semSubjects = _semester == 1
        ? [
            {'id': 'm1', 'name': 'Maths 1 (M1)'},
            {'id': 'physics', 'name': 'Physics'},
            {'id': 'bxe', 'name': 'Basic Electronics'},
            {'id': 'eg', 'name': 'Graphics (EG)'},
            {'id': 'fpl', 'name': 'Programming (C)'},
          ]
        : [
            {'id': 'm2', 'name': 'Maths 2 (M2)'},
            {'id': 'chemistry', 'name': 'Chemistry'},
            {'id': 'bee', 'name': 'Basic Electrical'},
            {'id': 'mechanics', 'name': 'Mechanics'},
            {'id': 'pps', 'name': 'Python (PPS)'},
          ];

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🎯', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(
            'Which subjects feel hardest?',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Weak subjects receive 25% bonus study time in your SPPU timetable and targeted PYQ practice.',
            style: TextStyle(fontSize: 14, color: textSubtle),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: semSubjects.map((sub) {
              final id = sub['id']!;
              final isSelected = _hardSubjects.contains(id);
              return FilterChip(
                label: Text(sub['name']!),
                selected: isSelected,
                selectedColor: primaryColor.withValues(alpha: 0.2),
                checkmarkColor: primaryColor,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _hardSubjects.add(id);
                    } else {
                      _hardSubjects.remove(id);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAppsPage(Color textPrimary, Color textSubtle, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📱', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(
            'Your Most Used Apps',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Select the apps you open most. We use them for intuitive analogies and gentle distraction blocking during focus mode.',
            style: TextStyle(fontSize: 14, color: textSubtle),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableApps.map((app) {
              final isSelected = _topApps.contains(app);
              return FilterChip(
                label: Text(app),
                selected: isSelected,
                selectedColor: primaryColor.withValues(alpha: 0.2),
                checkmarkColor: primaryColor,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _topApps.add(app);
                    } else {
                      _topApps.remove(app);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _ChoiceChip({required this.label, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: primary.withValues(alpha: 0.2),
      onSelected: (_) => onSelected(),
    );
  }
}

class _VocabOption extends StatelessWidget {
  final String title;
  final String desc;
  final bool selected;
  final VoidCallback onTap;

  const _VocabOption({
    required this.title,
    required this.desc,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? primary.withValues(alpha: isDark ? 0.18 : 0.1)
              : (isDark ? RosePineColors.darkSurface : RosePineColors.dawnSurface),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? primary : (isDark ? RosePineColors.darkOverlay : RosePineColors.dawnOverlay),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: selected ? primary : null)),
            const SizedBox(height: 4),
            Text(desc, style: const TextStyle(fontSize: 13, height: 1.3)),
          ],
        ),
      ),
    );
  }
}
