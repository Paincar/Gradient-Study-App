import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/rose_pine_theme.dart';
import '../../data/models/models.dart';
import '../../providers.dart';
import '../common/responsive_wrapper.dart';
import '../tests/pyq_viewer_screen.dart';
import '../tests/quiz_screen.dart';

class SyllabusScreen extends ConsumerStatefulWidget {
  final String? initialSubjectId;

  const SyllabusScreen({super.key, this.initialSubjectId});

  @override
  ConsumerState<SyllabusScreen> createState() => _SyllabusScreenState();
}

class _SyllabusScreenState extends ConsumerState<SyllabusScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedSubjectId;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProfileNotifierProvider);
    _tabController = TabController(length: 2, vsync: this, initialIndex: profile.semester == 2 ? 1 : 0);
    _selectedSubjectId = widget.initialSubjectId;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subjects = ref.watch(subjectsNotifierProvider);
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textPrimary = isDark ? RosePineColors.darkText : RosePineColors.dawnText;
    final textSubtle = isDark ? RosePineColors.darkSubtle : RosePineColors.dawnSubtle;
    final goldAccent = isDark ? RosePineColors.darkGold : RosePineColors.dawnGold;
    final irisAccent = isDark ? RosePineColors.darkIris : RosePineColors.dawnIris;

    final sem1Subjects = subjects.where((s) => s.semester == 1).toList();
    final sem2Subjects = subjects.where((s) => s.semester == 2).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('SPPU FE Syllabus Tree'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryColor,
          unselectedLabelColor: textSubtle,
          indicatorColor: primaryColor,
          tabs: const [
            Tab(text: 'Semester I (Revised 2024)'),
            Tab(text: 'Semester II (Revised 2024)'),
          ],
        ),
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildSubjectList(sem1Subjects, isDark, primaryColor, textPrimary, textSubtle, goldAccent, irisAccent),
              _buildSubjectList(sem2Subjects, isDark, primaryColor, textPrimary, textSubtle, goldAccent, irisAccent),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectList(
    List<Subject> subjects,
    bool isDark,
    Color primaryColor,
    Color textPrimary,
    Color textSubtle,
    Color goldAccent,
    Color irisAccent,
  ) {
    if (subjects.isEmpty) {
      return Center(
        child: Text('No subjects loaded.', style: TextStyle(color: textSubtle)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: subjects.length,
      itemBuilder: (context, index) {
        final subject = subjects[index];
        final isExpanded = _selectedSubjectId == subject.id;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Column(
            children: [
              // Subject Header
              InkWell(
                onTap: () {
                  setState(() {
                    _selectedSubjectId = isExpanded ? null : subject.id;
                  });
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: Text(subject.emoji, style: const TextStyle(fontSize: 22)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    subject.name,
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textPrimary),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${subject.teachingHours} hrs',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryColor),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'SPPU 2024 Revised Pattern · ${subject.units.length} Units',
                              style: TextStyle(fontSize: 12, color: textSubtle),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        color: textSubtle,
                      ),
                    ],
                  ),
                ),
              ),

              // Expanded Units View
              if (isExpanded) ...[
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quick Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.quiz_outlined, size: 16),
                              label: const Text('Start Quiz', style: TextStyle(fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: irisAccent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => QuizScreen(subject: subject)),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.menu_book_rounded, size: 16),
                              label: const Text('Browse PYQs', style: TextStyle(fontSize: 12)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => PYQViewerScreen(subject: subject)),
                                );
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      Text(
                        'COURSE MODULES & PRESCRIBED HOURS',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: textSubtle),
                      ),
                      const SizedBox(height: 10),

                      ...subject.units.map((unit) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? RosePineColors.darkOverlay : RosePineColors.dawnOverlay,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${unit.unitNumber}',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 13),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      unit.name,
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${unit.hours} SPPU Teaching Hours',
                                      style: TextStyle(fontSize: 11, color: textSubtle),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: goldAccent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${unit.weightage} Weight',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: goldAccent),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
