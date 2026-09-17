import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/cloud_sync_service.dart';
import '../../core/theme/rose_pine_theme.dart';
import '../../data/datasources/local_store.dart';
import '../../data/models/models.dart';
import '../../providers.dart';
import '../assessment/assessment_screen.dart';
import '../calendar/calendar_screen.dart';
import '../common/responsive_wrapper.dart';
import '../feedback/feedback_screen.dart';
import '../onboarding/onboarding_screen.dart';
import '../syllabus/syllabus_screen.dart';
import 'app_blocking_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final store = ref.watch(localStoreProvider);
    final profile = ref.watch(userProfileNotifierProvider);
    final subjects = ref.watch(subjectsNotifierProvider);
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textPrimary = isDark ? RosePineColors.darkText : RosePineColors.dawnText;
    final textSubtle = isDark ? RosePineColors.darkSubtle : RosePineColors.dawnSubtle;
    final goldAccent = isDark ? RosePineColors.darkGold : RosePineColors.dawnGold;
    final loveAccent = isDark ? RosePineColors.darkLove : RosePineColors.dawnLove;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sanctuary Settings'),
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // User Header Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryColor.withValues(alpha: isDark ? 0.25 : 0.15),
                      RosePineColors.dawnIris.withValues(alpha: isDark ? 0.2 : 0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: primaryColor.withValues(alpha: 0.25),
                      child: Text(
                        profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'S',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryColor),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.name,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Semester ${profile.semester} · SPPU FE',
                            style: TextStyle(fontSize: 13, color: textSubtle),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Google Account & Cloud Backup Card
              StreamBuilder<User?>(
                stream: AuthService.instance.authStateChanges,
                builder: (context, snapshot) {
                  final user = snapshot.data ?? AuthService.instance.currentUser;
                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.cloud_sync_rounded, color: primaryColor, size: 22),
                              const SizedBox(width: 8),
                              Text(
                                'Google Account & Cloud Backup',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: textPrimary),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: user != null
                                      ? Colors.green.withValues(alpha: 0.15)
                                      : Colors.orange.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  user != null ? 'Connected' : 'Offline / Local',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: user != null ? Colors.green : Colors.orange,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (user != null) ...[
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                                  child: user.photoURL == null
                                      ? Text((user.displayName ?? 'U')[0].toUpperCase())
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user.displayName ?? 'Google User',
                                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: textPrimary),
                                      ),
                                      Text(
                                        user.email ?? '',
                                        style: TextStyle(fontSize: 12, color: textSubtle),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.sync_rounded, size: 16),
                                    label: const Text('Sync Notes Now'),
                                    onPressed: () async {
                                      final current = ref.read(notesNotifierProvider);
                                      final merged = await CloudSyncService.instance.syncAllNotes(current);
                                      await ref.read(notesNotifierProvider.notifier).saveNotes(merged);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('✨ Notes backed up to Google Cloud!')),
                                        );
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                TextButton(
                                  onPressed: () async {
                                    await AuthService.instance.signOut();
                                  },
                                  child: const Text('Sign Out', style: TextStyle(color: Colors.redAccent)),
                                ),
                              ],
                            ),
                          ] else ...[
                            Text(
                              'Sign in with Google to safely synchronize your SPPU notes, formulas, and academic records to the cloud with Firebase.',
                              style: TextStyle(fontSize: 12.5, color: textSubtle, height: 1.35),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: const Icon(Icons.g_mobiledata_rounded, size: 24),
                                label: const Text('Sign in with Google', style: TextStyle(fontWeight: FontWeight.bold)),
                                onPressed: () async {
                                  try {
                                    await AuthService.instance.signInWithGoogle();
                                    final current = ref.read(notesNotifierProvider);
                                    final merged = await CloudSyncService.instance.syncAllNotes(current);
                                    await ref.read(notesNotifierProvider.notifier).saveNotes(merged);
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Sign-In notice: $e')),
                                      );
                                    }
                                  }
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              const _SectionHeader(title: 'Manage Subjects & Timetable Inclusion'),
              const SizedBox(height: 8),

              // Description
              Text(
                'Include or exclude subjects from your daily SPPU timetable (e.g. enable PCS or DTIL, or add your own custom subjects).',
                style: TextStyle(fontSize: 12, color: textSubtle),
              ),
              const SizedBox(height: 12),

              // Subjects List with toggles
              ...subjects.map((sub) {
                final isIncluded = !sub.isExcluded;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(sub.emoji, style: const TextStyle(fontSize: 18)),
                    ),
                    title: Text(
                      sub.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isIncluded ? textPrimary : textSubtle,
                      ),
                    ),
                    subtitle: Text(
                      'Semester ${sub.semester} · ${sub.teachingHours} Syllabus Hours',
                      style: TextStyle(fontSize: 11, color: textSubtle),
                    ),
                    trailing: Switch(
                      value: isIncluded,
                      activeThumbColor: primaryColor,
                      onChanged: (_) {
                        ref.read(subjectsNotifierProvider.notifier).toggleExclusion(sub.id);
                      },
                    ),
                  ),
                );
              }),

              const SizedBox(height: 8),

              // Add Custom Subject Button
              OutlinedButton.icon(
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Custom Subject to Timetable', style: TextStyle(fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryColor,
                  side: BorderSide(color: primaryColor.withValues(alpha: 0.4), width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => _showAddSubjectDialog(context, ref, profile.semester),
              ),

              const SizedBox(height: 28),

              const _SectionHeader(title: 'Theme & Vibrancy'),
              const SizedBox(height: 10),

              // Light / Dark Mode Toggle
              Card(
                child: ListTile(
                  leading: Icon(isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded, color: primaryColor),
                  title: Text('Appearance', style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary)),
                  subtitle: Text(isDark ? 'Rosé Pine Main (Vibrant Dark)' : 'Rosé Pine Dawn (Vibrant Light)', style: TextStyle(color: textSubtle)),
                  trailing: Switch(
                    value: profile.isDarkMode,
                    activeThumbColor: primaryColor,
                    onChanged: (_) {
                      ref.read(userProfileNotifierProvider.notifier).toggleDarkMode();
                    },
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Pastel Theme Palette Selector
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pastel Accent Tone', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textPrimary)),
                      const SizedBox(height: 4),
                      Text('Choose a vibrant pastel theme for cards, buttons & highlights', style: TextStyle(fontSize: 12, color: textSubtle)),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: RosePineColors.pastels.entries.map((entry) {
                          final key = entry.key;
                          final palette = entry.value;
                          final isSel = profile.accentPalette == key;

                          return ChoiceChip(
                            avatar: CircleAvatar(backgroundColor: palette.primary, radius: 8),
                            label: Text(palette.name),
                            selected: isSel,
                            selectedColor: palette.primary.withValues(alpha: 0.25),
                            onSelected: (_) {
                              ref.read(userProfileNotifierProvider.notifier).setPalette(key);
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              const _SectionHeader(title: 'Personalization & AI Tutor'),
              const SizedBox(height: 10),

              // Gemini API Key Tile
              Card(
                child: ListTile(
                  leading: const Icon(Icons.auto_awesome_rounded, color: RosePineColors.dawnIris),
                  title: Text('Google Gemini API Key', style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary)),
                  subtitle: Text(
                    store.geminiApiKey.isNotEmpty
                        ? 'Active: Live Gemini 2.0 Flash connected'
                        : 'Free Tier (15 RPM): Tap to enter Google AI Studio Key',
                    style: TextStyle(
                      fontSize: 12,
                      color: store.geminiApiKey.isNotEmpty ? RosePineColors.dawnPine : RosePineColors.dawnGold,
                      fontWeight: store.geminiApiKey.isNotEmpty ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: Icon(
                    store.geminiApiKey.isNotEmpty ? Icons.check_circle_rounded : Icons.edit_rounded,
                    color: store.geminiApiKey.isNotEmpty ? RosePineColors.dawnPine : primaryColor,
                    size: 20,
                  ),
                  onTap: () => _showGeminiKeyDialog(context, ref),
                ),
              ),


              const SizedBox(height: 10),

              // OpenAI API Configuration Tile
              Card(
                child: ListTile(
                  leading: const Icon(Icons.api_rounded, color: RosePineColors.dawnLove),
                  title: Text('Custom OpenAI Compatible API', style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary)),
                  subtitle: Text(
                    profile.customOpenAiBaseUrl.isNotEmpty
                        ? 'Active: ${profile.customOpenAiBaseUrl}'
                        : 'Connect llama.cpp or any local LLM',
                    style: TextStyle(
                      fontSize: 12,
                      color: profile.customOpenAiBaseUrl.isNotEmpty ? RosePineColors.dawnPine : textSubtle,
                      fontWeight: profile.customOpenAiBaseUrl.isNotEmpty ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: Icon(
                    profile.customOpenAiBaseUrl.isNotEmpty ? Icons.check_circle_rounded : Icons.edit_rounded,
                    color: profile.customOpenAiBaseUrl.isNotEmpty ? RosePineColors.dawnPine : primaryColor,
                    size: 20,
                  ),
                  onTap: () => _showOpenAiApiDialog(context, ref, profile),
                ),
              ),

              const SizedBox(height: 10),

              // Vocabulary Style
              Card(
                child: ListTile(
                  leading: Icon(Icons.psychology_rounded, color: primaryColor),
                  title: Text('Explanation Style', style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary)),
                  subtitle: Text(profile.aiVocabularyStyle, style: TextStyle(color: textSubtle, fontSize: 12)),
                  trailing: DropdownButton<String>(
                    value: profile.aiVocabularyStyle,
                    underline: const SizedBox(),
                    items: ['Easy & Simple', 'Short & Concise', 'Academic & Formal'].map((v) {
                      return DropdownMenuItem(value: v, child: Text(v, style: const TextStyle(fontSize: 13)));
                    }).toList(),
                    onChanged: (newVal) {
                      if (newVal != null) {
                        ref.read(userProfileNotifierProvider.notifier).updateProfile(
                              profile.copyWith(
                                aiVocabularyStyle: newVal,
                                vocabularyLevel: newVal == 'Short & Concise'
                                    ? 'Moderate'
                                    : (newVal == 'Academic & Formal' ? 'Advanced' : 'Simple'),
                              ),
                            );
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Examples Count
              Card(
                child: ListTile(
                  leading: Icon(Icons.lightbulb_rounded, color: goldAccent),
                  title: Text('Examples Per Concept', style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary)),
                  subtitle: Text('${profile.aiExamplesCount} real-world engineering examples per explanation', style: TextStyle(color: textSubtle, fontSize: 12)),
                  trailing: DropdownButton<int>(
                    value: profile.aiExamplesCount,
                    underline: const SizedBox(),
                    items: [1, 2, 3, 4].map((cnt) {
                      return DropdownMenuItem(value: cnt, child: Text('$cnt'));
                    }).toList(),
                    onChanged: (newCnt) {
                      if (newCnt != null) {
                        ref.read(userProfileNotifierProvider.notifier).updateProfile(
                              profile.copyWith(aiExamplesCount: newCnt),
                            );
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // College Timings Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.account_balance_rounded, color: primaryColor, size: 20),
                          const SizedBox(width: 8),
                          Text('College Timings', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textPrimary)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Timetable leaves these hours free for lectures & labs:', style: TextStyle(fontSize: 11, color: textSubtle)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () async {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: const TimeOfDay(hour: 9, minute: 0),
                                );
                                if (time != null && context.mounted) {
                                  ref.read(userProfileNotifierProvider.notifier).updateProfile(
                                        profile.copyWith(collegeStartTime: time.format(context)),
                                      );
                                  ref.read(timetableNotifierProvider.notifier).regenerateWeeklySchedule();
                                }
                              },
                              child: Text('Start: ${profile.collegeStartTime}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () async {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: const TimeOfDay(hour: 16, minute: 30),
                                );
                                if (time != null && context.mounted) {
                                  ref.read(userProfileNotifierProvider.notifier).updateProfile(
                                        profile.copyWith(collegeEndTime: time.format(context)),
                                      );
                                  ref.read(timetableNotifierProvider.notifier).regenerateWeeklySchedule();
                                }
                              },
                              child: Text('End: ${profile.collegeEndTime}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Peak Motivation Window Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.bolt_rounded, color: goldAccent, size: 20),
                          const SizedBox(width: 8),
                          Text('Peak Motivation Window', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textPrimary)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Difficult subjects are automatically scheduled here:', style: TextStyle(fontSize: 11, color: textSubtle)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          'Early Morning (06:00 AM - 09:00 AM)',
                          'Morning (09:00 AM - 12:00 PM)',
                          'Evening (05:00 PM - 09:00 PM)',
                          'Late Night (09:00 PM - 12:00 AM)',
                        ].map((win) {
                          final isSel = profile.peakMotivationWindow == win;
                          return ChoiceChip(
                            label: Text(win, style: const TextStyle(fontSize: 10)),
                            selected: isSel,
                            selectedColor: primaryColor.withValues(alpha: 0.25),
                            onSelected: (_) {
                              ref.read(userProfileNotifierProvider.notifier).updateProfile(
                                    profile.copyWith(peakMotivationWindow: win),
                                  );
                              ref.read(timetableNotifierProvider.notifier).regenerateWeeklySchedule();
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // ChatterUI Custom AI Persona Tile
              Card(
                child: ListTile(
                  leading: Icon(Icons.tune_rounded, color: primaryColor),
                  title: Text('Custom AI Persona & Prompt', style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary)),
                  subtitle: Text(
                    profile.customAiPrompt.isNotEmpty
                        ? 'Custom: "${profile.customAiPrompt}"'
                        : 'Default SPPU engineering tutor. Tap to define custom persona',
                    style: TextStyle(fontSize: 12, color: textSubtle),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.edit_note_rounded),
                  onTap: () => _showCustomPersonaDialog(context, ref, profile.customAiPrompt),
                ),
              ),

              const SizedBox(height: 10),

              // Live AI Weak Unit Mastery Diagnostics Card
              Builder(
                builder: (ctx) {
                  final weakList = profile.getWeakUnitsList(subjects);
                  if (weakList.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Card(
                    color: loveAccent.withValues(alpha: isDark ? 0.12 : 0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: loveAccent.withValues(alpha: 0.35)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.auto_fix_high_rounded, color: loveAccent, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Adaptive AI Tutor Active Focus Areas',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: loveAccent),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Based on your quiz performance, Gemini AI Tutor proactively injects extra diagnostic help for:',
                            style: TextStyle(fontSize: 11, color: textSubtle),
                          ),
                          const SizedBox(height: 8),
                          ...weakList.map((w) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(shape: BoxShape.circle, color: loveAccent),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(w, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary)),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 10),

              // Retake Onboarding Questionnaire
              Card(
                child: ListTile(
                  leading: Icon(Icons.quiz_outlined, color: primaryColor),
                  title: Text('Personalization Questionnaire', style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary)),
                  subtitle: Text('Retake onboarding: favorite apps, hard subjects & daily targets', style: TextStyle(fontSize: 12, color: textSubtle)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (navCtx) => OnboardingScreen(
                          onFinish: () => Navigator.pop(navCtx),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),

              // Daily Study Target Slider
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.timer_outlined, color: primaryColor, size: 20),
                              const SizedBox(width: 8),
                              Text('Daily Study Target', style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${profile.dailyStudyHours} hrs / day',
                              style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Slider(
                        value: profile.dailyStudyHours.toDouble(),
                        min: 1,
                        max: 8,
                        divisions: 7,
                        activeColor: primaryColor,
                        label: '${profile.dailyStudyHours} hrs',
                        onChanged: (val) {
                          ref.read(userProfileNotifierProvider.notifier).updateProfile(
                                profile.copyWith(dailyStudyHours: val.toInt()),
                              );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // SPPU Exam Target Date
              Card(
                child: ListTile(
                  leading: Icon(Icons.event_rounded, color: primaryColor),
                  title: Text('SPPU Exam Date', style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary)),
                  subtitle: Text(profile.examDate, style: TextStyle(color: textSubtle)),
                  trailing: TextButton(
                    onPressed: () async {
                      final parsed = DateTime.tryParse(profile.examDate) ?? DateTime.now().add(const Duration(days: 60));
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: parsed,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        final formatted = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                        ref.read(userProfileNotifierProvider.notifier).updateProfile(
                              profile.copyWith(examDate: formatted),
                            );
                      }
                    },
                    child: const Text('Change Date'),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Distraction Guard & DND
              Card(
                child: ListTile(
                  leading: Icon(Icons.do_not_disturb_on_rounded, color: goldAccent),
                  title: Text('Do Not Disturb Assistant', style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary)),
                  subtitle: Text('Show DND reminder when focus timer begins', style: TextStyle(color: textSubtle)),
                  trailing: Switch(
                    value: profile.dndEnabled,
                    activeThumbColor: goldAccent,
                    onChanged: (_) {
                      ref.read(userProfileNotifierProvider.notifier).toggleDnd();
                    },
                  ),
                ),
              ),

              const SizedBox(height: 24),

              const _SectionHeader(title: 'Distraction Shield & App Blocking'),
              const SizedBox(height: 10),

              Card(
                child: ListTile(
                  leading: Icon(Icons.shield_outlined, color: primaryColor),
                  title: Text('App Blocking & Distraction Limits', style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary)),
                  subtitle: Text('Tier: ${profile.appBlockingTier} · ${profile.distractionThresholdMinutes}m threshold · ${profile.blockedApps.length} apps monitored', style: TextStyle(color: textSubtle)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AppBlockingScreen()),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              const _SectionHeader(title: 'Study Notifications & Reminders'),
              const SizedBox(height: 10),

              // Morning Briefing
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: SwitchListTile(
                  secondary: Icon(Icons.wb_sunny_outlined, color: goldAccent),
                  title: Text('Morning Briefing (${profile.morningBriefingTime})', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textPrimary)),
                  subtitle: Text('Daily routine briefing with today\'s target topics', style: TextStyle(fontSize: 12, color: textSubtle)),
                  value: profile.morningBriefingEnabled,
                  activeThumbColor: primaryColor,
                  onChanged: (val) {
                    ref.read(userProfileNotifierProvider.notifier).updateProfile(
                          profile.copyWith(morningBriefingEnabled: val),
                        );
                  },
                ),
              ),

              // Timetable Slot Alarms
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: SwitchListTile(
                  secondary: Icon(Icons.alarm_rounded, color: primaryColor),
                  title: Text('Timetable Slot Alarms', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textPrimary)),
                  subtitle: Text('Chime before each scheduled SPPU study session', style: TextStyle(fontSize: 12, color: textSubtle)),
                  value: profile.slotRemindersEnabled,
                  activeThumbColor: primaryColor,
                  onChanged: (val) {
                    ref.read(userProfileNotifierProvider.notifier).updateProfile(
                          profile.copyWith(slotRemindersEnabled: val),
                        );
                  },
                ),
              ),

              // Streak Nudge
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: SwitchListTile(
                  secondary: Icon(Icons.local_fire_department_rounded, color: goldAccent),
                  title: Text('Evening Streak Nudge (8:00 PM)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textPrimary)),
                  subtitle: Text('Friendly reminder if daily study target is not met', style: TextStyle(fontSize: 12, color: textSubtle)),
                  value: profile.streakNudgeEnabled,
                  activeThumbColor: primaryColor,
                  onChanged: (val) {
                    ref.read(userProfileNotifierProvider.notifier).updateProfile(
                          profile.copyWith(streakNudgeEnabled: val),
                        );
                  },
                ),
              ),

              // Break Reminders
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: SwitchListTile(
                  secondary: const Icon(Icons.coffee_rounded, color: RosePineColors.dawnFoam),
                  title: Text('Continuous Study Break Reminder', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textPrimary)),
                  subtitle: Text('Prompt a recharge break after 90m continuous study', style: TextStyle(fontSize: 12, color: textSubtle)),
                  value: profile.breakRemindersEnabled,
                  activeThumbColor: primaryColor,
                  onChanged: (val) {
                    ref.read(userProfileNotifierProvider.notifier).updateProfile(
                          profile.copyWith(breakRemindersEnabled: val),
                        );
                  },
                ),
              ),

              // Quiet Hours
              Card(
                child: SwitchListTile(
                  secondary: Icon(Icons.bedtime_outlined, color: textSubtle),
                  title: Text('Quiet Hours (${profile.quietHoursStart} - ${profile.quietHoursEnd})', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textPrimary)),
                  subtitle: Text('Mute all study reminders during sleep hours', style: TextStyle(fontSize: 12, color: textSubtle)),
                  value: profile.quietHoursEnabled,
                  activeThumbColor: primaryColor,
                  onChanged: (val) {
                    ref.read(userProfileNotifierProvider.notifier).updateProfile(
                          profile.copyWith(quietHoursEnabled: val),
                        );
                  },
                ),
              ),

              const SizedBox(height: 24),

              const _SectionHeader(title: 'Academic Resources & Navigation'),
              const SizedBox(height: 10),

              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.calculate_rounded, color: RosePineColors.dawnFoam),
                  title: Text('Internal Assessment & CCE Calculator', style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary)),
                  subtitle: const Text('Calculate 40-mark continuous evaluation & forecast 125-mark grade (SPPU 2024)', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AssessmentScreen()),
                    );
                  },
                ),
              ),

              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(Icons.account_tree_outlined, color: primaryColor),
                  title: Text('SPPU FE Syllabus Tree', style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary)),
                  subtitle: const Text('Browse all Semester 1 & 2 units, teaching hours, and weightage', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SyllabusScreen()),
                    );
                  },
                ),
              ),

              Card(
                child: ListTile(
                  leading: Icon(Icons.calendar_month_rounded, color: goldAccent),
                  title: Text('Academic Calendar & Holidays', style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary)),
                  subtitle: const Text('View Maharashtra state holidays, exam countdown & custom leaves', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CalendarScreen()),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              const _SectionHeader(title: 'Feedback & Offline Data'),
              const SizedBox(height: 10),

              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(Icons.rate_review_outlined, color: primaryColor),
                  title: Text('Student Feedback & Ideas', style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary)),
                  subtitle: const Text('Submit feature requests, bug reports, and suggestions offline', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FeedbackScreen()),
                    );
                  },
                ),
              ),

              Card(
                child: ListTile(
                  leading: Icon(Icons.cloud_off_rounded, color: primaryColor),
                  title: Text('100% Offline Single Source of Truth', style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary)),
                  subtitle: const Text('All syllabus hours, timetable slots, notes, and PYQs are saved locally on your device.', style: TextStyle(fontSize: 12)),
                ),
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddSubjectDialog(BuildContext context, WidgetRef ref, int userSemester) {
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    final emojiController = TextEditingController(text: '📘');
    final hoursController = TextEditingController(text: '36');
    int sem = userSemester;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Custom Subject'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Subject Name',
                        hintText: 'e.g. Environmental Engineering',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: codeController,
                      decoration: const InputDecoration(
                        labelText: 'Course Code',
                        hintText: 'e.g. ESC-108',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: emojiController,
                            decoration: const InputDecoration(
                              labelText: 'Emoji Icon',
                              hintText: '🌿',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: hoursController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Syllabus Hours',
                              hintText: '36',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Text('Semester: ', style: TextStyle(fontWeight: FontWeight.bold)),
                        ChoiceChip(
                          label: const Text('Sem 1'),
                          selected: sem == 1,
                          onSelected: (_) => setDialogState(() => sem = 1),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Sem 2'),
                          selected: sem == 2,
                          onSelected: (_) => setDialogState(() => sem = 2),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isNotEmpty) {
                      final newSub = Subject(
                        id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                        name: name,
                        code: codeController.text.trim().isEmpty ? 'CUSTOM' : codeController.text.trim(),
                        emoji: emojiController.text.trim().isEmpty ? '📘' : emojiController.text.trim(),
                        color: '#1680A6',
                        semester: sem,
                        teachingHours: int.tryParse(hoursController.text) ?? 36,
                        isExcluded: false,
                        units: [
                          Unit(unitNumber: 1, name: 'Unit 1 Fundamentals', hours: 8, weightage: 'High'),
                          Unit(unitNumber: 2, name: 'Unit 2 Core Concepts', hours: 8, weightage: 'High'),
                          Unit(unitNumber: 3, name: 'Unit 3 Applications', hours: 8, weightage: 'High'),
                        ],
                      );

                      ref.read(subjectsNotifierProvider.notifier).addSubject(newSub);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Added $name to your curriculum & timetable!')),
                      );
                    }
                  },
                  child: const Text('Add Subject'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showGeminiKeyDialog(BuildContext context, WidgetRef ref) {
    final store = ref.read(localStoreProvider);
    final ctrl = TextEditingController(text: store.geminiApiKey);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.auto_awesome_rounded, color: RosePineColors.dawnIris),
            SizedBox(width: 8),
            Text('Google Gemini API Key'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Powers the SPPU AI Concept Explainer using Gemini 2.0 Flash (with automatic Gemini 1.5 Flash fallback).\n\nGet your free key from Google AI Studio at:\naistudio.google.com',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              decoration: InputDecoration(
                hintText: 'AIzaSy...',
                labelText: 'Gemini API Key',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final key = ctrl.text.trim();
              await store.setGeminiApiKey(key);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: RosePineColors.dawnPine,
                    content: Text(key.isNotEmpty
                        ? '✨ Gemini 2.0 Flash API Key connected!'
                        : 'Gemini API key cleared.'),
                  ),
                );
              }
            },
            child: const Text('Save Key'),
          ),
        ],
      ),
    );
  }

  void _showOpenAiApiDialog(BuildContext context, WidgetRef ref, UserProfile profile) {
    final urlCtrl = TextEditingController(text: profile.customOpenAiBaseUrl);
    final keyCtrl = TextEditingController(text: profile.customOpenAiApiKey);
    final modelCtrl = TextEditingController(text: profile.customOpenAiModel);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.api_rounded, color: RosePineColors.dawnLove),
            SizedBox(width: 8),
            Text('Custom API'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Connect to llama.cpp, LM Studio, Ollama, or any OpenAI-compatible API to run open source models.',
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: urlCtrl,
                decoration: InputDecoration(
                  hintText: 'http://localhost:8080/v1',
                  labelText: 'Base URL',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: keyCtrl,
                decoration: InputDecoration(
                  hintText: '(Optional) sk-...',
                  labelText: 'API Key',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: modelCtrl,
                decoration: InputDecoration(
                  hintText: '(Optional) llama-3-8b',
                  labelText: 'Model Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              ref.read(userProfileNotifierProvider.notifier).updateProfile(
                    profile.copyWith(
                      customOpenAiBaseUrl: urlCtrl.text.trim(),
                      customOpenAiApiKey: keyCtrl.text.trim(),
                      customOpenAiModel: modelCtrl.text.trim(),
                    ),
                  );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: RosePineColors.dawnPine,
                  content: Text(urlCtrl.text.trim().isNotEmpty
                      ? 'Custom API connected!'
                      : 'Custom API cleared.'),
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showCustomPersonaDialog(BuildContext context, WidgetRef ref, String currentPrompt) {
    final ctrl = TextEditingController(text: currentPrompt);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.tune_rounded, color: RosePineColors.dawnIris),
            SizedBox(width: 8),
            Text('Custom AI Persona (ChatterUI)'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Customize the exact persona or system instructions passed to Gemini AI Tutor (e.g. "Focus on numerical formulas with racing analogies", "Act like an exam examiner who grades strictly"):',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'e.g. Provide derivations step-by-step and test my understanding with a quick 1-line question.',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          if (currentPrompt.isNotEmpty)
            TextButton(
              onPressed: () async {
                await ref.read(userProfileNotifierProvider.notifier).updateCustomAiPrompt('');
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Reset to Default', style: TextStyle(color: Colors.red)),
            ),
          ElevatedButton(
            onPressed: () async {
              final newPrompt = ctrl.text.trim();
              await ref.read(userProfileNotifierProvider.notifier).updateCustomAiPrompt(newPrompt);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save Persona'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
