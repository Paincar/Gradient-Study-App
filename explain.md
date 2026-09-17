# FocusPath — Complete Technical Architecture, Feature Documentation & Evolution Guide

> **FocusPath** is an offline-first, distraction-free study sanctuary and exam preparation platform tailored specifically for **Savitribai Phule Pune University (SPPU) First Year Engineering (FE 2024 Revised Curriculum)**.
> It blends a **Structured-style daily timeline scheduler**, an **immersive Pomodoro focus sanctuary** with binaural/ambient soundscapes, an **authentic SPPU question bank and Previous Year Questions (PYQs)**, an **adaptive AI Tutor powered by Google Gemini**, and a **hardware-level Android Distraction Shield** utilizing native Kotlin `UsageStatsManager` and `AlarmManager`.

---

## Table of Contents
1. [App Overview & Core Philosophy](#1-app-overview--core-philosophy)
2. [Academic Grounding: SPPU 2024 Curriculum](#2-academic-grounding-sppu-2024-curriculum)
3. [Complete Directory & File Structure](#3-complete-directory--file-structure)
4. [Deep Dive into Every Feature](#4-deep-dive-into-every-feature)
   - 4.1 Onboarding & Personalization Questionnaire
   - 4.2 Home Sanctuary Dashboard
   - 4.3 Structured-Style Daily Scheduler & Timetable
   - 4.4 Focus Sanctuary (Pomodoro & Ambient Audio)
   - 4.5 Tests & Diagnostics Hub (MCQs & Exam Prep)
   - 4.6 Authentic Subjectwise Question Datasets & PYQ Repository
   - 4.7 Subject Notes & Gemini AI Tutor
   - 4.8 Android Native Distraction Shield & App Blocking
   - 4.9 SPPU Academic Calendar & Custom Holidays
   - 4.10 Full Syllabus Tree & Unit Explorer
   - 4.11 Study Analytics & Progress Visualizer
   - 4.12 Settings, Rosé Pine Theming & Data Portability
5. [Native Android Kotlin Engine & Hardware Bridges](#5-native-android-kotlin-engine--hardware-bridges)
6. [State Management & Data Persistence Architecture](#6-state-management--data-persistence-architecture)
7. [Evolution, Key Refactorings & UI Sanitization](#7-evolution-key-refactorings--ui-sanitization)
8. [Bugs Encountered, Root Causes & Technical Fixes](#8-bugs-encountered-root-causes--technical-fixes)
9. [Automated Testing & Release Verification](#9-automated-testing--release-verification)
10. [Maintenance & Extension Guide](#10-maintenance--extension-guide)

---

## 1. App Overview & Core Philosophy

Most study apps suffer from three fatal flaws:
1. **Generic Content**: They contain generic questions that do not match the specific marking scheme, unit division, or exam patterns of the student's university.
2. **UI Clutter & Distraction**: Harsh, high-contrast interfaces, banner ads, and complex menus drain cognitive energy.
3. **Shallow Implementation ("Mock UI")**: Notification toggles, scheduling reminders, and distraction blockers often only show temporary in-app snackbars rather than interacting with the underlying Android operating system.

### The FocusPath Solution:
- **SPPU-Grounded**: Every unit, topic, question, and PYQ is mapped directly to the official SPPU 2024 Revised Course Curriculum (`fe-2024.pdf`).
- **Rosé Pine Pastel Aesthetics**: Built on the Rosé Pine color philosophy (warm chalky surfaces, soft pastels, muted text) designed to minimize ocular fatigue during late-night study sessions.
- **Real Native Android Integration**: Utilizes Kotlin MethodChannels for exact `AlarmManager` reminders, `UsageStatsManager` foreground application monitoring, and heads-up system notifications with vibration and sound.
- **100% Offline-First**: All curriculum datasets, questions, PYQs, and study schedules are bundled locally inside the APK. SharedPreferences handles reactive persistence, with Google Gemini AI as an optional real-time enhancement when online.

---

## 2. Academic Grounding: SPPU 2024 Curriculum

FocusPath natively models the entire **SPPU First Year Engineering (All Branches - Group A & Group B)** structure:

| Internal Subject ID | Full Clean Subject Name | Category | Semester | Units Covered |
|---|---|---|---|---|
| `m1` | Engineering Mathematics 1 | Basic Science Course | Sem 1 | 1. Linear Algebra (Matrices), 2. Calculus (Rolle's, Mean Value), 3. Partial Differentiation, 4. Applications of Partial Diff, 5. Differential Equations of First Order |
| `physics` | Engineering Physics | Basic Science Course | Sem 1 / 2 | 1. Wave Optics, 2. Lasers & Fiber Optics, 3. Quantum Mechanics, 4. Semiconductor Physics, 5. Superconductivity & Nanotechnology |
| `bxe` | Basic Electronics Engineering | Engineering Science Course | Sem 1 / 2 | 1. Semiconductor Diodes, 2. Bipolar Junction Transistors (BJT), 3. Field Effect Transistors (FET/MOSFET), 4. Operational Amplifiers (Op-Amp), 5. Digital Electronics Fundamentals |
| `eg` | Engineering Graphics | Engineering Science Course | Sem 1 / 2 | 1. Fundamentals of Engineering Drawing, 2. Projections of Points & Lines, 3. Projections of Planes, 4. Projections of Solids, 5. Isometric & Orthographic Projections |
| `fpl` | Fundamentals of Programming Languages | Engineering Science Course | Sem 1 | 1. Computer Fundamentals & Algorithms, 2. Variables, Data Types & Operators, 3. Control Flow & Loops, 4. Functions & Modular Programming, 5. Arrays, Pointers & File Basics |
| `m2` | Engineering Mathematics 2 | Basic Science Course | Sem 2 | 1. First Order Diff Eq Applications, 2. Higher Order Linear Diff Eq, 3. Integral Calculus (Gamma & Beta), 4. Curve Tracing & Rectification, 5. Multiple Integrals (Double & Triple) |
| `chemistry` | Engineering Chemistry | Basic Science Course | Sem 1 / 2 | 1. Periodic Properties & Chemical Bonding, 2. Water Technology & Hardness, 3. Instrumental Analysis (UV-Vis, IR), 4. Polymer Chemistry & Advanced Materials, 5. Fuels & Combustion / Energy Storage |
| `bee` | Basic Electrical Engineering | Engineering Science Course | Sem 1 / 2 | 1. DC Circuits & Network Theorems, 2. Electromagnetism & Magnetic Circuits, 3. Single Phase AC Circuits, 4. Polyphase (3-Phase) AC Circuits, 5. Transformers & DC Machines |
| `mechanics` | Engineering Mechanics | Engineering Science Course | Sem 1 / 2 | 1. Concurrent Coplanar Force Systems, 2. Non-Concurrent Force Systems, 3. Analysis of Trusses & Friction, 4. Kinematics of Particles (Rectilinear & Curvilinear), 5. Kinetics of Particles (Newton's 2nd Law, Work-Energy, Impulse) |
| `pps` | Programming & Problem Solving (Python) | Engineering Science Course | Sem 2 | 1. Problem Solving Concepts & Algorithms, 2. Python Basics & Control Structures, 3. Functions, Modules & Strings, 4. Python Data Structures (Lists, Tuples, Dictionaries, Sets), 5. File Handling & Object-Oriented Programming |

---

## 3. Complete Directory & File Structure

```
c:/projects/app/
│
├── android/
│   └── app/src/main/
│       ├── AndroidManifest.xml          # Declares exact alarms, POST_NOTIFICATIONS, PACKAGE_USAGE_STATS
│       └── kotlin/com/focuspath/app/
│           ├── MainActivity.kt          # Kotlin MethodChannel engine (UsageStats, Alarms, Notifications)
│           └── AlarmReceiver.kt         # BroadcastReceiver firing system heads-up notifications with sound
│
├── assets/
│   ├── data/
│   │   ├── syllabus.json               # Full SPPU curriculum breakdown (units, subtopics, exam weightages)
│   │   ├── quotes.json                 # Curated motivational & stoic study quotes
│   │   ├── questions.json              # Aggregated master question bank
│   │   ├── pyqs.json                   # Authentic SPPU university PYQs with step marking & model answers
│   │   └── questions/                  # Modular subjectwise datasets (User directive)
│   │       ├── m1.json
│   │       ├── physics.json
│   │       ├── bxe.json
│   │       ├── eg.json
│   │       ├── fpl.json
│   │       ├── m2.json
│   │       ├── chemistry.json
│   │       ├── bee.json
│   │       ├── mechanics.json
│   │       └── pps.json
│   │
│   └── sounds/                         # High-fidelity ambient audio files for Pomodoro sanctuary
│       ├── Rain.m4a
│       ├── Library.m4a
│       ├── CofficeShop.m4a
│       ├── Stream.m4a
│       ├── FireBurning.m4a
│       └── Whitenoise.m4a
│
├── lib/
│   ├── main.dart                       # App entry point, WidgetsFlutterBinding, async local store init
│   ├── app.dart                        # MaterialApp host, theme observer, onboarding router, IndexedStack
│   ├── providers.dart                  # Riverpod Notifiers (UserProfile, Notes, Timetable, Feedback)
│   │
│   ├── core/
│   │   ├── services/
│   │   │   ├── native_service.dart     # Flutter-to-Kotlin MethodChannel bridge
│   │   │   └── gemini_service.dart     # Google Gemini AI tutor integration with vocabulary adaptation
│   │   └── theme/
│   │       └── rose_pine_theme.dart    # Rosé Pine Dark & Dawn Light palettes, Typography & M3 styles
│   │
│   ├── data/
│   │   ├── models/
│   │   │   └── models.dart             # Data classes (UserProfile, Subject, TimetableSlot, PYQItem, etc.)
│   │   └── datasources/
│   │       └── local_store.dart        # SharedPreferences persistence layer & schedule generator
│   │
│   └── ui/
│       ├── common/
│       │   ├── floating_bottom_nav.dart # Aesthetic pill-shaped 6-tab navigation bar
│       │   └── responsive_wrapper.dart  # Mobile & tablet layout constraint wrapper
│       ├── onboarding/
│       │   └── onboarding_screen.dart   # 5-step interactive personalization questionnaire
│       ├── home/
│       │   └── home_screen.dart         # Hero streak, daily progress ring, next study block, quick launch
│       ├── timetable/
│       │   └── timetable_screen.dart    # Structured-style 7-day timeline scheduler with alarms
│       ├── focus/
│       │   └── focus_screen.dart        # Pomodoro timer, ambient audio engine, distraction shield trigger
│       ├── tests/
│       │   ├── test_hub_screen.dart     # Unit quiz selector, In-Sem & End-Sem exam prep hubs
│       │   ├── quiz_screen.dart         # Timed quiz runner with per-question countdown and time-traps
│       │   ├── quiz_result_screen.dart  # Score diagnostic, time analytics, bookmark to notes, routine boost
│       │   └── pyq_viewer_screen.dart   # Authentic SPPU university paper viewer with step marking
│       ├── notes/
│       │   └── notes_screen.dart        # Markdown notes editor, subject filter, Gemini AI Tutor dialogue
│       ├── calendar/
│       │   └── calendar_screen.dart     # SPPU academic semester calendar, exams & custom holiday creator
│       ├── syllabus/
│       │   └── syllabus_screen.dart     # Tree explorer for subjects, units, subtopics, and weightages
│       ├── analytics/
│       │   └── analytics_screen.dart    # Weekly study hours, subject breakdown chart, streak statistics
│       ├── settings/
│       │   ├── settings_screen.dart     # Theme mode, accent color selector, subject exclusions, API key
│       │   └── app_blocking_screen.dart # Real Android UsageStats shield, tier toggles & test nudges
│       └── feedback/
│           └── feedback_screen.dart     # In-app user feedback submission & local history
│
└── test/
    ├── dataset_and_scheduler_test.dart  # Unit tests for all 10 subject datasets, PYQs, and scheduler
    └── widget_test.dart                 # Widget tests for navigation tabs, responsive container, theme
```

---

## 4. Deep Dive into Every Feature

### 4.1 Onboarding & Personalization Questionnaire
- **File**: [`lib/ui/onboarding/onboarding_screen.dart`](file:///c:/projects/app/lib/ui/onboarding/onboarding_screen.dart)
- **Purpose**: Welcomes the engineering student and creates an individualized profile before they begin studying.
- **How It Works**:
  1. **Page 1: Identity & Greeting**: Captures the student's preferred name.
  2. **Page 2: Vocabulary & Tone Customization**: Lets the student select their desired AI Tutor communication style:
     - `Simple`: Explains technical engineering concepts using everyday analogies (e.g., explaining transistor gates like water valves).
     - `Intermediate`: Standard university textbook language with clear definitions.
     - `Academic`: Rigorous formal engineering proofs, theorems, and mathematical precision.
  3. **Page 3: Study Target & Timing**: Daily study goal (2 to 8 hours) and preferred focus window (Early Morning, Afternoon, Evening, Night Owl).
  4. **Page 4: Weak Subject Identification**: Multi-select chip interface. Subjects marked as "hard" automatically receive **+25% extended study blocks** in the timetable generator.
  5. **Page 5: Distraction Monitoring**: Selects apps to shield against (Instagram, YouTube, Reddit, TikTok, BGMI/Games).
- **Persistence**: Persists directly into `LocalStore` and sets `hasCompletedOnboarding = true`.

---

### 4.2 Home Sanctuary Dashboard
- **File**: [`lib/ui/home/home_screen.dart`](file:///c:/projects/app/lib/ui/home/home_screen.dart)
- **Key Elements**:
  - **Dynamic Greeting**: Time-aware greeting (`Good morning / afternoon / evening, <Name>`) with motivational quotes rotating on app start.
  - **Streak & Study Time Badges**: Shows active day streak (e.g., `🔥 5 Days`) and today's total study minutes.
  - **Circular Daily Progress Ring**: Calculates the fraction of scheduled study slots completed for the current day.
  - **Next Up Timetable Card**: Displays the immediate upcoming study slot with countdown pill, start button (which jumps straight into a Pomodoro pre-configured for that subject), and notes preview.
  - **Quick Action Grid**: 1-tap navigation to *Start Pomodoro*, *Take Unit Quiz*, *Open SPPU PYQs*, and *Ask AI Tutor*.
  - **In-Sem Exam Countdown Card**: Live countdown ticker to the upcoming SPPU examination period.

---

### 4.3 Structured-Style Daily Scheduler & Timetable
- **File**: [`lib/ui/timetable/timetable_screen.dart`](file:///c:/projects/app/lib/ui/timetable/timetable_screen.dart)
- **Design Inspiration**: Modeled directly after the beloved **Structured** iOS/macOS task planner.
- **Features**:
  1. **7-Day Strip (Monday to Sunday)**: Horizontal day selector showing day name, date number, and a micro-progress ring indicating completion status for each day of the week.
  2. **Vertical Timeline**:
     - Left axis with distinct hourly markers (`09:00`, `10:00`, `11:00`, etc.) and connector guide lines.
     - Color-coded task cards matched to the subject's theme accent.
     - Task status pills (`Completed`, `In Progress`, `Upcoming`).
     - Interactive completion checkmark: Tapping immediately marks the slot completed, plays haptic feedback, and updates daily metrics.
  3. **"+ Add Study Block" Modal**:
     - Custom task title or SPPU subject dropdown.
     - Unit selection (Units 1 to 5).
     - Day of the week picker.
     - Time picker (Hour and Minute).
     - Duration slider (15 min to 180 min).
     - Reminder alarm toggle.
     - Custom revision notes.
  4. **Slot Action Sheet**:
     - Tapping any slot opens a bottom sheet with options:
       - **Start Focus Session**: Directly launches the Pomodoro timer pre-populated with that subject and unit.
       - **Mark Complete / Incomplete**.
       - **Delete Block**.
  5. **Auto-Routine Generator**: Distributes subjects across Monday–Saturday sequentially, with Sunday reserved for full-length revision and mock test diagnostics. Hard subjects automatically receive 75–90 minute blocks instead of the default 60 minutes.
  6. **Native Alarms**: Whenever a timetable is created or edited, FocusPath schedules exact alarms **5 minutes before the block starts** via `NativeService.scheduleAlarm`.

---

### 4.4 Focus Sanctuary (Pomodoro & Ambient Audio)
- **File**: [`lib/ui/focus/focus_screen.dart`](file:///c:/projects/app/lib/ui/focus/focus_screen.dart)
- **Capabilities**:
  - **Configurable Sessions**: Presets for *Pomodoro (25m / 5m break)*, *Deep Work (50m / 10m break)*, and *Custom Duration*.
  - **Ambient Soundscapes Engine**: Integrated high-efficiency audio playback using `just_audio` supporting:
    - 🌧️ Rain (`assets/sounds/Rain.m4a`)
    - 📚 Library Silence (`assets/sounds/Library.m4a`)
    - ☕ Café Ambience (`assets/sounds/CofficeShop.m4a`)
    - 🌊 Mountain Stream (`assets/sounds/Stream.m4a`)
    - 🔥 Fireplace Hearth (`assets/sounds/FireBurning.m4a`)
    - ⚪ Focused White Noise (`assets/sounds/Whitenoise.m4a`)
  - **Looping & Audio Session Optimization**: Sounds loop seamlessly and pause automatically when the timer stops or pauses.
  - **Native Distraction Shield Trigger**: During active sessions, the distraction shield runs in the background. If the user navigates away to a blacklisted app, a native warning notification is dispatched.
  - **Completion Protocol**: When the timer reaches zero, the audio pauses, native notifications trigger with sound/vibration, the study minutes are committed to local storage, and streak calculation runs.
  - **Safe Exit Dialog**: Wrapped in `PopScope` to prevent accidental timer loss when the Android back gesture is triggered.

---

### 4.5 Tests & Diagnostics Hub (MCQs & Exam Prep)
- **Files**:
  - [`lib/ui/tests/test_hub_screen.dart`](file:///c:/projects/app/lib/ui/tests/test_hub_screen.dart)
  - [`lib/ui/tests/quiz_screen.dart`](file:///c:/projects/app/lib/ui/tests/quiz_screen.dart)
  - [`lib/ui/tests/quiz_result_screen.dart`](file:///c:/projects/app/lib/ui/tests/quiz_result_screen.dart)
- **Architecture**:
  - **Unit Quizzes**: Allows testing individual units (e.g., *Engineering Mathematics 1 — Unit 3: Partial Differentiation*).
  - **In-Sem Diagnostic Mode**: Covers Units 1 & 2 (SPPU 30-mark mid-term syllabus).
  - **End-Sem Full Diagnostic Mode**: Covers all Units 1 through 5 (SPPU 70-mark university paper syllabus).
  - **Live Question Countdown & Time-Trap Detection**:
    - Each question features a live timer.
    - If a student spends >90 seconds on a question, the timer turns amber (`Needs Work`).
    - If >150 seconds, it turns red and flags the question as a `Time Trap`.
  - **Diagnostic Results & Remediation**:
    - Calculates Accuracy Score, Total Time, Average Time per Question, and Time Trap Count.
    - Shows an in-depth breakdown of every question with the correct answer highlighted in emerald, chosen incorrect answer in rose, and a step-by-step mathematical explanation.
    - **"Save to Notes 📝"**: 1-tap button appending tricky questions directly to the student's notebook.
    - **"Boost in Daily Timetable ⚡"**: If the student scores low, a 1-tap button adds the subject to their `hardSubjects` list, immediately boosting future timetable allocations by +25%.

---

### 4.6 Authentic Subjectwise Question Datasets & PYQ Repository
- **Directory**: `assets/data/questions/`
- **Master Files**: `assets/data/questions.json`, `assets/data/pyqs.json`
- **User Directive Honored**: The dataset was completely separated into modular, standalone JSON files for each subject:
  ```
  assets/data/questions/
  ├── m1.json         # 8+ authentic questions across Units 1-5
  ├── physics.json    # 8+ authentic questions across Units 1-5
  ├── bxe.json        # 8+ authentic questions across Units 1-5
  ├── eg.json         # 8+ authentic questions across Units 1-5
  ├── fpl.json        # 8+ authentic questions across Units 1-5
  ├── m2.json         # 8+ authentic questions across Units 1-5
  ├── chemistry.json  # 8+ authentic questions across Units 1-5
  ├── bee.json        # 8+ authentic questions across Units 1-5
  ├── mechanics.json  # 8+ authentic questions across Units 1-5
  └── pps.json        # 8+ authentic questions across Units 1-5
  ```
- **PYQ Viewer Screen** ([`pyq_viewer_screen.dart`](file:///c:/projects/app/lib/ui/tests/pyq_viewer_screen.dart)):
  - Authentic previous year SPPU questions (May 2024, Dec 2023, May 2023, Dec 2022).
  - Filter by Unit or view all.
  - Displays official exam session, year, marks (e.g., `5 Marks`, `7 Marks`), and difficulty.
  - Expandable **Step-by-Step Marking Scheme** (e.g., `Step 1: Characteristic Equation [1 Mark]`, `Step 2: Eigenvalues calculation [2 Marks]`, `Step 3: Eigenvectors [2 Marks]`).
  - Expandable **Model Solution** with full mathematical steps.
  - "Save to Notes" action on every PYQ.

---

### 4.7 Subject Notes & Gemini AI Tutor (Personalization Closed-Loop)
- **Files**:
  - UI: [`lib/ui/notes/notes_screen.dart`](file:///c:/projects/app/lib/ui/notes/notes_screen.dart)
  - Service: [`lib/core/services/gemini_service.dart`](file:///c:/projects/app/lib/core/services/gemini_service.dart)
  - Models: [`lib/data/models/models.dart`](file:///c:/projects/app/lib/data/models/models.dart)
- **Closed-Loop AI Personalization**:
  - **Diagnostic Mastery Tracking**: Every completed quiz computes rolling mastery per unit:
    $$M_{new} = 0.40 \times M_{hist} + 0.60 \times A_{recent}$$
  - **Weak Unit Detection**: Any unit with accuracy below 60% is diagnosed as weak.
  - **Dynamic System Prompt Injection**:
    ```dart
    'STUDENT DIAGNOSTICS & WEAK AREAS (SPPU):'
    '- The student currently struggles with: [Engineering Mathematics 1 — Unit 3 (33% accuracy)]'
    '- When explaining concepts in these areas, break down fundamentals step-by-step, highlight common pitfalls in SPPU In-Sem / End-Sem papers, and provide an illustrative solved example.'
    ```
  - **Custom AI Persona System Instructions**: Students can set custom persona instructions (e.g., *"Explain like Feynman"*, *"SPPU Exam Topper Mentor"*, *"B.Tech Senior Guide"*) in Sanctuary Settings, which are injected at highest priority.
  - **Gemini 2.0 Flash Upgrade**: Default AI model upgraded from retiring `gemini-2.5-flash` to the state-of-the-art `gemini-2.0-flash`, with automatic fallback to `gemini-1.5-flash` upon network/quota failure.
  - **Timetable Feedback Loop**: Weak units automatically receive a 25% duration boost and priority slots in the Structured Timetable.

---

### 4.8 Android Native Distraction Shield & App Blocking (Installed Apps Picker & Overlay)
- **File**: [`lib/ui/settings/app_blocking_screen.dart`](file:///c:/projects/app/lib/ui/settings/app_blocking_screen.dart)
- **Native Implementation**: [`MainActivity.kt`](file:///c:/projects/app/android/app/src/main/kotlin/com/focuspath/app/MainActivity.kt)
- **Permissions Declared**:
  - `PACKAGE_USAGE_STATS` (Usage Access)
  - `SYSTEM_ALERT_WINDOW` (Display Over Other Apps)
  - `QUERY_ALL_PACKAGES` (Allows querying all launcher activities across Android 11–16)
- **How It Works**:
  1. **Dual Permission Monitoring**: Live cards reflect both Android Usage Access and Display Over Other Apps statuses, with one-tap deep-links to Android System Settings.
  2. **Installed Apps Picker**:
     - Calls native Kotlin `getInstalledApps()` which queries `packageManager.queryIntentActivities(Intent.ACTION_MAIN.addCategory(CATEGORY_LAUNCHER))` to retrieve all user-launchable apps installed on the device.
     - Searchable bottom sheet modal allows students to select and block **any** installed app (e.g. BGMI, Discord, Free Fire, Telegram, Chrome) in addition to popular defaults.
  3. **3-Hour Rolling Usage Scan**:
     - Matches apps by package name, custom bundle IDs, or application label.
     - Detects cumulative foreground screen-time across the past 3 hours.
  4. **Enforcement & Heads-Up Alerts**:
     - Triggers native high-priority heads-up system notifications with sound and vibration.
     - Full-screen focus lock overlay support when continuous usage limit is breached.
  5. **4 Enforcement Tiers**:
     - *Off*: No background checks.
     - *Nudge Only*: Friendly system notification.
     - *Full-screen Overlay*: System alert + lock-screen study prompt.
     - *Strict Mode*: Aggressive repeating reminders until the Pomodoro ends.

---

### 4.9 SPPU Academic Calendar & Custom Holidays
- **File**: [`lib/ui/calendar/calendar_screen.dart`](file:///c:/projects/app/lib/ui/calendar/calendar_screen.dart)
- **Features**:
  - Preloaded with official SPPU 2024–2025 academic milestones:
    - Commencement of Term 1
    - SPPU In-Sem Theory Examinations (Phase 1)
    - Conclusion of Teaching
    - Practical / Oral / Project Examinations
    - SPPU End-Sem Theory Examinations (Phase 2)
    - Diwali Vacation, Winter Break, and National Holidays.
  - Interactive calendar month view highlighting study days, exam periods, and holidays.
  - Custom Holiday Addition: Students can add college-specific symposiums, sports days, or personal leave.

---

### 4.10 Full Syllabus Tree & Unit Explorer
- **File**: [`lib/ui/syllabus/syllabus_screen.dart`](file:///c:/projects/app/lib/ui/syllabus/syllabus_screen.dart)
- **Features**:
  - Complete hierarchical explorer of all 10 subjects.
  - Visual progress bar per subject based on completed units and notes created.
  - Expandable accordion tiles for each of the 5 units displaying:
    - Official SPPU unit title.
    - Complete subtopic bullet points.
    - Theory hours allocation according to the SPPU curriculum.
    - Quick action buttons: *"Practice MCQs for this Unit"* and *"View Unit PYQs"*.

---

### 4.11 Study Analytics & Progress Visualizer
- **File**: [`lib/ui/analytics/analytics_screen.dart`](file:///c:/projects/app/lib/ui/analytics/analytics_screen.dart)
- **Features**:
  - Weekly study time bar chart built with `fl_chart`.
  - Subject-by-subject distribution showing exact minutes spent.
  - Longest streak vs. current streak tracking.
  - Focus score calculation based on completed vs. skipped timetable blocks.

---

### 4.12 Settings, Rosé Pine Theming & Data Portability
- **File**: [`lib/ui/settings/settings_screen.dart`](file:///c:/projects/app/lib/ui/settings/settings_screen.dart)
- **Features**:
  - **Dynamic Theme Mode**: System default, Rosé Pine Dark, or Rosé Pine Dawn (Light).
  - **Accent Palette Selector**: Switch primary accents between `Pine` (emerald), `Love` (blush coral), `Gold` (warm ochre), `Foam` (aquamarine), and `Iris` (lavender).
  - **Curriculum Subject Exclusions**: Toggle off subjects not applicable to the student's current semester division (e.g., if taking Chemistry cycle in Sem 1, exclude Physics).
  - **Google Gemini API Key Management**: Store user-provided API key safely in private local storage.
  - **Complete Backup & Reset**: Export profile, notes, and study logs as structured JSON, or reset all data cleanly.

---

## 5. Native Android Kotlin Engine & Hardware Bridges

To ensure zero third-party plugin crashes on modern Android (API 34, 35, and Android 16), all OS-level capabilities were engineered directly in native Kotlin:

### MethodChannel Specification: `com.focuspath.app/native`

| Method Name | Input Parameters | Return Type | Native Kotlin Implementation Details |
|---|---|---|---|
| `showNotification` | `id: Int`, `title: String`, `body: String`, `channelId: String` | `Boolean` | Uses `NotificationCompat.Builder` with `PRIORITY_HIGH`, heads-up display, default ringtone, and vibration pattern `[0, 300, 200, 300]`. |
| `scheduleAlarm` | `id: Int`, `title: String`, `body: String`, `triggerAtMillis: Long` | `Boolean` | Wraps an Intent to `AlarmReceiver::class.java` in an immutable `PendingIntent`, calling `AlarmManager.setExactAndAllowWhileIdle(RTC_WAKEUP, triggerAtMillis, pendingIntent)`. |
| `cancelAlarm` | `id: Int` | `Boolean` | Cancels the registered `PendingIntent` from `AlarmManager`. |
| `checkUsageStatsPermission` | None | `Boolean` | Queries `AppOpsManager.checkOpNoThrow(OPSTR_GET_USAGE_STATS, Process.myUid(), packageName) == MODE_ALLOWED`. |
| `openUsageAccessSettings` | None | `Void` | Dispatches `Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)` with `FLAG_ACTIVITY_NEW_TASK`. |
| `checkDistractionUsage` | `appNames: List<String>`, `thresholdMinutes: Int` | `Map<String, Any>` | Queries `UsageStatsManager.queryUsageStats()` for the past 3 hours, matches package names, sums foreground minutes, identifies the most-used application, and fires a notification if the threshold is breached. |
| `getInstalledApps` | None | `List<Map<String, String>>` | Queries `packageManager.queryIntentActivities(Intent.ACTION_MAIN.addCategory(CATEGORY_LAUNCHER))` filtering out system daemons to return all launchable user packages with app name and package ID. |
| `checkOverlayPermission` | None | `Boolean` | Checks `Settings.canDrawOverlays(context)` to verify if the app can display system-level focus lock overlays. |
| `openOverlaySettings` | None | `Void` | Dispatches `Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION)` taking the user directly to the app's overlay permission screen. |
| `addCalendarEvent` | `title: String`, `description: String`, `location: String`, `startTimeMillis: Long`, `endTimeMillis: Long` | `Boolean` | Dispatches native `Intent(Intent.ACTION_INSERT, CalendarContract.Events.CONTENT_URI)` allowing zero-OAuth, instant export of SPPU timetable blocks into Google Calendar. |
| `updateWidget` | `streak: Int`, `focusMinutes: Int`, `nextSubject: String` | `Boolean` | Updates `FocusPathWidgetProvider` RemoteViews with current streak, today's focus minutes, and next SPPU block. |

### Home-Screen Streak Widget: `FocusPathWidgetProvider`
- **Class**: [`FocusPathWidgetProvider.kt`](file:///c:/projects/app/android/app/src/main/kotlin/com/focuspath/app/FocusPathWidgetProvider.kt)
- **Layout**: [`widget_focus_path.xml`](file:///c:/projects/app/android/app/src/main/res/layout/widget_focus_path.xml)
- **Design Philosophy**: Rosé Pine dark surface (`#191724`) with Pine emerald borders, Gold streak badge (`🔥 5 Days`), Foam focus time badge (`⏱️ 90m`), and direct tap-to-open `MainActivity` action.
- **Auto-Sync**: Automatically updated whenever the student finishes a Pomodoro, opens the app, or logs study time.

### Notification Channels Registered in `MainActivity.kt`:
1. `focuspath_study_reminders`: High-importance channel for scheduled timetable alarms.
2. `focuspath_timer`: Ongoing/alert channel for Pomodoro session start and completion.
3. `focuspath_distraction_alerts`: High-priority heads-up warning channel for app-blocking nudges.

---

## 6. State Management & Data Persistence Architecture

FocusPath uses **Flutter Riverpod (2.6.1)** combined with a centralized **`LocalStore`**:

```
[UI Layer (ConsumerStatefulWidget)]
        │
        ▼
[Riverpod Providers (StateNotifierProvider)]
  ├── userProfileNotifierProvider
  ├── timetableNotifierProvider
  ├── notesNotifierProvider
  └── feedbackNotifierProvider
        │
        ▼
[LocalStore (Singleton Data Source)]
  ├── SharedPreferences (Key-value store)
  └── rootBundle (Asset JSONs: syllabus, questions, pyqs, quotes)
        │
        ▼
[NativeService (MethodChannel)]
  └── Kotlin MainActivity / AlarmReceiver
```

### Key Providers:
- `userProfileNotifierProvider`: Manages student name, semester, hard subjects, theme preferences, and distraction settings.
- `timetableNotifierProvider`: Manages weekly schedule slots. Calling `addSlot`, `updateSlot`, or `deleteSlot` automatically reschedules native Android alarms via `NativeService.scheduleAlarm`.
- `notesNotifierProvider`: Reactive list of user notes, handling additions from quizzes, PYQs, and AI tutor chats.

---

## 7. Evolution, Key Refactorings & UI Sanitization

### 1. Complete Elimination of Subject Codes
- **Problem**: Early versions displayed internal database identifiers and university codes (such as `BSC-101-BES`, `ESC-103-ENG`, `m1`, `bxe`, `fpl`). Students found this confusing and unnatural.
- **Solution**: Audited all screens using regex grep and replaced every instance with the full human-readable subject name (e.g., `Engineering Mathematics 1`, `Basic Electronics Engineering`).

### 2. Evolution to the "Structured" Vertical Timeline
- **Problem**: Initial timetable was a static list of cards with generic times, lacking day-to-day progression.
- **Solution**: Rebuilt `TimetableScreen` with a Mon–Sun interactive day strip, completion progress rings, hour markers on the vertical axis, a custom study block bottom sheet, and direct links to Pomodoro focus sessions.

### 3. Separation of Subject Datasets
- **Problem**: Earlier iterations placed all questions into a single monolithic JSON file, making it difficult to maintain, verify, or expand individual subject units.
- **Solution**: Created `assets/data/questions/` containing 10 distinct subject files (`m1.json`, `physics.json`, etc.) verified by automated unit tests.

### 4. Transition from Mock UI to Real Native Engine
- **Problem**: Tapping "Test Distraction Notification" or toggling app blocking previously showed only an in-app SnackBar.
- **Solution**: Built the native Kotlin MethodChannel bridge, enabling real OS-level permissions, real system notifications, and real usage statistics queries.

---

## 8. Bugs Encountered, Root Causes & Technical Fixes

| Bug # | Diagnostic / Symptom | Root Cause | Technical Resolution |
|---|---|---|---|
| **1** | `error - The named parameter 'initialSubjectId' isn't defined` in `timetable_screen.dart` | `FocusScreen` constructor did not declare `initialSubjectId`, but the timetable quick action sheet attempted to pass it. | Added `final String? initialSubjectId;` to `FocusScreen({super.key, this.initialSubjectId})` and initialized `_selectedSubjectId = widget.initialSubjectId;` in `initState()`. |
| **2** | `info - Don't use 'BuildContext's across async gaps` in `focus_screen.dart` and `quiz_screen.dart` | In `onPopInvokedWithResult`, the `showDialog` builder shadowed `context` (`builder: (context) => ...`), and `Navigator.pop(context)` was called after an `await` without capturing navigator reference. | Renamed dialog builder parameter to `builder: (dialogCtx) => ...`, captured `final navigator = Navigator.of(context);` before the async gap, and used `if (shouldPop == true && mounted) navigator.pop();`. |
| **3** | `warning - Unused import: local_store.dart` in `syllabus_screen.dart` | Redundant import left behind after moving syllabus queries to Riverpod providers. | Removed the unused import directive. |
| **4** | `warning - The value of the local variable 'isDark' isn't used` in `timetable_screen.dart` | Local variable `isDark` declared in `_showSlotOptions` was never referenced. | Removed the redundant local variable declaration. |
| **5** | `TimeoutException after 10 minutes` in `test/widget_test.dart` | Test attempted to pump the entire `FocusPathApp`, which initialized `AudioPlayer()` from `just_audio` and loaded `rootBundle` inside fakeAsync without mock bindings, causing the test isolate to hang. | Replaced the monolithic tree dump with focused, modular unit and widget tests for individual components (`FloatingBottomNav`, `ResponsiveContainer`, `AppTheme`, `OnboardingScreen`). |
| **6** | `Unhandled Exception: No ProviderScope found` in `widget_test.dart` | `OnboardingScreen` calls `ref.read(userProfileNotifierProvider)` in `initState()`. Pumping it inside a raw `MaterialApp` without `ProviderScope` crashed the test runner. | Wrapped the widget test in `ProviderScope(overrides: [localStoreProvider.overrideWithValue(store)])`. |
| **7** | `PYQ marks assertion failed: Expected in range 4..15, Actual: 2` in `dataset_and_scheduler_test.dart` | Test assumed all SPPU questions were worth 4 to 15 marks. Authentic SPPU papers include 2-mark short-definition questions. | Adjusted the test assertion to `inInclusiveRange(2, 15)`. |
| **8** | `generateWeeklyTimetable` returned empty list in test | `LocalStore` instance in test did not call `init()` and had an empty `_subjects` list. | Added an optional `customSubjects` parameter to `generateWeeklyTimetable({List<Subject>? customSubjects})` with an automatic fallback mechanism. |
| **9** | `FormatException: Unexpected character (at character 1)` when reading `assets/data/syllabus.json` | The JSON file contained a leading 3-byte UTF-8 Byte Order Mark (`0xEF, 0xBB, 0xBF`). Standard JSON parsers treat this as an invalid token. | Stripped the BOM sequence physically using PowerShell byte-offset truncation and added defensive `.replaceFirst('\uFEFF', '')` sanitization across all `rootBundle.loadString` calls in `LocalStore`. |
| **10** | Missing native calendar push & installed apps picker | Third-party dependencies had complex Google sign-in/OAuth setup that failed on sideloaded APKs, and app blocking only monitored a static hardcoded list. | Implemented zero-OAuth native Android `CalendarContract.Events.CONTENT_URI` insert intent and native `PackageManager.queryIntentActivities(CATEGORY_LAUNCHER)` bridge to pick any installed device app. |

---

## 9. Automated Testing & Release Verification

### 1. Static Analysis
Executed across the entire project:
```bash
flutter analyze
```
**Output**:
```
Analyzing app...
No issues found! (ran in 5.2s)
```
- **0 Errors**
- **0 Warnings**
- **0 Lints**

### 2. Automated Test Suites
Executed across all unit and widget tests:
```bash
flutter test
```
**Output**:
```
00:00 +0: Subject questions dataset for "m1" exists, is valid JSON and well-formed
00:00 +1: Subject questions dataset for "physics" exists, is valid JSON and well-formed
00:00 +2: Subject questions dataset for "bxe" exists, is valid JSON and well-formed
00:00 +3: Subject questions dataset for "eg" exists, is valid JSON and well-formed
00:00 +4: Subject questions dataset for "fpl" exists, is valid JSON and well-formed
00:00 +5: Subject questions dataset for "m2" exists, is valid JSON and well-formed
00:00 +6: Subject questions dataset for "chemistry" exists, is valid JSON and well-formed
00:00 +7: Subject questions dataset for "bee" exists, is valid JSON and well-formed
00:00 +8: Subject questions dataset for "mechanics" exists, is valid JSON and well-formed
00:00 +9: Subject questions dataset for "pps" exists, is valid JSON and well-formed
00:00 +10: Master aggregated questions.json is consistent with subject files
00:00 +11: PYQ Dataset in assets/data/pyqs.json is well-formed with model answers
00:00 +12: Structured Scheduler & Timetable Tests generateWeeklyTimetable produces a valid 7-day schedule
00:00 +13: Structured Scheduler & Timetable Tests TimetableSlot serialization and deserialization retains all fields
00:00 +14: FloatingBottomNav renders all 6 navigation tabs and fires callback
00:01 +15: FloatingBottomNav tab switches work smoothly
00:01 +16: ResponsiveContainer constrains width correctly on wide views
00:01 +17: Rose Pine Theme defines consistent light and dark palettes
00:01 +18: Personalization onboarding questionnaire displays on first launch
00:02 +19: Unit mastery calculations and weak unit detection operate correctly
00:02 +19: All tests passed!
```

### 3. Production Release APK Compilation
Executed with Android Gradle Plugin optimizations:
```bash
flutter build apk --release
```
**Output**:
```
Running Gradle task 'assembleRelease'...
Built build\app\outputs\flutter-apk\app-release.apk (61.8MB)
```
- **File Path**: `c:\projects\app\build\app\outputs\flutter-apk\app-release.apk`
- **Compatibility**: Android 8.0 (API 26) through Android 16 (API 36).
- **Target Device**: Realme P3 (tested architecture: `arm64-v8a`).
- **Compatibility**: Android 8.0 (API 26) through Android 16 (API 36).
- **Target Device**: Realme P3 (tested architecture: `arm64-v8a`).

---

## 10. Maintenance & Extension Guide

### Adding New Questions to a Subject
1. Open the specific subject file in `assets/data/questions/<subjectId>.json`.
2. Add a new JSON object adhering to the schema:
   ```json
   {
     "id": "m1_u3_q03",
     "subjectId": "m1",
     "unitNumber": 3,
     "topic": "Euler's Theorem on Homogeneous Functions",
     "questionText": "If u is a homogeneous function of degree n in x and y, then x*(du/dx) + y*(du/dy) equals:",
     "options": ["n * u", "(n - 1) * u", "n * (n - 1) * u", "u / n"],
     "correctOption": 0,
     "explanation": "By Euler's Theorem for a homogeneous function of degree n: x*(du/dx) + y*(du/dy) = n*u."
   }
   ```
3. Copy the object into the master `assets/data/questions.json`.
4. Run `flutter test test/dataset_and_scheduler_test.dart` to automatically validate syntax and integrity.

### Adding New PYQ Papers
1. Open `assets/data/pyqs.json`.
2. Append a new `PYQItem`:
   ```json
   {
     "id": "pyq_m1_dec2024_01",
     "subjectId": "m1",
     "unitNumber": 1,
     "topic": "Linear System Consistency",
     "exam": "SPPU In-Sem Examination",
     "year": 2024,
     "marks": 5,
     "difficulty": "Medium",
     "questionText": "Investigate for what values of lambda and mu the system of equations has: (i) No solution, (ii) A unique solution, (iii) An infinite number of solutions...",
     "modelAnswer": "Step 1: Write augmented matrix [A|B]...\nStep 2: Reduce to row echelon form...",
     "stepMarking": [
       {"step": "Augmented matrix formulation", "marks": 1},
       {"step": "Echelon reduction", "marks": 2},
       {"step": "Three cases analysis (lambda & mu)", "marks": 2}
     ]
   }
   ```
3. Run `flutter test` to verify.

---
*Document generated for FocusPath version 1.0.0+1 (September 2026).*
