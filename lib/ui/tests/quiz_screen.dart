import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/rose_pine_theme.dart';
import '../../data/datasources/local_store.dart';
import '../../data/models/models.dart';
import '../../core/services/gemini_service.dart';
import '../../providers.dart';
import 'quiz_result_screen.dart';

class QuizScreen extends ConsumerStatefulWidget {
  final Subject subject;
  final int? targetUnitNumber;
  final int? questionCount;
  final String? examMode; // 'all', 'in_sem' (units 1-2), 'end_sem' (units 3-5)
  final String? difficulty;
  final bool useAi;

  const QuizScreen({
    super.key,
    required this.subject,
    this.targetUnitNumber,
    this.questionCount,
    this.examMode,
    this.difficulty,
    this.useAi = false,
  });

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  int _currentQuestionIndex = 0;
  int? _selectedOption;
  int _score = 0;

  Timer? _timer;
  int _questionSeconds = 0;
  final List<Map<String, dynamic>> _history = [];
  
  late List<Question> _questions = [];
  late List<List<int>> _shuffledOptionsMap = [];
  bool _isLoading = true;
  String _errorMsg = '';

  @override
  void initState() {
    super.initState();
    if (widget.useAi) {
      _loadAiQuiz();
    } else {
      _loadPremadeQuiz();
    }
  }

