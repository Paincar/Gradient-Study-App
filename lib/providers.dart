import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/native_service.dart';
import 'data/datasources/local_store.dart';
import 'data/models/models.dart';

// User Profile Provider
final userProfileNotifierProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfile>((ref) {
  final store = ref.watch(localStoreProvider);
  return UserProfileNotifier(store);
});

class UserProfileNotifier extends StateNotifier<UserProfile> {
  final LocalStore _store;

  UserProfileNotifier(this._store) : super(_store.userProfile);

  Future<void> updateProfile(UserProfile newProfile) async {
    final oldProfile = state;
    state = newProfile;
    try {
      await _store.saveUserProfile(newProfile);
    } catch (e) {
      state = oldProfile;
      debugPrint('Failed to save profile: $e');
    }
  }

  Future<void> setPalette(String paletteKey) async {
    await updateProfile(state.copyWith(accentPalette: paletteKey));
  }

  Future<void> toggleDarkMode() async {
    await updateProfile(state.copyWith(isDarkMode: !state.isDarkMode));
  }

  Future<void> toggleDnd() async {
    await updateProfile(state.copyWith(dndEnabled: !state.dndEnabled));
  }

  Future<void> updateCustomAiPrompt(String customPrompt) async {
    await updateProfile(state.copyWith(customAiPrompt: customPrompt));
  }

  Future<void> recordQuizMastery({
    required String subjectId,
    required int unitNumber,
    required int score,
    required int total,
  }) async {
    if (total <= 0) return;
    final newPct = score / total;
    final key = '$subjectId:$unitNumber';
    final existing = state.unitMastery[key];

    final updatedMastery = Map<String, double>.from(state.unitMastery);
    if (existing != null) {
      // Rolling mastery calculation: 40% historical + 60% recent performance
      updatedMastery[key] = double.parse(((existing * 0.4) + (newPct * 0.6)).toStringAsFixed(2));
    } else {
      updatedMastery[key] = double.parse(newPct.toStringAsFixed(2));
    }

    // If unit mastery dropped below 60%, automatically ensure subject receives timetable boost
    final updatedHard = List<String>.from(state.hardSubjects);
    if (updatedMastery[key]! < 0.60 && !updatedHard.contains(subjectId)) {
      updatedHard.add(subjectId);
    }

    await updateProfile(state.copyWith(
      unitMastery: updatedMastery,
      hardSubjects: updatedHard,
    ));
  }
}

// Subjects Provider
final subjectsNotifierProvider =
    StateNotifierProvider<SubjectsNotifier, List<Subject>>((ref) {
  final store = ref.watch(localStoreProvider);
  return SubjectsNotifier(store, ref);
});

class SubjectsNotifier extends StateNotifier<List<Subject>> {
  final LocalStore _store;
  final Ref _ref;

  SubjectsNotifier(this._store, this._ref) : super(_store.subjects);

  Future<void> toggleExclusion(String subjectId) async {
    await _store.toggleSubjectExclusion(subjectId);
    state = [..._store.subjects];
    _ref.read(timetableNotifierProvider.notifier).refresh();
  }

  Future<void> addSubject(Subject subject) async {
    await _store.addCustomSubject(subject);
    state = [..._store.subjects];
    _ref.read(timetableNotifierProvider.notifier).refresh();
  }
}

// Timetable Provider
final timetableNotifierProvider =
    StateNotifierProvider<TimetableNotifier, List<TimetableSlot>>((ref) {
  final store = ref.watch(localStoreProvider);
  return TimetableNotifier(store);
});

class TimetableNotifier extends StateNotifier<List<TimetableSlot>> {
  final LocalStore _store;

  TimetableNotifier(this._store) : super([]) {
    refresh();
  }

  void refresh() {
    if (_store.scheduleSlots.isEmpty) {
      final generated = _store.generateWeeklyTimetable();
      _store.saveScheduleSlots(generated);
      state = generated;
    } else {
      state = [..._store.scheduleSlots];
    }
  }

