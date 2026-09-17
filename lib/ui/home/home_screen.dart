import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/rose_pine_theme.dart';
import '../../data/datasources/local_store.dart';
import '../../providers.dart';
import '../analytics/analytics_screen.dart';
import '../assessment/assessment_screen.dart';
import '../calendar/calendar_screen.dart';
import '../common/responsive_wrapper.dart';
import '../syllabus/syllabus_screen.dart';
import '../../data/models/models.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final Function(int) onNavigateTab;

  const HomeScreen({super.key, required this.onNavigateTab});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final store = ref.watch(localStoreProvider);
    final profile = ref.watch(userProfileNotifierProvider);

    final textPrimary = isDark ? RosePineColors.darkText : RosePineColors.dawnText;
    final textSubtle = isDark ? RosePineColors.darkSubtle : RosePineColors.dawnSubtle;
    final goldAccent = isDark ? RosePineColors.darkGold : RosePineColors.dawnGold;
    final irisAccent = isDark ? RosePineColors.darkIris : RosePineColors.dawnIris;
    final foamAccent = isDark ? RosePineColors.darkFoam : RosePineColors.dawnFoam;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return SafeArea(
      child: ResponsiveContainer(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Top Bar: Minimal Greeting & Streak (with Expanded to prevent any overflow)
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Gradient',
                            style: TextStyle(
                              fontSize: 22,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'SPPU FE',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryColor),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Semester ${profile.semester} · 2024 Pattern',
                        style: TextStyle(
                          fontSize: 12,
                          color: textSubtle,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    SharePlus.instance.share(
                      ShareParams(
                        text: 'I am on a ${store.currentStreak} day study streak for SPPU Engineering with Gradient! 🔥\n#GradientApp #SPPU',
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: goldAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: goldAccent.withValues(alpha: 0.4), width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_fire_department_rounded, color: goldAccent, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          'Day ${store.currentStreak} Streak',
                          style: TextStyle(
                            color: goldAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.share_rounded, color: goldAccent, size: 12),
                      ],
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 300.ms),

            const SizedBox(height: 36),

            // Hero: Pure Motivational Quote (Sanctuary Home)
            _QuoteSection(
              quotes: store.quotes,
              primaryColor: primaryColor,
              textPrimary: textPrimary,
              textSubtle: textSubtle,
            ),

            const SizedBox(height: 36),

            // Daily Goal Indicator with vibrant gradient bar
            Builder(
              builder: (context) {
                final double todayHrs = store.todayStudyMinutes / 60.0;
                final double goalHrs = profile.dailyStudyHours.toDouble();
                final double progress = goalHrs > 0 ? (todayHrs / goalHrs).clamp(0.0, 1.0) : 0.0;
                final int percent = (progress * 100).toInt();

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark ? RosePineColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? RosePineColors.darkOverlay : RosePineColors.dawnOverlay,
                      width: 1.5,
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
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.track_changes_rounded, size: 16, color: primaryColor),
                              const SizedBox(width: 6),
                              Text(
                                'Today\'s Study Goal',
                                style: TextStyle(fontSize: 13, color: textPrimary, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${todayHrs.toStringAsFixed(1)} / $goalHrs hrs ($percent%)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          height: 8,
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: (isDark ? RosePineColors.darkOverlay : RosePineColors.dawnOverlay),
                            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 250.ms, duration: 400.ms);
              },
            ),

            const SizedBox(height: 20),

            // 4 Fast Action Pills (Clean navigation shortcuts)
            Row(
              children: [
                Expanded(
                  child: _ActionPill(
                    icon: Icons.timer_outlined,
                    label: 'Focus',
                    color: isDark ? RosePineColors.darkFoam : RosePineColors.dawnFoam,
                    onTap: () => widget.onNavigateTab(2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionPill(
                    icon: Icons.quiz_outlined,
                    label: 'Quiz',
                    color: isDark ? RosePineColors.darkIris : RosePineColors.dawnIris,
                    onTap: () => widget.onNavigateTab(3),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionPill(
                    icon: Icons.calendar_today_outlined,
                    label: 'Plan',
                    color: isDark ? RosePineColors.darkRose : RosePineColors.dawnRose,
                    onTap: () => widget.onNavigateTab(1),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionPill(
                    icon: Icons.edit_note_rounded,
                    label: 'Notes',
                    color: isDark ? RosePineColors.darkGold : RosePineColors.dawnGold,
                    onTap: () => widget.onNavigateTab(4),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 350.ms, duration: 400.ms),

            const SizedBox(height: 18),

            // Study Analytics & Diagnostics Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: irisAccent.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.insights_rounded, color: irisAccent, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Study Analytics & Diagnostics',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textPrimary),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'View weekly study hours, subject mastery & time-trap analysis',
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
            ).animate().fadeIn(delay: 400.ms, duration: 400.ms),

            const SizedBox(height: 12),

            // Internal Assessment & CCE Calculator Card (SPPU 2024 Revised Pattern)
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AssessmentScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: foamAccent.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.calculate_rounded, color: foamAccent, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Internal Assessment (CCE)',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textPrimary),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: foamAccent.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '40 Marks',
                                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: foamAccent),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Calculate Unit Tests, Assignments, Seminar & Project marks',
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
            ).animate().fadeIn(delay: 450.ms, duration: 400.ms),

            const SizedBox(height: 12),

            // Two-column Quick Navigation: Academic Calendar & Syllabus Tree
            Row(
              children: [
                Expanded(
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CalendarScreen()),
                        );
                      },
                      borderRadius: BorderRadius.circular(18),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: goldAccent.withValues(alpha: 0.18),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.calendar_month_rounded, color: goldAccent, size: 20),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Calendar',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary),
                                  ),
                                  Text(
                                    'Holidays & Days',
                                    style: TextStyle(fontSize: 10, color: textSubtle),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SyllabusScreen()),
                        );
                      },
                      borderRadius: BorderRadius.circular(18),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.18),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.menu_book_rounded, color: primaryColor, size: 20),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Syllabus',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary),
                                  ),
                                  Text(
                                    'SPPU Units 1-5',
                                    style: TextStyle(fontSize: 10, color: textSubtle),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 450.ms, duration: 400.ms),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _QuoteSection extends StatefulWidget {
  final List<Quote> quotes;
  final Color primaryColor;
  final Color textPrimary;
  final Color textSubtle;

  const _QuoteSection({
    required this.quotes,
    required this.primaryColor,
    required this.textPrimary,
    required this.textSubtle,
  });

  @override
  State<_QuoteSection> createState() => _QuoteSectionState();
}

