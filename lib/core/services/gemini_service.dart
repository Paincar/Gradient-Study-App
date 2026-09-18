import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import '../../data/models/models.dart';

class GeminiService {
  static const String _primaryModel = 'gemini-1.5-pro';
  static const String _secondaryModel = 'gemini-1.5-flash';
  static const String _fallbackModel = 'gemini-1.5-flash-8b';

  /// Generate a personalized SPPU engineering concept explanation using Gemini API
  static Future<String> explainConcept({
    required String prompt,
    required Subject? subject,
    required UserProfile profile,
    required String apiKey,
  }) async {
    if (apiKey.trim().isEmpty) {
      // Return offline fallback with rich structured answer
      return _generateOfflineFallback(prompt, subject, profile);
    }

    // Build weak units and mastery diagnostics summary
    final weakUnitsInfo = <String>[];
    for (final entry in profile.unitMastery.entries) {
      if (entry.value < 0.60) {
        final pct = (entry.value * 100).round();
        weakUnitsInfo.add('${entry.key} ($pct% accuracy)');
      }
    }

    final weakUnitsSection = weakUnitsInfo.isNotEmpty
        ? '''
Student Mastery & Performance Diagnostics:
- Diagnosed Weak Units: ${weakUnitsInfo.join(', ')}
- Instructions: The student has struggled with these topics in recent diagnostic quizzes. If the current question relates to any of these, proactively address common time-traps, clarify foundational definitions, and provide extra supportive explanations without being prompted!
'''
        : '';

    final customPersonaSection = profile.customAiPrompt.trim().isNotEmpty
        ? '''
Student Custom Instructions (ChatterUI Persona Customization):
"${profile.customAiPrompt.trim()}"
(Adhere to these preferences while retaining SPPU technical engineering accuracy).
'''
        : '';

    final vocabInstruction = switch (profile.aiVocabularyStyle) {
      'Short & Concise' =>
        'Use compressed high-yield notes, concise bullet points, core equations, and minimal conversational fluff. Maximum exam revision density.',
      'Academic & Formal' =>
        'Use rigorous academic terminology, formal proofs, standard SPPU textbook definitions, and university-level mathematical derivations.',
      _ =>
        'Use intuitive everyday language, relatable analogies (e.g. relatable real-world systems or apps like ${profile.topApps.isNotEmpty ? profile.topApps.first : "YouTube"}), and demystify all technical jargon simply.',
    };


    final subjectName = subject?.name ?? 'SPPU First Year Engineering';

    final systemPrompt = '''
You are 'Gradient AI', an elite personalized academic tutor built specifically for Savitribai Phule Pune University (SPPU) First Year Engineering (FE) students following the 2024 Revised Course Pattern (NEP-aligned).

Your prime directive is to explain "$prompt" in the context of $subjectName.

SPPU Exam Structure Context:
  • Continuous Comprehensive Evaluation (CCE / Internal Assessment): 40 Marks (Unit Test 12m for Units 1-2, Assignments 12m for Units 3-4, Seminar/Quiz 6m for Unit 5, Mini Project 10m).
  • End-Semester Examination (ESE): 60 Marks (Units 1-5, Mandatory minimum 24/60 to pass).
  • Term Work (TW): 25 Marks. Total per course: 125 Marks (Min 40% aggregate / 50 marks to pass).
- Units covered: Units 1 to 5 per course syllabus.

Student Profile & Personalization:
- Name: ${profile.name}
- Semester: ${profile.semester}
- Current Subject: ${subject?.name ?? 'SPPU First Year Engineering'}
- Vocabulary Level: ${profile.vocabularyLevel}
- Style Instruction: $vocabInstruction
- Distracting Apps Used: ${profile.topApps.join(', ')}
$weakUnitsSection
$customPersonaSection

Guidelines for the Perfect Answer:
1. Concept Definition: Define the core law/theorem/principle clearly with correct standard SI units and SPPU syllabus notations.
2. Real-World Examples: Provide realistic examples demonstrating this principle in action.
3. Mathematical Walkthrough / Derivation: Show step-by-step mathematical derivation, formula manipulation, or circuit/block diagram logic.
4. SPPU Exam Strategy & Time-Trap: Point out how this topic appears in SPPU CCE (Unit Tests/Assignments) or 60-mark End-Sem exams, common calculation traps students fall into, and how to score full marks.
5. Formatting: Use clean markdown headers, bullet points, bold key terms, and LaTeX math formatting.
''';

    if (profile.customOpenAiBaseUrl.isNotEmpty) {
      try {
        final url = Uri.parse(profile.customOpenAiBaseUrl.endsWith('/')
            ? '${profile.customOpenAiBaseUrl}chat/completions'
            : '${profile.customOpenAiBaseUrl}/chat/completions');
            
        final headers = {
          'Content-Type': 'application/json',
        };
        if (profile.customOpenAiApiKey.isNotEmpty) {
          headers['Authorization'] = 'Bearer ${profile.customOpenAiApiKey}';
        }
        
        final body = jsonEncode({
          'model': profile.customOpenAiModel.isNotEmpty ? profile.customOpenAiModel : 'llama',
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': prompt.trim()},
          ],
          'temperature': 0.7,
        });

        final response = await http.post(url, headers: headers, body: body).timeout(const Duration(seconds: 40));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['choices'] != null && data['choices'].isNotEmpty) {
            final content = data['choices'][0]['message']['content'];
            if (content != null && content.toString().trim().isNotEmpty) {
              return content.toString().trim();
            }
          }
        } else {
          debugPrint('OpenAI Compatible API Error: ${response.statusCode} - ${response.body}');
        }
      } catch (e) {
        debugPrint('OpenAI Compatible API call failed: $e');
        return '⚠️ Open Source API Connection: $e\n\nOffline Concept Summary:\n\n${_generateOfflineFallback(prompt, subject, profile)}';
      }
    } else {
      // Use Gemini API
      // Try models in sequence with fallback
      for (final modelName in [_primaryModel, _secondaryModel, _fallbackModel]) {
        try {
          final model = GenerativeModel(
            model: modelName,
            apiKey: apiKey.trim(),
            systemInstruction: Content.system(systemPrompt),
          );

          final content = [Content.text(prompt.trim())];
          final response = await model.generateContent(content).timeout(const Duration(seconds: 25));

          final text = response.text;
          if (text != null && text.trim().isNotEmpty) {
            return text.trim();
          }
        } catch (e) {
          debugPrint('Gemini call failed on $modelName: $e');
          if (modelName == _fallbackModel) {
            return '⚠️ Gemini API Connection: $e\n\nOffline Concept Summary:\n\n${_generateOfflineFallback(prompt, subject, profile)}';
          }
        }
      }
    }

    return _generateOfflineFallback(prompt, subject, profile);
  }

  static String _generateOfflineFallback(String prompt, Subject? subject, UserProfile profile) {
    final subjectName = subject?.name ?? 'SPPU Engineering Foundations';
    final count = profile.aiExamplesCount;
    final style = profile.aiVocabularyStyle;

    final examples = <String>[];
    if (count >= 1) {
      examples.add('1. Practical Engineering Application: Measuring input-output response across variable electrical loads or mechanical shear strain.');
    }
    if (count >= 2) {
      examples.add('2. Modern Digital / IoT System: Processing signal transmission packets with buffering to prevent buffer overflow under load.');
    }
    if (count >= 3) {
      examples.add('3. Industrial Control System: Closed-loop thermal regulation in continuous automated manufacturing.');
    }
    if (count >= 4) {
      examples.add('4. Structural Infrastructure: Resonance frequency damping in suspension bridges and skyscraper dampers.');
    }

    return '''
💡 SPPU 2024 Concept Breakdown ($subjectName · $style Style)

• Core Definition & Principles:
"$prompt" is a fundamental concept in the SPPU 2024 Revised Course Pattern for $subjectName. It governs system equilibrium, rate transfer, or computational resource execution according to governing physical and mathematical laws.

• Real-World Examples ($count Configured):
${examples.join('\n')}

• SPPU 2024 Exam & CCE Strategy (40m Internal + 60m End-Sem):
1. Parameter 1 & 2 (Unit Tests & Assignments, 24 Marks): Always state standard SI units and draw clear labelled circuit/block schematics.
2. End-Semester Examination (60 Marks, min 24 to pass): Show all intermediate calculation steps for partial marking credit.
3. Common Time-Trap: Watch out for unit conversions (e.g. mm vs m, kHz vs Hz, or degrees vs radians) before substituting into formulas.

🔑 Tip: Enter your free Google AI Studio API key in Sanctuary Settings to unlock full live Gemini 2.5 Flash personalized explanations!
''';
  }

  /// Real-time chat with AI Tutor & Study Strategist supporting conversational history
  static Future<String> chat({
    required String prompt,
    required UserProfile profile,
    required String apiKey,
    List<Map<String, String>> history = const [],
    List<Subject> subjects = const [],
  }) async {
    final activeSubjects = subjects.map((s) => s.name).join(', ');
    final isPlanRequest = prompt.toLowerCase().contains('plan') || 
                          prompt.toLowerCase().contains('schedule') || 
                          prompt.toLowerCase().contains('end sem') ||
                          prompt.toLowerCase().contains('holiday') ||
                          prompt.toLowerCase().contains('missed');

    final systemPrompt = '''
You are Gradient AI, an expert academic tutor and study strategist for Savitribai Phule Pune University (SPPU) First Year Engineering (2024 Revised Pattern).
Student Profile:
- Name: ${profile.name}
- Semester: ${profile.semester}
- Active Subjects: $activeSubjects
- Daily Study Target: ${profile.dailyStudyHours} hours/day
- Peak Motivation Window: ${profile.peakMotivationWindow}
- Weak Units: ${profile.unitMastery.entries.where((e) => e.value < 0.6).map((e) => e.key).join(', ')}

Guidelines:
1. When asked about study plans or exam prep:
   - Calculate pacing based on SPPU weightage (In-Sem: Units 1-2; End-Sem: Units 3-5/6).
   - Structure a clear, actionable daily revision schedule.
   - Mention that you can automatically apply this schedule to their in-app timetable with 1 tap.
2. When asked about engineering concepts:
   - Provide clear definitions, formula breakdowns, step-by-step steps, and SPPU PYQ exam tips.
3. Keep formatting clean with bold headers, bullet points, and equations.
''';

    if (profile.customOpenAiBaseUrl.isNotEmpty) {
      try {
        final url = Uri.parse(profile.customOpenAiBaseUrl.endsWith('/')
            ? '${profile.customOpenAiBaseUrl}chat/completions'
            : '${profile.customOpenAiBaseUrl}/chat/completions');
        final headers = {'Content-Type': 'application/json'};
        if (profile.customOpenAiApiKey.isNotEmpty) {
          headers['Authorization'] = 'Bearer ${profile.customOpenAiApiKey}';
        }

        final messages = <Map<String, String>>[
          {'role': 'system', 'content': systemPrompt},
          ...history,
          {'role': 'user', 'content': prompt.trim()},
        ];

        final response = await http.post(
          url,
          headers: headers,
          body: jsonEncode({
            'model': profile.customOpenAiModel.isNotEmpty ? profile.customOpenAiModel : 'llama3',
            'messages': messages,
            'temperature': 0.7,
          }),
        ).timeout(const Duration(seconds: 25));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final choices = data['choices'] as List<dynamic>?;
          if (choices != null && choices.isNotEmpty) {
            return choices.first['message']['content']?.toString() ?? 'No response generated.';
          }
        }
      } catch (e) {
        debugPrint('Custom OpenAI chat error: $e');
      }
    }

    if (apiKey.trim().isNotEmpty) {
      for (final modelName in [_primaryModel, _secondaryModel, _fallbackModel]) {
        try {
          final model = GenerativeModel(
            model: modelName,
            apiKey: apiKey.trim(),
            systemInstruction: Content.system(systemPrompt),
          );

          final chatSession = model.startChat(
            history: history.map((m) {
              if (m['role'] == 'user') {
                return Content.text(m['content'] ?? '');
              } else {
                return Content.model([TextPart(m['content'] ?? '')]);
              }
            }).toList(),
          );

          final response = await chatSession.sendMessage(Content.text(prompt.trim())).timeout(const Duration(seconds: 25));
          final text = response.text;
          if (text != null && text.trim().isNotEmpty) {
            return text.trim();
          }
        } catch (e) {
          debugPrint('Gemini chat failed on $modelName: $e');
        }
      }
    }

    if (isPlanRequest) {
      return '''
# 📅 SPPU End-Sem Study & Revision Strategy

Here is a structured academic study plan tailored for your active semester subjects ($activeSubjects):

### 🎯 High-Yield Weightage Breakdown (SPPU 2024 Pattern):
- **End-Semester Focus:** Units 3, 4, 5, and 6 carry the maximum marks in your 60-mark End-Sem theory exam.
- **Daily Target:** Allocate ${profile.dailyStudyHours} hours daily during your ${profile.peakMotivationWindow}.

### 📋 Recommended Daily Distribution:
1. **Block 1 (90 mins):** Deep conceptual derivations & numerical problems for high-weightage units.
2. **Block 2 (60 mins):** Solve SPPU Previous Year Question (PYQ) 5-mark and 6-mark problems.
3. **Block 3 (30 mins):** Formula sheet consolidation & diagnostic quiz review.

💡 **One-Tap Schedule Update:**
You can tap the action button below to instantly apply this optimized End-Sem plan to your timetable!
''';
    }

    return '💡 **AI Academic Tutor**\n\nTo unlock live real-time conversational responses from Gemini 2.5 Flash, please configure your Gemini API Key in Settings (or connect your local llama.cpp / Ollama API endpoint).';
  }

  /// Generates a Quiz dynamically using AI (Gemini or OpenAI Compatible)
  static Future<List<Question>> generateQuiz({
    required Subject subject,
    required int? targetUnitNumber,
    required UserProfile profile,
    required String apiKey,
    required int count,
  }) async {
    final unitText = targetUnitNumber != null ? 'Unit $targetUnitNumber' : 'Units 1 to 5';
    final systemPrompt = '''
You are an expert AI quiz generator for SPPU (Savitribai Phule Pune University) First Year Engineering (2024 Pattern).
Generate $count highly important multiple-choice questions for the subject: ${subject.name}, covering $unitText.
Focus strictly on Previous Year Questions (PYQs) important topics. The AI must know what to ask based on SPPU exam patterns.
Format the output EXACTLY as a JSON array of objects. Do not include markdown code blocks. Each object must have:
"questionText" (string), "options" (array of 4 strings), "correctOption" (integer 0-3), "explanation" (string), "difficulty" (string: Easy/Medium/Hard).
''';

    if (profile.customOpenAiBaseUrl.trim().isNotEmpty && profile.customOpenAiApiKey.trim().isNotEmpty) {
      // Use Custom OpenAI API
      final model = profile.customOpenAiModel.trim().isNotEmpty ? profile.customOpenAiModel.trim() : 'llama3';
      try {
        final response = await http.post(
          Uri.parse('${profile.customOpenAiBaseUrl.trim()}/v1/chat/completions'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer \${profile.customOpenAiApiKey.trim()}',
          },
          body: jsonEncode({
            'model': model,
            'messages': [
              {'role': 'system', 'content': systemPrompt},
              {'role': 'user', 'content': 'Generate the quiz now in JSON.'}
            ],
            'temperature': 0.7,
          }),
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final text = data['choices'][0]['message']['content'] as String;
          return _parseQuizJson(text, subject.id, targetUnitNumber ?? 1);
        } else {
          debugPrint('Local API error: \${response.statusCode}');
        }
      } catch (e) {
        debugPrint('Local API exception: \$e');
      }
      return [];
    }

    if (apiKey.trim().isEmpty) return [];

    // Use Gemini API
    try {
      final model = GenerativeModel(
        model: _primaryModel,
        apiKey: apiKey,
        systemInstruction: Content.system(systemPrompt),
      );
      final response = await model.generateContent([Content.text('Generate the quiz now in JSON.')]);
      if (response.text != null) {
        return _parseQuizJson(response.text!, subject.id, targetUnitNumber ?? 1);
      }
    } catch (e) {
      debugPrint('Gemini API quiz generation failed: \$e');
    }
    return [];
  }

  static List<Question> _parseQuizJson(String rawText, String subjectId, int unitNumber) {
    try {
      var clean = rawText.trim();
      if (clean.startsWith('```json')) {
        clean = clean.substring(7);
        if (clean.endsWith('```')) clean = clean.substring(0, clean.length - 3);
      } else if (clean.startsWith('```')) {
        clean = clean.substring(3);
        if (clean.endsWith('```')) clean = clean.substring(0, clean.length - 3);
      }
      final List<dynamic> jsonList = jsonDecode(clean.trim());
      return jsonList.asMap().entries.map((entry) {
        final idx = entry.key;
        final map = entry.value as Map<String, dynamic>;
        return Question(
          id: 'ai_quiz_${DateTime.now().millisecondsSinceEpoch}_$idx',
          subjectId: subjectId,
          unitNumber: unitNumber,
          topic: 'SPPU PYQ Topic',
          questionText: map['questionText']?.toString() ?? 'Error parsing question',
          options: List<String>.from(map['options'] ?? ['A', 'B', 'C', 'D']),
          correctOption: map['correctOption'] as int? ?? 0,
          explanation: map['explanation']?.toString() ?? 'No explanation.',
          normalTimeSeconds: 90,
          difficulty: map['difficulty']?.toString() ?? 'Medium',
          year: 2024,
          exam: 'AI Generated',
        );
      }).toList();
    } catch (e) {
      debugPrint('Failed to parse AI quiz JSON: \$e');
      return [];
    }
  }
}
