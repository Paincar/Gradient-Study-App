import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/cloud_sync_service.dart';
import '../../core/services/gemini_service.dart';
import '../../core/theme/rose_pine_theme.dart';
import '../../data/datasources/local_store.dart';
import '../../data/models/models.dart';
import '../../providers.dart';
import '../common/responsive_wrapper.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  final NoteItem? existingNote;
  final String? initialSubjectId;

  const NoteEditorScreen({
    super.key,
    this.existingNote,
    this.initialSubjectId,
  });

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late String _selectedSubjectId;
  late bool _isPinned;
  bool _isModified = false;
  bool _isAiGenerating = false;

  @override
  void initState() {
    super.initState();
    final note = widget.existingNote;
    _titleController = TextEditingController(text: note?.title ?? '');
    _contentController = TextEditingController(text: note?.content ?? '');
    _isPinned = note?.isPinned ?? false;

    final store = ref.read(localStoreProvider);
    if (note != null && note.subjectId.isNotEmpty) {
      _selectedSubjectId = note.subjectId;
    } else if (widget.initialSubjectId != null &&
        widget.initialSubjectId != 'All' &&
        widget.initialSubjectId!.isNotEmpty) {
      _selectedSubjectId = widget.initialSubjectId!;
    } else {
      _selectedSubjectId =
          store.subjects.isNotEmpty ? store.subjects.first.id : 'm1';
    }

    _titleController.addListener(_markModified);
    _contentController.addListener(_markModified);
  }

  void _markModified() {
    if (!_isModified) {
      setState(() => _isModified = true);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveNote({bool showFeedback = false}) async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty && content.isEmpty) return;

    final store = ref.read(localStoreProvider);
    final subject = store.subjects.firstWhere(
      (s) => s.id == _selectedSubjectId,
      orElse: () => Subject(
        id: _selectedSubjectId,
        name: 'General Engineering',
        code: '100000',
        emoji: '📚',
        color: '#31748f',
        semester: 1,
        teachingHours: 40,
        isExcluded: false,
        units: [],
      ),
    );

    final finalTitle = title.isEmpty ? 'Untitled Note' : title;
    final noteId = widget.existingNote?.id ?? 'note_${DateTime.now().millisecondsSinceEpoch}';

    final updatedNote = NoteItem(
      id: noteId,
      title: finalTitle,
      content: content,
      subjectId: _selectedSubjectId,
      subjectName: subject.name,
      updatedAt: DateTime.now(),
      isPinned: _isPinned,
    );

    final currentNotes = ref.read(notesNotifierProvider);
    final exists = currentNotes.any((n) => n.id == noteId);

    List<NoteItem> newList;
    if (exists) {
      newList = [
        for (final n in currentNotes)
          if (n.id == noteId) updatedNote else n
      ];
    } else {
      newList = [updatedNote, ...currentNotes];
    }

    await ref.read(notesNotifierProvider.notifier).saveNotes(newList);
    // Cloud sync to Firestore
    await CloudSyncService.instance.syncNote(updatedNote);

    if (mounted) {
      setState(() => _isModified = false);
      if (showFeedback) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✨ Note saved and synced!'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    }
  }

  void _showAiAssistantModal(BuildContext context) {
    final store = ref.read(localStoreProvider);
    final profile = ref.read(userProfileNotifierProvider);
    final primaryColor = Theme.of(context).colorScheme.primary;

    final currentSubject = store.subjects.cast<Subject?>().firstWhere(
      (s) => s?.id == _selectedSubjectId,
      orElse: () => store.subjects.isNotEmpty ? store.subjects.first : null,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.auto_awesome_rounded, color: primaryColor, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Gradient AI Note Assistant',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Grounded in SPPU 2024 Course Structure',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (_isAiGenerating)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 14),
                            Text('Generating academic insights...'),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    _buildAiOptionTile(
                      icon: Icons.summarize_rounded,
                      title: 'Summarize into SPPU Exam Revision Sheet',
                      subtitle: 'Extract key points, definitions and marking traps',
                      onTap: () async {
                        final textToAnalyze = '${_titleController.text}\n${_contentController.text}'.trim();
                        if (textToAnalyze.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please add some text in the note first.')),
                          );
                          return;
                        }
                        Navigator.pop(ctx);
                        await _runAiPrompt(
                          'Summarize these notes into a concise SPPU exam revision cheat sheet with core formulas and step marking: $textToAnalyze',
                          currentSubject,
                          profile,
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildAiOptionTile(
                      icon: Icons.functions_rounded,
                      title: 'Extract Formulas & SPPU PYQ Traps',
                      subtitle: 'Lists mathematical equations and typical numerical traps',
                      onTap: () async {
                        final textToAnalyze = '${_titleController.text}\n${_contentController.text}'.trim();
                        Navigator.pop(ctx);
                        await _runAiPrompt(
                          'Extract all mathematical formulas, constants, and SPPU question pitfalls for: $textToAnalyze',
                          currentSubject,
                          profile,
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildAiOptionTile(
                      icon: Icons.lightbulb_outline_rounded,
                      title: 'Explain in Simple Everyday Analogy',
                      subtitle: 'Transform complex engineering concept into easy intuition',
                      onTap: () async {
                        final textToAnalyze = '${_titleController.text}\n${_contentController.text}'.trim();
                        Navigator.pop(ctx);
                        await _runAiPrompt(
                          'Explain this engineering concept with an intuitive everyday real-world analogy: $textToAnalyze',
                          currentSubject,
                          profile,
                        );
                      },
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAiOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.black12,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Future<void> _runAiPrompt(String prompt, Subject? subject, UserProfile profile) async {
    setState(() => _isAiGenerating = true);
    final apiKey = ref.read(localStoreProvider).geminiApiKey;

    try {
      final response = await GeminiService.explainConcept(
        prompt: prompt,
        subject: subject,
        profile: profile,
        apiKey: apiKey,
      );

      if (mounted) {
        final currentText = _contentController.text;
        final separator = currentText.trim().isEmpty ? '' : '\n\n---\n### 💡 Gradient AI Summary:\n';
        _contentController.text = '$currentText$separator$response';
        _markModified();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✨ AI insights appended to your note!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI generation error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAiGenerating = false);
      }
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Note?'),
        content: const Text('This will delete the note from your device and the cloud.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && widget.existingNote != null) {
      final currentNotes = ref.read(notesNotifierProvider);
      final filtered = currentNotes.where((n) => n.id != widget.existingNote!.id).toList();
      await ref.read(notesNotifierProvider.notifier).saveNotes(filtered);
      await CloudSyncService.instance.deleteNote(widget.existingNote!.id);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note deleted')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final store = ref.watch(localStoreProvider);
    final textPrimary = isDark ? RosePineColors.darkText : RosePineColors.dawnText;
    final textSubtle = isDark ? RosePineColors.darkSubtle : RosePineColors.dawnSubtle;
    final primaryColor = Theme.of(context).colorScheme.primary;

    final wordCount = _contentController.text.trim().isEmpty
        ? 0
        : _contentController.text.trim().split(RegExp(r'\s+')).length;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (_isModified) {
          _saveNote();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedSubjectId,
              icon: const Icon(Icons.arrow_drop_down_rounded, size: 20),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
              items: store.subjects.map((s) {
                return DropdownMenuItem<String>(
                  value: s.id,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(s.emoji),
                      const SizedBox(width: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 160),
                        child: Text(
                          s.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedSubjectId = val;
                    _markModified();
                  });
                }
              },
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                _isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                color: _isPinned ? RosePineColors.dawnGold : null,
              ),
              tooltip: _isPinned ? 'Unpin Note' : 'Pin Note',
              onPressed: () {
                setState(() {
                  _isPinned = !_isPinned;
                  _markModified();
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.auto_awesome_rounded),
              tooltip: 'Gradient AI Assistant',
              color: primaryColor,
              onPressed: () => _showAiAssistantModal(context),
            ),
            if (widget.existingNote != null)
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                tooltip: 'Delete Note',
                onPressed: _confirmDelete,
              ),
            IconButton(
              icon: const Icon(Icons.check_rounded),
              tooltip: 'Save',
              onPressed: () => _saveNote(showFeedback: true),
            ),
          ],
        ),
        body: SafeArea(
          child: ResponsiveContainer(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    children: [
                      // Title input
                      TextField(
                        controller: _titleController,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Note Title...',
                          hintStyle: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: textSubtle.withValues(alpha: 0.6),
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Divider(color: (isDark ? Colors.white12 : Colors.black12)),
                      const SizedBox(height: 12),
                      // Content input
                      TextField(
                        controller: _contentController,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        style: TextStyle(
                          fontSize: 15.5,
                          height: 1.6,
                          color: textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Start writing your SPPU study notes, derivations, formulas, or key definitions...',
                          hintStyle: TextStyle(
                            fontSize: 15,
                            height: 1.6,
                            color: textSubtle.withValues(alpha: 0.5),
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ),
                // Footer Status Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? RosePineColors.darkSurface : RosePineColors.dawnSurface,
                    border: Border(
                      top: BorderSide(
                        color: isDark ? Colors.white10 : Colors.black12,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '$wordCount ${wordCount == 1 ? "word" : "words"}',
                        style: TextStyle(fontSize: 12, color: textSubtle),
                      ),
                      const Spacer(),
                      if (_isModified)
                        Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: Colors.orangeAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text('Unsaved edits', style: TextStyle(fontSize: 11.5, color: textSubtle)),
                          ],
                        )
                      else
                        Row(
                          children: [
                            const Icon(Icons.cloud_done_rounded, size: 14, color: Colors.green),
                            const SizedBox(width: 6),
                            Text('Synced to cloud', style: TextStyle(fontSize: 11.5, color: textSubtle)),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