  Future<void> addSlot(TimetableSlot slot) async {
    await _store.addScheduleSlot(slot);
    state = [..._store.scheduleSlots];

    if (slot.hasReminder) {
      _scheduleNativeNotification(slot);
    }
  }

  Future<void> updateSlot(TimetableSlot slot) async {
    await _store.updateScheduleSlot(slot);
    state = [..._store.scheduleSlots];

    if (slot.hasReminder) {
      _scheduleNativeNotification(slot);
    }
  }

  Future<void> deleteSlot(String slotId) async {
    await _store.deleteScheduleSlot(slotId);
    state = [..._store.scheduleSlots];
  }

  Future<void> toggleCompleted(String slotId) async {
    await _store.toggleScheduleSlotCompleted(slotId);
    state = [..._store.scheduleSlots];
  }

  Future<void> regenerateWeeklySchedule() async {
    final freshSlots = _store.generateWeeklyTimetable();
    await _store.saveScheduleSlots(freshSlots);
    state = freshSlots;
  }

  void _scheduleNativeNotification(TimetableSlot slot) {
    try {
      final now = DateTime.now();
      // Calculate next occurrence of this slot's dayOfWeek & start time
      int daysAhead = (slot.dayOfWeek - now.weekday) % 7;
      if (daysAhead < 0) daysAhead += 7;
      
      var targetDate = DateTime(
        now.year,
        now.month,
        now.day,
      ).add(Duration(days: daysAhead, hours: slot.startHour, minutes: slot.startMinute));
      
      if (daysAhead == 0 && targetDate.isBefore(now)) {
        targetDate = targetDate.add(const Duration(days: 7));
      }

      // Remind 5 minutes before
      final reminderTime = targetDate.subtract(const Duration(minutes: 5));
      if (reminderTime.isAfter(now)) {
        NativeService.scheduleAlarm(
          id: slot.id.hashCode.abs() % 100000,
          title: 'Upcoming: ${slot.subjectName}',
          body: 'Unit ${slot.unitNumber}: ${slot.unitName} starts at ${slot.timeRange}. Get ready! 📖',
          triggerAt: reminderTime,
        );
      }
    } catch (e) {
      debugPrint('Failed to schedule reminder for slot: $e');
    }
  }
}

// Notes Provider
final notesNotifierProvider =
    StateNotifierProvider<NotesNotifier, List<NoteItem>>((ref) {
  final store = ref.watch(localStoreProvider);
  return NotesNotifier(store);
});

class NotesNotifier extends StateNotifier<List<NoteItem>> {
  final LocalStore _store;

