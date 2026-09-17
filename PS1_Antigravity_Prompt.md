# Antigravity Build Prompt — PS1: Personalized AI Learning Assistant (Native Android)

Copy everything below into Antigravity as your initial project prompt. Feel free to split it into
stages (see "Suggested Staging" at the bottom) rather than firing it all at once.

---

## Project Overview

Build a native Android app called **"FocusPath"** — a personalized AI learning assistant for
students, using Kotlin and Jetpack Compose. The app analyzes a student's quiz performance,
generates a personalized study plan using the Gemini API, tracks progress over time, schedules
study reminders using AlarmManager, and — as a key differentiator — monitors phone usage of
distracting apps (via UsageStatsManager) to nudge the student back to studying when they've been
distracted too long.

Target: Android 8.0 (API 26) and above. Use Kotlin, Jetpack Compose, Material 3 design.

## Tech Stack

- **Language/UI**: Kotlin, Jetpack Compose, Material 3, Navigation Compose
- **AI**: Gemini API via the official Google AI SDK for Android (Kotlin)
- **Backend/Data**: Firebase Firestore (data), Firebase Auth (simple anonymous or email auth)
- **Local storage**: DataStore (for user preferences, e.g., which apps are "distracting")
- **Native APIs**: AlarmManager + BroadcastReceiver (reminders), UsageStatsManager (app usage
  tracking), NotificationManager (nudges/reminders)
- **Architecture**: MVVM (ViewModel + StateFlow/UiState), Repository pattern for Firestore and
  Gemini calls, dependency injection with Hilt if feasible (otherwise manual DI is fine for a
  hackathon-scale app)

## Core User Flow

1. **Onboarding**: Student enters name/grade level and selects subjects they're studying (e.g.,
   Math, Physics, Chemistry — make this a simple multi-select list, extensible).
2. **Quiz**: Student takes a short quiz (10 questions) on a selected subject. Questions are
   generated dynamically by calling the Gemini API with a prompt requesting topic-tagged
   multiple-choice questions in structured JSON format (see Data Contracts below).
3. **Scoring & Analysis**: After the quiz, the app tags each answer as correct/incorrect per
   topic, computes a per-topic mastery score (0–100), and stores results in Firestore.
4. **AI Study Plan Generation**: The app sends the student's topic-wise scores to Gemini and
   requests a personalized study plan: prioritized list of weak topics, a short explanation of
   *why* each topic needs work (in plain language, referencing their specific mistakes if
   possible), and a suggested daily study schedule for the next 7 days.
5. **Dashboard**: Shows overall mastery per subject (progress bars or radar chart), the current
   study plan, and a "next recommended session" card.
6. **Adaptive Practice**: Student can start a practice session on a specific weak topic; question
   difficulty adjusts based on live performance within the session (get 2 right → next question
   is harder; get 1 wrong → next is easier/reinforces the same concept differently).
