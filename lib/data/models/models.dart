class UserProfile {
  final String name;
  final int semester;
  final String vocabularyLevel; // 'Simple', 'Moderate', 'Advanced'
  final int dailyStudyHours;
  final String preferredStudyTime;
  final List<String> hardSubjects;
  final List<String> topApps;
  final String examDate;
  final String accentPalette;
  final bool isDarkMode;
  final bool dndEnabled;
  // Notification preferences
  final bool morningBriefingEnabled;
  final String morningBriefingTime;
  final bool slotRemindersEnabled;
  final bool streakNudgeEnabled;
  final bool breakRemindersEnabled;
  final bool quietHoursEnabled;
  final String quietHoursStart;
  final String quietHoursEnd;

  // App blocking preferences
  final String appBlockingTier; // 'Off', 'Nudge Only', 'Full-screen Overlay', 'Strict Mode'
  final int distractionThresholdMinutes;
  final List<String> blockedApps;

  // AI & Personalization Preferences
  final String aiVocabularyStyle; // 'Easy & Simple', 'Short & Concise', 'Academic & Formal'
  final int aiExamplesCount; // default 2, 1-4
  final String collegeStartTime; // '09:00 AM'
  final String collegeEndTime; // '04:30 PM'
  final String peakMotivationWindow; // 'Morning', 'Afternoon', 'Evening', 'Night Owl'

  // AI & Mastery Personalization (PS1)
  final Map<String, double> unitMastery; // Key format: "$subjectId:$unitNumber" -> 0.0 to 1.0
  final String customAiPrompt; // ChatterUI-style student custom instructions

  // Custom OpenAI Compatible API (llama.cpp)
  final String customOpenAiBaseUrl;
  final String customOpenAiApiKey;
  final String customOpenAiModel;

  const UserProfile({
    this.name = 'Student',
    this.semester = 1,
    this.vocabularyLevel = 'Simple',
    this.dailyStudyHours = 4,
    this.preferredStudyTime = 'Morning',
    this.hardSubjects = const ['m1', 'mechanics'],
    this.topApps = const ['Instagram', 'YouTube', 'WhatsApp', 'Chrome', 'Snapchat'],
    this.examDate = '',
    this.accentPalette = 'rose_pine',
    this.isDarkMode = false,
    this.dndEnabled = false,
    this.morningBriefingEnabled = true,
    this.morningBriefingTime = '07:30 AM',
    this.slotRemindersEnabled = true,
    this.streakNudgeEnabled = true,
    this.breakRemindersEnabled = true,
    this.quietHoursEnabled = true,
    this.quietHoursStart = '22:00',
    this.quietHoursEnd = '07:00',
    this.appBlockingTier = 'Nudge Only',
    this.distractionThresholdMinutes = 15,
    this.blockedApps = const ['Instagram', 'YouTube', 'Snapchat', 'Reddit', 'Netflix'],
    this.aiVocabularyStyle = 'Easy & Simple',
    this.aiExamplesCount = 2,
    this.collegeStartTime = '09:00 AM',
    this.collegeEndTime = '04:30 PM',
    this.peakMotivationWindow = 'Evening (5 PM - 9 PM)',
    this.unitMastery = const {},
    this.customAiPrompt = '',
    this.customOpenAiBaseUrl = '',
    this.customOpenAiApiKey = '',
    this.customOpenAiModel = '',
  });

  UserProfile copyWith({
    String? name,
    int? semester,
    String? vocabularyLevel,
    int? dailyStudyHours,
    String? preferredStudyTime,
    List<String>? hardSubjects,
    List<String>? topApps,
    String? examDate,
    String? accentPalette,
    bool? isDarkMode,
    bool? dndEnabled,
    bool? morningBriefingEnabled,
    String? morningBriefingTime,
    bool? slotRemindersEnabled,
    bool? streakNudgeEnabled,
    bool? breakRemindersEnabled,
    bool? quietHoursEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
    String? appBlockingTier,
    int? distractionThresholdMinutes,
    List<String>? blockedApps,
    String? aiVocabularyStyle,
    int? aiExamplesCount,
    String? collegeStartTime,
    String? collegeEndTime,
    String? peakMotivationWindow,
    Map<String, double>? unitMastery,
    String? customAiPrompt,
    String? customOpenAiBaseUrl,
    String? customOpenAiApiKey,
    String? customOpenAiModel,
  }) {
    return UserProfile(
      name: name ?? this.name,
      semester: semester ?? this.semester,
      vocabularyLevel: vocabularyLevel ?? this.vocabularyLevel,
      dailyStudyHours: dailyStudyHours ?? this.dailyStudyHours,
      preferredStudyTime: preferredStudyTime ?? this.preferredStudyTime,
      hardSubjects: hardSubjects ?? this.hardSubjects,
      topApps: topApps ?? this.topApps,
      examDate: examDate ?? this.examDate,
      accentPalette: accentPalette ?? this.accentPalette,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      dndEnabled: dndEnabled ?? this.dndEnabled,
      morningBriefingEnabled: morningBriefingEnabled ?? this.morningBriefingEnabled,
      morningBriefingTime: morningBriefingTime ?? this.morningBriefingTime,
      slotRemindersEnabled: slotRemindersEnabled ?? this.slotRemindersEnabled,
      streakNudgeEnabled: streakNudgeEnabled ?? this.streakNudgeEnabled,
      breakRemindersEnabled: breakRemindersEnabled ?? this.breakRemindersEnabled,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      appBlockingTier: appBlockingTier ?? this.appBlockingTier,
      distractionThresholdMinutes: distractionThresholdMinutes ?? this.distractionThresholdMinutes,
      blockedApps: blockedApps ?? this.blockedApps,
      aiVocabularyStyle: aiVocabularyStyle ?? this.aiVocabularyStyle,
      aiExamplesCount: aiExamplesCount ?? this.aiExamplesCount,
      collegeStartTime: collegeStartTime ?? this.collegeStartTime,
      collegeEndTime: collegeEndTime ?? this.collegeEndTime,
      peakMotivationWindow: peakMotivationWindow ?? this.peakMotivationWindow,
      unitMastery: unitMastery ?? this.unitMastery,
      customAiPrompt: customAiPrompt ?? this.customAiPrompt,
      customOpenAiBaseUrl: customOpenAiBaseUrl ?? this.customOpenAiBaseUrl,
      customOpenAiApiKey: customOpenAiApiKey ?? this.customOpenAiApiKey,
      customOpenAiModel: customOpenAiModel ?? this.customOpenAiModel,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'semester': semester,
    'vocabularyLevel': vocabularyLevel,
    'dailyStudyHours': dailyStudyHours,
    'preferredStudyTime': preferredStudyTime,
    'hardSubjects': hardSubjects,
    'topApps': topApps,
    'examDate': examDate,
    'accentPalette': accentPalette,
    'isDarkMode': isDarkMode,
    'dndEnabled': dndEnabled,
    'morningBriefingEnabled': morningBriefingEnabled,
    'morningBriefingTime': morningBriefingTime,
    'slotRemindersEnabled': slotRemindersEnabled,
    'streakNudgeEnabled': streakNudgeEnabled,
    'breakRemindersEnabled': breakRemindersEnabled,
    'quietHoursEnabled': quietHoursEnabled,
    'quietHoursStart': quietHoursStart,
    'quietHoursEnd': quietHoursEnd,
    'appBlockingTier': appBlockingTier,
    'distractionThresholdMinutes': distractionThresholdMinutes,
    'blockedApps': blockedApps,
    'aiVocabularyStyle': aiVocabularyStyle,
    'aiExamplesCount': aiExamplesCount,
    'collegeStartTime': collegeStartTime,
    'collegeEndTime': collegeEndTime,
    'peakMotivationWindow': peakMotivationWindow,
    'unitMastery': unitMastery,
    'customAiPrompt': customAiPrompt,
    'customOpenAiBaseUrl': customOpenAiBaseUrl,
    'customOpenAiApiKey': customOpenAiApiKey,
    'customOpenAiModel': customOpenAiModel,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final rawMastery = json['unitMastery'] as Map<String, dynamic>?;
    final parsedMastery = <String, double>{};
    if (rawMastery != null) {
      rawMastery.forEach((k, v) {
        if (v is num) parsedMastery[k] = v.toDouble();
      });
    }

    return UserProfile(
      name: json['name'] ?? 'Student',
      semester: json['semester'] ?? 1,
      vocabularyLevel: json['vocabularyLevel'] ?? 'Simple',
      dailyStudyHours: json['dailyStudyHours'] ?? 4,
      preferredStudyTime: json['preferredStudyTime'] ?? 'Morning',
      hardSubjects: List<String>.from(json['hardSubjects'] ?? ['m1']),
      topApps: List<String>.from(json['topApps'] ?? ['Instagram', 'YouTube']),
      examDate: json['examDate'] ?? '',
      accentPalette: json['accentPalette'] ?? 'rose_pine',
      isDarkMode: json['isDarkMode'] ?? false,
      dndEnabled: json['dndEnabled'] ?? false,
      morningBriefingEnabled: json['morningBriefingEnabled'] ?? true,
      morningBriefingTime: json['morningBriefingTime'] ?? '07:30 AM',
      slotRemindersEnabled: json['slotRemindersEnabled'] ?? true,
      streakNudgeEnabled: json['streakNudgeEnabled'] ?? true,
      breakRemindersEnabled: json['breakRemindersEnabled'] ?? true,
      quietHoursEnabled: json['quietHoursEnabled'] ?? true,
      quietHoursStart: json['quietHoursStart'] ?? '22:00',
      quietHoursEnd: json['quietHoursEnd'] ?? '07:00',
      appBlockingTier: json['appBlockingTier'] ?? 'Nudge Only',
      distractionThresholdMinutes: json['distractionThresholdMinutes'] ?? 15,
      blockedApps: List<String>.from(json['blockedApps'] ?? ['Instagram', 'YouTube', 'Snapchat', 'Reddit', 'Netflix']),
      aiVocabularyStyle: json['aiVocabularyStyle'] ?? 'Easy & Simple',
      aiExamplesCount: json['aiExamplesCount'] ?? 2,
      collegeStartTime: json['collegeStartTime'] ?? '09:00 AM',
      collegeEndTime: json['collegeEndTime'] ?? '04:30 PM',
      peakMotivationWindow: json['peakMotivationWindow'] ?? 'Evening (5 PM - 9 PM)',
      unitMastery: parsedMastery,
      customAiPrompt: json['customAiPrompt'] ?? '',
      customOpenAiBaseUrl: json['customOpenAiBaseUrl'] ?? '',
      customOpenAiApiKey: json['customOpenAiApiKey'] ?? '',
      customOpenAiModel: json['customOpenAiModel'] ?? '',
    );
  }

  double getMasteryFor(String subjectId, int unitNumber) {
    final key = '$subjectId:$unitNumber';
    return unitMastery[key] ?? 0.75;
  }

  bool isUnitWeak(String subjectId, int unitNumber) {
    final key = '$subjectId:$unitNumber';
    final score = unitMastery[key];
    if (score != null) {
      return score < 0.60;
    }
    return hardSubjects.contains(subjectId);
  }

  List<String> getWeakUnitsList(List<Subject> allSubjects) {
    final list = <String>[];
    for (final entry in unitMastery.entries) {
      if (entry.value < 0.60) {
        final parts = entry.key.split(':');
        if (parts.length == 2) {
          final sId = parts[0];
          final uNum = int.tryParse(parts[1]) ?? 1;
          final sub = allSubjects.where((s) => s.id == sId).firstOrNull;
          final subName = sub?.name ?? sId;
          final unit = sub?.units.where((u) => u.unitNumber == uNum).firstOrNull;
          final unitName = unit?.name ?? 'Unit $uNum';
          final pct = (entry.value * 100).round();
          list.add('$subName — Unit $uNum: $unitName ($pct% mastery)');
        }
      }
    }
    return list;
  }
}

class FeedbackItem {
  final String id;
  final String category; // 'Bug Report', 'Feature Request', 'General Feedback'
  final int rating; // 1-5
  final String title;
  final String details;
  final DateTime createdAt;

  FeedbackItem({
    required this.id,
    required this.category,
    required this.rating,
    required this.title,
    required this.details,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category,
    'rating': rating,
    'title': title,
    'details': details,
    'createdAt': createdAt.toIso8601String(),
  };

  factory FeedbackItem.fromJson(Map<String, dynamic> json) {
    return FeedbackItem(
      id: json['id'] ?? '',
      category: json['category'] ?? 'General Feedback',
      rating: json['rating'] ?? 5,
      title: json['title'] ?? '',
      details: json['details'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class Subject {
  final String id;
  final String name;
  final String code;
  final String emoji;
  final String color;
  final int semester;
  final int teachingHours;
  final bool isExcluded;
  final List<Unit> units;

  Subject({
    required this.id,
    required this.name,
    required this.code,
    required this.emoji,
    required this.color,
    required this.semester,
    required this.teachingHours,
    required this.isExcluded,
    required this.units,
  });

  Subject copyWith({
    String? id,
    String? name,
    String? code,
    String? emoji,
    String? color,
    int? semester,
    int? teachingHours,
    bool? isExcluded,
    List<Unit>? units,
  }) {
    return Subject(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      emoji: emoji ?? this.emoji,
      color: color ?? this.color,
      semester: semester ?? this.semester,
      teachingHours: teachingHours ?? this.teachingHours,
      isExcluded: isExcluded ?? this.isExcluded,
      units: units ?? this.units,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'code': code,
    'emoji': emoji,
    'color': color,
    'semester': semester,
    'teachingHours': teachingHours,
    'isExcluded': isExcluded,
    'units': units.map((u) => u.toJson()).toList(),
  };

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      emoji: json['emoji'] ?? '📚',
      color: json['color'] ?? '#286983',
      semester: json['semester'] ?? 1,
      teachingHours: json['teachingHours'] ?? 40,
      isExcluded: json['isExcluded'] ?? false,
      units: (json['units'] as List<dynamic>?)
              ?.map((u) => Unit.fromJson(u))
              .toList() ??
          [],
    );
  }
}

class Unit {
  final int unitNumber;
  final String name;
  final int hours;
  final String weightage;

  Unit({
    required this.unitNumber,
    required this.name,
    required this.hours,
    required this.weightage,
  });

  Unit copyWith({
    int? unitNumber,
    String? name,
    int? hours,
    String? weightage,
  }) {
    return Unit(
      unitNumber: unitNumber ?? this.unitNumber,
      name: name ?? this.name,
      hours: hours ?? this.hours,
      weightage: weightage ?? this.weightage,
    );
  }

  Map<String, dynamic> toJson() => {
    'unitNumber': unitNumber,
    'name': name,
    'hours': hours,
    'weightage': weightage,
  };

  factory Unit.fromJson(Map<String, dynamic> json) {
    return Unit(
      unitNumber: json['unitNumber'] ?? 1,
      name: json['name'] ?? '',
      hours: json['hours'] ?? 8,
      weightage: json['weightage'] ?? 'Medium',
    );
  }
}

class Question {
  final String id;
  final String subjectId;
  final int unitNumber;
  final String topic;
  final String questionText;
  final List<String> options;
  final int correctOption;
  final String explanation;
  final int normalTimeSeconds;
  final String difficulty;
  final int year;
  final String exam;

  Question({
    required this.id,
    required this.subjectId,
    required this.unitNumber,
    required this.topic,
    required this.questionText,
    required this.options,
    required this.correctOption,
    required this.explanation,
    required this.normalTimeSeconds,
    required this.difficulty,
    required this.year,
    required this.exam,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] ?? '',
      subjectId: json['subjectId'] ?? '',
      unitNumber: json['unitNumber'] ?? 1,
      topic: json['topic'] ?? '',
      questionText: json['questionText'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      correctOption: json['correctOption'] ?? 0,
      explanation: json['explanation'] ?? '',
      normalTimeSeconds: json['normalTimeSeconds'] ?? 90,
      difficulty: json['difficulty'] ?? 'medium',
      year: json['year'] ?? 2024,
      exam: json['exam'] ?? 'SPPU',
    );
  }
}

class Quote {
  final int id;
  final String text;
  final String author;
  final String category;

  Quote({
    required this.id,
    required this.text,
    required this.author,
    required this.category,
  });

  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      id: json['id'] ?? 0,
      text: json['text'] ?? '',
      author: json['author'] ?? 'Unknown',
      category: json['category'] ?? 'study',
    );
  }
}

enum QuestionTimeStatus { normal, needsWork, timeTrap }

class TimetableSlot {
  final String id;
  final String subjectId;
  final String subjectName;
  final String unitName;
  final int unitNumber;
  final String timeRange;
  final int durationMinutes;
  final int dayOfWeek; // 1 = Monday, 7 = Sunday
  final String date; // YYYY-MM-DD
  final int startHour;
  final int startMinute;
  final bool isCompleted;
  final bool isWeakSubject;
  final bool isCustomTask;
  final bool hasReminder;
  final String notes;

  TimetableSlot({
    required this.id,
    required this.subjectId,
    required this.subjectName,
    required this.unitName,
    required this.unitNumber,
    required this.timeRange,
    required this.durationMinutes,
    this.dayOfWeek = 1,
    this.date = '',
    this.startHour = 9,
    this.startMinute = 0,
    this.isCompleted = false,
    this.isWeakSubject = false,
    this.isCustomTask = false,
    this.hasReminder = true,
    this.notes = '',
  });

  TimetableSlot copyWith({
    String? id,
    String? subjectId,
    String? subjectName,
    String? unitName,
    int? unitNumber,
    String? timeRange,
    int? durationMinutes,
    int? dayOfWeek,
    String? date,
    int? startHour,
    int? startMinute,
    bool? isCompleted,
    bool? isWeakSubject,
    bool? isCustomTask,
    bool? hasReminder,
    String? notes,
  }) {
    return TimetableSlot(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      unitName: unitName ?? this.unitName,
      unitNumber: unitNumber ?? this.unitNumber,
      timeRange: timeRange ?? this.timeRange,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      date: date ?? this.date,
      startHour: startHour ?? this.startHour,
      startMinute: startMinute ?? this.startMinute,
      isCompleted: isCompleted ?? this.isCompleted,
      isWeakSubject: isWeakSubject ?? this.isWeakSubject,
      isCustomTask: isCustomTask ?? this.isCustomTask,
      hasReminder: hasReminder ?? this.hasReminder,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'subjectId': subjectId,
        'subjectName': subjectName,
        'unitName': unitName,
        'unitNumber': unitNumber,
        'timeRange': timeRange,
        'durationMinutes': durationMinutes,
        'dayOfWeek': dayOfWeek,
        'date': date,
        'startHour': startHour,
        'startMinute': startMinute,
        'isCompleted': isCompleted,
        'isWeakSubject': isWeakSubject,
        'isCustomTask': isCustomTask,
        'hasReminder': hasReminder,
        'notes': notes,
      };

  factory TimetableSlot.fromJson(Map<String, dynamic> json) => TimetableSlot(
        id: json['id'] ?? '',
        subjectId: json['subjectId'] ?? '',
        subjectName: json['subjectName'] ?? '',
        unitName: json['unitName'] ?? '',
        unitNumber: json['unitNumber'] ?? 1,
        timeRange: json['timeRange'] ?? '09:00 - 10:00',
        durationMinutes: json['durationMinutes'] ?? 60,
        dayOfWeek: json['dayOfWeek'] ?? 1,
        date: json['date'] ?? '',
        startHour: json['startHour'] ?? 9,
        startMinute: json['startMinute'] ?? 0,
        isCompleted: json['isCompleted'] ?? false,
        isWeakSubject: json['isWeakSubject'] ?? false,
        isCustomTask: json['isCustomTask'] ?? false,
        hasReminder: json['hasReminder'] ?? true,
        notes: json['notes'] ?? '',
      );
}

class PYQItem {
  final String id;
  final String subjectId;
  final int unitNumber;
  final String topic;
  final String questionText;
  final String exam;
  final int year;
  final int marks;
  final String difficulty;
  final String modelAnswer;
  final List<Map<String, dynamic>> stepMarking;

  PYQItem({
    required this.id,
    required this.subjectId,
    required this.unitNumber,
    required this.topic,
    required this.questionText,
    required this.exam,
    required this.year,
    required this.marks,
    required this.difficulty,
    required this.modelAnswer,
    this.stepMarking = const [],
  });

  factory PYQItem.fromJson(Map<String, dynamic> json) => PYQItem(
        id: json['id'] ?? '',
        subjectId: json['subjectId'] ?? '',
        unitNumber: json['unitNumber'] ?? 1,
        topic: json['topic'] ?? '',
        questionText: json['questionText'] ?? '',
        exam: json['exam'] ?? 'SPPU University Exam',
        year: json['year'] ?? 2024,
        marks: json['marks'] ?? 5,
        difficulty: json['difficulty'] ?? 'Medium',
        modelAnswer: json['modelAnswer'] ?? '',
        stepMarking: List<Map<String, dynamic>>.from(json['stepMarking'] ?? []),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'subjectId': subjectId,
        'unitNumber': unitNumber,
        'topic': topic,
        'questionText': questionText,
        'exam': exam,
        'year': year,
        'marks': marks,
        'difficulty': difficulty,
        'modelAnswer': modelAnswer,
        'stepMarking': stepMarking,
      };
}

class NoteItem {
  final String id;
  final String title;
  final String content;
  final String subjectId;
  final String subjectName;
  final DateTime updatedAt;
  final bool isPinned;

  NoteItem({
    required this.id,
    required this.title,
    required this.content,
    required this.subjectId,
    required this.subjectName,
    required this.updatedAt,
    this.isPinned = false,
  });

  NoteItem copyWith({
    String? id,
    String? title,
    String? content,
    String? subjectId,
    String? subjectName,
    DateTime? updatedAt,
    bool? isPinned,
  }) {
    return NoteItem(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      updatedAt: updatedAt ?? this.updatedAt,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'subjectId': subjectId,
        'subjectName': subjectName,
        'updatedAt': updatedAt.toIso8601String(),
        'isPinned': isPinned,
      };

  factory NoteItem.fromJson(Map<String, dynamic> json) => NoteItem(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        content: json['content'] as String? ?? '',
        subjectId: json['subjectId'] as String? ?? '',
        subjectName: json['subjectName'] as String? ?? '',
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
        isPinned: json['isPinned'] as bool? ?? false,
      );
}

/// Authentic SPPU FE 2024 Revised Course Internal Assessment (CCE) & Exam Model
class InternalAssessmentRecord {
  final String subjectId;
  final String subjectName;
  // Parameter 1: Unit Test (Units 1 & 2) - 12 Marks Max (6 Marks / Unit)
  final double unitTestMarks;
  // Parameter 2: Assignments / Case Study (Units 3 & 4) - 12 Marks Max (6 Marks / Unit)
  final double assignmentsMarks;
  // Parameter 3: Seminar / Open Book Test / Quiz (Unit 5) - 06 Marks Max
  final double quizSeminarMarks;
  // Parameter 4: Mini Project / Project-Based Learning (PBL) / Activity - 10 Marks Max
  final double miniProjectMarks;
  // Term Work (TW) - 25 Marks Max
  final double termWorkMarks;
  // End-Semester Examination (ESE) - 60 Marks Max
  final double endSemMarks;

  const InternalAssessmentRecord({
    required this.subjectId,
    required this.subjectName,
    this.unitTestMarks = 10.0,
    this.assignmentsMarks = 10.0,
    this.quizSeminarMarks = 5.0,
    this.miniProjectMarks = 8.5,
    this.termWorkMarks = 22.0,
    this.endSemMarks = 48.0,
  });

  /// Continuous Comprehensive Evaluation (CCE) total out of 40 marks
  double get cceTotal =>
      (unitTestMarks + assignmentsMarks + quizSeminarMarks + miniProjectMarks)
          .clamp(0.0, 40.0);

  /// Total Theory Marks out of 100 (40 CCE + 60 End-Sem)
  double get totalTheoryMarks => (cceTotal + endSemMarks).clamp(0.0, 100.0);

  /// Grand Total Course Marks out of 125 (40 CCE + 60 ESE + 25 TW)
  double get grandTotalMarks =>
      (cceTotal + endSemMarks + termWorkMarks).clamp(0.0, 125.0);

  /// Overall percentage out of 125
  double get overallPercentage => (grandTotalMarks / 125.0) * 100.0;

  /// SPPU Passing Rule: minimum 24/60 in End-Sem ESE, and minimum 40% aggregate (50/125)
  bool get isPassed => endSemMarks >= 24.0 && grandTotalMarks >= 50.0;

  /// Projected SPPU Grade & Pointer (Credit System)
  String get projectedGrade {
    final pct = overallPercentage;
    if (endSemMarks < 24.0 || grandTotalMarks < 50.0) return 'F (Fail / Re-appear)';
    if (pct >= 90) return 'O (Outstanding - 10)';
    if (pct >= 80) return 'A+ (Excellent - 9)';
    if (pct >= 70) return 'A (Very Good - 8)';
    if (pct >= 60) return 'B+ (Good - 7)';
    if (pct >= 55) return 'B (Above Average - 6)';
    if (pct >= 50) return 'C (Average - 5)';
    return 'P (Pass - 4)';
  }

  /// Calculates required End-Semester score (out of 60) to achieve target aggregate percentage
  double requiredEndSemFor(double targetPercentage) {
    final targetTotal = targetPercentage * 1.25;
    final needed = targetTotal - cceTotal - termWorkMarks;
    return needed.clamp(24.0, 60.0);
  }

  InternalAssessmentRecord copyWith({
    String? subjectId,
    String? subjectName,
    double? unitTestMarks,
    double? assignmentsMarks,
    double? quizSeminarMarks,
    double? miniProjectMarks,
    double? termWorkMarks,
    double? endSemMarks,
  }) {
    return InternalAssessmentRecord(
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      unitTestMarks: unitTestMarks ?? this.unitTestMarks,
      assignmentsMarks: assignmentsMarks ?? this.assignmentsMarks,
      quizSeminarMarks: quizSeminarMarks ?? this.quizSeminarMarks,
      miniProjectMarks: miniProjectMarks ?? this.miniProjectMarks,
      termWorkMarks: termWorkMarks ?? this.termWorkMarks,
      endSemMarks: endSemMarks ?? this.endSemMarks,
    );
  }

  Map<String, dynamic> toJson() => {
        'subjectId': subjectId,
        'subjectName': subjectName,
        'unitTestMarks': unitTestMarks,
        'assignmentsMarks': assignmentsMarks,
        'quizSeminarMarks': quizSeminarMarks,
        'miniProjectMarks': miniProjectMarks,
        'termWorkMarks': termWorkMarks,
        'endSemMarks': endSemMarks,
      };

  factory InternalAssessmentRecord.fromJson(Map<String, dynamic> json) {
    return InternalAssessmentRecord(
      subjectId: json['subjectId'] ?? '',
      subjectName: json['subjectName'] ?? '',
      unitTestMarks: (json['unitTestMarks'] as num?)?.toDouble() ?? 10.0,
      assignmentsMarks: (json['assignmentsMarks'] as num?)?.toDouble() ?? 10.0,
      quizSeminarMarks: (json['quizSeminarMarks'] as num?)?.toDouble() ?? 5.0,
      miniProjectMarks: (json['miniProjectMarks'] as num?)?.toDouble() ?? 8.5,
      termWorkMarks: (json['termWorkMarks'] as num?)?.toDouble() ?? 22.0,
      endSemMarks: (json['endSemMarks'] as num?)?.toDouble() ?? 48.0,
    );
  }
}

/// Goals System: Daily, Weekly, and Monthly Target Tracking
enum GoalType { daily, weekly, monthly }

class GoalItem {
  final String id;
  final String title;
  final GoalType type;
  final int targetMinutes; // Target study minutes (or target units/quiz count)
  final int currentMinutes;
  final bool isCompleted;
  final String category; // 'Study Hours', 'Quiz Practice', 'Syllabus Unit'
  final DateTime createdAt;

  GoalItem({
    required this.id,
    required this.title,
    required this.type,
    required this.targetMinutes,
    this.currentMinutes = 0,
    this.isCompleted = false,
    this.category = 'Study Hours',
    required this.createdAt,
  });

  double get progress =>
      targetMinutes > 0 ? (currentMinutes / targetMinutes).clamp(0.0, 1.0) : 0.0;

  GoalItem copyWith({
    String? id,
    String? title,
    GoalType? type,
    int? targetMinutes,
    int? currentMinutes,
    bool? isCompleted,
    String? category,
    DateTime? createdAt,
  }) {
    return GoalItem(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      targetMinutes: targetMinutes ?? this.targetMinutes,
      currentMinutes: currentMinutes ?? this.currentMinutes,
      isCompleted: isCompleted ?? this.isCompleted,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'type': type.name,
        'targetMinutes': targetMinutes,
        'currentMinutes': currentMinutes,
        'isCompleted': isCompleted,
        'category': category,
        'createdAt': createdAt.toIso8601String(),
      };

  factory GoalItem.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String? ?? 'daily';
    final goalType = GoalType.values.firstWhere(
      (e) => e.name == typeName,
      orElse: () => GoalType.daily,
    );

    return GoalItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      type: goalType,
      targetMinutes: json['targetMinutes'] ?? 60,
      currentMinutes: json['currentMinutes'] ?? 0,
      isCompleted: json['isCompleted'] ?? false,
      category: json['category'] ?? 'Study Hours',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

/// Spotify Focus Music Integration Model
class SpotifyStudyPlaylist {
  final String id;
  final String title;
  final String subtitle;
  final String emoji;
  final String spotifyUri;
  final String webUrl;

  const SpotifyStudyPlaylist({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.spotifyUri,
    required this.webUrl,
  });

  static const List<SpotifyStudyPlaylist> defaultPlaylists = [
    SpotifyStudyPlaylist(
      id: 'lofi_study',
      title: 'Lofi Beats for Study',
      subtitle: 'Gentle chillhop & low-tempo study rhythm',
      emoji: '🎧',
      spotifyUri: 'spotify:playlist:37i9dQZF1DXdLEN7aqioXM',
      webUrl: 'https://open.spotify.com/playlist/37i9dQZF1DXdLEN7aqioXM',
    ),
    SpotifyStudyPlaylist(
      id: 'deep_focus',
      title: 'Deep Focus & Coding',
      subtitle: 'Atmospheric instrumental concentration beats',
      emoji: '🧠',
      spotifyUri: 'spotify:playlist:37i9dQZF1DX4sWSpwq3LiO',
      webUrl: 'https://open.spotify.com/playlist/37i9dQZF1DX4sWSpwq3LiO',
    ),
    SpotifyStudyPlaylist(
      id: 'classical_focus',
      title: 'Classical Concentration',
      subtitle: 'Mozart, Bach & Chopin for cognitive flow',
      emoji: '🎻',
      spotifyUri: 'spotify:playlist:37i9dQZF1DX8Uebhn9wzrS',
      webUrl: 'https://open.spotify.com/playlist/37i9dQZF1DX8Uebhn9wzrS',
    ),
    SpotifyStudyPlaylist(
      id: 'binaural_alpha',
      title: 'Binaural Alpha Waves (40Hz)',
      subtitle: 'Alpha/Gamma soundscapes for memory retention',
      emoji: '🌊',
      spotifyUri: 'spotify:playlist:37i9dQZF1DXbITWG1ZJKYt',
      webUrl: 'https://open.spotify.com/playlist/37i9dQZF1DXbITWG1ZJKYt',
    ),
    SpotifyStudyPlaylist(
      id: 'synthwave_focus',
      title: 'Chill Synthwave Study',
      subtitle: 'Retro electronic focus & flow state',
      emoji: '🌌',
      spotifyUri: 'spotify:playlist:37i9dQZF1DXdLEN7aqioXM',
      webUrl: 'https://open.spotify.com/playlist/37i9dQZF1DXdLEN7aqioXM',
    ),
  ];
}