  void _loadPremadeQuiz() {
    try {
      final store = ref.read(localStoreProvider);
      var pool = store.getQuestionsForSubject(widget.subject.id);

      if (pool.isEmpty) {
        pool = store.questions;
      }

      if (widget.targetUnitNumber != null) {
        final unitPool = pool.where((q) => q.unitNumber == widget.targetUnitNumber).toList();
        if (unitPool.isNotEmpty) pool = unitPool;
      }

      if (widget.examMode == 'in_sem') {
        final inSemPool = pool.where((q) => q.unitNumber <= 2).toList();
        if (inSemPool.isNotEmpty) pool = inSemPool;
      } else if (widget.examMode == 'end_sem') {
        final endSemPool = pool.where((q) => q.unitNumber >= 3).toList();
        if (endSemPool.isNotEmpty) pool = endSemPool;
      }

      if (widget.difficulty != null) {
        final diffPool = pool.where((q) => q.difficulty.toLowerCase() == widget.difficulty!.toLowerCase()).toList();
        if (diffPool.isNotEmpty) pool = diffPool;
      }

      final shuffledPool = List<Question>.from(pool)..shuffle();
      final limit = (widget.questionCount ?? 5).clamp(1, shuffledPool.isNotEmpty ? shuffledPool.length : 1);
      final selected = shuffledPool.take(limit).toList();

      if (selected.isEmpty) {
        setState(() {
          _errorMsg = 'No questions available for ${widget.subject.name}.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _questions = selected;
        _shuffledOptionsMap = _questions.map((q) {
          final list = List.generate(q.options.length, (i) => i);
          list.shuffle();
          return list;
        }).toList();
        _isLoading = false;
        _startTimer();
      });
    } catch (e) {
      setState(() {
        _errorMsg = 'Error loading questions: $e';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _loadAiQuiz() async {
    try {
      final store = ref.read(localStoreProvider);
      final profile = ref.read(userProfileNotifierProvider);
      final countLimit = widget.questionCount ?? 5;
      
      final generated = await GeminiService.generateQuiz(
        subject: widget.subject,
        targetUnitNumber: widget.targetUnitNumber,
        profile: profile,
        apiKey: store.geminiApiKey,
        count: countLimit,
      );

      if (mounted) {
        if (generated.isEmpty) {
          _loadPremadeQuiz();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚡ AI offline or busy — loaded official SPPU premade questions!'),
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          setState(() {
            _questions = generated;
            _shuffledOptionsMap = _questions.map((q) {
              final list = List.generate(q.options.length, (i) => i);
              list.shuffle();
              return list;
            }).toList();
            _isLoading = false;
            _startTimer();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        _loadPremadeQuiz();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚡ AI error — loaded official SPPU premade questions! ($e)'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _questionSeconds = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _questionSeconds++);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool _hasSubmitted = false;

  QuestionTimeStatus _getTimeStatus(int normalSeconds, int actualSeconds) {
    if (actualSeconds <= normalSeconds + 120) {
      return QuestionTimeStatus.normal; // Within 2 mins of normal
    } else if (actualSeconds <= normalSeconds + 300) {
      return QuestionTimeStatus.needsWork; // 2-5 mins over normal
    } else {
      return QuestionTimeStatus.timeTrap; // > 5 mins over normal
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = ref.watch(userProfileNotifierProvider);
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textPrimary = isDark ? RosePineColors.darkText : RosePineColors.dawnText;
    final textSubtle = isDark ? RosePineColors.darkSubtle : RosePineColors.dawnSubtle;
    final loveAccent = isDark ? RosePineColors.darkLove : RosePineColors.dawnLove;
    final goldAccent = isDark ? RosePineColors.darkGold : RosePineColors.dawnGold;
    final foamAccent = isDark ? RosePineColors.darkFoam : RosePineColors.dawnFoam;

    String appTitle = '${widget.subject.name} Practice';
    if (widget.targetUnitNumber != null) {
      appTitle = '${widget.subject.name} · Unit ${widget.targetUnitNumber}';
    } else if (widget.examMode == 'in_sem') {
      appTitle = '${widget.subject.name} · In-Sem Prep';
    } else if (widget.examMode == 'end_sem') {
      appTitle = '${widget.subject.name} · End-Sem Prep';
    }

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(appTitle)),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('Generating AI Quiz using SPPU PYQs...', style: TextStyle(color: textPrimary, fontSize: 16)),
            ],
          ),
        ),
      );
    }

    if (_errorMsg.isNotEmpty || _questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(appTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(_errorMsg.isNotEmpty ? _errorMsg : 'No questions generated.', textAlign: TextAlign.center),
          ),
        ),
      );
    }

    final question = _questions[_currentQuestionIndex % _questions.length];
    final isLast = _currentQuestionIndex >= _questions.length - 1;
    final timeStatus = _getTimeStatus(question.normalTimeSeconds, _questionSeconds);

    final timerMin = (_questionSeconds ~/ 60).toString().padLeft(2, '0');
    final timerSec = (_questionSeconds % 60).toString().padLeft(2, '0');

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            title: const Text('Quit Quiz?'),
            content: const Text('Your current progress will be lost. Are you sure you want to quit?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogCtx, true),
                child: const Text('Quit'),
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
          title: Text(appTitle),
        ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress and Live Timer Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Q ${_currentQuestionIndex + 1} of ${_questions.length}',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textSubtle),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (timeStatus == QuestionTimeStatus.timeTrap
                              ? loveAccent
                              : timeStatus == QuestionTimeStatus.needsWork
                                  ? goldAccent
                                  : foamAccent)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.timer_rounded,
                          size: 14,
                          color: (timeStatus == QuestionTimeStatus.timeTrap
                              ? loveAccent
                              : timeStatus == QuestionTimeStatus.needsWork
                                  ? goldAccent
                                  : foamAccent),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$timerMin:$timerSec',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: (timeStatus == QuestionTimeStatus.timeTrap
                                ? loveAccent
                                : timeStatus == QuestionTimeStatus.needsWork
                                    ? goldAccent
                                    : foamAccent),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          timeStatus == QuestionTimeStatus.timeTrap
                              ? '(Time Trap!)'
                              : timeStatus == QuestionTimeStatus.needsWork
                                  ? '(Needs Work)'
                                  : '(Normal)',
                          style: TextStyle(
                            fontSize: 10,
                            color: (timeStatus == QuestionTimeStatus.timeTrap
                                ? loveAccent
                                : timeStatus == QuestionTimeStatus.needsWork
                                    ? goldAccent
                                    : foamAccent),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                children: [
                  // Unit & Topic Tag
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Unit ${question.unitNumber} · ${question.topic}',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryColor),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${question.exam} (${question.year})',
                        style: TextStyle(fontSize: 11, color: textSubtle),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Question Text
                  Text(
                    question.questionText,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, height: 1.4, color: textPrimary),
                  ),

                  const SizedBox(height: 20),

                  // Options List
                  ...List.generate(question.options.length, (uiIdx) {
                    final realIdx = _shuffledOptionsMap[_currentQuestionIndex][uiIdx];
                    final opt = question.options[realIdx];
                    final isSelected = _selectedOption == realIdx;
                    final isCorrect = question.correctOption == realIdx;

                    Color optBorder = isDark ? RosePineColors.darkOverlay : RosePineColors.dawnOverlay;
                    Color optBg = isDark ? RosePineColors.darkSurface : RosePineColors.dawnSurface;

                    if (_hasSubmitted) {
                      if (isCorrect) {
                        optBorder = foamAccent;
                        optBg = foamAccent.withValues(alpha: 0.15);
                      } else if (isSelected && !isCorrect) {
                        optBorder = loveAccent;
                        optBg = loveAccent.withValues(alpha: 0.15);
                      }
                    } else if (isSelected) {
                      optBorder = primaryColor;
                      optBg = primaryColor.withValues(alpha: 0.12);
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: optBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: optBorder, width: isSelected || (_hasSubmitted && isCorrect) ? 2 : 1),
                      ),
                      child: InkWell(
                        onTap: _hasSubmitted
                            ? null
                            : () {
                                setState(() => _selectedOption = realIdx);
                              },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected ? primaryColor : Colors.transparent,
                                  border: Border.all(color: isSelected ? primaryColor : textSubtle, width: 1.5),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  String.fromCharCode(65 + uiIdx), // A, B, C, D
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: isSelected ? Colors.white : textSubtle,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  opt,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                  // Detailed Solution / Vocabulary-adjusted explanation
                  if (_hasSubmitted) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: isDark ? 0.15 : 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.lightbulb_outline_rounded, color: primaryColor, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                'Explanation (${profile.vocabularyLevel} Vocabulary)',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primaryColor),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            question.explanation,
                            style: TextStyle(fontSize: 13, color: textPrimary, height: 1.35),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Bottom Submit / Next Button
            Padding(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton(
                onPressed: _selectedOption == null
                    ? null
                    : () {
                        if (!_hasSubmitted) {
                          // Submit
                          setState(() {
                            _hasSubmitted = true;
                            _timer?.cancel();
                            if (_selectedOption == question.correctOption) {
                              _score++;
                            }
                            _history.add({
                              'topic': question.topic,
                              'timeSeconds': _questionSeconds,
                              'isCorrect': _selectedOption == question.correctOption,
                              'status': timeStatus,
                            });
                          });
                        } else {
                          // Next or Finish
                          if (isLast) {
                            _showResultDialog(context, _questions.length, _questions);
                          } else {
                            setState(() {
                              _currentQuestionIndex++;
                              _selectedOption = null;
                              _hasSubmitted = false;
                            });
                            _startTimer();
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                child: Text(
                  !_hasSubmitted
                      ? 'Submit Answer'
                      : (isLast ? 'View Test Analysis' : 'Next Question'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
      ), // Close PopScope
    );
  }

  void _showResultDialog(BuildContext context, int total, List<Question> questions) {
    final totalTime = _history.fold<int>(
      0,
      (sum, item) => sum + (item['timeSeconds'] as int? ?? 0),
    );

    // Persist study time for analytics and streak
    if (totalTime > 0) {
      ref.read(localStoreProvider).logStudyTime(widget.subject.id, (totalTime / 60).ceil());
    }

    // Automatically record unit mastery for AI Tutor & Timetable adaptation (PS1 closing loop)
    final targetUnit = widget.targetUnitNumber ?? (questions.isNotEmpty ? questions.first.unitNumber : 1);
    ref.read(userProfileNotifierProvider.notifier).recordQuizMastery(
      subjectId: widget.subject.id,
      unitNumber: targetUnit,
      score: _score,
      total: total,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => QuizResultScreen(
          subject: widget.subject,
          score: _score,
          total: total,
          totalTimeSeconds: totalTime,
          questionAnalytics: _history,
          questions: questions,
          onRetake: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => QuizScreen(
                  subject: widget.subject,
                  targetUnitNumber: widget.targetUnitNumber,
                  questionCount: widget.questionCount,
                  examMode: widget.examMode,
                  difficulty: widget.difficulty,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
