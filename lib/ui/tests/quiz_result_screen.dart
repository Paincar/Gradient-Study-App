import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/rose_pine_theme.dart';
import '../../data/models/models.dart';
import '../../providers.dart';
import '../assessment/assessment_screen.dart';

class QuizResultScreen extends ConsumerWidget {
  final Subject subject;
  final int score;
  final int total;
  final int totalTimeSeconds;
  final List<Map<String, dynamic>> questionAnalytics;
  final List<Question> questions;
  final VoidCallback onRetake;

  const QuizResultScreen({
    super.key,
    required this.subject,
    required this.score,
    required this.total,
    required this.totalTimeSeconds,
    required this.questionAnalytics,
    required this.questions,
    required this.onRetake,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textPrimary = isDark ? RosePineColors.darkText : RosePineColors.dawnText;
    final textSubtle = isDark ? RosePineColors.darkSubtle : RosePineColors.dawnSubtle;
    final loveAccent = isDark ? RosePineColors.darkLove : RosePineColors.dawnLove;
    final goldAccent = isDark ? RosePineColors.darkGold : RosePineColors.dawnGold;
    final foamAccent = isDark ? RosePineColors.darkFoam : RosePineColors.dawnFoam;
    final irisAccent = isDark ? RosePineColors.darkIris : RosePineColors.dawnIris;
    final profile = ref.watch(userProfileNotifierProvider);

    final percentage = total > 0 ? ((score / total) * 100).toInt() : 0;
    final timeTraps = questionAnalytics.where((a) => a['status'] == QuestionTimeStatus.timeTrap).length;
    final needsWork = questionAnalytics.where((a) => a['status'] == QuestionTimeStatus.needsWork).length;
    final normalCount = questionAnalytics.where((a) => a['status'] == QuestionTimeStatus.normal).length;

    final avgTimePerQ = total > 0 ? (totalTimeSeconds / total).round() : 0;
    final totalMin = (totalTimeSeconds ~/ 60).toString().padLeft(2, '0');
    final totalSec = (totalTimeSeconds % 60).toString().padLeft(2, '0');

    final isWeakAlready = profile.hardSubjects.contains(subject.id);

    return Scaffold(
      appBar: AppBar(
        title: Text('${subject.name} Diagnostic Results'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Hero Score Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryColor.withValues(alpha: isDark ? 0.3 : 0.18),
                    irisAccent.withValues(alpha: isDark ? 0.2 : 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: primaryColor.withValues(alpha: 0.35), width: 1.5),
              ),
              child: Column(
                children: [
                  Text(
                    percentage >= 80
                        ? '🌟 Exceptional Mastery!'
                        : (percentage >= 50 ? '👍 Solid Effort!' : '⚡ Needs Focused Revision'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: CircularProgressIndicator(
                          value: total > 0 ? score / total : 0,
                          strokeWidth: 10,
                          backgroundColor: isDark ? RosePineColors.darkOverlay : RosePineColors.dawnOverlay,
                          color: percentage >= 75
                              ? foamAccent
                              : (percentage >= 50 ? goldAccent : loveAccent),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$percentage%',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          Text(
                            '$score / $total Correct',
                            style: TextStyle(fontSize: 12, color: textSubtle, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatColumn(
                        label: 'Total Time',
                        value: '$totalMin:$totalSec',
                        color: textPrimary,
                      ),
                      _StatColumn(
                        label: 'Avg / Question',
                        value: '${avgTimePerQ}s',
                        color: textPrimary,
                      ),
                      _StatColumn(
                        label: 'Time Traps',
                        value: '$timeTraps',
                        color: timeTraps > 0 ? loveAccent : foamAccent,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Time Diagnostics Breakdown Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? RosePineColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? RosePineColors.darkOverlay : RosePineColors.dawnOverlay,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.speed_rounded, color: primaryColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Time Management Diagnostics',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _DiagnosticPill(
                          label: 'Optimal Pace',
                          count: normalCount,
                          color: foamAccent,
                          description: 'Within standard SPPU time',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _DiagnosticPill(
                          label: 'Needs Work',
                          count: needsWork,
                          color: goldAccent,
                          description: '2-5m over baseline',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _DiagnosticPill(
                          label: 'Time Trap',
                          count: timeTraps,
                          color: loveAccent,
                          description: '>5m over baseline',
                        ),
                      ),
                    ],
                  ),
                  if (timeTraps > 0) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: loveAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: loveAccent.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: loveAccent, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Warning: $timeTraps question(s) took over normal time. Review their concepts below to avoid exam penalties.',
                              style: TextStyle(fontSize: 12, color: textPrimary, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Live AI Mastery & Personalization Loop Banner (PS1)
            Builder(
              builder: (ctx) {
                final unitNum = questions.isNotEmpty ? questions.first.unitNumber : 1;
                final currentMastery = profile.getMasteryFor(subject.id, unitNum);
                final masteryPct = (currentMastery * 100).round();
                final isWeak = currentMastery < 0.60;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: (isWeak ? loveAccent : primaryColor).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: (isWeak ? loveAccent : primaryColor).withValues(alpha: 0.35),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isWeak ? Icons.warning_amber_rounded : Icons.psychology_rounded,
                            color: isWeak ? loveAccent : primaryColor,
                            size: 24,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'AI Personalization & Unit $unitNum Mastery',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textPrimary),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: (isWeak ? loveAccent : primaryColor).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$masteryPct% Mastery',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: isWeak ? loveAccent : primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isWeak
                            ? '⚡ AI Tutor Loop Active: Gemini has automatically registered Unit $unitNum as a high-priority weak area and will proactively offer diagnostic tips and time-trap alerts. Your daily timetable has also scheduled +25% extra revision time.'
                            : '✨ Solid Conceptual Mastery: Your performance on Unit $unitNum is on track for top marks in the SPPU examination!',
                        style: TextStyle(fontSize: 12, color: textSubtle, height: 1.35),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 14),

            // Adaptive Schedule Action Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (isWeakAlready ? primaryColor : goldAccent).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: (isWeakAlready ? primaryColor : goldAccent).withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isWeakAlready ? Icons.check_circle_rounded : Icons.auto_awesome_rounded,
                    color: isWeakAlready ? primaryColor : goldAccent,
                    size: 26,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isWeakAlready
                              ? 'Subject Routine Boost Active (+25%)'
                              : 'Boost in Daily Timetable?',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isWeakAlready
                              ? '${subject.name} already receives 75-minute focus slots in your timetable.'
                              : 'Automatically allocate +25% extra study time for ${subject.name} in routine.',
                          style: TextStyle(fontSize: 11, color: textSubtle),
                        ),
                      ],
                    ),
                  ),
                  if (!isWeakAlready)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: goldAccent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        final currentHard = [...profile.hardSubjects, subject.id];
                        ref.read(userProfileNotifierProvider.notifier).updateProfile(
                              profile.copyWith(hardSubjects: currentHard),
                            );
                        ref.read(timetableNotifierProvider.notifier).refresh();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('⚡ ${subject.name} boosted! Timetable updated with +25% study time.'),
                          ),
                        );
                      },
                      child: const Text('Boost', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // SPPU 2024 CCE / Internal Assessment Auto-Sync Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: foamAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: foamAccent.withValues(alpha: 0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calculate_rounded, color: foamAccent, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'SPPU Continuous Evaluation (CCE)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: foamAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Parameter 3',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: foamAccent),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Sync this quiz score ($score/$total) into your official SPPU 40-mark Internal Assessment sheet (Parameter 3: Quiz/Seminar out of 6 marks).',
                    style: TextStyle(fontSize: 12, color: textSubtle, height: 1.3),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: foamAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                        icon: const Icon(Icons.sync_rounded, size: 16),
                        label: const Text('Save to CCE Sheet', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        onPressed: () async {
                          final scoreOutOf6 = (score / (total > 0 ? total : 1)) * 6.0;
                          await ref
                              .read(internalAssessmentsNotifierProvider.notifier)
                              .autoUpdateQuizScore(subject.id, scoreOutOf6);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: RosePineColors.dawnPine,
                                content: Text(
                                  '📊 Logged ${scoreOutOf6.toStringAsFixed(1)} / 6.0 into CCE Parameter 3 for ${subject.name}!',
                                ),
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: foamAccent,
                          side: BorderSide(color: foamAccent.withValues(alpha: 0.4)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        child: const Text('View All Marks', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AssessmentScreen(initialSubjectId: subject.id),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Detailed Question Review Header
            Text(
              'Detailed Question Review',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
            ),
            const SizedBox(height: 12),

            // Question Review List
            ...List.generate(questions.length, (idx) {
              final q = questions[idx];
              final a = idx < questionAnalytics.length ? questionAnalytics[idx] : null;
              final isCorrect = a != null && a['isCorrect'] == true;
              final timeSpent = a != null ? (a['timeSeconds'] as int? ?? 0) : 0;
              final status = a != null ? (a['status'] as QuestionTimeStatus? ?? QuestionTimeStatus.normal) : QuestionTimeStatus.normal;

              final statusColor = status == QuestionTimeStatus.timeTrap
                  ? loveAccent
                  : (status == QuestionTimeStatus.needsWork ? goldAccent : foamAccent);

              final statusLabel = status == QuestionTimeStatus.timeTrap
                  ? 'Time Trap'
                  : (status == QuestionTimeStatus.needsWork ? 'Slow' : 'Optimal');

              return Card(
                margin: const EdgeInsets.only(bottom: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(
                    color: isCorrect ? foamAccent.withValues(alpha: 0.3) : loveAccent.withValues(alpha: 0.3),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: (isCorrect ? foamAccent : loveAccent).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                  size: 14,
                                  color: isCorrect ? foamAccent : loveAccent,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isCorrect ? 'Correct' : 'Incorrect',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isCorrect ? foamAccent : loveAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${timeSpent}s ($statusLabel)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Unit ${q.unitNumber}',
                            style: TextStyle(fontSize: 11, color: textSubtle, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Q${idx + 1}. ${q.questionText}',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? RosePineColors.darkSurface : RosePineColors.dawnSurface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Correct Answer: ${q.options[q.correctOption]}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: foamAccent,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              q.explanation,
                              style: TextStyle(fontSize: 12, color: textSubtle, height: 1.35),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          icon: const Icon(Icons.bookmark_add_outlined, size: 16),
                          label: const Text('Save to Notes 📝', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          onPressed: () {
                            ref.read(notesNotifierProvider.notifier).addNote(
                                  NoteItem(
                                    id: 'note_q_${DateTime.now().millisecondsSinceEpoch}',
                                    title: '${subject.name} Q: ${q.topic}',
                                    content: '${q.questionText}\n\nAns: ${q.options[q.correctOption]}\n\nExplanation:\n${q.explanation}',
                                    subjectId: subject.id,
                                    subjectName: subject.name,
                                    updatedAt: DateTime.now(),
                                  ),
                                );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('✨ Saved Q${idx + 1} into ${subject.name} notes!'),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 20),

            // Bottom Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onRetake,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Retake Test', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatColumn({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _DiagnosticPill extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final String description;

  const _DiagnosticPill({
    required this.label,
    required this.count,
    required this.color,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            description,
            style: const TextStyle(fontSize: 9, color: Colors.grey),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
