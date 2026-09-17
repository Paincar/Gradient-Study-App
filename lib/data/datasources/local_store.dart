import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../../core/services/native_service.dart';

final localStoreProvider = Provider<LocalStore>((ref) => LocalStore());

class LocalStore {
  SharedPreferences? _prefs;
  bool _initialized = false;

  List<Subject> _subjects = [];
  List<Quote> _quotes = [];
  List<Question> _questions = [];
  List<PYQItem> _pyqs = [];
  List<TimetableSlot> _scheduleSlots = [];
  UserProfile _userProfile = const UserProfile();

  bool _hasCompletedOnboarding = false;
  String _geminiApiKey = '';
  Map<String, int> _subjectStudyMinutes = {};
  Map<String, int> _weeklyStudyHistory = {};

  List<NoteItem> _notes = [];
  List<FeedbackItem> _feedback = [];
  Set<String> _completedSlotIds = {};
  List<Map<String, dynamic>> _customHolidays = [];
  Map<String, InternalAssessmentRecord> _internalAssessments = {};
  List<GoalItem> _goals = [];
  String _savedCustomSpotifyUri = '';

  int _currentStreak = 0;
  String _lastStudyDate = '';
  int _todayStudyMinutes = 0;

  UserProfile get userProfile => _userProfile;
  List<Subject> get subjects => _subjects;
  List<Quote> get quotes => _quotes;
  List<Question> get questions => _questions;
  List<PYQItem> get pyqs => _pyqs;
  List<TimetableSlot> get scheduleSlots => _scheduleSlots;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  String get geminiApiKey => _geminiApiKey;
  Map<String, int> get subjectStudyMinutes => _subjectStudyMinutes;
  Map<String, int> get weeklyStudyHistory => _weeklyStudyHistory;
  
  List<NoteItem> get notes => _notes;
  List<FeedbackItem> get feedback => _feedback;
  Set<String> get completedSlotIds => _completedSlotIds;
  List<Map<String, dynamic>> get customHolidays => _customHolidays;
  Map<String, InternalAssessmentRecord> get internalAssessments => _internalAssessments;
  List<GoalItem> get goals => _goals;
  String get savedCustomSpotifyUri => _savedCustomSpotifyUri;

  int get currentStreak => _currentStreak;
  String get lastStudyDate => _lastStudyDate;
  int get todayStudyMinutes => _todayStudyMinutes;

  bool get isInitialized => _initialized;

