import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/rose_pine_theme.dart';
import '../../data/models/models.dart';
import '../../providers.dart';
import '../common/responsive_wrapper.dart';

class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  String _selectedCategory = 'General Feedback';
  int _rating = 5;
  final _titleController = TextEditingController();
  final _detailsController = TextEditingController();
  bool _isSubmitted = false;

  final List<String> _categories = [
    'Bug Report',
    'Feature Request',
    'General Feedback',
    'Syllabus / PYQ Accuracy',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  void _submitFeedback() {
    final title = _titleController.text.trim();
    final details = _detailsController.text.trim();

    if (details.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your feedback details.')),
      );
      return;
    }

    final item = FeedbackItem(
      id: 'fb_${DateTime.now().millisecondsSinceEpoch}',
      category: _selectedCategory,
      rating: _rating,
      title: title.isEmpty ? 'Student Feedback' : title,
      details: details,
      createdAt: DateTime.now(),
    );

    ref.read(feedbackNotifierProvider.notifier).submitFeedback(item);

    setState(() {
      _isSubmitted = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: RosePineColors.dawnPine,
        content: Row(
          children: [
            Icon(Icons.check_circle_outline_rounded, color: Colors.white),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Feedback saved locally to your device! Thank you for supporting Gradient.',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
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
    final pastFeedbacks = ref.watch(feedbackNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Feedback & Ideas'),
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // Hero Banner
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryColor.withValues(alpha: isDark ? 0.25 : 0.15),
                      goldAccent.withValues(alpha: isDark ? 0.2 : 0.1),
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
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.favorite_rounded, color: primaryColor, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Built for SPPU FE Engineers',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Gradient is completely free and offline. Let us know what features or PYQs you want added!',
                            style: TextStyle(fontSize: 12, color: textSubtle, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              if (_isSubmitted) ...[
                // Thank You State
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? RosePineColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: RosePineColors.dawnPine.withValues(alpha: 0.5), width: 1.5),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 54, color: RosePineColors.dawnPine),
                      const SizedBox(height: 14),
                      Text(
                        'Thank You for Your Feedback!',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your suggestions have been recorded offline in your local database and will help guide future SPPU FE study features.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: textSubtle, height: 1.4),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.edit_note_rounded),
                        label: const Text('Send Another Feedback'),
                        onPressed: () {
                          setState(() {
                            _isSubmitted = false;
                            _titleController.clear();
                            _detailsController.clear();
                            _rating = 5;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Feedback Form
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Category',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _categories.map((cat) {
                            final isSel = _selectedCategory == cat;
                            return ChoiceChip(
                              label: Text(cat),
                              selected: isSel,
                              selectedColor: primaryColor.withValues(alpha: 0.25),
                              onSelected: (_) => setState(() => _selectedCategory = cat),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 20),

                        Text(
                          'Experience Rating',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: List.generate(5, (index) {
                            final star = index + 1;
                            final isFilled = star <= _rating;
                            return IconButton(
                              iconSize: 32,
                              icon: Icon(
                                isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                                color: isFilled ? goldAccent : textSubtle,
                              ),
                              onPressed: () => setState(() => _rating = star),
                            );
                          }),
                        ),

                        const SizedBox(height: 16),

                        Text(
                          'Subject / Summary',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            hintText: 'e.g. Add more Mechanics Unit 3 PYQs',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),

                        const SizedBox(height: 16),

                        Text(
                          'Detailed Thoughts & Suggestions',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _detailsController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Describe what could be improved or what you loved most...',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),

                        const SizedBox(height: 24),

                        ElevatedButton.icon(
                          icon: const Icon(Icons.send_rounded),
                          label: const Text('Save Feedback Locally', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: _submitFeedback,
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Past Submissions Section
              if (pastFeedbacks.isNotEmpty) ...[
                Text(
                  'Your Saved Feedback (${pastFeedbacks.length})',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
                ),
                const SizedBox(height: 12),
                ...pastFeedbacks.map((fb) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  fb.category,
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryColor),
                                ),
                              ),
                              Row(
                                children: List.generate(
                                  fb.rating,
                                  (_) => Icon(Icons.star_rounded, size: 16, color: goldAccent),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            fb.title,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            fb.details,
                            style: TextStyle(fontSize: 12, color: textSubtle, height: 1.35),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
