import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/rose_pine_theme.dart';
import '../../data/datasources/local_store.dart';
import '../../data/models/models.dart';
import '../../providers.dart';
import '../common/responsive_wrapper.dart';

class AssessmentScreen extends ConsumerStatefulWidget {
  final String? initialSubjectId;

  const AssessmentScreen({super.key, this.initialSubjectId});

  @override
  ConsumerState<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends ConsumerState<AssessmentScreen> {
  String? _selectedSubjectId;

  // Form edit controllers & state
  double _unitTestMarks = 0.0;
  double _assignmentsMarks = 0.0;
  double _quizSeminarMarks = 0.0;
  double _miniProjectMarks = 0.0;
  double _termWorkMarks = 0.0;
  double _endSemMarks = 0.0;

  bool _initializedSubject = false;

  void _loadSubjectRecord(Subject subject, Map<String, InternalAssessmentRecord> records) {
    final record = records[subject.id] ??
        ref.read(localStoreProvider).getAssessmentForSubject(subject);
    setState(() {
      _unitTestMarks = record.unitTestMarks;
      _assignmentsMarks = record.assignmentsMarks;
      _quizSeminarMarks = record.quizSeminarMarks;
      _miniProjectMarks = record.miniProjectMarks;
      _termWorkMarks = record.termWorkMarks;
      _endSemMarks = record.endSemMarks;
    });
  }

  void _saveCurrentRecord(Subject subject) {
    final record = InternalAssessmentRecord(
      subjectId: subject.id,
      subjectName: subject.name,
      unitTestMarks: _unitTestMarks,
      assignmentsMarks: _assignmentsMarks,
      quizSeminarMarks: _quizSeminarMarks,
      miniProjectMarks: _miniProjectMarks,
      termWorkMarks: _termWorkMarks,
      endSemMarks: _endSemMarks,
    );
    ref.read(internalAssessmentsNotifierProvider.notifier).saveAssessment(record);
  }

  void _syncFromQuizzes(Subject subject) {
    final profile = ref.read(userProfileNotifierProvider);
    // Calculate average mastery across units 1 and 2 for Unit Test
    final u1 = profile.getMasteryFor(subject.id, 1);
    final u2 = profile.getMasteryFor(subject.id, 2);
    final avgU12 = (u1 + u2) / 2.0;
    final autoUnitTest = double.parse((avgU12 * 12.0).toStringAsFixed(1));

    // Unit 5 for Quiz
    final u5 = profile.getMasteryFor(subject.id, 5);
    final autoQuiz = double.parse((u5 * 6.0).toStringAsFixed(1));

    setState(() {
      _unitTestMarks = autoUnitTest.clamp(0.0, 12.0);
      _quizSeminarMarks = autoQuiz.clamp(0.0, 6.0);
    });

    _saveCurrentRecord(subject);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: RosePineColors.dawnFoam,
        content: Text(
          '✨ Synced from diagnostic quizzes! Unit Test updated to $_unitTestMarks/12, Quiz to $_quizSeminarMarks/6.',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textPrimary = isDark ? RosePineColors.darkText : RosePineColors.dawnText;
    final textSubtle = isDark ? RosePineColors.darkSubtle : RosePineColors.dawnSubtle;
    final goldAccent = isDark ? RosePineColors.darkGold : RosePineColors.dawnGold;
    final foamAccent = isDark ? RosePineColors.darkFoam : RosePineColors.dawnFoam;
    final loveAccent = isDark ? RosePineColors.darkLove : RosePineColors.dawnLove;
    final irisAccent = isDark ? RosePineColors.darkIris : RosePineColors.dawnIris;

    final store = ref.watch(localStoreProvider);
    final profile = ref.watch(userProfileNotifierProvider);
    final assessments = ref.watch(internalAssessmentsNotifierProvider);

    final semSubjects = store.subjects
        .where((s) => s.semester == profile.semester && !s.isExcluded)
        .toList();

    if (semSubjects.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Internal Assessment Calculator')),
        body: const Center(child: Text('No active subjects in this semester.')),
      );
    }

    if (!_initializedSubject) {
      _selectedSubjectId = widget.initialSubjectId ?? semSubjects.first.id;
      final currentSub = semSubjects.firstWhere(
        (s) => s.id == _selectedSubjectId,
        orElse: () => semSubjects.first,
      );
      _loadSubjectRecord(currentSub, assessments);
      _initializedSubject = true;
    }

    final currentSubject = semSubjects.firstWhere(
      (s) => s.id == _selectedSubjectId,
      orElse: () => semSubjects.first,
    );

    // Live computed values
    final cceTotal = (_unitTestMarks + _assignmentsMarks + _quizSeminarMarks + _miniProjectMarks).clamp(0.0, 40.0);
    final grandTotal = (cceTotal + _endSemMarks + _termWorkMarks).clamp(0.0, 125.0);
    final overallPct = (grandTotal / 125.0) * 100.0;
    final isPassed = _endSemMarks >= 24.0 && grandTotal >= 50.0;

    String projectedGrade;
    if (_endSemMarks < 24.0 || grandTotal < 50.0) {
      projectedGrade = 'F (Fail / Needs ESE >= 24)';
    } else if (overallPct >= 90) {
      projectedGrade = 'O (Outstanding - 10 Pointer)';
    } else if (overallPct >= 80) {
      projectedGrade = 'A+ (Excellent - 9 Pointer)';
    } else if (overallPct >= 70) {
      projectedGrade = 'A (Very Good - 8 Pointer)';
    } else if (overallPct >= 60) {
      projectedGrade = 'B+ (Good - 7 Pointer)';
    } else if (overallPct >= 55) {
      projectedGrade = 'B (Above Average - 6 Pointer)';
    } else if (overallPct >= 50) {
      projectedGrade = 'C (Average - 5 Pointer)';
    } else {
      projectedGrade = 'P (Pass - 4 Pointer)';
    }

    // Required End-Sem target to achieve O (90%) and A+ (80%)
    final reqForO = (90.0 * 1.25 - cceTotal - _termWorkMarks).clamp(24.0, 60.0);
    final reqForA = (80.0 * 1.25 - cceTotal - _termWorkMarks).clamp(24.0, 60.0);
    final reqForPass = (50.0 - cceTotal - _termWorkMarks).clamp(24.0, 60.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Internal Assessment (CCE)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded),
            tooltip: 'Auto-Sync from Quizzes',
            onPressed: () => _syncFromQuizzes(currentSubject),
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              // Subject Selection Scrollable Pills
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: semSubjects.map((sub) {
                    final isSel = sub.id == currentSubject.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        avatar: Text(sub.emoji, style: const TextStyle(fontSize: 16)),
                        label: Text(sub.name),
                        selected: isSel,
                        selectedColor: primaryColor.withValues(alpha: 0.25),
                        onSelected: (sel) {
                          if (sel) {
                            setState(() => _selectedSubjectId = sub.id);
                            _loadSubjectRecord(sub, assessments);
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16),

              // Hero Marks Overview Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryColor.withValues(alpha: isDark ? 0.35 : 0.18),
                      irisAccent.withValues(alpha: isDark ? 0.25 : 0.12),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: primaryColor.withValues(alpha: 0.35), width: 1.5),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentSubject.name,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'SPPU FE 2024 Revised Course · 4 Credits',
                              style: TextStyle(fontSize: 12, color: textSubtle),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: (isPassed ? foamAccent : loveAccent).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: (isPassed ? foamAccent : loveAccent).withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            isPassed ? '✅ ON TRACK' : '⚠️ AT RISK',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isPassed ? foamAccent : loveAccent,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _ScoreGauge(
                          title: 'CCE Internal',
                          value: '${cceTotal.toStringAsFixed(1)} / 40',
                          percent: cceTotal / 40.0,
                          color: primaryColor,
                          textPrimary: textPrimary,
                          textSubtle: textSubtle,
                        ),
                        _ScoreGauge(
                          title: 'Total Course',
                          value: '${grandTotal.toStringAsFixed(1)} / 125',
                          percent: grandTotal / 125.0,
                          color: isPassed ? foamAccent : loveAccent,
                          textPrimary: textPrimary,
                          textSubtle: textSubtle,
                        ),
                        _ScoreGauge(
                          title: 'Percentage',
                          value: '${overallPct.toStringAsFixed(1)}%',
                          percent: overallPct / 100.0,
                          color: goldAccent,
                          textPrimary: textPrimary,
                          textSubtle: textSubtle,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (isDark ? RosePineColors.darkSurface : Colors.white).withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.workspace_premium_rounded, color: goldAccent, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Projected Grade: $projectedGrade',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Section 1: CCE (40 Marks) Breakdown
              _SectionTitle(
                title: 'Comprehensive Continuous Evaluation (CCE — 40 Marks)',
                subtitle: 'Evaluated continuously at institute level as per SPPU 2024 Course Structure',
                icon: Icons.assignment_turned_in_rounded,
                color: primaryColor,
                textPrimary: textPrimary,
                textSubtle: textSubtle,
              ),
              const SizedBox(height: 10),

              // Parameter 1: Unit Test (12 Marks)
              _ParameterCard(
                title: 'Parameter 1: Unit Test (Units 1 & 2)',
                subtitle: '6 Marks per unit (Remembering, Understanding, Applying, Analyzing)',
                maxMarks: 12.0,
                currentMarks: _unitTestMarks,
                accentColor: primaryColor,
                isDark: isDark,
                textPrimary: textPrimary,
                textSubtle: textSubtle,
                onChanged: (val) {
                  setState(() => _unitTestMarks = val);
                  _saveCurrentRecord(currentSubject);
                },
              ),

              // Parameter 2: Assignments / Case Study (12 Marks)
              _ParameterCard(
                title: 'Parameter 2: Assignments / Case Study (Units 3 & 4)',
                subtitle: '6 Marks per unit (Problem solving, analytical case studies)',
                maxMarks: 12.0,
                currentMarks: _assignmentsMarks,
                accentColor: irisAccent,
                isDark: isDark,
                textPrimary: textPrimary,
                textSubtle: textSubtle,
                onChanged: (val) {
                  setState(() => _assignmentsMarks = val);
                  _saveCurrentRecord(currentSubject);
                },
              ),

              // Parameter 3: Seminar / Quiz (6 Marks)
              _ParameterCard(
                title: 'Parameter 3: Seminar / Open Book / Quiz (Unit 5)',
                subtitle: 'Evaluates advanced Unit 5 topics & conceptual tests',
                maxMarks: 6.0,
                currentMarks: _quizSeminarMarks,
                accentColor: foamAccent,
                isDark: isDark,
                textPrimary: textPrimary,
                textSubtle: textSubtle,
                onChanged: (val) {
                  setState(() => _quizSeminarMarks = val);
                  _saveCurrentRecord(currentSubject);
                },
              ),

              // Parameter 4: Mini Project / PBL (10 Marks)
              _ParameterCard(
                title: 'Parameter 4: Mini Project / PBL / Activity',
                subtitle: 'Project-based learning, prototype, or activity across any unit',
                maxMarks: 10.0,
                currentMarks: _miniProjectMarks,
                accentColor: goldAccent,
                isDark: isDark,
                textPrimary: textPrimary,
                textSubtle: textSubtle,
                onChanged: (val) {
                  setState(() => _miniProjectMarks = val);
                  _saveCurrentRecord(currentSubject);
                },
              ),

              const SizedBox(height: 20),

              // Section 2: Term Work & End-Semester Paper
              _SectionTitle(
                title: 'Term Work (25M) & End-Semester Exam (60M)',
                subtitle: 'Complete degree assessment components for 125 total course marks',
                icon: Icons.school_rounded,
                color: foamAccent,
                textPrimary: textPrimary,
                textSubtle: textSubtle,
              ),
              const SizedBox(height: 10),

              // Term Work (25 Marks)
              _ParameterCard(
                title: 'Term Work (TW) — Practical / Lab',
                subtitle: 'Continuous assessment of laboratory assignments & journal work',
                maxMarks: 25.0,
                currentMarks: _termWorkMarks,
                accentColor: foamAccent,
                isDark: isDark,
                textPrimary: textPrimary,
                textSubtle: textSubtle,
                onChanged: (val) {
                  setState(() => _termWorkMarks = val);
                  _saveCurrentRecord(currentSubject);
                },
              ),

              // End-Sem Theory Exam (60 Marks)
              _ParameterCard(
                title: 'End-Sem Theory Exam (ESE) Target / Score',
                subtitle: 'Official SPPU 60-mark 2.5 hr written paper (Mandatory min: 24/60 to pass)',
                maxMarks: 60.0,
                currentMarks: _endSemMarks,
                accentColor: primaryColor,
                isDark: isDark,
                textPrimary: textPrimary,
                textSubtle: textSubtle,
                onChanged: (val) {
                  setState(() => _endSemMarks = val);
                  _saveCurrentRecord(currentSubject);
                },
              ),

              const SizedBox(height: 20),

              // Smart Target Forecaster
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? RosePineColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? RosePineColors.darkOverlay : RosePineColors.dawnOverlay,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_graph_rounded, color: goldAccent, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'End-Sem Target Score Calculator',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Based on your current CCE ($cceTotal/40) and Term Work ($_termWorkMarks/25), here is what you need in the 60-mark End-Sem paper:',
                      style: TextStyle(fontSize: 12, color: textSubtle, height: 1.4),
                    ),
                    const SizedBox(height: 14),
                    _TargetRow(
                      targetGrade: 'O Grade (10 Pointer)',
                      neededMarks: reqForO,
                      accentColor: goldAccent,
                      textPrimary: textPrimary,
                    ),
                    const Divider(height: 16),
                    _TargetRow(
                      targetGrade: 'A+ Grade (9 Pointer)',
                      neededMarks: reqForA,
                      accentColor: foamAccent,
                      textPrimary: textPrimary,
                    ),
                    const Divider(height: 16),
                    _TargetRow(
                      targetGrade: 'Minimum Passing (40% aggregate)',
                      neededMarks: reqForPass,
                      accentColor: isPassed ? primaryColor : loveAccent,
                      textPrimary: textPrimary,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreGauge extends StatelessWidget {
  final String title;
  final String value;
  final double percent;
  final Color color;
  final Color textPrimary;
  final Color textSubtle;

  const _ScoreGauge({
    required this.title,
    required this.value,
    required this.percent,
    required this.color,
    required this.textPrimary,
    required this.textSubtle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 60,
          height: 60,
          child: Stack(
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: percent.clamp(0.0, 1.0),
                strokeWidth: 6,
                backgroundColor: color.withValues(alpha: 0.18),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
              Center(
                child: Text(
                  '${(percent * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textSubtle),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textPrimary),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color textPrimary;
  final Color textSubtle;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.textPrimary,
    required this.textSubtle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11, color: textSubtle),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ParameterCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double maxMarks;
  final double currentMarks;
  final Color accentColor;
  final bool isDark;
  final Color textPrimary;
  final Color textSubtle;
  final ValueChanged<double> onChanged;

  const _ParameterCard({
    required this.title,
    required this.subtitle,
    required this.maxMarks,
    required this.currentMarks,
    required this.accentColor,
    required this.isDark,
    required this.textPrimary,
    required this.textSubtle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '${currentMarks.toStringAsFixed(1)} / ${maxMarks.toInt()} Marks',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: accentColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: textSubtle),
            ),
            const SizedBox(height: 10),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: accentColor,
                thumbColor: accentColor,
                overlayColor: accentColor.withValues(alpha: 0.2),
              ),
              child: Slider(
                value: currentMarks.clamp(0.0, maxMarks),
                min: 0.0,
                max: maxMarks,
                divisions: (maxMarks * 2).toInt(),
                onChanged: (val) {
                  final rounded = double.parse(val.toStringAsFixed(1));
                  onChanged(rounded);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TargetRow extends StatelessWidget {
  final String targetGrade;
  final double neededMarks;
  final Color accentColor;
  final Color textPrimary;

  const _TargetRow({
    required this.targetGrade,
    required this.neededMarks,
    required this.accentColor,
    required this.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final neededInt = neededMarks.ceil();
    final isFeasible = neededMarks <= 60.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          targetGrade,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
        ),
        Row(
          children: [
            Text(
              isFeasible ? 'Need $neededInt / 60 in ESE' : 'Unachievable (Requires >60)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isFeasible ? accentColor : Colors.grey,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              isFeasible ? Icons.check_circle_outline_rounded : Icons.cancel_outlined,
              size: 16,
              color: isFeasible ? accentColor : Colors.grey,
            ),
          ],
        ),
      ],
    );
  }
}