7. **Study Reminders (AlarmManager)**: Based on the generated 7-day schedule, the app schedules
   exact alarms that fire local notifications at the recommended study times ("Time to review
   Thermodynamics — you're at 62% mastery").
8. **Distraction Awareness (UsageStatsManager)**: In a settings screen, the student marks certain
   apps as "distracting" (e.g., Instagram, YouTube, games — pull the installed app list and let
   them multi-select). During active study hours (derived from the schedule), the app
   periodically checks recent foreground app usage via UsageStatsManager. If a distracting app has
   been used for more than a configurable threshold (e.g., 15 minutes) during a scheduled study
   block, fire a gentle nudge notification ("You've spent 18 min on Instagram during your Chemistry
   study block — want to jump back in?").

## Data Contracts (require Gemini to return structured JSON — critical, be explicit about this)

### Quiz question generation request/response shape:
```json
{
  "questions": [
    {
      "id": "q1",
      "topic": "Thermodynamics",
      "question_text": "...",
      "options": ["A", "B", "C", "D"],
      "correct_option_index": 2,
      "difficulty": "medium"
    }
  ]
}
```

### Study plan generation response shape:
```json
{
  "weak_topics": [
    {
      "topic": "Thermodynamics",
      "mastery_score": 42,
      "reason": "Missed 3/4 questions on entropy calculations",
      "recommended_action": "Review entropy formulas, then retry practice set"
    }
  ],
  "schedule": [
    { "day": "Day 1", "topic": "Thermodynamics", "duration_minutes": 30, "time_of_day": "Evening" }
  ]
}
```

Instruct Antigravity explicitly: **"All Gemini responses must be requested and parsed as strict
JSON matching these schemas. Include a system/prompt instruction telling Gemini to return ONLY
valid JSON with no markdown code fences or extra text. Add a JSON-parsing fallback that strips
markdown fences if present, since models sometimes wrap JSON in ```json blocks despite
instructions."**

## Firestore Data Model

- `users/{userId}`: name, gradeLevel, subjects (list), createdAt
- `users/{userId}/quizResults/{quizId}`: subject, topicScores (map), timestamp, rawAnswers
- `users/{userId}/studyPlans/{planId}`: weakTopics (list), schedule (list), generatedAt
- `users/{userId}/distractionSettings`: distractingApps (list of package names), thresholdMinutes

## Screens to Build (Compose)

1. Onboarding screen
2. Subject selection screen
3. Quiz screen (question card, options, progress indicator, timer optional)
4. Quiz results screen (score summary, topic breakdown)
5. Dashboard screen (main hub: mastery overview, today's plan, next session CTA)
6. Study plan detail screen (7-day schedule view)
7. Adaptive practice screen
8. Distraction settings screen (app picker + threshold slider)
9. Notification/reminder settings screen

## Permissions & Native API Handling — Be Explicit With Antigravity

- Request `PACKAGE_USAGE_STATS` permission via `Settings.ACTION_USAGE_ACCESS_SETTINGS` intent
  (this is NOT a runtime dialog permission — build a clear in-app screen explaining why it's
  needed before redirecting to system settings).
- For Android 12+ (API 31+), handle `SCHEDULE_EXACT_ALARM` permission properly — check
  `AlarmManager.canScheduleExactAlarms()` and request via
  `ACTION_REQUEST_SCHEDULE_EXACT_ALARM` if not granted.
- Handle notification permission (`POST_NOTIFICATIONS`) for Android 13+ (API 33+) as a runtime
  permission request.
- **Ask Antigravity to explicitly state which Android API levels its generated code targets and
  flag any deprecated APIs it uses** — this is a known weak spot for AI-generated Android code.

## What I Want You (Antigravity) To Do

1. Set up the full project structure (Gradle, Kotlin, Compose, Hilt/manual DI, Firebase config
   placeholders, Gemini SDK dependency).
2. Build each screen listed above with working navigation between them.
3. Implement the Repository layer for Firestore and Gemini calls, with proper loading/error/success
   states surfaced to the UI (no silent failures).
4. Implement AlarmManager scheduling tied to the generated study plan.
5. Implement UsageStatsManager integration with correct permission handling for the target API
   levels.
6. After generating each major piece, explain in plain language what you built, which Android API
   levels it targets, and flag anything you're unsure about or any deprecated/soon-to-change APIs
   you used.
7. Do NOT hardcode API keys — use local.properties / BuildConfig for the Gemini API key and
   google-services.json for Firebase, and tell me exactly where to plug in my own keys.

## Suggested Staging (don't dump this all in one prompt)

1. **Stage 1**: Project scaffold + onboarding + subject selection + navigation skeleton
2. **Stage 2**: Quiz screen + Gemini question generation + JSON parsing
3. **Stage 3**: Scoring logic + Firestore write/read + dashboard screen
4. **Stage 4**: Study plan generation (Gemini) + study plan detail screen
5. **Stage 5**: AlarmManager reminders
6. **Stage 6**: UsageStatsManager distraction detection + settings screen
7. **Stage 7**: Adaptive practice screen (harder — do this once core loop is solid)

Test and understand each stage before moving to the next — this is where you'll learn the most
about Antigravity's strengths/weaknesses (per-screen UI polish, Firestore wiring reliability, and
especially Stage 5/6 native API correctness).
