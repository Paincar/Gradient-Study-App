import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/gemini_service.dart';
import '../../core/theme/rose_pine_theme.dart';
import '../../data/datasources/local_store.dart';
import '../../providers.dart';
import '../common/responsive_wrapper.dart';
import '../settings/settings_screen.dart';

class ChatMessage {
  final String id;
  final String sender; // 'user' or 'ai'
  final String text;
  final DateTime timestamp;
  final bool isSchedulePlan;
  final int? planDays;
  final String? planType; // 'end_sem', 'holidays', 'missed'

  ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.timestamp,
    this.isSchedulePlan = false,
    this.planDays,
    this.planType,
  });
}

class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _messages.add(
      ChatMessage(
        id: 'welcome',
        sender: 'ai',
        text: '👋 **Hello! I am your SPPU AI Tutor & Study Strategist.**\n\nI can help you prepare customized study plans, explain complex syllabus topics, solve doubts, and automatically adjust your timetable schedule.\n\nTry asking me one of the quick actions below! 👇',
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text, {int? planDays, String? planType}) async {
    final query = text.trim();
    if (query.isEmpty) return;

    _controller.clear();

    final userMsg = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      sender: 'user',
      text: query,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final store = ref.read(localStoreProvider);
      final profile = ref.read(userProfileNotifierProvider);
      final activeSubjects = store.subjects.where((s) => s.semester == profile.semester && !s.isExcluded).toList();

      // Detect if user is asking for End-Sem, holiday, or missed session plan
      final lower = query.toLowerCase();
      int? detectedDays = planDays;
      String? detectedType = planType;

      if (detectedType == null) {
        if (lower.contains('end sem') || lower.contains('end-sem')) {
          detectedType = 'end_sem';
          final match = RegExp(r'(\d+)\s*days?').firstMatch(lower);
          detectedDays = match != null ? int.tryParse(match.group(1)!) ?? 15 : 15;
        } else if (lower.contains('holiday')) {
          detectedType = 'holidays';
        } else if (lower.contains('missed') || lower.contains('catch up')) {
          detectedType = 'missed';
        }
      }

      final history = _messages.take(_messages.length - 1).map((m) => {
        'role': m.sender == 'user' ? 'user' : 'model',
        'content': m.text,
      }).toList();

      final responseText = await GeminiService.chat(
        prompt: query,
        profile: profile,
        apiKey: store.geminiApiKey,
        history: history,
        subjects: activeSubjects,
      );

      final isScheduleAction = detectedType != null;

      final aiMsg = ChatMessage(
        id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
        sender: 'ai',
        text: responseText,
        timestamp: DateTime.now(),
        isSchedulePlan: isScheduleAction,
        planDays: detectedDays,
        planType: detectedType,
      );

      if (mounted) {
        setState(() {
          _messages.add(aiMsg);
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              id: 'err_${DateTime.now().millisecondsSinceEpoch}',
              sender: 'ai',
              text: '⚠️ An error occurred while generating your response: $e',
              timestamp: DateTime.now(),
            ),
          );
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  Future<void> _applySchedulePlan(ChatMessage message) async {
    final notifier = ref.read(timetableNotifierProvider.notifier);
    int affected = 0;

    if (message.planType == 'end_sem') {
      final days = message.planDays ?? 15;
      affected = await notifier.applyAiEndSemPlan(days);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: RosePineColors.dawnFoam,
            content: Text('✨ End-Sem plan applied! $affected study slots scheduled & weighted for Units 3-6.'),
          ),
        );
      }
    } else if (message.planType == 'holidays') {
      affected = await notifier.shiftScheduleForHolidays();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: RosePineColors.dawnIris,
            content: Text('✨ Holiday shift applied! $affected study slots moved to open weekdays.'),
          ),
        );
      }
    } else if (message.planType == 'missed') {
      affected = await notifier.rescheduleMissedSlotsToWeekdays();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: RosePineColors.dawnPine,
            content: Text('✨ Catch-up complete! $affected missed slots placed on upcoming weekdays.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textPrimary = isDark ? RosePineColors.darkText : RosePineColors.dawnText;
    final textSubtle = isDark ? RosePineColors.darkSubtle : RosePineColors.dawnSubtle;
    final irisAccent = isDark ? RosePineColors.darkIris : RosePineColors.dawnIris;
    final surfaceColor = isDark ? RosePineColors.darkSurface : Colors.white;

    final profile = ref.watch(userProfileNotifierProvider);
    final isLocalModel = profile.customOpenAiBaseUrl.isNotEmpty;
    final modelLabel = isLocalModel
        ? 'Local LLM (${profile.customOpenAiModel.isNotEmpty ? profile.customOpenAiModel : "llama3"})'
        : 'Gemini 2.5 Flash';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: RosePineColors.dawnIris, size: 20),
                SizedBox(width: 8),
                Text('Gradient AI Tutor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            Text('SPPU 2024 Syllabus & Strategy Engine', style: TextStyle(fontSize: 11, color: textSubtle)),
          ],
        ),
        actions: [
          Tooltip(
            message: modelLabel,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isLocalModel ? Colors.purple.withValues(alpha: 0.15) : primaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: (isLocalModel ? Colors.purple : primaryColor).withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(isLocalModel ? Icons.memory_rounded : Icons.bolt_rounded, size: 14, color: isLocalModel ? Colors.purple : primaryColor),
                  const SizedBox(width: 4),
                  Text(
                    isLocalModel ? 'Local' : 'Gemini',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isLocalModel ? Colors.purple : primaryColor),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Configure AI Model & Keys',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          child: Column(
            children: [
              // Quick Prompt Suggestion Chips
              Container(
                height: 44,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _QuickChip(
                      label: '🎯 End-Sem in 15 days',
                      onTap: () => _sendMessage('Make a study plan for End-Sem exam in 15 days', planDays: 15, planType: 'end_sem'),
                    ),
                    _QuickChip(
                      label: '🎯 End-Sem in 30 days',
                      onTap: () => _sendMessage('Make a study plan for End-Sem exam in 30 days', planDays: 30, planType: 'end_sem'),
                    ),
                    _QuickChip(
                      label: '🏖️ Shift for Holidays',
                      onTap: () => _sendMessage('Adjust my study schedule for upcoming holidays', planType: 'holidays'),
                    ),
                    _QuickChip(
                      label: '🔄 Reschedule Missed Timers',
                      onTap: () => _sendMessage('I missed some study sessions. Reschedule them to weekdays.', planType: 'missed'),
                    ),
                    _QuickChip(
                      label: '💡 M1 Leibnitz Theorem',
                      onTap: () => _sendMessage('Explain Leibnitz Theorem for M1 with SPPU PYQ examples'),
                    ),
                    _QuickChip(
                      label: '⚡ Mechanics PYQs',
                      onTap: () => _sendMessage('What are the high-weightage PYQ topics for Engineering Mechanics?'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Chat Messages Thread
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    final isUser = msg.sender == 'user';

                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.82,
                        ),
                        child: Column(
                          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isUser
                                    ? primaryColor
                                    : (isDark ? RosePineColors.darkSurface : Colors.grey.shade100),
                                borderRadius: BorderRadius.circular(18).copyWith(
                                  bottomRight: isUser ? const Radius.circular(2) : const Radius.circular(18),
                                  bottomLeft: !isUser ? const Radius.circular(2) : const Radius.circular(18),
                                ),
                                border: isUser
                                    ? null
                                    : Border.all(
                                        color: isDark ? RosePineColors.darkOverlay : Colors.grey.shade300,
                                      ),
                              ),
                              child: Text(
                                msg.text,
                                style: TextStyle(
                                  color: isUser ? Colors.white : textPrimary,
                                  fontSize: 13.5,
                                  height: 1.45,
                                ),
                              ),
                            ),

                            // Action Card if AI proposed schedule change
                            if (msg.isSchedulePlan) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: irisAccent.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: irisAccent.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.calendar_month_rounded, color: irisAccent, size: 22),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            msg.planType == 'end_sem'
                                                ? 'End-Sem Study Plan (${msg.planDays ?? 15} Days)'
                                                : (msg.planType == 'holidays' ? 'Holiday Schedule Shift' : 'Weekday Catch-up'),
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: textPrimary),
                                          ),
                                          Text(
                                            'One-tap to update your in-app timetable slots.',
                                            style: TextStyle(fontSize: 11, color: textSubtle),
                                          ),
                                        ],
                                      ),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: irisAccent,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        minimumSize: Size.zero,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      onPressed: () => _applySchedulePlan(msg),
                                      child: const Text('Apply Plan', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              if (_isLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor),
                      ),
                      const SizedBox(width: 8),
                      Text('Gradient AI is thinking...', style: TextStyle(fontSize: 12, color: textSubtle)),
                    ],
                  ),
                ),

              // Bottom Input Bar
              Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  border: Border(
                    top: BorderSide(
                      color: isDark ? RosePineColors.darkOverlay : Colors.grey.shade200,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (val) => _sendMessage(val),
                        decoration: InputDecoration(
                          hintText: 'Ask doubt or say "Plan End-Sem in 20 days"...',
                          hintStyle: TextStyle(fontSize: 13, color: textSubtle),
                          filled: true,
                          fillColor: isDark ? RosePineColors.darkOverlay : Colors.grey.shade100,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white),
                        onPressed: () => _sendMessage(_controller.text),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
        backgroundColor: isDark ? RosePineColors.darkSurface : Colors.grey.shade100,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: isDark ? RosePineColors.darkOverlay : Colors.grey.shade300),
        ),
        onPressed: onTap,
      ),
    );
  }
}