class _QuoteSectionState extends State<_QuoteSection> {
  int _quoteIndex = 0;

  @override
  Widget build(BuildContext context) {
    final quote = widget.quotes.isNotEmpty ? widget.quotes[_quoteIndex % widget.quotes.length] : null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.primaryColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.format_quote_rounded,
                size: 36,
                color: widget.primaryColor,
              ),
            ).animate().scale(delay: 150.ms, duration: 400.ms),
            const SizedBox(height: 20),
            Text(
              quote != null ? '"${quote.text}"' : '"The secret of getting ahead is getting started."',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                height: 1.35,
                fontWeight: FontWeight.bold,
                color: widget.textPrimary,
                letterSpacing: 0.3,
              ),
            )
                .animate(key: ValueKey(_quoteIndex))
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.08, end: 0),
            const SizedBox(height: 16),
            Text(
              quote != null ? '— ${quote.author}' : '— Mark Twain',
              style: TextStyle(
                fontSize: 15,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
                color: widget.primaryColor,
              ),
            )
                .animate(key: ValueKey('author_$_quoteIndex'))
                .fadeIn(delay: 200.ms, duration: 400.ms),
            const SizedBox(height: 12),
            TextButton.icon(
              icon: Icon(Icons.refresh_rounded, size: 18, color: widget.textSubtle),
              label: Text('Next Quote', style: TextStyle(fontSize: 12, color: widget.textSubtle)),
              onPressed: () {
                setState(() {
                  _quoteIndex++;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionPill({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.2 : 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
