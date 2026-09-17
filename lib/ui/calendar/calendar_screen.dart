import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/rose_pine_theme.dart';
import '../../data/datasources/local_store.dart';
import '../../providers.dart';
import '../common/responsive_wrapper.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _currentMonth;
  late DateTime _selectedDate;
  List<Map<String, dynamic>> _holidays = [];
  String _categoryFilter = 'all'; // 'all', 'holidays', 'sppu_exams'

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month, 1);
    _selectedDate = DateTime(now.year, now.month, now.day);
    _loadHolidays();
  }

  Future<void> _loadHolidays() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/data/holidays.json');
      final list = jsonDecode(jsonStr) as List<dynamic>;
      final builtIn = list.map((h) => Map<String, dynamic>.from(h as Map)).toList();
      
      final localStore = ref.read(localStoreProvider);
      setState(() {
        _holidays = [...builtIn, ...localStore.customHolidays];
      });
    } catch (_) {}
  }

  Map<String, dynamic>? _getHolidayForDate(DateTime date) {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return _holidays.cast<Map<String, dynamic>?>().firstWhere(
      (h) {
        if (h?['date'] != dateStr) return false;
        if (_categoryFilter == 'holidays') {
          return h?['category'] != 'SPPU Exam' && h?['category'] != 'Academic';
        } else if (_categoryFilter == 'sppu_exams') {
          return h?['category'] == 'SPPU Exam' || h?['category'] == 'Academic';
        }
        return true;
      },
      orElse: () => null,
    );
  }

  Future<void> _openGoogleCalendar() async {
    final uri = Uri.parse('https://calendar.google.com/calendar/r');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  Future<void> _addToGoogleCalendar(String title, DateTime date, {String details = ''}) async {
    final dateStr = '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
    final nextDay = date.add(const Duration(days: 1));
    final nextDayStr = '${nextDay.year}${nextDay.month.toString().padLeft(2, '0')}${nextDay.day.toString().padLeft(2, '0')}';
    final url = 'https://calendar.google.com/calendar/render?action=TEMPLATE&text=${Uri.encodeComponent(title)}&dates=$dateStr/$nextDayStr&details=${Uri.encodeComponent(details)}';
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  Future<void> _syncWithGoogleCalendar(BuildContext context) async {
    final holiday = _getHolidayForDate(_selectedDate);
    if (holiday != null) {
      final name = holiday['name'] as String? ?? 'SPPU Event';
      final details = holiday['category'] as String? ?? 'Academic Event';
      await _addToGoogleCalendar(name, _selectedDate, details: details);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✨ Added "$name" to your Google Calendar!')),
        );
      }
    } else {
      await _openGoogleCalendar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textPrimary = isDark ? RosePineColors.darkText : RosePineColors.dawnText;
    final textSubtle = isDark ? RosePineColors.darkSubtle : RosePineColors.dawnSubtle;
    final goldAccent = isDark ? RosePineColors.darkGold : RosePineColors.dawnGold;
    final irisAccent = isDark ? RosePineColors.darkIris : RosePineColors.dawnIris;

    final timetableSlots = ref.watch(timetableNotifierProvider);
    final selectedHoliday = _getHolidayForDate(_selectedDate);

    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Academic Calendar & Holidays'),
        actions: [
          IconButton(
            icon: const Icon(Icons.event_available_rounded),
            tooltip: 'Sync with Google Calendar',
            onPressed: () => _syncWithGoogleCalendar(context),
          ),
          IconButton(
            icon: const Icon(Icons.add_task_rounded),
            tooltip: 'Add Custom Holiday / Leave',
            onPressed: () => _showAddHolidayDialog(context),
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              // Google Calendar Sync Banner Card
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryColor.withValues(alpha: isDark ? 0.25 : 0.15),
                      irisAccent.withValues(alpha: isDark ? 0.2 : 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Text('📅', style: TextStyle(fontSize: 22)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Google Calendar Sync (2026)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Sync SPPU 2026 exam dates & holidays to Google Calendar.',
                            style: TextStyle(fontSize: 11, color: textSubtle),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.sync_rounded, size: 14),
                      label: const Text('Sync', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      onPressed: () => _syncWithGoogleCalendar(context),
                    ),
                  ],
                ),
              ),

              // Category Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('All 2026 Dates (43)'),
                      selected: _categoryFilter == 'all',
                      onSelected: (_) => setState(() => _categoryFilter = 'all'),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('🏖️ Holidays (27)'),
                      selected: _categoryFilter == 'holidays',
                      onSelected: (_) => setState(() => _categoryFilter = 'holidays'),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('📝 SPPU Exams (16)'),
                      selected: _categoryFilter == 'sppu_exams',
                      onSelected: (_) => setState(() => _categoryFilter = 'sppu_exams'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Month Selector Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        '${monthNames[_currentMonth.month - 1]} ${_currentMonth.year}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                        ),
                        onPressed: () {
                          final now = DateTime.now();
                          setState(() {
                            _currentMonth = DateTime(now.year, now.month, 1);
                            _selectedDate = DateTime(now.year, now.month, now.day);
                          });
                        },
                        child: Text('Today', style: TextStyle(fontSize: 12, color: primaryColor, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded),
                        onPressed: () {
                          setState(() {
                            _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded),
                        onPressed: () {
                          setState(() {
                            _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Calendar Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? RosePineColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? RosePineColors.darkOverlay : RosePineColors.dawnOverlay,
                  ),
                ),
                child: Column(
                  children: [
                    // Day of Week Header
                    Row(
                      children: ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'].map((d) {
                        return Expanded(
                          child: Center(
                            child: Text(
                              d,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: d == 'Su' ? goldAccent : textSubtle,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),

                    // Calendar Grid
                    _buildMonthGrid(isDark, primaryColor, textPrimary, textSubtle, goldAccent, irisAccent),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Selected Date Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${monthNames[_selectedDate.month - 1]} ${_selectedDate.day}, ${_selectedDate.year}',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: textPrimary),
                  ),
                  if (selectedHoliday != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (selectedHoliday['category'] == 'SPPU Exam' ? primaryColor : goldAccent).withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        selectedHoliday['category'] == 'SPPU Exam' ? 'SPPU Exam 📝' : 'Holiday 🏖',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: selectedHoliday['category'] == 'SPPU Exam' ? primaryColor : goldAccent,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Holiday Card (if date is holiday)
              if (selectedHoliday != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        (selectedHoliday['category'] == 'SPPU Exam' ? primaryColor : goldAccent).withValues(alpha: isDark ? 0.25 : 0.18),
                        (selectedHoliday['category'] == 'SPPU Exam' ? irisAccent : primaryColor).withValues(alpha: isDark ? 0.2 : 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: (selectedHoliday['category'] == 'SPPU Exam' ? primaryColor : goldAccent).withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (selectedHoliday['category'] == 'SPPU Exam' ? primaryColor : goldAccent).withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          selectedHoliday['category'] == 'SPPU Exam' ? Icons.school_rounded : Icons.celebration_rounded,
                          color: selectedHoliday['category'] == 'SPPU Exam' ? primaryColor : goldAccent,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedHoliday['name'] ?? 'Holiday',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textPrimary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              selectedHoliday['category'] == 'SPPU Exam'
                                  ? 'Official SPPU 2026 Examination'
                                  : (selectedHoliday['isNational'] == true
                                      ? 'SPPU & National Gazetted Holiday'
                                      : 'Maharashtra State / Custom Holiday'),
                              style: TextStyle(fontSize: 12, color: textSubtle),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_calendar_rounded),
                        tooltip: 'Add this date to Google Calendar',
                        color: selectedHoliday['category'] == 'SPPU Exam' ? primaryColor : goldAccent,
                        onPressed: () => _addToGoogleCalendar(
                          selectedHoliday['name'] ?? 'SPPU Event',
                          _selectedDate,
                          details: selectedHoliday['category'] == 'SPPU Exam'
                              ? 'Official SPPU 2026 Examination'
                              : 'SPPU Gazetted Holiday 2026',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Timetable Slots for this Day
              Text(
                'Scheduled Study Sessions',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textSubtle),
              ),
              const SizedBox(height: 8),

              if (_selectedDate.weekday == DateTime.sunday || selectedHoliday != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Enjoy your day off! No study sessions scheduled.', style: TextStyle(color: textSubtle, fontStyle: FontStyle.italic)),
                  ),
                )
              else if (timetableSlots.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('No slots scheduled for this day.', style: TextStyle(color: textSubtle)),
                  ),
                )
              else
                ...timetableSlots.map((slot) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.book_rounded, color: primaryColor, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  slot.subjectName,
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Unit ${slot.unitNumber}: ${slot.unitName}',
                                  style: TextStyle(fontSize: 12, color: textSubtle),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                slot.timeRange,
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${slot.durationMinutes} min',
                                style: TextStyle(fontSize: 11, color: textSubtle),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthGrid(
    bool isDark,
    Color primaryColor,
    Color textPrimary,
    Color textSubtle,
    Color goldAccent,
    Color irisAccent,
  ) {
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);

    // Monday is 1, Sunday is 7 in DateTime.weekday
    final startWeekday = firstDayOfMonth.weekday; // 1 = Mon, 7 = Sun
    final leadingBlanks = startWeekday - 1;

    final totalCells = leadingBlanks + daysInMonth;
    final totalRows = (totalCells / 7).ceil();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Column(
      children: List.generate(totalRows, (rowIdx) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: List.generate(7, (colIdx) {
              final cellIdx = rowIdx * 7 + colIdx;
              final dayNumber = cellIdx - leadingBlanks + 1;

              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const Expanded(child: SizedBox(height: 38));
              }

              final cellDate = DateTime(_currentMonth.year, _currentMonth.month, dayNumber);
              final isToday = cellDate.isAtSameMomentAs(today);
              final isSelected = cellDate.isAtSameMomentAs(_selectedDate);
              final holiday = _getHolidayForDate(cellDate);
              final hasHoliday = holiday != null;
              final isExam = holiday?['category'] == 'SPPU Exam';

              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedDate = cellDate),
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? primaryColor
                          : (isToday ? primaryColor.withValues(alpha: 0.15) : Colors.transparent),
                      borderRadius: BorderRadius.circular(12),
                      border: isToday && !isSelected
                          ? Border.all(color: primaryColor, width: 1.5)
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$dayNumber',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                            color: isSelected
                                ? Colors.white
                                : (cellDate.weekday == 7 ? goldAccent : textPrimary),
                          ),
                        ),
                        if (hasHoliday)
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white : (isExam ? primaryColor : goldAccent),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  void _showAddHolidayDialog(BuildContext context) {
    final nameController = TextEditingController();
    DateTime pickedDate = _selectedDate;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Add Custom Holiday / Leave'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Holiday or Leave Name',
                      hintText: 'e.g. College Fest, Personal Prep',
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Selected Date:'),
                    subtitle: Text('${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}'),
                    trailing: TextButton(
                      onPressed: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: pickedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (d != null) {
                          setDialogState(() => pickedDate = d);
                        }
                      },
                      child: const Text('Change Date'),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.trim().isNotEmpty) {
                      final dateStr = '${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}';
                      setState(() {
                        final newHoliday = {
                          'date': dateStr,
                          'name': nameController.text.trim(),
                          'isNational': false,
                        };
                        _holidays.add(newHoliday);
                        
                        final localStore = ref.read(localStoreProvider);
                        final updatedCustom = [...localStore.customHolidays, newHoliday];
                        localStore.saveCustomHolidays(updatedCustom);
                        
                        _selectedDate = pickedDate;
                      });
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('✨ Added ${nameController.text.trim()} to calendar!')),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
