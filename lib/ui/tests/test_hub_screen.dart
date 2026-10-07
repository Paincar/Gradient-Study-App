import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/rose_pine_theme.dart';
import '../../data/datasources/local_store.dart';
import '../../data/models/models.dart';
import '../../providers.dart';
import '../common/responsive_wrapper.dart';
import '../syllabus/syllabus_screen.dart';
import 'pyq_viewer_screen.dart';
import 'quiz_screen.dart';

class TestHubScreen extends ConsumerStatefulWidget {
  const TestHubScreen({super.key});

  @override
  ConsumerState<TestHubScreen> createState() => _TestHubScreenState();
}

class _TestHubScreenState extends ConsumerState<TestHubScreen> {
  int _selectedTab = 0; // 0 = Quiz Section, 1 = SPPU PYQ Papers

  // Rapid Quiz State
  String? _rapidSubjectId;
  String _rapidExamMode = 'all'; // 'all', 'in_sem', 'end_sem'

  // Quiz Builder State
  String? _quizSubjectId;
  int _quizUnitNumber = 1;
  int _questionCount = 5;
  String _difficulty = 'Medium';
  bool _useAiQuiz = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final store = ref.watch(localStoreProvider);
    final profile = ref.watch(userProfileNotifierProvider);
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textPrimary = isDark ? RosePineColors.darkText : RosePineColors.dawnText;
    final textSubtle = isDark ? RosePineColors.darkSubtle : RosePineColors.dawnSubtle;
    final irisAccent = isDark ? RosePineColors.darkIris : RosePineColors.dawnIris;
    final loveAccent = isDark ? RosePineColors.darkLove : RosePineColors.dawnLove;

    final semSubjects = store.subjects
        .where((s) => s.semester == profile.semester && !s.isExcluded)
        .toList();

    String? currentQuizSub = _quizSubjectId;
    if (currentQuizSub == null || !semSubjects.any((s) => s.id == currentQuizSub)) {
      currentQuizSub = semSubjects.isNotEmpty ? semSubjects.first.id : null;
    }

