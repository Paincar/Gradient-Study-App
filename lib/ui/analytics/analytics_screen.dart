import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/rose_pine_theme.dart';
import '../../data/datasources/local_store.dart';
import '../../providers.dart';
import '../common/responsive_wrapper.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textPrimary = isDark ? RosePineColors.darkText : RosePineColors.dawnText;
    final textSubtle = isDark ? RosePineColors.darkSubtle : RosePineColors.dawnSubtle;
    final foamAccent = isDark ? RosePineColors.darkFoam : RosePineColors.dawnFoam;
    final goldAccent = isDark ? RosePineColors.darkGold : RosePineColors.dawnGold;
    final loveAccent = isDark ? RosePineColors.darkLove : RosePineColors.dawnLove;
    final irisAccent = isDark ? RosePineColors.darkIris : RosePineColors.dawnIris;

    final profile = ref.watch(userProfileNotifierProvider);
    final store = ref.watch(localStoreProvider);

    // Filter active semester subjects
    final subjects = store.subjects.where((s) => s.semester == profile.semester && !s.isExcluded).toList();

    // Calculate days until exam if configured
    final hasExamDate = profile.examDate.trim().isNotEmpty;
    final examDateTime = hasExamDate ? DateTime.tryParse(profile.examDate) : null;
    final daysUntilExam = (examDateTime != null) ? examDateTime.difference(DateTime.now()).inDays.clamp(0, 365) : null;

    // Fetch weekly study hours from last 7 days
    final now = DateTime.now();
    final weeklyHours = <double>[];
    final days = <String>[];
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final minutes = store.weeklyStudyHistory[dateStr] ?? 0;
      weeklyHours.add(minutes / 60.0);
      days.add(['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1]);
    }
    final totalWeeklyHours = weeklyHours.fold(0.0, (a, b) => a + b);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics & Diagnostics'),
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // Top Exam Countdown or Setup Banner
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryColor.withValues(alpha: isDark ? 0.3 : 0.18),
                      irisAccent.withValues(alpha: isDark ? 0.22 : 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: primaryColor.withValues(alpha: 0.35)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(hasExamDate ? Icons.alarm_on_rounded : Icons.calendar_today_rounded, color: primaryColor, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hasExamDate ? '$daysUntilExam Days Until SPPU Exams' : 'Target Your SPPU Exam Date',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            hasExamDate
                                ? 'Target: ${profile.dailyStudyHours}h/day · ${(daysUntilExam ?? 0) * profile.dailyStudyHours}h prep remaining'
                                : 'Set your exam date to unlock dynamic prep countdown and AI revision pacing.',
                            style: TextStyle(fontSize: 12, color: textSubtle),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: examDateTime ?? DateTime.now().add(const Duration(days: 30)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          final formatted = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                          await ref.read(userProfileNotifierProvider.notifier).updateProfile(
                            profile.copyWith(examDate: formatted),
                          );
                        }
                      },
                      child: Text(hasExamDate ? 'Edit' : 'Set Date', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Weekly Study Hours Bar Chart Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? RosePineColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? RosePineColors.darkOverlay : RosePineColors.dawnOverlay,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Weekly Study Hours',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${totalWeeklyHours.toStringAsFixed(1)} hours logged this week',
                              style: TextStyle(fontSize: 12, color: textSubtle),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: foamAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Goal: ${profile.dailyStudyHours}h/day',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: foamAccent),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Bar Chart
                    SizedBox(
                      height: 180,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: 6.0,
                          barTouchData: BarTouchData(
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                return BarTooltipItem(
                                  '${days[groupIndex]}: ${rod.toY} hrs',
                                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                );
                              },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (val, meta) {
                                  final idx = val.toInt();
                                  if (idx < 0 || idx >= days.length) return const SizedBox();
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      days[idx],
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: textSubtle,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 28,
                                interval: 2,
                                getTitlesWidget: (val, meta) {
                                  return Text(
                                    '${val.toInt()}h',
                                    style: TextStyle(fontSize: 10, color: textSubtle),
                                  );
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: 2,
                            getDrawingHorizontalLine: (val) => FlLine(
                              color: isDark ? RosePineColors.darkOverlay : RosePineColors.dawnOverlay,
                              strokeWidth: 1,
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: List.generate(weeklyHours.length, (idx) {
                            final hours = weeklyHours[idx];
                            final metGoal = hours >= profile.dailyStudyHours;
                            return BarChartGroupData(
                              x: idx,
                              barRods: [
                                BarChartRodData(
                                  toY: hours,
                                  color: metGoal ? primaryColor : goldAccent,
                                  width: 18,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Subject Study Distribution (Donut Chart)
              Builder(
                builder: (context) {
                  final Map<String, int> mins = store.subjectStudyMinutes;
                  final totalMins = mins.values.fold<int>(0, (a, b) => a + b);
                  final List<Color> colors = [foamAccent, goldAccent, irisAccent, loveAccent, primaryColor, Colors.orange];

                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? RosePineColors.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark ? RosePineColors.darkOverlay : RosePineColors.dawnOverlay,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Subject Study Distribution',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Based on your total logged study sessions',
                          style: TextStyle(fontSize: 12, color: textSubtle),
                        ),
                        const SizedBox(height: 16),
                        if (totalMins == 0)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Text('No study sessions logged yet.', style: TextStyle(color: textSubtle)),
                            ),
                          )
                        else
                          Row(
                            children: [
                              SizedBox(
                                width: 110,
                                height: 110,
                                child: PieChart(
                                  PieChartData(
                                    sectionsSpace: 3,
                                    centerSpaceRadius: 32,
                                    sections: subjects.where((s) => (mins[s.id] ?? 0) > 0).map((s) {
                                      final i = subjects.indexOf(s);
                                      final color = colors[i % colors.length];
                                      final val = (mins[s.id] ?? 0).toDouble();
                                      return PieChartSectionData(
                                        value: val,
                                        color: color,
                                        radius: 18,
                                        showTitle: false,
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: subjects.where((s) => (mins[s.id] ?? 0) > 0).take(4).map((s) {
                                    final i = subjects.indexOf(s);
                                    final color = colors[i % colors.length];
                                    final val = mins[s.id] ?? 0;
                                    final pct = ((val / totalMins) * 100).toStringAsFixed(0);
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: _LegendRow(color: color, label: s.name, percentage: '$pct%'),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Subject Readiness & Mastery Progress
              Text(
                'SPPU Subject Mastery & Routine Boost',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
              ),
              const SizedBox(height: 12),

              ...subjects.map((s) {
                final isWeak = profile.hardSubjects.contains(s.id);
                // Compute real average mastery from all units of this subject
                final unitKeys = profile.unitMastery.keys.where((k) => k.startsWith('${s.id}:')).toList();
                double progress;
                if (unitKeys.isEmpty) {
                  progress = 0.0;
                } else {
                  final avg = unitKeys.fold(0.0, (sum, k) => sum + (profile.unitMastery[k] ?? 0.0)) / unitKeys.length;
                  progress = avg.clamp(0.0, 1.0);
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text(s.emoji, style: const TextStyle(fontSize: 22)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          s.name,
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary),
                                        ),
                                      ),
                                      if (isWeak)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: loveAccent.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: loveAccent.withValues(alpha: 0.3)),
                                          ),
                                          child: Text(
                                            '+25% Routine Boost',
                                            style: TextStyle(fontSize: 10, color: loveAccent, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${s.units.length} Units · ${s.teachingHours} Syllabus Hours',
                                    style: TextStyle(fontSize: 11, color: textSubtle),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: isDark ? RosePineColors.darkOverlay : RosePineColors.dawnOverlay,
                                  color: isWeak ? goldAccent : primaryColor,
                                  minHeight: 7,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${(progress * 100).toInt()}%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isWeak ? goldAccent : primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final String percentage;

  const _LegendRow({required this.color, required this.label, required this.percentage});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ),
        Text(percentage, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
