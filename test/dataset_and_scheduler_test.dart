import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:focuspath/data/datasources/local_store.dart';
import 'package:focuspath/data/models/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Subjectwise Question Datasets Verification', () {
    final subjects = [
      'm1',
      'physics',
      'bxe',
      'eg',
      'fpl',
      'm2',
      'chemistry',
      'bee',
      'mechanics',
      'pps',
    ];

    for (final subId in subjects) {
      test('Subject questions dataset for "$subId" exists, is valid JSON and well-formed', () {
        final file = File('assets/data/questions/$subId.json');
        expect(file.existsSync(), isTrue, reason: 'File assets/data/questions/$subId.json should exist');

        final jsonString = file.readAsStringSync();
        final dynamic rawList = jsonDecode(jsonString);
        expect(rawList, isA<List>());

        final list = rawList as List;
        expect(list.isNotEmpty, isTrue, reason: 'Questions for $subId should not be empty');

        final units = <int>{};
        for (final item in list) {
          final q = Question.fromJson(item as Map<String, dynamic>);
          expect(q.subjectId, equals(subId));
          expect(q.options.length, equals(4), reason: 'Every MCQ must have exactly 4 options');
          expect(q.correctOption, inInclusiveRange(0, 3), reason: 'Correct option index must be 0, 1, 2, or 3');
          expect(q.questionText.trim().isNotEmpty, isTrue);
          expect(q.explanation.trim().isNotEmpty, isTrue);
          expect(q.topic.trim().isNotEmpty, isTrue);
          expect(q.unitNumber, inInclusiveRange(1, 5), reason: 'Unit number must be 1 to 5');
          units.add(q.unitNumber);
        }

        // Verify that questions cover all 5 units
        for (int u = 1; u <= 5; u++) {
          expect(units.contains(u), isTrue, reason: 'Subject $subId must contain questions for Unit $u');
        }
      });
    }

    test('Master aggregated questions.json is consistent with subject files', () {
      final masterFile = File('assets/data/questions.json');
      expect(masterFile.existsSync(), isTrue);

      final masterList = jsonDecode(masterFile.readAsStringSync()) as List;
      expect(masterList.length, greaterThanOrEqualTo(80));

      final uniqueIds = <String>{};
      for (final item in masterList) {
        final q = Question.fromJson(item as Map<String, dynamic>);
        expect(uniqueIds.add(q.id), isTrue, reason: 'Duplicate question ID found: ${q.id}');
      }
    });

    test('PYQ Dataset in assets/data/pyqs.json is well-formed with model answers', () {
      final pyqFile = File('assets/data/pyqs.json');
      expect(pyqFile.existsSync(), isTrue);

      final pyqList = jsonDecode(pyqFile.readAsStringSync()) as List;
      expect(pyqList.isNotEmpty, isTrue);

      for (final item in pyqList) {
        final p = PYQItem.fromJson(item as Map<String, dynamic>);
        expect(p.id.isNotEmpty, isTrue);
        expect(p.subjectId.isNotEmpty, isTrue);
        expect(p.unitNumber, inInclusiveRange(1, 5));
        expect(p.exam.isNotEmpty, isTrue);
        expect(p.marks, inInclusiveRange(2, 15));
        expect(p.questionText.isNotEmpty, isTrue);
        expect(p.modelAnswer.isNotEmpty, isTrue);
        expect(p.stepMarking.isNotEmpty, isTrue);
      }
    });
  });

  group('Structured Scheduler & Timetable Tests', () {
    test('generateWeeklyTimetable produces a valid 7-day schedule', () {
      final syllabusFile = File('assets/data/syllabus.json');
      expect(syllabusFile.existsSync(), isTrue);
      final syllabusJson = jsonDecode(syllabusFile.readAsStringSync()) as List;
      final syllabusSubjects = syllabusJson.map((s) => Subject.fromJson(s as Map<String, dynamic>)).toList();

      final store = LocalStore();
      final slots = store.generateWeeklyTimetable(customSubjects: syllabusSubjects);

      expect(slots.isNotEmpty, isTrue);

      // Verify all 7 days of the week are covered
      final days = slots.map((s) => s.dayOfWeek).toSet();
      for (int day = 1; day <= 7; day++) {
        expect(days.contains(day), isTrue, reason: 'Schedule should have slots for Day $day');
      }

      for (final slot in slots) {
        expect(slot.dayOfWeek, inInclusiveRange(1, 7));
        expect(slot.startHour, inInclusiveRange(6, 23));
        expect(slot.startMinute, inInclusiveRange(0, 59));
        expect(slot.durationMinutes, greaterThan(0));
        expect(slot.timeRange.isNotEmpty, isTrue);
        expect(slot.subjectName.isNotEmpty, isTrue);
      }
    });

    test('TimetableSlot serialization and deserialization retains all fields', () {
      final original = TimetableSlot(
        id: 'slot_test_1',
        dayOfWeek: 3,
        timeRange: '10:00 AM - 11:30 AM',
        startHour: 10,
        startMinute: 0,
        durationMinutes: 90,
        subjectId: 'm1',
        subjectName: 'Engineering Mathematics 1',
        unitNumber: 2,
        unitName: 'Partial Differentiation',
        isCustomTask: true,
        hasReminder: true,
        notes: 'Practice Euler theorem questions',
        isCompleted: true,
      );

      final jsonMap = original.toJson();
      final reconstructed = TimetableSlot.fromJson(jsonMap);

      expect(reconstructed.id, equals(original.id));
      expect(reconstructed.dayOfWeek, equals(original.dayOfWeek));
      expect(reconstructed.timeRange, equals(original.timeRange));
      expect(reconstructed.startHour, equals(original.startHour));
      expect(reconstructed.startMinute, equals(original.startMinute));
      expect(reconstructed.durationMinutes, equals(original.durationMinutes));
      expect(reconstructed.subjectId, equals(original.subjectId));
      expect(reconstructed.subjectName, equals(original.subjectName));
      expect(reconstructed.unitNumber, equals(original.unitNumber));
      expect(reconstructed.unitName, equals(original.unitName));
      expect(reconstructed.isCustomTask, equals(original.isCustomTask));
      expect(reconstructed.hasReminder, equals(original.hasReminder));
      expect(reconstructed.notes, equals(original.notes));
      expect(reconstructed.isCompleted, equals(original.isCompleted));
    });
  });

  group('AI Personalization Loop & Unit Mastery Diagnostics', () {
    test('Unit mastery calculations and weak unit detection operate correctly', () {
      var profile = const UserProfile(
        name: 'Test Student',
        unitMastery: {
          'm1:2': 0.35, // 35% accuracy -> weak
          'm1:1': 0.85, // 85% accuracy -> strong
        },
        customAiPrompt: 'You are an SPPU topper mentor. Explain step-by-step.',
      );

      expect(profile.getMasteryFor('m1', 2), equals(0.35));
      expect(profile.isUnitWeak('m1', 2), isTrue);
      expect(profile.isUnitWeak('m1', 1), isFalse);

      final mockSubject = Subject(
        id: 'm1',
        name: 'Engineering Mathematics 1',
        code: '107001',
        emoji: '📐',
        color: '#31748f',
        semester: 1,
        teachingHours: 40,
        isExcluded: false,
        units: [
          Unit(unitNumber: 1, name: 'Differential Calculus', hours: 8, weightage: '10%'),
          Unit(unitNumber: 2, name: 'Partial Differentiation', hours: 8, weightage: '12%'),
        ],
      );

      final weakList = profile.getWeakUnitsList([mockSubject]);
      expect(weakList.length, equals(1));
      expect(weakList.first, contains('Engineering Mathematics 1 — Unit 2: Partial Differentiation (35% mastery)'));
      expect(profile.customAiPrompt, contains('topper mentor'));

      // Test copyWith serialization
      final updated = profile.copyWith(
        unitMastery: {...profile.unitMastery, 'm1:2': 0.75},
        customAiPrompt: 'Speak like Iron Man jarvis',
      );
      expect(updated.getMasteryFor('m1', 2), equals(0.75));
      expect(updated.isUnitWeak('m1', 2), isFalse);
      expect(updated.customAiPrompt, equals('Speak like Iron Man jarvis'));

      final json = updated.toJson();
      final loaded = UserProfile.fromJson(json);
      expect(loaded.getMasteryFor('m1', 2), equals(0.75));
      expect(loaded.customAiPrompt, equals('Speak like Iron Man jarvis'));
    });
  });

  group('SPPU FE 2024 Revised Pattern CCE Internal Assessment (40 Marks) Tests', () {
    test('InternalAssessmentRecord calculates CCE total, End-Sem threshold, and grand total correctly', () {
      // Default record: 10 (UT) + 10 (Assign) + 5 (Quiz) + 8.5 (Mini Proj) = 33.5 CCE
      // End-Sem: 48, Term Work: 22 -> Grand total = 103.5 / 125 = 82.8%
      const defaultRec = InternalAssessmentRecord(
        subjectId: 'm1',
        subjectName: 'Engineering Mathematics 1',
      );

      expect(defaultRec.unitTestMarks, equals(10.0));
      expect(defaultRec.assignmentsMarks, equals(10.0));
      expect(defaultRec.quizSeminarMarks, equals(5.0));
      expect(defaultRec.miniProjectMarks, equals(8.5));
      expect(defaultRec.cceTotal, equals(33.5));
      expect(defaultRec.termWorkMarks, equals(22.0));
      expect(defaultRec.endSemMarks, equals(48.0));
      expect(defaultRec.totalTheoryMarks, equals(81.5)); // 33.5 + 48
      expect(defaultRec.grandTotalMarks, equals(103.5)); // 33.5 + 48 + 22
      expect(defaultRec.overallPercentage, closeTo(82.8, 0.01));
      expect(defaultRec.isPassed, isTrue);
      expect(defaultRec.projectedGrade, equals('A+ (Excellent - 9)'));
    });

    test('InternalAssessmentRecord correctly identifies Failures and Grade thresholds', () {
      // Case 1: Fail because End-Sem is below 24 (SPPU passing criterion: min 24/60 in ESE)
      const failEndSem = InternalAssessmentRecord(
        subjectId: 'mechanics',
        subjectName: 'Engineering Mechanics',
        unitTestMarks: 11.0,
        assignmentsMarks: 11.0,
        quizSeminarMarks: 6.0,
        miniProjectMarks: 9.0,
        termWorkMarks: 20.0,
        endSemMarks: 22.0, // Failed (< 24)
      );
      expect(failEndSem.cceTotal, equals(37.0));
      expect(failEndSem.grandTotalMarks, equals(79.0)); // Aggregate is well above 50, but ESE failed
      expect(failEndSem.isPassed, isFalse);
      expect(failEndSem.projectedGrade, equals('F (Fail / Re-appear)'));

      // Case 2: Fail because Grand Total is below 50/125 (40% aggregate)
      const failAggregate = InternalAssessmentRecord(
        subjectId: 'bxe',
        subjectName: 'Basic Electronics Engineering',
        unitTestMarks: 4.0,
        assignmentsMarks: 4.0,
        quizSeminarMarks: 2.0,
        miniProjectMarks: 3.0, // CCE = 13.0
        termWorkMarks: 10.0,
        endSemMarks: 24.0, // Bare minimum ESE pass, but total = 13 + 24 + 10 = 47 (< 50)
      );
      expect(failAggregate.grandTotalMarks, equals(47.0));
      expect(failAggregate.isPassed, isFalse);
      expect(failAggregate.projectedGrade, equals('F (Fail / Re-appear)'));

      // Case 3: Outstanding Grade 'O' (>= 90%)
      const outstanding = InternalAssessmentRecord(
        subjectId: 'physics',
        subjectName: 'Engineering Physics',
        unitTestMarks: 12.0,
        assignmentsMarks: 12.0,
        quizSeminarMarks: 6.0,
        miniProjectMarks: 10.0, // CCE = 40.0
        termWorkMarks: 24.0,
        endSemMarks: 52.0, // Total = 116 / 125 = 92.8%
      );
      expect(outstanding.cceTotal, equals(40.0));
      expect(outstanding.grandTotalMarks, equals(116.0));
      expect(outstanding.overallPercentage, closeTo(92.8, 0.01));
      expect(outstanding.isPassed, isTrue);
      expect(outstanding.projectedGrade, equals('O (Outstanding - 10)'));
    });

    test('requiredEndSemFor calculates the exact score needed for target aggregate', () {
      const rec = InternalAssessmentRecord(
        subjectId: 'm1',
        subjectName: 'Engineering Mathematics 1',
        unitTestMarks: 10.0,
        assignmentsMarks: 10.0,
        quizSeminarMarks: 5.0,
        miniProjectMarks: 8.5, // CCE = 33.5
        termWorkMarks: 22.0,
      );
      // For 80% aggregate: targetTotal = 80 * 1.25 = 100.
      // needed = 100 - 33.5 - 22 = 44.5
      expect(rec.requiredEndSemFor(80.0), closeTo(44.5, 0.01));

      // Cannot be less than passing mark of 24 even if target percentage is low
      expect(rec.requiredEndSemFor(40.0), equals(24.0));

      // Clamped to 60 maximum
      expect(rec.requiredEndSemFor(100.0), equals(60.0));
    });

    test('InternalAssessmentRecord serialization & deserialization retains all 8 parameters', () {
      const original = InternalAssessmentRecord(
        subjectId: 'chemistry',
        subjectName: 'Engineering Chemistry',
        unitTestMarks: 11.5,
        assignmentsMarks: 10.5,
        quizSeminarMarks: 5.5,
        miniProjectMarks: 9.0,
        termWorkMarks: 23.5,
        endSemMarks: 50.0,
      );

      final json = original.toJson();
      final loaded = InternalAssessmentRecord.fromJson(json);

      expect(loaded.subjectId, equals('chemistry'));
      expect(loaded.subjectName, equals('Engineering Chemistry'));
      expect(loaded.unitTestMarks, equals(11.5));
      expect(loaded.assignmentsMarks, equals(10.5));
      expect(loaded.quizSeminarMarks, equals(5.5));
      expect(loaded.miniProjectMarks, equals(9.0));
      expect(loaded.termWorkMarks, equals(23.5));
      expect(loaded.endSemMarks, equals(50.0));
      expect(loaded.cceTotal, equals(36.5));
      expect(loaded.grandTotalMarks, equals(110.0));
    });
  });

  group('Daily, Weekly, and Monthly Goals System Tests', () {
    test('GoalItem computes progress and serialization faithfully', () {
      final goal = GoalItem(
        id: 'goal_test_1',
        title: 'Master Unit 2 Integrals',
        type: GoalType.weekly,
        targetMinutes: 120,
        currentMinutes: 60,
        isCompleted: false,
        category: 'Study Hours',
        createdAt: DateTime(2026, 9, 1),
      );

      expect(goal.progress, equals(0.5));
      expect(goal.type, equals(GoalType.weekly));

      // Overachieved goal progress clamped to 1.0
      final overachieved = goal.copyWith(currentMinutes: 150);
      expect(overachieved.progress, equals(1.0));

      // Serialization check
      final json = goal.toJson();
      final restored = GoalItem.fromJson(json);
      expect(restored.id, equals('goal_test_1'));
      expect(restored.title, equals('Master Unit 2 Integrals'));
      expect(restored.type, equals(GoalType.weekly));
      expect(restored.targetMinutes, equals(120));
      expect(restored.currentMinutes, equals(60));
      expect(restored.isCompleted, isFalse);
    });

    test('LocalStore manages Goals lifecycle and study time auto-advancement', () async {
      final store = LocalStore();
      final defaultGoals = store.goals;

      // When initialized or before storage, defaults can be created
      expect(defaultGoals, isA<List<GoalItem>>());

      final customGoal = GoalItem(
        id: 'goal_daily_quick',
        title: 'Daily Quick Solve',
        type: GoalType.daily,
        targetMinutes: 30,
        currentMinutes: 0,
        createdAt: DateTime.now(),
      );

      await store.addGoal(customGoal);
      expect(store.goals.any((g) => g.id == 'goal_daily_quick'), isTrue);

      // Toggle completed
      await store.toggleGoalCompleted('goal_daily_quick');
      expect(store.goals.firstWhere((g) => g.id == 'goal_daily_quick').isCompleted, isTrue);

      // Toggle back
      await store.toggleGoalCompleted('goal_daily_quick');
      expect(store.goals.firstWhere((g) => g.id == 'goal_daily_quick').isCompleted, isFalse);

      // Delete goal
      await store.deleteGoal('goal_daily_quick');
      expect(store.goals.any((g) => g.id == 'goal_daily_quick'), isFalse);
    });
  });

  group('Timetable Collision Avoidance & Spotify Study Playlists', () {
    final mockSubjects = [
      Subject(
        id: 'm1',
        name: 'Engineering Mathematics 1',
        code: '107001',
        emoji: '📐',
        color: '#31748f',
        semester: 1,
        teachingHours: 40,
        isExcluded: false,
        units: [
          Unit(unitNumber: 1, name: 'Differential Calculus', hours: 8, weightage: '10%'),
          Unit(unitNumber: 2, name: 'Partial Differentiation', hours: 8, weightage: '12%'),
        ],
      ),
      Subject(
        id: 'mechanics',
        name: 'Engineering Mechanics',
        code: '101011',
        emoji: '⚙️',
        color: '#eb6f92',
        semester: 1,
        teachingHours: 40,
        isExcluded: false,
        units: [
          Unit(unitNumber: 1, name: 'Statics of Particles', hours: 8, weightage: '10%'),
        ],
      ),
      Subject(
        id: 'bxe',
        name: 'Basic Electronics',
        code: '104012',
        emoji: '⚡',
        color: '#c4a7e7',
        semester: 1,
        teachingHours: 40,
        isExcluded: false,
        units: [
          Unit(unitNumber: 1, name: 'Semiconductor Diodes', hours: 8, weightage: '10%'),
        ],
      ),
    ];

    test('generateWeeklyTimetable generates slots avoiding college timings for Early Morning peak', () async {
      final store = LocalStore();
      await store.saveUserProfile(
        const UserProfile(
          peakMotivationWindow: 'Early Morning (6 AM - 9 AM)',
          collegeStartTime: '09:00 AM',
          collegeEndTime: '04:30 PM',
          hardSubjects: ['m1'],
        ),
      );

      final slots = store.generateWeeklyTimetable(customSubjects: mockSubjects);
      expect(slots.isNotEmpty, isTrue);

      // Check Monday slots (dayOfWeek == 1)
      final mondaySlots = slots.where((s) => s.dayOfWeek == 1).toList();
      expect(mondaySlots.isNotEmpty, isTrue);

      // Morning peak starts at 6:30 AM (hour 6, minute 30)
      expect(mondaySlots.first.startHour, equals(6));
      expect(mondaySlots.first.startMinute, equals(30));

      // Ensure no slots collide with college window (09:00 AM to 04:30 PM: 540 to 990 minutes)
      for (final slot in mondaySlots) {
        final slotStartMinute = slot.startHour * 60 + slot.startMinute;
        final slotEndMinute = slotStartMinute + slot.durationMinutes;
        final collidesWithCollege = slotStartMinute < (16 * 60 + 30) && slotEndMinute > (9 * 60);
        expect(collidesWithCollege, isFalse, reason: 'Slot ${slot.timeRange} must not collide with college hours (09:00 AM - 04:30 PM)');
      }

      // Hard subject 'm1' receives 75 min duration and weak subject flag
      final m1Slot = mondaySlots.firstWhere((s) => s.subjectId == 'm1');
      expect(m1Slot.durationMinutes, equals(75));
      expect(m1Slot.isWeakSubject, isTrue);
    });

    test('generateWeeklyTimetable generates slots for Evening and Night Owl peaks outside college hours', () async {
      final store = LocalStore();

      // Night Owl: 8:00 PM (20:00)
      await store.saveUserProfile(
        const UserProfile(
          peakMotivationWindow: 'Night Owl (9 PM - 12 AM)',
          collegeStartTime: '09:00 AM',
          collegeEndTime: '05:00 PM',
        ),
      );
      final nightSlots = store.generateWeeklyTimetable(customSubjects: mockSubjects);
      final monNight = nightSlots.where((s) => s.dayOfWeek == 1).toList();
      expect(monNight.first.startHour, equals(20));

      // Evening: 5:15 PM (17:15)
      await store.saveUserProfile(
        const UserProfile(
          peakMotivationWindow: 'Evening (5 PM - 9 PM)',
          collegeStartTime: '09:00 AM',
          collegeEndTime: '05:00 PM',
        ),
      );
      final eveSlots = store.generateWeeklyTimetable(customSubjects: mockSubjects);
      final monEve = eveSlots.where((s) => s.dayOfWeek == 1).toList();
      expect(monEve.first.startHour, equals(17));
      expect(monEve.first.startMinute, equals(45));
    });

    test('SpotifyStudyPlaylist default curated playlists and custom URI storage', () async {
      const playlists = SpotifyStudyPlaylist.defaultPlaylists;
      expect(playlists.length, equals(5));

      for (final p in playlists) {
        expect(p.id.isNotEmpty, isTrue);
        expect(p.title.isNotEmpty, isTrue);
        expect(p.subtitle.isNotEmpty, isTrue);
        expect(p.emoji.isNotEmpty, isTrue);
        expect(p.spotifyUri, startsWith('spotify:playlist:'));
        expect(p.webUrl, startsWith('https://open.spotify.com/playlist/'));
      }

      final store = LocalStore();
      await store.saveCustomSpotifyUri('spotify:playlist:my_custom_fe_mix');
      expect(store.savedCustomSpotifyUri, equals('spotify:playlist:my_custom_fe_mix'));
    });
  });
}