  Future<void> init() async {
    if (_initialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (e, st) {
      debugPrint('Failed to initialize SharedPreferences: $e\n$st');
      return; // Do not mark as initialized if prefs fail
    }

    try {
      _hasCompletedOnboarding = _prefs!.getBool('has_completed_onboarding') ?? false;
      _geminiApiKey = _prefs!.getString('gemini_api_key') ?? '';

      final studyMinutesJson = _prefs!.getString('subject_study_minutes');
      if (studyMinutesJson != null) {
        _subjectStudyMinutes = Map<String, int>.from(jsonDecode(studyMinutesJson));
      }

      final weeklyHistoryJson = _prefs!.getString('weekly_study_history');
      if (weeklyHistoryJson != null) {
        _weeklyStudyHistory = Map<String, int>.from(jsonDecode(weeklyHistoryJson));
      }

      _currentStreak = _prefs!.getInt('current_streak') ?? 0;
      _lastStudyDate = _prefs!.getString('last_study_date') ?? '';
      
      // Calculate today's study minutes properly by checking if last study date is today
      final now = DateTime.now();
      final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      if (_lastStudyDate == todayStr) {
        _todayStudyMinutes = _prefs!.getInt('today_study_minutes') ?? 0;
      } else {
        _todayStudyMinutes = 0;
      }

      unawaited(NativeService.updateWidget(streak: _currentStreak, focusMinutes: _todayStudyMinutes));

      final userJson = _prefs!.getString('user_profile');
      if (userJson != null) {
        _userProfile = UserProfile.fromJson(jsonDecode(userJson));
      }


      // Load custom subjects or load syllabus from assets
      final customSubsJson = _prefs!.getString('custom_subjects');
      if (customSubsJson != null) {
        final list = jsonDecode(customSubsJson) as List<dynamic>;
        _subjects = list.map((s) => Subject.fromJson(s)).toList();
      } else {
        final syllabusString = await rootBundle.loadString('assets/data/syllabus.json');
        final cleanSyllabus = syllabusString.replaceFirst('\uFEFF', '');
        final syllabusJson = jsonDecode(cleanSyllabus) as List<dynamic>;
        _subjects = syllabusJson.map((s) => Subject.fromJson(s)).toList();
      }
    } catch (e, st) {
      debugPrint('Failed to load user preferences or syllabus: $e\n$st');
    }

    try {
      // Load quotes
      final quotesString = await rootBundle.loadString('assets/data/quotes.json');
      final cleanQuotes = quotesString.replaceFirst('\uFEFF', '');
      final quotesJson = jsonDecode(cleanQuotes) as List<dynamic>;
      _quotes = quotesJson.map((q) => Quote.fromJson(q)).toList();
    } catch (e, st) {
      debugPrint('Failed to load quotes: $e\n$st');
    }

    try {
      // Load questions
      final questionsString = await rootBundle.loadString('assets/data/questions.json');
      final cleanQuestions = questionsString.replaceFirst('\uFEFF', '');
      final questionsJson = jsonDecode(cleanQuestions) as List<dynamic>;
      _questions = questionsJson.map((q) => Question.fromJson(q)).toList();
    } catch (e, st) {
      debugPrint('Failed to load questions: $e\n$st');
    }

    try {
      // Load PYQs
      final pyqsString = await rootBundle.loadString('assets/data/pyqs.json');
      final cleanPyqs = pyqsString.replaceFirst('\uFEFF', '');
      final pyqsJson = jsonDecode(cleanPyqs) as List<dynamic>;
      _pyqs = pyqsJson.map((p) => PYQItem.fromJson(p)).toList();
    } catch (e, st) {
      debugPrint('Failed to load pyqs: $e\n$st');
    }

    try {
      // Load Structured Schedule Slots
      final scheduleStr = _prefs!.getString('user_schedule_slots');
      if (scheduleStr != null && scheduleStr.isNotEmpty) {
        final list = jsonDecode(scheduleStr) as List<dynamic>;
        _scheduleSlots = list.map((s) => TimetableSlot.fromJson(s)).toList();
      }
      if (_scheduleSlots.isEmpty) {
        _scheduleSlots = generateWeeklyTimetable();
        await saveScheduleSlots(_scheduleSlots);
      }
    } catch (e, st) {
      debugPrint('Failed to load schedule slots: $e\n$st');
      _scheduleSlots = generateWeeklyTimetable();
    }

    try {
      // Load Notes
      final notesJsonStr = _prefs!.getString('user_notes');
      if (notesJsonStr != null) {
        final list = jsonDecode(notesJsonStr) as List<dynamic>;
        _notes = list.map((n) => NoteItem.fromJson(n)).toList();
      }
    } catch (e, st) {
      debugPrint('Failed to load notes: $e\n$st');
    }

    try {
      // Load Feedback
      final feedbackJsonStr = _prefs!.getString('user_feedback');
      if (feedbackJsonStr != null) {
        final list = jsonDecode(feedbackJsonStr) as List<dynamic>;
        _feedback = list.map((f) => FeedbackItem.fromJson(f)).toList();
      }
    } catch (e, st) {
      debugPrint('Failed to load feedback: $e\n$st');
    }

    try {
      // Load Completed Timetable Slots
      final completedSlotsStr = _prefs!.getString('completed_slots');
      if (completedSlotsStr != null) {
        final list = jsonDecode(completedSlotsStr) as List<dynamic>;
        _completedSlotIds = list.map((e) => e.toString()).toSet();
      }
    } catch (e, st) {
      debugPrint('Failed to load completed slots: $e\n$st');
    }

    try {
      // Load Custom Holidays
      final customHolidaysStr = _prefs!.getString('custom_holidays');
      if (customHolidaysStr != null) {
        final list = jsonDecode(customHolidaysStr) as List<dynamic>;
        _customHolidays = list.map((e) => e as Map<String, dynamic>).toList();
      }
    } catch (e, st) {
      debugPrint('Failed to load custom holidays: $e\n$st');
    }

    try {
      // Load Internal Assessments
      final iaJsonStr = _prefs!.getString('internal_assessments');
      if (iaJsonStr != null) {
        final map = jsonDecode(iaJsonStr) as Map<String, dynamic>;
        _internalAssessments = map.map(
          (k, v) => MapEntry(k, InternalAssessmentRecord.fromJson(v as Map<String, dynamic>)),
        );
      }
    } catch (e, st) {
      debugPrint('Failed to load internal assessments: $e\n$st');
    }

    try {
      // Load Goals
      final goalsJsonStr = _prefs!.getString('user_goals');
      if (goalsJsonStr != null) {
        final list = jsonDecode(goalsJsonStr) as List<dynamic>;
        _goals = list.map((g) => GoalItem.fromJson(g as Map<String, dynamic>)).toList();
      }
      if (_goals.isEmpty) {
        _goals = _generateDefaultGoals();
        await saveGoals(_goals);
      }
    } catch (e, st) {
      debugPrint('Failed to load goals: $e\n$st');
      _goals = _generateDefaultGoals();
    }

    try {
      _savedCustomSpotifyUri = _prefs!.getString('custom_spotify_uri') ?? '';
    } catch (_) {}

    _initialized = true;
  }

  Future<void> setOnboardingCompleted(bool completed) async {
    _hasCompletedOnboarding = completed;
    await _prefs?.setBool('has_completed_onboarding', completed);
  }

  Future<void> setGeminiApiKey(String apiKey) async {
    _geminiApiKey = apiKey;
    await _prefs?.setString('gemini_api_key', apiKey);
  }

  Future<void> logStudyTime(String subjectId, int minutes) async {
    // Subject cumulative minutes
    _subjectStudyMinutes[subjectId] = (_subjectStudyMinutes[subjectId] ?? 0) + minutes;
    await _prefs?.setString('subject_study_minutes', jsonEncode(_subjectStudyMinutes));

    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    // Update weekly history
    _weeklyStudyHistory[todayStr] = (_weeklyStudyHistory[todayStr] ?? 0) + minutes;
    await _prefs?.setString('weekly_study_history', jsonEncode(_weeklyStudyHistory));

    // Streak logic
    final yesterday = now.subtract(const Duration(days: 1));
    final yesterdayStr = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

    if (_lastStudyDate == todayStr) {
      _todayStudyMinutes += minutes;
    } else if (_lastStudyDate == yesterdayStr) {
      _currentStreak += 1;
      _todayStudyMinutes = minutes;
    } else {
      // Missed a day or more (or first time)
      _currentStreak = 1;
      _todayStudyMinutes = minutes;
    }

    _lastStudyDate = todayStr;

    await _prefs?.setInt('current_streak', _currentStreak);
    await _prefs?.setString('last_study_date', _lastStudyDate);
    await _prefs?.setInt('today_study_minutes', _todayStudyMinutes);

    // Update active study goals
    _goals = [
      for (final g in _goals)
        if (g.type == GoalType.daily && g.category == 'Study Hours')
          g.copyWith(
            currentMinutes: _todayStudyMinutes,
            isCompleted: _todayStudyMinutes >= g.targetMinutes,
          )
        else if (g.type == GoalType.weekly && g.category == 'Study Hours')
          g.copyWith(
            currentMinutes: g.currentMinutes + minutes,
            isCompleted: (g.currentMinutes + minutes) >= g.targetMinutes,
          )
        else
          g
    ];
    await _prefs?.setString('user_goals', jsonEncode(_goals.map((g) => g.toJson()).toList()));

    unawaited(NativeService.updateWidget(streak: _currentStreak, focusMinutes: _todayStudyMinutes));
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    _userProfile = profile;
    await _prefs?.setString('user_profile', jsonEncode(profile.toJson()));
  }

  Future<void> toggleSubjectExclusion(String subjectId) async {
    _subjects = [
      for (final s in _subjects)
        if (s.id == subjectId)
          s.copyWith(isExcluded: !s.isExcluded)
        else
          s
    ];
    await _prefs?.setString('custom_subjects', jsonEncode(_subjects.map((s) => s.toJson()).toList()));
  }

  Future<void> addCustomSubject(Subject newSubject) async {
    _subjects = [..._subjects, newSubject];
    await _prefs?.setString('custom_subjects', jsonEncode(_subjects.map((s) => s.toJson()).toList()));
  }

  Future<void> saveNotes(List<NoteItem> notes) async {
    _notes = notes;
    await _prefs?.setString('user_notes', jsonEncode(notes.map((n) => n.toJson()).toList()));
  }

  Future<void> saveFeedback(List<FeedbackItem> feedback) async {
    _feedback = feedback;
    await _prefs?.setString('user_feedback', jsonEncode(feedback.map((f) => f.toJson()).toList()));
  }

  Future<void> saveCompletedSlots(Set<String> completedSlotIds) async {
    _completedSlotIds = completedSlotIds;
    await _prefs?.setString('completed_slots', jsonEncode(completedSlotIds.toList()));
  }

  Future<void> saveCustomHolidays(List<Map<String, dynamic>> customHolidays) async {
    _customHolidays = customHolidays;
    await _prefs?.setString('custom_holidays', jsonEncode(customHolidays));
  }

  Future<void> saveScheduleSlots(List<TimetableSlot> slots) async {
    _scheduleSlots = slots;
    await _prefs?.setString('user_schedule_slots', jsonEncode(slots.map((s) => s.toJson()).toList()));
  }

  Future<void> addScheduleSlot(TimetableSlot slot) async {
    _scheduleSlots = [..._scheduleSlots, slot];
    await saveScheduleSlots(_scheduleSlots);
  }

  Future<void> updateScheduleSlot(TimetableSlot updatedSlot) async {
    _scheduleSlots = [
      for (final s in _scheduleSlots)
        if (s.id == updatedSlot.id) updatedSlot else s
    ];
    await saveScheduleSlots(_scheduleSlots);
  }

  Future<void> deleteScheduleSlot(String slotId) async {
    _scheduleSlots = _scheduleSlots.where((s) => s.id != slotId).toList();
    await saveScheduleSlots(_scheduleSlots);
  }

  Future<void> toggleScheduleSlotCompleted(String slotId) async {
    _scheduleSlots = [
      for (final s in _scheduleSlots)
        if (s.id == slotId) s.copyWith(isCompleted: !s.isCompleted) else s
    ];
    await saveScheduleSlots(_scheduleSlots);
  }

  List<Question> getQuestionsForSubject(String subjectId) {
    return _questions.where((q) => q.subjectId == subjectId).toList();
  }

  List<PYQItem> getPyqsForSubject(String subjectId) {
    return _pyqs.where((p) => p.subjectId == subjectId).toList();
  }

  // ==========================================
  // Internal Assessment (CCE 40M) API & Storage
  // ==========================================

  InternalAssessmentRecord getAssessmentForSubject(Subject subject) {
    if (_internalAssessments.containsKey(subject.id)) {
      return _internalAssessments[subject.id]!;
    }
    final defaultRec = InternalAssessmentRecord(
      subjectId: subject.id,
      subjectName: subject.name,
      unitTestMarks: 10.0,
      assignmentsMarks: 10.0,
      quizSeminarMarks: 5.0,
      miniProjectMarks: 8.5,
      termWorkMarks: 22.0,
      endSemMarks: 48.0,
    );
    _internalAssessments[subject.id] = defaultRec;
    return defaultRec;
  }

  Future<void> saveAssessment(InternalAssessmentRecord record) async {
    _internalAssessments[record.subjectId] = record;
    final map = _internalAssessments.map((k, v) => MapEntry(k, v.toJson()));
    await _prefs?.setString('internal_assessments', jsonEncode(map));
  }

  Future<void> autoUpdateQuizScore(String subjectId, double quizScoreOutOf6) async {
    final current = _internalAssessments[subjectId];
    if (current != null) {
      final updated = current.copyWith(quizSeminarMarks: quizScoreOutOf6.clamp(0.0, 6.0));
      await saveAssessment(updated);
    }
  }

  Future<void> autoUpdateUnitTestScore(String subjectId, double unitScoreOutOf12) async {
    final current = _internalAssessments[subjectId];
    if (current != null) {
      final updated = current.copyWith(unitTestMarks: unitScoreOutOf12.clamp(0.0, 12.0));
      await saveAssessment(updated);
    }
  }

  // ==========================================
  // Goals (Daily, Weekly, Monthly) Management
  // ==========================================

  List<GoalItem> _generateDefaultGoals() {
    final now = DateTime.now();
    return [
      GoalItem(
        id: 'goal_daily_hours',
        title: 'Daily Focus Target (${_userProfile.dailyStudyHours} hrs)',
        type: GoalType.daily,
        targetMinutes: _userProfile.dailyStudyHours * 60,
        currentMinutes: 0,
        category: 'Study Hours',
        createdAt: now,
      ),
      GoalItem(
        id: 'goal_daily_quiz',
        title: 'Complete 1 SPPU Unit Practice Quiz',
        type: GoalType.daily,
        targetMinutes: 1,
        currentMinutes: 0,
        category: 'Quiz Practice',
        createdAt: now,
      ),
      GoalItem(
        id: 'goal_weekly_deepwork',
        title: 'Log 20+ Hours of Distraction-Free Study',
        type: GoalType.weekly,
        targetMinutes: 20 * 60,
        currentMinutes: 0,
        category: 'Study Hours',
        createdAt: now,
      ),
      GoalItem(
        id: 'goal_weekly_pyq',
        title: 'Review 5 SPPU Previous Year Question Papers',
        type: GoalType.weekly,
        targetMinutes: 5,
        currentMinutes: 0,
        category: 'PYQ Practice',
        createdAt: now,
      ),
      GoalItem(
        id: 'goal_monthly_cce',
        title: 'Maintain 35+/40 in SPPU CCE Assessments',
        type: GoalType.monthly,
        targetMinutes: 35,
        currentMinutes: 0,
        category: 'Assessment',
        createdAt: now,
      ),
      GoalItem(
        id: 'goal_monthly_syllabus',
        title: 'Complete Units 1 to 3 across active semester',
        type: GoalType.monthly,
        targetMinutes: 15,
        currentMinutes: 0,
        category: 'Syllabus Unit',
        createdAt: now,
      ),
    ];
  }

  Future<void> saveGoals(List<GoalItem> goals) async {
    _goals = goals;
    await _prefs?.setString('user_goals', jsonEncode(goals.map((g) => g.toJson()).toList()));
  }

  Future<void> addGoal(GoalItem goal) async {
    _goals = [..._goals, goal];
    await saveGoals(_goals);
  }

  Future<void> toggleGoalCompleted(String goalId) async {
    _goals = [
      for (final g in _goals)
        if (g.id == goalId) g.copyWith(isCompleted: !g.isCompleted) else g
    ];
    await saveGoals(_goals);
  }

  Future<void> deleteGoal(String goalId) async {
    _goals = _goals.where((g) => g.id != goalId).toList();
    await saveGoals(_goals);
  }

  Future<void> saveCustomSpotifyUri(String uri) async {
    _savedCustomSpotifyUri = uri;
    await _prefs?.setString('custom_spotify_uri', uri);
  }

  int _parseTimeToMinutes(String timeStr, int defaultMinutes) {
    try {
      final cleaned = timeStr.trim().toUpperCase();
      final isPm = cleaned.contains('PM');
      final isAm = cleaned.contains('AM');
      final parts = cleaned.replaceAll('AM', '').replaceAll('PM', '').trim().split(':');
      int h = int.parse(parts[0].trim());
      int m = parts.length > 1 ? int.parse(parts[1].trim()) : 0;
      if (isPm && h < 12) h += 12;
      if (isAm && h == 12) h = 0;
      return h * 60 + m;
    } catch (_) {
      return defaultMinutes;
    }
  }

  /// Generate SPPU 7-day realistic weekly timetable (Structured style)
  /// Automatically takes college timings and peak motivation windows into account!
  List<TimetableSlot> generateWeeklyTimetable({List<Subject>? customSubjects}) {
    final pool = customSubjects ?? _subjects;
    var semSubjects = pool
        .where((s) => s.semester == _userProfile.semester && !s.isExcluded)
        .toList();

    if (semSubjects.isEmpty && pool.isNotEmpty) {
      semSubjects = pool.where((s) => !s.isExcluded).toList();
    }

    if (semSubjects.isEmpty) return [];

    final slots = <TimetableSlot>[];
    final daysOfWeek = [1, 2, 3, 4, 5, 6, 7]; // Mon to Sun

    for (final day in daysOfWeek) {
      if (day == 7) {
        // Sunday: Full-length Revision & Mock Test slot
        slots.add(
          TimetableSlot(
            id: 'slot_sun_rev_1',
            subjectId: semSubjects.first.id,
            subjectName: 'Weekly Revision & PYQ Practice',
            unitName: 'Mock Exam Diagnostics & Weak Areas Review',
            unitNumber: 1,
            timeRange: '10:00 - 12:00',
            durationMinutes: 120,
            dayOfWeek: 7,
            startHour: 10,
            startMinute: 0,
            isWeakSubject: true,
            notes: 'Comprehensive revision of difficult derivations and time-trap questions.',
          ),
        );
        continue;
      }

      // Monday to Saturday: Schedule outside of college timings based on peak motivation window
      final collegeStartMinutes = _parseTimeToMinutes(_userProfile.collegeStartTime, 9 * 60); // Default 9:00 AM
      final collegeEndMinutes = _parseTimeToMinutes(_userProfile.collegeEndTime, 16 * 60 + 30); // Default 4:30 PM

      int currentHour = 17; // Default: 5:00 PM after college
      int currentMinute = 0;

      final peak = _userProfile.peakMotivationWindow.toLowerCase();
      if (peak.contains('morning') || peak.contains('early')) {
        currentHour = 6;
        currentMinute = 30;
      } else if (peak.contains('night')) {
        currentHour = 20;
        currentMinute = 0;
      } else {
        currentHour = (collegeEndMinutes + 45) ~/ 60;
        currentMinute = (collegeEndMinutes + 45) % 60;
      }

      // Rotate subjects per day for balanced weekly distribution
      final dayOffset = (day - 1) % semSubjects.length;
      final daySubjects = [
        for (int j = 0; j < 3; j++)
          semSubjects[(dayOffset + j) % semSubjects.length]
      ];

      for (int i = 0; i < daySubjects.length; i++) {
        final subject = daySubjects[i];
        final isWeak = _userProfile.hardSubjects.contains(subject.id);
        final duration = isWeak ? 75 : 60;

        int slotStartMinutes = currentHour * 60 + currentMinute;
        int slotEndMinutes = slotStartMinutes + duration;

        // Collision Avoidance: If slot overlaps with college hours, jump after college
        if (slotEndMinutes > collegeStartMinutes && slotStartMinutes < collegeEndMinutes) {
          slotStartMinutes = collegeEndMinutes + 30;
          slotEndMinutes = slotStartMinutes + duration;
          currentHour = slotStartMinutes ~/ 60;
          currentMinute = slotStartMinutes % 60;
        }

        final startH = slotStartMinutes ~/ 60;
        final startM = slotStartMinutes % 60;
        final endH = slotEndMinutes ~/ 60;
        final endM = slotEndMinutes % 60;

        final startStr = '${startH.toString().padLeft(2, '0')}:${startM.toString().padLeft(2, '0')}';
        final endStr = '${endH.toString().padLeft(2, '0')}:${endM.toString().padLeft(2, '0')}';

        final unitIndex = (day + i) % (subject.units.isNotEmpty ? subject.units.length : 1);
        final unit = subject.units.isNotEmpty
            ? subject.units[unitIndex]
            : Unit(unitNumber: 1, name: 'Core Principles', hours: 8, weightage: 'High');

        final slotId = 'slot_d${day}_s${subject.id}_$i';

        slots.add(
          TimetableSlot(
            id: slotId,
            subjectId: subject.id,
            subjectName: subject.name,
            unitName: unit.name,
            unitNumber: unit.unitNumber,
            timeRange: '$startStr - $endStr',
            durationMinutes: duration,
            dayOfWeek: day,
            startHour: startH,
            startMinute: startM,
            isWeakSubject: isWeak,
            notes: 'SPPU 2024 Pattern syllabus block. Focus on numericals & diagrams.',
          ),
        );

        // Add 15 min break between slots
        int nextTotal = slotEndMinutes + 15;
        currentHour = nextTotal ~/ 60;
        currentMinute = nextTotal % 60;
      }
    }

    return slots;
  }

  /// Backward compatible helper for today's generated timetable
  List<TimetableSlot> generateTimetable() {
    return _scheduleSlots;
  }
}