  NotesNotifier(this._store) : super([]) {
    if (_store.notes.isEmpty) {
      // Setup initial dummy notes if empty
      state = [
        NoteItem(
          id: 'n1',
          title: 'M1 - Leibnitz Theorem Formula Sheet',
          content:
              'Leibnitz Formula for nth derivative of uv:\n(uv)_n = u_n v + nC1 u_{n-1} v_1 + nC2 u_{n-2} v_2 + ... + u v_n.\n\nKey trick: Keep algebraic polynomial as v so higher derivatives vanish quickly!',
          subjectId: 'm1',
          subjectName: 'Engineering Mathematics - I',
          updatedAt: DateTime.now().subtract(const Duration(hours: 3)),
          isPinned: true,
        ),
        NoteItem(
          id: 'n2',
          title: 'Physics - Thin Film Optical Path Difference',
          content:
              'For reflected light:\nDelta = 2 * mu * t * cos(r) - lambda/2 (Stokes condition at denser medium).\nBright Fringe: 2 * mu * t * cos(r) = (2n + 1) * lambda / 2\nDark Fringe: 2 * mu * t * cos(r) = n * lambda',
          subjectId: 'physics',
          subjectName: 'Engineering Physics',
          updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        NoteItem(
          id: 'n3',
          title: 'BXE - Op-Amp Virtual Ground Concept',
          content:
              'Because open loop gain A is infinite, the differential input voltage Vd = V+ - V- = Vo/A = 0.\nTherefore, V+ = V-. In an inverting amplifier where V+ is grounded, V- acts as a virtual ground!',
          subjectId: 'bxe',
          subjectName: 'Basic Electronics',
          updatedAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ];
      _saveNotes();
    } else {
      state = [..._store.notes];
    }
  }

  Future<void> _saveNotes() async {
    await _store.saveNotes(state);
  }

  Future<void> saveNotes(List<NoteItem> notes) async {
    state = notes;
    await _store.saveNotes(notes);
  }

  Future<void> addNote(NoteItem note) async {
    state = [note, ...state];
    await _saveNotes();
  }

  Future<void> updateNote(NoteItem updatedNote) async {
    state = [
      for (final n in state)
        if (n.id == updatedNote.id) updatedNote else n
    ];
    await _saveNotes();
  }

  Future<void> togglePin(String id) async {
    state = [
      for (final n in state)
        if (n.id == id)
          n.copyWith(isPinned: !n.isPinned)
        else
          n
    ];
    await _saveNotes();
  }

  Future<void> deleteNote(String id) async {
    state = state.where((n) => n.id != id).toList();
    await _saveNotes();
  }
}

// Feedback Provider
final feedbackNotifierProvider =
    StateNotifierProvider<FeedbackNotifier, List<FeedbackItem>>((ref) {
  final store = ref.watch(localStoreProvider);
  return FeedbackNotifier(store);
});

class FeedbackNotifier extends StateNotifier<List<FeedbackItem>> {
  final LocalStore _store;

  FeedbackNotifier(this._store) : super([..._store.feedback]);

  Future<void> submitFeedback(FeedbackItem item) async {
    state = [item, ...state];
    await _store.saveFeedback(state);
  }
}

// Gemini API Key Provider
final geminiApiKeyProvider = StateProvider<String>((ref) {
  return ref.watch(localStoreProvider).geminiApiKey;
});

// Internal Assessments Provider
final internalAssessmentsNotifierProvider = StateNotifierProvider<
    InternalAssessmentsNotifier, Map<String, InternalAssessmentRecord>>((ref) {
  final store = ref.watch(localStoreProvider);
  return InternalAssessmentsNotifier(store);
});

class InternalAssessmentsNotifier
    extends StateNotifier<Map<String, InternalAssessmentRecord>> {
  final LocalStore _store;

  InternalAssessmentsNotifier(this._store)
      : super({..._store.internalAssessments});

  Future<void> saveAssessment(InternalAssessmentRecord record) async {
    await _store.saveAssessment(record);
    state = {..._store.internalAssessments};
  }

  Future<void> autoUpdateQuizScore(String subjectId, double quizScoreOutOf6) async {
    await _store.autoUpdateQuizScore(subjectId, quizScoreOutOf6);
    state = {..._store.internalAssessments};
  }

  Future<void> autoUpdateUnitTestScore(String subjectId, double unitScoreOutOf12) async {
    await _store.autoUpdateUnitTestScore(subjectId, unitScoreOutOf12);
    state = {..._store.internalAssessments};
  }
}

// Goals Provider
final goalsNotifierProvider =
    StateNotifierProvider<GoalsNotifier, List<GoalItem>>((ref) {
  final store = ref.watch(localStoreProvider);
  return GoalsNotifier(store);
});

class GoalsNotifier extends StateNotifier<List<GoalItem>> {
  final LocalStore _store;

  GoalsNotifier(this._store) : super([..._store.goals]);

  Future<void> addGoal(GoalItem goal) async {
    await _store.addGoal(goal);
    state = [..._store.goals];
  }

  Future<void> toggleGoalCompleted(String goalId) async {
    await _store.toggleGoalCompleted(goalId);
    state = [..._store.goals];
  }

  Future<void> deleteGoal(String goalId) async {
    await _store.deleteGoal(goalId);
    state = [..._store.goals];
  }

  void refresh() {
    state = [..._store.goals];
  }
}

