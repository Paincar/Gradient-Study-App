import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/rose_pine_theme.dart';
import '../../data/datasources/local_store.dart';
import '../../data/models/models.dart';
import '../../providers.dart';
import 'quiz_screen.dart';

class PYQViewerScreen extends ConsumerStatefulWidget {
  final Subject subject;

  const PYQViewerScreen({super.key, required this.subject});

  @override
  ConsumerState<PYQViewerScreen> createState() => _PYQViewerScreenState();
}

class _PYQViewerScreenState extends ConsumerState<PYQViewerScreen> {
  int _selectedUnit = 0; // 0 = All units

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textPrimary = isDark ? RosePineColors.darkText : RosePineColors.dawnText;
    final textSubtle = isDark ? RosePineColors.darkSubtle : RosePineColors.dawnSubtle;
    final foamAccent = isDark ? RosePineColors.darkFoam : RosePineColors.dawnFoam;
    final irisAccent = isDark ? RosePineColors.darkIris : RosePineColors.dawnIris;
    final store = ref.watch(localStoreProvider);

    final allQuestions = store.questions.where((q) => q.subjectId == widget.subject.id).toList();
    final questions = _selectedUnit == 0
        ? allQuestions
        : allQuestions.where((q) => q.unitNumber == _selectedUnit).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.subject.name} PYQs'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.timer_outlined, size: 18),
            label: const Text('Practice', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => QuizScreen(subject: widget.subject),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Unit Filter Bar
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _FilterChip(
                    label: 'All Units (${allQuestions.length})',
                    isSelected: _selectedUnit == 0,
                    onTap: () => setState(() => _selectedUnit = 0),
                  ),
                  for (int u = 1; u <= 5; u++)
                    _FilterChip(
                      label: 'Unit $u (${allQuestions.where((q) => q.unitNumber == u).length})',
                      isSelected: _selectedUnit == u,
                      onTap: () => setState(() => _selectedUnit = u),
                    ),
                ],
              ),
            ),

            // Question List
            Expanded(
              child: questions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.menu_book_rounded, size: 48, color: textSubtle.withValues(alpha: 0.3)),
                          const SizedBox(height: 12),
                          Text(
                            'No questions available for Unit $_selectedUnit yet.',
                            style: TextStyle(color: textSubtle, fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      itemCount: questions.length,
                      itemBuilder: (ctx, idx) {
                        final q = questions[idx];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isDark ? RosePineColors.darkOverlay : RosePineColors.dawnOverlay,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Exam & Unit Tags
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: primaryColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Unit ${q.unitNumber} · ${q.topic}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: primaryColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: irisAccent.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${q.exam} ${q.year}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: irisAccent,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Row(
                                      children: [
                                        Icon(Icons.access_time_rounded, size: 14, color: textSubtle),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${q.normalTimeSeconds}s',
                                          style: TextStyle(fontSize: 11, color: textSubtle, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 12),

                                // Question Text
                                Text(
                                  'Q${idx + 1}. ${q.questionText}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: textPrimary,
                                    height: 1.35,
                                  ),
                                ),

                                const SizedBox(height: 12),

                                // Options
                                ...List.generate(q.options.length, (optIdx) {
                                  final isAnswer = optIdx == q.correctOption;
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 6),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isAnswer
                                          ? foamAccent.withValues(alpha: isDark ? 0.2 : 0.12)
                                          : (isDark ? RosePineColors.darkSurface : Colors.white),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isAnswer
                                            ? foamAccent.withValues(alpha: 0.5)
                                            : (isDark ? RosePineColors.darkOverlay : RosePineColors.dawnOverlay),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          '${String.fromCharCode(65 + optIdx)}) ',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: isAnswer ? foamAccent : textSubtle,
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            q.options[optIdx],
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: isAnswer ? FontWeight.bold : FontWeight.normal,
                                              color: textPrimary,
                                            ),
                                          ),
                                        ),
                                        if (isAnswer)
                                          Icon(Icons.check_circle_rounded, size: 16, color: foamAccent),
                                      ],
                                    ),
                                  );
                                }),

                                const SizedBox(height: 12),

                                // Explanation Box
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: (isDark ? RosePineColors.darkSurface : RosePineColors.dawnSurface),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.lightbulb_outline_rounded, size: 16, color: primaryColor),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Official Solution & Concept',
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        q.explanation,
                                        style: TextStyle(fontSize: 12, color: textSubtle, height: 1.4),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 10),

                                // Save to Notes Button
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    icon: const Icon(Icons.bookmark_add_outlined, size: 16),
                                    label: const Text('Save to Notes 📝', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    onPressed: () {
                                      ref.read(notesNotifierProvider.notifier).addNote(
                                            NoteItem(
                                              id: 'pyq_${q.id}_${DateTime.now().millisecondsSinceEpoch}',
                                              title: '${widget.subject.name} PYQ: ${q.topic}',
                                              content: '${q.questionText}\n\nCorrect Answer: ${q.options[q.correctOption]}\n\nSolution:\n${q.explanation}',
                                              subjectId: widget.subject.id,
                                              subjectName: widget.subject.name,
                                              updatedAt: DateTime.now(),
                                            ),
                                          );
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('✨ Saved into ${widget.subject.name} notes!'),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: primary.withValues(alpha: 0.2),
        checkmarkColor: primary,
        backgroundColor: isDark ? RosePineColors.darkSurface : RosePineColors.dawnSurface,
        onSelected: (_) => onTap(),
      ),
    );
  }
}
