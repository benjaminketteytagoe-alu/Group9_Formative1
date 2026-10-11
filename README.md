# SLA Task Tracker

**Group 9 · Flutter Mobile Development · Formative 1**

A Flutter mobile app that helps small teams manage project tasks with built-in **Service Level Agreement (SLA) awareness**. Every task is automatically classified as **On Track**, **At Risk**, **Overdue** or **Completed** from its deadline, priority and status, so a team can see project health at a glance. There is no backend: all data is stored on the device.

> **Repository:** https://github.com/benjaminketteytagoe-alu/Group9_Formative1  
> The Flutter project lives in the [`sla_task_tracker/`](sla_task_tracker) folder.

---

## Table of contents

1. [Features](#features)
2. [Screens](#screens)
3. [How SLA classification works](#how-sla-classification-works)
4. [Quick start](#quick-start)
5. [Demo credentials and seed data](#demo-credentials-and-seed-data)
6. [Project structure](#project-structure)
7. [Architecture](#architecture)
8. [Data persistence](#data-persistence)
9. [Form validation](#form-validation)
10. [Testing](#testing)
11. [Dependencies](#dependencies)
12. [Team and contributions](#team-and-contributions)
13. [Git workflow](#git-workflow)
14. [Known limitations](#known-limitations)
15. [Submission documents](#submission-documents)

---

## Features

- **Seven screens** (plus a home shell with bottom navigation): Sign In, Dashboard, Task List, Task Details, Create/Edit Task, Team Members, Member Profile.
- **SLA engine** that classifies each task and explains it with a status chip and a plain-language message.
- **Priority-based risk windows**: high-priority tasks become *At Risk* 72 hours before the deadline, all others 48 hours before.
- **Full task lifecycle**: create, edit, delete (with confirmation), assign to a team member, set priority, status and due date.
- **Task List tools**: free-text search, filters by SLA status, priority and assignee, and sort by soonest or latest deadline.
- **Workload tracking**: each team member is classified as Light (0–2 open tasks), Moderate (3–4) or Heavy (5+) with a colour-coded indicator on the Team and Member Profile screens.
- **Dashboard**: overall progress bar, four colour-coded SLA summary tiles, and a "Needs attention" list of overdue and at-risk tasks.
- **Username/password sign-in** with validation, show/hide password toggle and a collapsible *demo credentials* panel.
- **Team management**: add, edit and delete members with a colour picker; the signed-in user cannot be deleted.
- **Activity log** recording task operations with timestamps and the acting user.
- **Light, dark and system themes**, with the choice persisted across restarts.
- **Local persistence** with SharedPreferences, including automatic first-launch seeding and migration of older stored members that lack credentials.
- **Sign-out** from the main screens with a confirmation dialog.

## Screens

The application has **seven screens** (exceeding the six-screen requirement):

| # | Screen | Purpose | Highlights |
|---|---|---|---|
| 1 | **Sign In** | Authenticate a team member | Username/password form, regex password validation, show/hide toggle, error messages, collapsible demo credentials panel, theme toggle |
| 2 | **Dashboard** | Project health overview | Personalized greeting, progress bar, four colour-coded SLA summary tiles, "Needs attention" list sorted by urgency (overdue first), theme toggle, sign-out |
| 3 | **Task List** | Browse and find tasks | Free-text search, filters by SLA status/priority/assignee, sort by soonest/latest deadline, empty state with action button, FAB to create a task, sign-out |
| 4 | **Task Details** | Inspect and act on one task | All fields displayed in sections, SLA chip with plain-language message, status dropdown for quick updates, edit button, delete with confirmation dialog, sign-out |
| 5 | **Create / Edit Task** | Capture or update a task | Required title, description and category with validation; assignee picker dialog; priority and status dropdowns; date picker (end-of-day deadline); optional notes; pre-filled in edit mode |
| 6 | **Team Members** | Manage the roster | Signed-in user profile card at top, team member list with `MemberAvatar` (coloured initials), role, email, open-task count, workload indicator (Light/Moderate/Heavy), tap to view member profile, FAB to add a member, edit/delete with confirmation, sign-out |
| 7 | **Member Profile** | Individual member's tasks and SLA | Member avatar, name, role, email, workload chip, SLA breakdown grid (On Track/At Risk/Overdue/Completed), assigned tasks list sorted by due date with done tasks last |

**Navigation flow:** *Sign In → Home shell (Dashboard · Tasks · Team via bottom navigation) → Task Details / Create-Edit Task / Member Profile via push navigation.* Named routes are defined in `lib/utils/app_routes.dart`.

## How SLA classification works

Logic lives in `lib/services/sla_service.dart` and is a pure function of the task and the current time (`now` can be injected for tests and live demos).

| Status | Rule | Colour |
|---|---|---|
| **Completed** | Task status is *Done* | Green |
| **Overdue** | Current time is after the deadline and the task is not done | Red |
| **At Risk** | Time left until the deadline is ≤ 48 h (≤ 72 h for **high** priority) | Orange |
| **On Track** | Anything else | Blue |

Rules are evaluated top to bottom. Two details worth knowing:

- **End-of-day deadlines.** A date picker returns midnight, which would mark a task overdue on its due date. `SlaService.deadlineOf()` therefore treats the deadline as **23:59:59** on the due date.
- **Earlier warning for critical work.** The window is `72` for `TaskPriority.high` and `48` otherwise (`at_risk_hours_high_priority`, `at_risk_hours`).

## Quick start

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) compatible with the project's `sdk: ^3.13.4` constraint in `pubspec.yaml`
- An Android emulator, iOS simulator or a physical device (desktop and web targets are also scaffolded)

### Run

```bash
git clone https://github.com/benjaminketteytagoe-alu/Group9_Formative1.git
cd Group9_Formative1/sla_task_tracker

flutter pub get
flutter run
```

### Check quality

```bash
flutter analyze   # static analysis (flutter_lints)
flutter test      # runs the full test suite
```

## Demo credentials and seed data

On first launch the app seeds four team members and 22 sample tasks. Task dates are generated **relative to today**, so every SLA status is always represented: 6 Completed, 4 Overdue, 5 At Risk, 7 On Track.

| Username | Password | Name |
|---|---|---|
| `benjamin` | `ben1234` | Benjamin |
| `michael` | `mike1234` | Michael |
| `kellen` | `kel1234` | Kellen |
| `boaz` | `boaz1234` | Boaz |

These are throw-away demo accounts. You can also tap **Show demo credentials** on the sign-in screen. Usernames are matched case-insensitively.

## Project structure

```
Group9_Formative1/
├── README.md                      
├── .gitignore
└── sla_task_tracker/              
    ├── pubspec.yaml
    ├── analysis_options.yaml
    ├── lib/
    │   ├── main.dart              # startup: storage, seeding, provider wiring
    │   ├── app.dart               # MaterialApp, themes, routes
    │   ├── models/                # Task, TeamMember, ActivityLog, enums
    │   │   ├── enums.dart         # TaskStatus, TaskPriority, SlaStatus
    │   │   ├── task.dart          # Task model with JSON serialization
    │   │   ├── team_member.dart   # TeamMember model with username/password
    │   │   └── activity_log.dart  # ActivityLog model for audit trail
    │   ├── providers/             # ChangeNotifier state management
    │   │   ├── task_provider.dart       # Task CRUD, SLA counts, progress
    │   │   ├── member_provider.dart     # Member CRUD, sign-in/sign-out
    │   │   ├── activity_provider.dart   # Activity log management
    │   │   └── theme_mode_provider.dart # Light/dark/system theme
    │   ├── services/              # Business logic and persistence
    │   │   ├── sla_service.dart   # SLA classification engine
    │   │   ├── storage_service.dart # SharedPreferences wrapper
    │   │   └── seed_data.dart     # First-launch seeding with migration
    │   ├── screens/               # UI screens
    │   │   ├── sign_in_screen.dart          # Username/password authentication
    │   │   ├── dashboard_screen.dart        # Project health overview
    │   │   ├── task_list_screen.dart        # Task list with search/filters
    │   │   ├── task_details_screen.dart     # Full task view and actions
    │   │   ├── task_form_screen.dart        # Create/edit task form
    │   │   ├── team_screen.dart             # Team roster with workload
    │   │   ├── member_profile_screen.dart   # Individual member profile
    │   │   └── home_shell.dart              # Bottom navigation shell
    │   ├── widgets/               # Reusable UI components
    │   │   ├── task_card.dart     # Task list item with SLA chip
    │   │   ├── status_chip.dart   # Colour-coded SLA status indicator
    │   │   ├── summary_tile.dart  # SLA count tile for dashboards
    │   │   ├── member_avatar.dart # Coloured circle with member initials
    │   │   ├── empty_state.dart   # Placeholder for empty lists
    │   │   └── loading_view.dart  # Loading spinner during data load
    │   └── utils/                 # Utilities and configuration
    │       ├── app_routes.dart    # Named route definitions
    │       ├── app_theme.dart     # Material 3 light and dark themes
    │       ├── sla_colors.dart    # SLA status colour mapping
    │       └── workload.dart      # MemberStats and Workload enum
    ├── test/                      # unit and widget tests (see Testing)
    └── android/ ios/ web/ linux/ macos/ windows/   # platform runners
```

## Architecture

The app is organised in four layers with one-way dependencies (screens → providers → services → models).

| Layer | Contents | Responsibility |
|---|---|---|
| **Presentation** | `screens/`, `widgets/`, `utils/` | Render UI, handle input, navigate; read state with `context.watch` and call provider methods |
| **State management** | `TaskProvider`, `MemberProvider`, `ActivityProvider`, `ThemeModeProvider` | `ChangeNotifier`s that own app state, notify listeners and persist changes |
| **Services** | `SlaService`, `StorageService`, `SeedData` | Business rules, persistence and first-launch data |
| **Data** | `Task`, `TeamMember`, `ActivityLog`, `TaskStatus`, `TaskPriority`, `SlaStatus`, `Workload` | Immutable models with JSON serialisation and `copyWith` |

**Why Provider?** It is a lightweight wrapper over Flutter's `InheritedWidget` and `ChangeNotifier`, has far less boilerplate than Bloc or Riverpod, and is enough for an app of this size.

| Provider | Responsibility |
|---|---|
| `TaskProvider` | Task CRUD, per-status SLA counts, completion progress, activity logging |
| `MemberProvider` | Member CRUD, credential-checked sign-in / sign-out |
| `ActivityProvider` | Recent activity log |
| `ThemeModeProvider` | Theme mode (system → dark → light cycle) persisted across launches |

### Workload system

The `MemberStats` class (`lib/utils/workload.dart`) computes per-member statistics from their assigned tasks: total tasks, open tasks, done tasks, and a breakdown by SLA status. It also derives a `Workload` level:

| Workload | Open tasks | Colour |
|---|---|---|
| **Light** | 0–2 | Green |
| **Moderate** | 3–4 | Orange |
| **Heavy** | 5+ | Red |

Workload is displayed on the Team Members screen and the Member Profile screen, giving teams a quick visual indicator of who may be overloaded.

## Data persistence

All data is serialized to JSON and stored with **SharedPreferences** through `StorageService`, which caches the preferences instance and uses generic list helpers for tasks, members and activity logs. It also stores the current user id, the theme mode and a "seeded" flag.

SharedPreferences was chosen over SQLite because the data set is small (tens of records), fully JSON-serializable, and needs no relational queries or schema migrations.

**Migration:** when `username` and `password` were added to `TeamMember`, members stored by earlier builds had empty credentials. `SeedData.seedIfFirstLaunch()` detects this and fills in defaults so those users can still sign in.

## Form validation

Every form uses `Form` + `TextFormField` validators with real-time feedback.

| Form | Rules |
|---|---|
| **Sign in** | Username and password required; password validated by regex (≥ 4 characters, at least one letter and one digit); clear error message on wrong credentials |
| **Create / Edit task** | Title, description and category required (non-empty); assignee selected from dialog picker; due date selected from date picker (set to end of day) |
| **Add / Edit member** | Name required; email optional but validated with regex; username required (≥ 3 characters); password validated by same regex as sign-in; colour selected from preset palette |

Password regex pattern: `^(?=.*[A-Za-z])(?=.*\d).{4,}$` — ensures at least one letter, one digit, and a minimum of 4 characters.

## Testing

**36 tests** across **7 files** (`flutter test`):

| File | Tests | Covers |
|---|---:|---|
| `sla_service_test.dart` | 8 | All four SLA statuses, priority-based risk windows, deadline edge cases |
| `providers_test.dart` | 9 | Task CRUD, SLA counts, progress calculation, member CRUD, sign-in/sign-out |
| `sign_in_screen_test.dart` | 6 | Valid login, wrong password, unknown user, demo credentials panel, field display |
| `seed_data_test.dart` | 4 | Every SLA status seeded, valid assignees, unique IDs, completion dates |
| `storage_service_test.dart` | 3 | Task and member persistence round-trips via SharedPreferences |
| `task_model_test.dart` | 1 | JSON serialisation/deserialisation and `copyWith` |
| `team_screen_test.dart` | 5 | Team screen rendering, member list, workload display, and sign-out |

Beyond automated tests, the team manually exercised each screen on an emulator, including wrong passwords, empty forms, deleting the signed-in user, theme toggling, and data persistence after restart.

## Dependencies

| Package | Version | Purpose |
|---|---|---|
| `provider` | ^6.1.2 | State management |
| `shared_preferences` | ^2.2.3 | Local persistence |
| `uuid` | ^4.4.0 | Unique ids |
| `intl` | ^0.19.0 | Date formatting |
| `cupertino_icons` | ^1.0.8 | iOS-style icons |
| `flutter_lints` (dev) | ^6.0.0 | Lint rules |

## Team and contributions

Every member has their own feature branches and commits in the history.

| Member | Main areas | Branches |
|---|---|---|
| **Benjamin** | Models, SLA engine, storage, seed data, providers, provider tests, integration of later screens | `benjamin/sla-engine`, `benjamin/providers` |
| **Michael** | Task form, task details, delete flow, form validation | `Michael/task-form`, `Michael/task-details`, `Michael/task-delete`, `Michael/task-validation`, `Michael_features` |
| **Kellen** | Shared widgets, SLA colours, task list, dashboard, search/filter/sort | `kellen/shared-widgets`, `kellen/task-list`, `kellen/dashboard-ui`, `kellen/filter-sort` |
| **Boaz** | Sign-in, navigation and theme, team profile and member form | `boaz/sign-in-screen`, `boaz/navigation-theme`, `boaz/team-profile`, `boaz/member-form`, `boaz/pdf-report` |

The detailed, per-session record (hours, commit/PR links, percentages) is in the group contribution tracker linked under [Submission documents](#submission-documents).

## Git workflow

- `main` is the integration branch; work happens on `<member>/<feature>` branches.
- Features are merged through pull requests.
- Commit messages follow a `feat:`, `fix:`, `test:`, `chore:` style, for example `feat: add SLA engine with unit tests`.
- Before opening a pull request: `flutter analyze` and `flutter test` should both pass.

## Known limitations

- **Demo-grade authentication.** Passwords are stored in plain text in SharedPreferences and there is no backend, as the assignment specifies. Do not reuse real passwords.
- **Single device.** Data is local; there is no sync between devices or users.
- **Scale.** SharedPreferences suits tens to low hundreds of records. A larger data set or relational queries would call for SQLite (e.g. `sqflite` or `drift`).
- **Notifications.** SLA status is computed when screens build; there are no push or local reminders yet.

## Submission documents

Place these in a `docs/` folder at the repository root and update the links if you use different names.

| Document | Link |
|---|--|
| Project and technical report (PDF) | `docs/Group9_SLA_Task_Tracker_Report.pdf` |
| Demo video (10–15 min) | `https://youtu.be/_XjDfxqnpmE` |
| Group contribution tracker | `https://docs.google.com/spreadsheets/d/1tQ6Uu2FO4umlHtulQd6mWa5kWDHd7Xzngq-mSRsshBg/edit?usp=sharing` |
| AI usage declaration | Included in the report (section 7) |

---

*Built with Flutter and Dart. Group 9, Formative 1.*
