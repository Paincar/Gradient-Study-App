import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/rose_pine_theme.dart';
import '../../data/models/models.dart';
import '../../providers.dart';
import '../calendar/calendar_screen.dart';
import '../common/responsive_wrapper.dart';
import '../focus/focus_screen.dart';
import '../syllabus/syllabus_screen.dart';
import '../../core/services/native_service.dart';

class TimetableScreen extends ConsumerStatefulWidget {
  const TimetableScreen({super.key});

  @override
  ConsumerState<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends ConsumerState<TimetableScreen> {
  late int _selectedDayOfWeek; // 1 = Monday, ..., 7 = Sunday
  int _currentTab = 0; // 0: Structured Timeline, 1: Goals & Milestones
  String _goalFilter = 'All'; // 'All', 'Daily', 'Weekly', 'Monthly'

  @override
  void initState() {
    super.initState();
    _selectedDayOfWeek = DateTime.now().weekday;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allSlots = ref.watch(timetableNotifierProvider);
    final subjects = ref.watch(subjectsNotifierProvider);
    final profile = ref.watch(userProfileNotifierProvider);
    final goals = ref.watch(goalsNotifierProvider);
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textPrimary = isDark ? RosePineColors.darkText : RosePineColors.dawnText;
    final textSubtle = isDark ? RosePineColors.darkSubtle : RosePineColors.dawnSubtle;
    final goldAccent = isDark ? RosePineColors.darkGold : RosePineColors.dawnGold;
    final loveAccent = isDark ? RosePineColors.darkLove : RosePineColors.dawnLove;
    final foamAccent = isDark ? RosePineColors.darkFoam : RosePineColors.dawnFoam;

    // Filter slots for selected day of week, sorted by start time
    final daySlots = allSlots.where((s) => s.dayOfWeek == _selectedDayOfWeek).toList()
      ..sort((a, b) {
        if (a.startHour != b.startHour) return a.startHour.compareTo(b.startHour);
        return a.startMinute.compareTo(b.startMinute);
      });

    final completedCount = daySlots.where((s) => s.isCompleted).length;
    final totalDuration = daySlots.fold<int>(0, (sum, s) => sum + s.durationMinutes);
    final completedDuration = daySlots
        .where((s) => s.isCompleted)
        .fold<int>(0, (sum, s) => sum + s.durationMinutes);

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentTab == 0 ? 'Structured Schedule' : 'Goals & Milestones'),
        actions: [
          if (_currentTab == 0) ...[
            IconButton(
              icon: const Icon(Icons.calendar_month_rounded),
              tooltip: 'Academic Calendar & Holidays',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CalendarScreen()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.menu_book_rounded),
              tooltip: 'SPPU Syllabus Tree',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SyllabusScreen()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.tune_rounded),
              tooltip: 'Manage Included Subjects',
              onPressed: () => _showManageSubjectsModal(context, ref, subjects, isDark),
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Regenerate Weekly Routine',
              onPressed: () => _confirmRegenerateSchedule(context),
            ),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _currentTab == 0
            ? () => _showAddBlockModal(context)
            : () => _showAddGoalModal(context),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          _currentTab == 0 ? 'Add Study Block' : 'Add Goal',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          child: Column(
            children: [
              // Segmented Tab Selector
              Container(
                margin: const EdgeInsets.fromLTRB(20, 10, 20, 6),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? RosePineColors.darkSurface : RosePineColors.dawnSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => setState(() => _currentTab = 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: _currentTab == 0 ? primaryColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.calendar_view_week_rounded,
                                size: 16,
                                color: _currentTab == 0 ? Colors.white : textSubtle,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Schedule',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: _currentTab == 0 ? Colors.white : textSubtle,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => setState(() => _currentTab = 1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: _currentTab == 1 ? primaryColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.flag_rounded,
                                size: 16,
                                color: _currentTab == 1 ? Colors.white : textSubtle,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Goals & Milestones',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: _currentTab == 1 ? Colors.white : textSubtle,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (_currentTab == 0) ...[
                // College Hours & Peak Motivation Banner
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.account_balance_rounded, size: 16, color: primaryColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '🏛️ College Hours: ${profile.collegeStartTime} – ${profile.collegeEndTime} · Peak: ${profile.peakMotivationWindow}',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              // Structured Day Strip (Monday to Sunday)
              _buildWeekDayStrip(primaryColor, isDark, textPrimary, textSubtle, allSlots),

              // Daily Summary Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? RosePineColors.darkSurface : RosePineColors.dawnSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? RosePineColors.darkOverlay : RosePineColors.dawnOverlay,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getDayName(_selectedDayOfWeek),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$completedCount of ${daySlots.length} completed · ${(completedDuration / 60).toStringAsFixed(1)} of ${(totalDuration / 60).toStringAsFixed(1)} hrs',
                            style: TextStyle(fontSize: 12, color: textSubtle),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          if (daySlots.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.calendar_today_rounded, size: 20),
                              tooltip: 'Export to Google Calendar',
                              onPressed: () => _exportDayToGoogleCalendar(context, daySlots),
                            ),
                          const SizedBox(width: 4),
                          // Progress Ring
                          SizedBox(
                            width: 38,
                            height: 38,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                CircularProgressIndicator(
                                  value: daySlots.isEmpty ? 0 : completedCount / daySlots.length,
                                  backgroundColor: primaryColor.withValues(alpha: 0.15),
                                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                                  strokeWidth: 3.5,
                                ),
                                Center(
                                  child: Text(
                                    daySlots.isEmpty
                                        ? '0%'
                                        : '${((completedCount / daySlots.length) * 100).toInt()}%',
                                    style: TextStyle(
                                      fontSize: 10,
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
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 4),

              // Vertical Timeline
              Expanded(
                child: daySlots.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.event_note_rounded,
                                  size: 48, color: textSubtle.withValues(alpha: 0.3)),
                              const SizedBox(height: 12),
                              Text(
                                'No study blocks scheduled for ${_getDayName(_selectedDayOfWeek)}.',
                                style: TextStyle(color: textSubtle, fontSize: 14),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () => _showAddBlockModal(context),
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('Schedule a Session'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 90),
                        itemCount: daySlots.length,
                        itemBuilder: (ctx, idx) {
                          final slot = daySlots[idx];
                          final isLast = idx == daySlots.length - 1;
                          return _buildTimelineItem(
                            slot: slot,
                            isLast: isLast,
                            primaryColor: primaryColor,
                            textPrimary: textPrimary,
                            textSubtle: textSubtle,
                            goldAccent: goldAccent,
                            loveAccent: loveAccent,
                            foamAccent: foamAccent,
                            isDark: isDark,
                          );
                        },
                      ),
              ),
            ] else ...[
              _buildGoalsView(
                context,
                goals,
                isDark,
                primaryColor,
                textPrimary,
                textSubtle,
                foamAccent,
                goldAccent,
                loveAccent,
              ),
            ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeekDayStrip(
    Color primaryColor,
    bool isDark,
    Color textPrimary,
    Color textSubtle,
    List<TimetableSlot> allSlots,
  ) {
    final days = [
      {'num': 1, 'name': 'Mon'},
      {'num': 2, 'name': 'Tue'},
      {'num': 3, 'name': 'Wed'},
      {'num': 4, 'name': 'Thu'},
      {'num': 5, 'name': 'Fri'},
      {'num': 6, 'name': 'Sat'},
      {'num': 7, 'name': 'Sun'},
    ];

    final today = DateTime.now().weekday;

    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: days.map((d) {
          final dayNum = d['num'] as int;
          final isSelected = dayNum == _selectedDayOfWeek;
          final isToday = dayNum == today;
          final hasTasks = allSlots.any((s) => s.dayOfWeek == dayNum);

          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedDayOfWeek = dayNum),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: isSelected
                      ? primaryColor
                      : (isDark ? RosePineColors.darkSurface : RosePineColors.dawnSurface),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? primaryColor
                        : (isToday
                            ? primaryColor.withValues(alpha: 0.5)
                            : (isDark ? RosePineColors.darkOverlay : RosePineColors.dawnOverlay)),
                    width: isToday ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      d['name'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : (isToday ? primaryColor : textSubtle),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (isToday)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white24 : primaryColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'TODAY',
                          style: TextStyle(
                            fontSize: 7,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            color: isSelected ? Colors.white : primaryColor,
                          ),
                        ),
                      )
                    else if (hasTasks)
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white70 : textSubtle.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                      )
                    else
                      const SizedBox(height: 4),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTimelineItem({
    required TimetableSlot slot,
    required bool isLast,
    required Color primaryColor,
    required Color textPrimary,
    required Color textSubtle,
    required Color goldAccent,
    required Color loveAccent,
    required Color foamAccent,
    required bool isDark,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Time Column (Hour indicator on the left, structured style)
          SizedBox(
            width: 58,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${slot.startHour.toString().padLeft(2, '0')}:${slot.startMinute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: slot.isCompleted ? textSubtle : textPrimary,
                  ),
                ),
                Text(
                  '${slot.durationMinutes}m',
                  style: TextStyle(fontSize: 10, color: textSubtle),
                ),
              ],
            ),
          ),

          // Timeline Axis Line & Indicator Dot
          Column(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: slot.isCompleted
                      ? foamAccent
                      : (slot.isWeakSubject ? goldAccent : primaryColor),
                  border: Border.all(
                    color: isDark ? RosePineColors.darkBase : Colors.white,
                    width: 2.5,
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isDark ? RosePineColors.darkOverlay : RosePineColors.dawnOverlay,
                  ),
                ),
            ],
          ),

          const SizedBox(width: 12),

          // Task / Study Block Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? RosePineColors.darkSurface : RosePineColors.dawnSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: slot.isCompleted
                        ? foamAccent.withValues(alpha: 0.3)
                        : (slot.isWeakSubject
                            ? goldAccent.withValues(alpha: 0.4)
                            : (isDark ? RosePineColors.darkOverlay : RosePineColors.dawnOverlay)),
                    width: slot.isWeakSubject ? 1.5 : 1,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _showSlotOptions(context, slot),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: Subject Title + Status Badges + Checkbox
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      slot.subjectName,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        decoration: slot.isCompleted
                                            ? TextDecoration.lineThrough
                                            : null,
                                        color: slot.isCompleted ? textSubtle : textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Unit ${slot.unitNumber}: ${slot.unitName}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: slot.isCompleted ? textSubtle : primaryColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Checkbox(
                                value: slot.isCompleted,
                                activeColor: foamAccent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                onChanged: (val) {
                                  ref
                                      .read(timetableNotifierProvider.notifier)
                                      .toggleCompleted(slot.id);
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          // Badges Row: Time, Weak Subject tag, Notes
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.schedule_rounded, size: 12, color: primaryColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      slot.timeRange,
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: primaryColor),
                                    ),
                                  ],
                                ),
                              ),
                              if (slot.isWeakSubject)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: goldAccent.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.bolt_rounded, size: 12, color: goldAccent),
                                      const SizedBox(width: 3),
                                      Text(
                                        'Focus Boost (+25%)',
                                        style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: goldAccent),
                                      ),
                                    ],
                                  ),
                                ),
                              if (slot.hasReminder)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? RosePineColors.darkOverlay
                                        : RosePineColors.dawnOverlay,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.notifications_active_rounded,
                                      size: 12, color: textSubtle),
                                ),
                            ],
                          ),

                          if (slot.notes.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              slot.notes,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: textSubtle,
                                  fontStyle: FontStyle.italic),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSlotOptions(BuildContext context, TimetableSlot slot) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final goldAccent = Theme.of(context).brightness == Brightness.dark ? RosePineColors.darkGold : RosePineColors.dawnGold;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                slot.subjectName,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Unit ${slot.unitNumber}: ${slot.unitName} · ${slot.timeRange}',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.timer_rounded, color: primaryColor),
                ),
                title: const Text('Start Focus Session for this Subject',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Launches Pomodoro with auto app distraction shield'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FocusScreen(initialSubjectId: slot.subjectId),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: goldAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.edit_calendar_rounded, color: goldAccent),
                ),
                title: const Text('Edit Study Block',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Modify subject, unit, time, duration, or notes'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditBlockModal(context, slot);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.event_available_rounded, color: Colors.blue),
                ),
                title: const Text('Add to Google Calendar',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Opens directly in Google Calendar with reminder & duration'),
                onTap: () {
                  Navigator.pop(ctx);
                  _exportSlotToGoogleCalendar(context, slot);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.check_circle_outline_rounded, color: Colors.green),
                ),
                title: Text(slot.isCompleted ? 'Mark as Incomplete' : 'Mark as Completed',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(ctx);
                  ref.read(timetableNotifierProvider.notifier).toggleCompleted(slot.id);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                ),
                title: const Text('Delete Study Block',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  ref.read(timetableNotifierProvider.notifier).deleteSlot(slot.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Study block removed.')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportSlotToGoogleCalendar(BuildContext context, TimetableSlot slot) async {
    final now = DateTime.now();
    final daysAhead = (slot.dayOfWeek - now.weekday) % 7;
    final realDaysAhead = daysAhead < 0 ? daysAhead + 7 : daysAhead;
    var targetDate = DateTime(now.year, now.month, now.day).add(
      Duration(days: realDaysAhead, hours: slot.startHour, minutes: slot.startMinute),
    );
    
    if (realDaysAhead == 0 && targetDate.isBefore(now)) {
      targetDate = targetDate.add(const Duration(days: 7));
    }
    
    final startTime = targetDate;
    final endTime = startTime.add(Duration(minutes: slot.durationMinutes));

    final desc = 'Subject: ${slot.subjectName}\nUnit ${slot.unitNumber}: ${slot.unitName}'
        '${slot.notes.isNotEmpty ? "\nNotes: ${slot.notes}" : ""}'
        '\n\nGradient SPPU Engineering Study Block';

    final success = await NativeService.addCalendarEvent(
      title: 'Study: ${slot.subjectName} (Unit ${slot.unitNumber})',
      description: desc,
      location: 'Study Desk',
      startTime: startTime,
      endTime: endTime,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Opening Google Calendar for "${slot.subjectName}"...'
                : 'Could not launch Google Calendar.',
          ),
        ),
      );
    }
  }

  void _exportDayToGoogleCalendar(BuildContext context, List<TimetableSlot> slots) {
    if (slots.isEmpty) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_month_rounded, color: Colors.blue),
                  const SizedBox(width: 10),
                  Text(
                    'Export ${_getDayName(_selectedDayOfWeek)} to Google Calendar',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Select any study block below to launch and save directly into Google Calendar:',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              ...slots.map((slot) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.calendar_today_rounded, color: Colors.blue, size: 18),
                    ),
                    title: Text(slot.subjectName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Text('Unit ${slot.unitNumber} · ${slot.timeRange} (${slot.durationMinutes}m)',
                        style: const TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    onTap: () {
                      Navigator.pop(ctx);
                      _exportSlotToGoogleCalendar(context, slot);
                    },
                  )),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddBlockModal(BuildContext context) {
    final subjects = ref.read(subjectsNotifierProvider).where((s) => !s.isExcluded).toList();
    if (subjects.isEmpty) return;

    String selectedSubjectId = subjects.first.id;
    int selectedUnitNumber = 1;
    int startHour = 14;
    int startMinute = 0;
    int duration = 60;
    int dayOfWeek = _selectedDayOfWeek;
    final notesController = TextEditingController();
    bool enableReminder = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final selectedSub = subjects.firstWhere(
              (s) => s.id == selectedSubjectId,
              orElse: () => subjects.first,
            );

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add Structured Study Block',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // Subject Dropdown (Showing pure subject names, NO subject codes)
                    const Text('Subject', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedSubjectId,
                          isExpanded: true,
                          items: subjects.map((s) {
                            return DropdownMenuItem(
                              value: s.id,
                              child: Text(
                                '${s.emoji} ${s.name}',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() => selectedSubjectId = val);
                            }
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Unit Selection
                    const Text('Target Unit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [1, 2, 3, 4, 5].map((u) {
                          final isSel = selectedUnitNumber == u;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text('Unit $u'),
                              selected: isSel,
                              onSelected: (_) => setModalState(() => selectedUnitNumber = u),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Day of Week
                    const Text('Day of Week', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          {'d': 1, 'name': 'Mon'},
                          {'d': 2, 'name': 'Tue'},
                          {'d': 3, 'name': 'Wed'},
                          {'d': 4, 'name': 'Thu'},
                          {'d': 5, 'name': 'Fri'},
                          {'d': 6, 'name': 'Sat'},
                          {'d': 7, 'name': 'Sun'},
                        ].map((item) {
                          final isSel = dayOfWeek == item['d'];
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(item['name'] as String),
                              selected: isSel,
                              onSelected: (_) => setModalState(() => dayOfWeek = item['d'] as int),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Start Time & Duration
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Start Time', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.access_time_rounded, size: 18),
                                label: Text(
                                  '${startHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () async {
                                  final time = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay(hour: startHour, minute: startMinute),
                                  );
                                  if (time != null) {
                                    setModalState(() {
                                      startHour = time.hour;
                                      startMinute = time.minute;
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Duration', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade400),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    value: duration,
                                    isExpanded: true,
                                    items: const [
                                      DropdownMenuItem(value: 30, child: Text('30 mins')),
                                      DropdownMenuItem(value: 45, child: Text('45 mins')),
                                      DropdownMenuItem(value: 60, child: Text('60 mins (1h)')),
                                      DropdownMenuItem(value: 75, child: Text('75 mins')),
                                      DropdownMenuItem(value: 90, child: Text('90 mins (1.5h)')),
                                      DropdownMenuItem(value: 120, child: Text('120 mins (2h)')),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) setModalState(() => duration = val);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Notes
                    TextField(
                      controller: notesController,
                      decoration: InputDecoration(
                        labelText: 'Study Goals / Notes (Optional)',
                        hintText: 'e.g. Solve 5 PYQs, memorize derivations',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Reminder toggle
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Remind me 5 minutes before',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      subtitle: const Text('Fires a high-priority Android notification alarm',
                          style: TextStyle(fontSize: 11)),
                      value: enableReminder,
                      onChanged: (v) => setModalState(() => enableReminder = v),
                    ),

                    const SizedBox(height: 16),

                    // Save Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        final endTotal = startHour * 60 + startMinute + duration;
                        final endHour = endTotal ~/ 60;
                        final endMinute = endTotal % 60;

                        final startStr =
                            '${startHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')}';
                        final endStr =
                            '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';

                        final unit = selectedSub.units.isNotEmpty &&
                                selectedUnitNumber <= selectedSub.units.length
                            ? selectedSub.units[selectedUnitNumber - 1]
                            : Unit(unitNumber: selectedUnitNumber, name: 'Core Foundations', hours: 8, weightage: 'High');

                        final newSlot = TimetableSlot(
                          id: 'custom_slot_${DateTime.now().millisecondsSinceEpoch}',
                          subjectId: selectedSub.id,
                          subjectName: selectedSub.name,
                          unitName: unit.name,
                          unitNumber: selectedUnitNumber,
                          timeRange: '$startStr - $endStr',
                          durationMinutes: duration,
                          dayOfWeek: dayOfWeek,
                          startHour: startHour,
                          startMinute: startMinute,
                          isCustomTask: true,
                          hasReminder: enableReminder,
                          notes: notesController.text.trim(),
                        );

                        ref.read(timetableNotifierProvider.notifier).addSlot(newSlot);
                        Navigator.pop(ctx);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                '✨ Study block added for ${_getDayName(dayOfWeek)} at $startStr!'),
                          ),
                        );
                      },
                      child: const Text('Save to Structured Schedule',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditBlockModal(BuildContext context, TimetableSlot slot) {
    final subjects = ref.read(subjectsNotifierProvider).where((s) => !s.isExcluded).toList();
    if (subjects.isEmpty) return;

    String selectedSubjectId = slot.subjectId;
    if (!subjects.any((s) => s.id == selectedSubjectId)) {
      selectedSubjectId = subjects.first.id;
    }
    int selectedUnitNumber = slot.unitNumber;
    int startHour = slot.startHour;
    int startMinute = slot.startMinute;
    int duration = slot.durationMinutes;
    int dayOfWeek = slot.dayOfWeek;
    final notesController = TextEditingController(text: slot.notes);
    bool enableReminder = slot.hasReminder;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final selectedSub = subjects.firstWhere(
              (s) => s.id == selectedSubjectId,
              orElse: () => subjects.first,
            );

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Edit Study Block',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // Subject Dropdown
                    const Text('Subject', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedSubjectId,
                          isExpanded: true,
                          items: subjects.map((s) {
                            return DropdownMenuItem(
                              value: s.id,
                              child: Text(
                                '${s.emoji} ${s.name}',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() => selectedSubjectId = val);
                            }
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Unit Selection
                    const Text('Target Unit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [1, 2, 3, 4, 5].map((u) {
                          final isSel = selectedUnitNumber == u;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text('Unit $u'),
                              selected: isSel,
                              onSelected: (_) => setModalState(() => selectedUnitNumber = u),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Day of Week
                    const Text('Day of Week', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          {'d': 1, 'name': 'Mon'},
                          {'d': 2, 'name': 'Tue'},
                          {'d': 3, 'name': 'Wed'},
                          {'d': 4, 'name': 'Thu'},
                          {'d': 5, 'name': 'Fri'},
                          {'d': 6, 'name': 'Sat'},
                          {'d': 7, 'name': 'Sun'},
                        ].map((item) {
                          final isSel = dayOfWeek == item['d'];
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(item['name'] as String),
                              selected: isSel,
                              onSelected: (_) => setModalState(() => dayOfWeek = item['d'] as int),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Start Time & Duration
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Start Time', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.access_time_rounded, size: 18),
                                label: Text(
                                  '${startHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () async {
                                  final time = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay(hour: startHour, minute: startMinute),
                                  );
                                  if (time != null) {
                                    setModalState(() {
                                      startHour = time.hour;
                                      startMinute = time.minute;
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Duration', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade400),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    value: duration,
                                    isExpanded: true,
                                    items: const [
                                      DropdownMenuItem(value: 30, child: Text('30 mins')),
                                      DropdownMenuItem(value: 45, child: Text('45 mins')),
                                      DropdownMenuItem(value: 60, child: Text('60 mins (1h)')),
                                      DropdownMenuItem(value: 75, child: Text('75 mins')),
                                      DropdownMenuItem(value: 90, child: Text('90 mins (1.5h)')),
                                      DropdownMenuItem(value: 120, child: Text('120 mins (2h)')),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) setModalState(() => duration = val);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Notes
                    TextField(
                      controller: notesController,
                      decoration: InputDecoration(
                        labelText: 'Study Goals / Notes',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Reminder toggle
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Remind me 5 minutes before',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      subtitle: const Text('Fires a high-priority Android notification alarm',
                          style: TextStyle(fontSize: 11)),
                      value: enableReminder,
                      onChanged: (v) => setModalState(() => enableReminder = v),
                    ),

                    const SizedBox(height: 16),

                    // Update Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        final endTotal = startHour * 60 + startMinute + duration;
                        final endHour = endTotal ~/ 60;
                        final endMinute = endTotal % 60;

                        final startStr =
                            '${startHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')}';
                        final endStr =
                            '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';

                        final unit = selectedSub.units.isNotEmpty &&
                                selectedUnitNumber <= selectedSub.units.length
                            ? selectedSub.units[selectedUnitNumber - 1]
                            : Unit(unitNumber: selectedUnitNumber, name: 'Core Foundations', hours: 8, weightage: 'High');

                        final updatedSlot = slot.copyWith(
                          subjectId: selectedSub.id,
                          subjectName: selectedSub.name,
                          unitName: unit.name,
                          unitNumber: selectedUnitNumber,
                          timeRange: '$startStr - $endStr',
                          durationMinutes: duration,
                          dayOfWeek: dayOfWeek,
                          startHour: startHour,
                          startMinute: startMinute,
                          hasReminder: enableReminder,
                          notes: notesController.text.trim(),
                        );

                        ref.read(timetableNotifierProvider.notifier).updateSlot(updatedSlot);
                        Navigator.pop(ctx);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                '✨ Study block updated for ${_getDayName(dayOfWeek)} at $startStr!'),
                          ),
                        );
                      },
                      child: const Text('Update Study Block',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGoalsView(
    BuildContext context,
    List<GoalItem> goals,
    bool isDark,
    Color primaryColor,
    Color textPrimary,
    Color textSubtle,
    Color foamAccent,
    Color goldAccent,
    Color loveAccent,
  ) {
    final filteredGoals = goals.where((g) {
      if (_goalFilter == 'Daily') return g.type == GoalType.daily;
      if (_goalFilter == 'Weekly') return g.type == GoalType.weekly;
      if (_goalFilter == 'Monthly') return g.type == GoalType.monthly;
      return true;
    }).toList();

    final completedCount = goals.where((g) => g.isCompleted).length;
    final progressVal = goals.isEmpty ? 0.0 : completedCount / goals.length;

    return Expanded(
      child: Column(
        children: [
          // Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Daily', 'Weekly', 'Monthly'].map((filter) {
                  final isSelected = _goalFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        filter == 'All'
                            ? 'All (${goals.length})'
                            : filter == 'Daily'
                                ? '🌅 Daily (${goals.where((g) => g.type == GoalType.daily).length})'
                                : filter == 'Weekly'
                                    ? '📆 Weekly (${goals.where((g) => g.type == GoalType.weekly).length})'
                                    : '🎯 Monthly (${goals.where((g) => g.type == GoalType.monthly).length})',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: primaryColor.withValues(alpha: 0.25),
                      onSelected: (_) => setState(() => _goalFilter = filter),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Overview Progress Card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? RosePineColors.darkSurface : RosePineColors.dawnSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? RosePineColors.darkOverlay : RosePineColors.dawnOverlay,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Milestones Progress',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      '$completedCount of ${goals.length} Completed',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: foamAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progressVal,
                    minHeight: 8,
                    backgroundColor: isDark ? RosePineColors.darkOverlay : RosePineColors.dawnOverlay,
                    valueColor: AlwaysStoppedAnimation<Color>(foamAccent),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Goals List
          Expanded(
            child: filteredGoals.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.flag_outlined, size: 48, color: textSubtle.withValues(alpha: 0.3)),
                          const SizedBox(height: 12),
                          Text(
                            'No $_goalFilter goals set yet.',
                            style: TextStyle(color: textSubtle, fontSize: 14),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _showAddGoalModal(context),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Create a Target Goal'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 90),
                    itemCount: filteredGoals.length,
                    itemBuilder: (ctx, idx) {
                      final goal = filteredGoals[idx];
                      return _buildGoalItemCard(
                        context,
                        goal,
                        isDark,
                        primaryColor,
                        textPrimary,
                        textSubtle,
                        foamAccent,
                        goldAccent,
                        loveAccent,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalItemCard(
    BuildContext context,
    GoalItem goal,
    bool isDark,
    Color primaryColor,
    Color textPrimary,
    Color textSubtle,
    Color foamAccent,
    Color goldAccent,
    Color loveAccent,
  ) {
    Color typeColor;
    String typeLabel;
    switch (goal.type) {
      case GoalType.daily:
        typeColor = foamAccent;
        typeLabel = 'DAILY';
        break;
      case GoalType.weekly:
        typeColor = primaryColor;
        typeLabel = 'WEEKLY';
        break;
      case GoalType.monthly:
        typeColor = goldAccent;
        typeLabel = 'MONTHLY';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? RosePineColors.darkSurface : RosePineColors.dawnSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: goal.isCompleted
              ? foamAccent.withValues(alpha: 0.3)
              : (isDark ? RosePineColors.darkOverlay : RosePineColors.dawnOverlay),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Transform.scale(
                  scale: 1.1,
                  child: Checkbox(
                    value: goal.isCompleted,
                    activeColor: foamAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                    onChanged: (_) {
                      ref.read(goalsNotifierProvider.notifier).toggleGoalCompleted(goal.id);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              typeLabel,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                                color: typeColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? RosePineColors.darkOverlay : RosePineColors.dawnOverlay,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              goal.category,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: textSubtle,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        goal.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          decoration: goal.isCompleted ? TextDecoration.lineThrough : null,
                          color: goal.isCompleted ? textSubtle : textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline_rounded, size: 20, color: textSubtle),
                  tooltip: 'Delete Goal',
                  onPressed: () {
                    ref.read(goalsNotifierProvider.notifier).deleteGoal(goal.id);
                  },
                ),
              ],
            ),
            if (goal.targetMinutes > 0) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progress: ${(goal.currentMinutes / 60).toStringAsFixed(1)} / ${(goal.targetMinutes / 60).toStringAsFixed(1)} hrs',
                    style: TextStyle(fontSize: 11, color: textSubtle, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${(goal.progress * 100).toInt()}%',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: typeColor),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: goal.progress,
                  minHeight: 6,
                  backgroundColor: isDark ? RosePineColors.darkOverlay : RosePineColors.dawnOverlay,
                  valueColor: AlwaysStoppedAnimation<Color>(typeColor),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAddGoalModal(BuildContext context) {
    final titleController = TextEditingController();
    GoalType selectedType = GoalType.daily;
    String selectedCategory = 'Study Hours';
    int targetHours = 2;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create Target Milestone / Goal',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // Goal Type
                    const Text('Goal Horizon', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        GoalType.daily,
                        GoalType.weekly,
                        GoalType.monthly,
                      ].map((t) {
                        final isSel = selectedType == t;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(t.name.toUpperCase()),
                            selected: isSel,
                            onSelected: (_) => setModalState(() => selectedType = t),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 14),

                    // Goal Title
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Goal Title',
                        hintText: 'e.g. Master Unit 2 Derivations, 3h Engineering Physics',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Category Dropdown
                    const Text('Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedCategory,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(value: 'Study Hours', child: Text('Study Hours Focus')),
                            DropdownMenuItem(value: 'Unit Test Prep', child: Text('Unit Test / Quiz Prep')),
                            DropdownMenuItem(value: 'Assignments & Case Studies', child: Text('Assignments & Case Studies')),
                            DropdownMenuItem(value: 'Mini Project / Activity', child: Text('Mini Project / Activity')),
                            DropdownMenuItem(value: 'End-Sem Revision', child: Text('End-Sem Exam Revision')),
                          ],
                          onChanged: (val) {
                            if (val != null) setModalState(() => selectedCategory = val);
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Target Hours
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Target Duration', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        Text('$targetHours hours (${targetHours * 60}m)',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Slider(
                      value: targetHours.toDouble(),
                      min: 1,
                      max: selectedType == GoalType.monthly ? 40 : (selectedType == GoalType.weekly ? 20 : 6),
                      divisions: selectedType == GoalType.monthly ? 39 : (selectedType == GoalType.weekly ? 19 : 5),
                      label: '$targetHours hrs',
                      onChanged: (val) => setModalState(() => targetHours = val.toInt()),
                    ),

                    const SizedBox(height: 16),

                    // Save Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        final title = titleController.text.trim();
                        if (title.isEmpty) return;

                        final newGoal = GoalItem(
                          id: 'goal_${DateTime.now().millisecondsSinceEpoch}',
                          title: title,
                          type: selectedType,
                          targetMinutes: targetHours * 60,
                          currentMinutes: 0,
                          isCompleted: false,
                          category: selectedCategory,
                          createdAt: DateTime.now(),
                        );

                        ref.read(goalsNotifierProvider.notifier).addGoal(newGoal);
                        Navigator.pop(ctx);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('🎯 New ${selectedType.name} goal added!')),
                        );
                      },
                      child: const Text('Add Goal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmRegenerateSchedule(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Regenerate SPPU Flow?'),
        content: const Text(
            'This will re-calculate an optimized 7-day routine tailored to your SPPU syllabus pattern and give extra focus duration to your weak subjects.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(timetableNotifierProvider.notifier).regenerateWeeklySchedule();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✨ Weekly schedule refreshed according to SPPU sequence!')),
              );
            },
            child: const Text('Regenerate'),
          ),
        ],
      ),
    );
  }

  void _showManageSubjectsModal(
      BuildContext context, WidgetRef refConsumer, List<Subject> currentSubjects, bool isDark) {
    final primary = Theme.of(context).colorScheme.primary;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final subs = refConsumer.watch(subjectsNotifierProvider);
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Manage Included Subjects',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Toggle off non-applicable subjects to exclude them from your daily routine.',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: subs.length,
                        itemBuilder: (context, i) {
                          final sub = subs[i];
                          final isIncluded = !sub.isExcluded;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: SwitchListTile(
                              secondary: Text(sub.emoji, style: const TextStyle(fontSize: 22)),
                              title: Text(sub.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              subtitle: Text('Semester ${sub.semester} · ${sub.teachingHours} Syllabus Hours'),
                              value: isIncluded,
                              activeThumbColor: primary,
                              onChanged: (val) {
                                refConsumer
                                    .read(subjectsNotifierProvider.notifier)
                                    .toggleExclusion(sub.id);
                              },
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
        );
      },
    );
  }

  String _getDayName(int dayOfWeek) {
    switch (dayOfWeek) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return 'Today';
    }
  }
}