    String? currentRapidSub = _rapidSubjectId;
    if (currentRapidSub == null || !semSubjects.any((s) => s.id == currentRapidSub)) {
      currentRapidSub = semSubjects.isNotEmpty ? semSubjects.first.id : null;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tests & Diagnostics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book_rounded),
            tooltip: 'SPPU FE Syllabus Tree',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SyllabusScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              // Top Segmented Switcher (Quiz Section vs PYQ Papers)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? RosePineColors.darkSurface : RosePineColors.dawnSurface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _TopTab(
                        label: '⚡ Concept Quiz',
                        isSelected: _selectedTab == 0,
                        onTap: () => setState(() => _selectedTab = 0),
                      ),
                    ),
                    Expanded(
                      child: _TopTab(
                        label: '📜 SPPU PYQ Papers',
                        isSelected: _selectedTab == 1,
                        onTap: () => setState(() => _selectedTab = 1),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              if (_selectedTab == 0) ...[
                // QUIZ SECTION (Prominent, Vibrant, Interactive)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryColor.withValues(alpha: isDark ? 0.3 : 0.18),
                        irisAccent.withValues(alpha: isDark ? 0.25 : 0.12),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: primaryColor.withValues(alpha: 0.35), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.25),
                              shape: BoxShape.circle,
                            ),
                            child: const Text('🎯', style: TextStyle(fontSize: 22)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Daily Flash Quiz Challenge',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryColor),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '5 rapid questions testing routine concepts. Real-time timer with time-trap detection.',
                                  style: TextStyle(fontSize: 12, color: textSubtle, height: 1.3),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Rapid Quiz Subject Selector
                      DropdownButtonFormField<String>(
                        initialValue: currentRapidSub,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Choose Subject for Rapid Quiz',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          filled: true,
                          fillColor: isDark ? RosePineColors.darkSurface.withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.7),
                        ),
                        items: semSubjects.map((s) {
                          return DropdownMenuItem(
                            value: s.id,
                            child: Text('${s.emoji} ${s.name}', overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _rapidSubjectId = val);
                        },
                      ),

                      const SizedBox(height: 10),

                      // Rapid Quiz Mode Selector
                      Row(
                        children: [
                          Text('Syllabus Scope: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textSubtle)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  ChoiceChip(
                                    label: const Text('All Units'),
                                    selected: _rapidExamMode == 'all',
                                    selectedColor: primaryColor.withValues(alpha: 0.3),
                                    onSelected: (_) => setState(() => _rapidExamMode = 'all'),
                                  ),
                                  const SizedBox(width: 6),
                                  ChoiceChip(
                                    label: const Text('In-Sem (U1-2)'),
                                    selected: _rapidExamMode == 'in_sem',
                                    selectedColor: primaryColor.withValues(alpha: 0.3),
                                    onSelected: (_) => setState(() => _rapidExamMode = 'in_sem'),
                                  ),
                                  const SizedBox(width: 6),
                                  ChoiceChip(
                                    label: const Text('End-Sem (U3-5)'),
                                    selected: _rapidExamMode == 'end_sem',
                                    selectedColor: primaryColor.withValues(alpha: 0.3),
                                    onSelected: (_) => setState(() => _rapidExamMode = 'end_sem'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      ElevatedButton.icon(
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Start Rapid Quiz Now (5 Questions)', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(46),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () {
                          if (semSubjects.isEmpty) {
                             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No subjects available for this semester')));
                             return;
                          }
                          final sub = semSubjects.firstWhere((s) => s.id == currentRapidSub, orElse: () => semSubjects.first);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => QuizScreen(
                                subject: sub,
                                examMode: _rapidExamMode,
                                questionCount: 5,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Custom Quiz Builder
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: irisAccent.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.psychology_rounded, color: irisAccent, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Custom Topic Quiz Builder',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: textPrimary),
                                  ),
                                  Text(
                                    'Select subject, unit and questions count for focused practice',
                                    style: TextStyle(fontSize: 12, color: textSubtle),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Subject Selector
                        Text('Choose Subject:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: currentQuizSub,
                          isExpanded: true,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                          items: semSubjects.map((s) {
                            return DropdownMenuItem(
                              value: s.id,
                              child: Text('${s.emoji} ${s.name}', overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _quizSubjectId = val);
                          },
                        ),

                        const SizedBox(height: 16),

                        // Unit Selector
                        Text('Target Unit:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary)),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [1, 2, 3, 4, 5].map((u) {
                            final isSel = _quizUnitNumber == u;
                            return ChoiceChip(
                              label: Text('Unit $u'),
                              selected: isSel,
                              selectedColor: irisAccent.withValues(alpha: 0.25),
                              onSelected: (_) => setState(() => _quizUnitNumber = u),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 16),

                        // Questions Count
                        Text('Question Count:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary)),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [5, 10, 15].map((count) {
                            final isSel = _questionCount == count;
                            return ChoiceChip(
                              label: Text('$count Questions'),
                              selected: isSel,
                              selectedColor: primaryColor.withValues(alpha: 0.25),
                              onSelected: (_) => setState(() => _questionCount = count),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 16),

                        // Difficulty
                        Text('Difficulty Level:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary)),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: ['Easy', 'Medium', 'Hard'].map((diff) {
                            final isSel = _difficulty == diff;
                            return ChoiceChip(
                              label: Text(diff),
                              selected: isSel,
                              selectedColor: primaryColor.withValues(alpha: 0.25),
                              onSelected: (_) => setState(() => _difficulty = diff),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 16),

                        // Question Source (Premade vs AI)
                        Text('Question Source:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: ChoiceChip(
                                label: const Center(child: Text('📚 Official SPPU Bank', style: TextStyle(fontSize: 12))),
                                selected: !_useAiQuiz,
                                selectedColor: irisAccent.withValues(alpha: 0.25),
                                onSelected: (_) => setState(() => _useAiQuiz = false),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ChoiceChip(
                                label: const Center(child: Text('✨ AI Generated', style: TextStyle(fontSize: 12))),
                                selected: _useAiQuiz,
                                selectedColor: primaryColor.withValues(alpha: 0.25),
                                onSelected: (_) => setState(() => _useAiQuiz = true),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Launch Custom Quiz Button
                        ElevatedButton.icon(
                          icon: Icon(_useAiQuiz ? Icons.auto_awesome_rounded : Icons.rocket_launch_rounded),
                          label: Text(_useAiQuiz ? 'Generate AI Quiz' : 'Start Premade Quiz', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _useAiQuiz ? primaryColor : irisAccent,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () {
                            final subject = semSubjects.firstWhere(
                              (s) => s.id == _quizSubjectId,
                              orElse: () => semSubjects.first,
                            );
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => QuizScreen(
                                  subject: subject,
                                  targetUnitNumber: _quizUnitNumber,
                                  questionCount: _questionCount,
                                  difficulty: _difficulty,
                                  useAi: _useAiQuiz,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                // SPPU PYQ PAPERS SECTION
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        irisAccent.withValues(alpha: isDark ? 0.25 : 0.15),
                        primaryColor.withValues(alpha: isDark ? 0.2 : 0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: irisAccent.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.timer_outlined, color: irisAccent, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'Intelligent Time Diagnostic',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: irisAccent),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Questions are analyzed based on length & calculation depth. Spending 2-5 mins is normal, but taking 5-10+ mins marks the concept as a "Time Trap" needing focused revision.',
                        style: TextStyle(fontSize: 12, color: textSubtle, height: 1.35),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  'Select Subject for PYQ Papers',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
                ),
                const SizedBox(height: 12),

                if (semSubjects.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text('Loading SPPU syllabus subjects...', style: TextStyle(color: textSubtle)),
                    ),
                  )
                else
                  ...semSubjects.map((subject) {
                    final isWeak = profile.hardSubjects.contains(subject.id);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () => _showSubjectPyqOptions(context, subject),
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
                                        if (isWeak)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: loveAccent.withValues(alpha: 0.18),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: loveAccent.withValues(alpha: 0.3)),
                                            ),
                                            child: Text(
                                              'Focus Needed',
                                              style: TextStyle(fontSize: 10, color: loveAccent, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${subject.units.length} Units · ${subject.teachingHours} Syllabus Hrs',
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
                    );
                  }),
              ],

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  void _showSubjectPyqOptions(BuildContext context, Subject subject) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textPrimary = isDark ? RosePineColors.darkText : RosePineColors.dawnText;
    final textSubtle = isDark ? RosePineColors.darkSubtle : RosePineColors.dawnSubtle;
    final irisAccent = isDark ? RosePineColors.darkIris : RosePineColors.dawnIris;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(subject.emoji, style: const TextStyle(fontSize: 26)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subject.name,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textPrimary),
                          ),
                          Text('SPPU 2024 Revised Pattern', style: TextStyle(fontSize: 12, color: textSubtle)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.timer_rounded, color: primaryColor),
                  ),
                  title: const Text('Timed Practice Test', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Live countdown with Time-Trap diagnostic analysis'),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => QuizScreen(subject: subject)),
                    );
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: irisAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.menu_book_rounded, color: irisAccent),
                  ),
                  title: const Text('Browse Past Papers & Solutions', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Explore unit-by-unit questions, solutions, and marking hints'),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => PYQViewerScreen(subject: subject)),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TopTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TopTab({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : null,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
