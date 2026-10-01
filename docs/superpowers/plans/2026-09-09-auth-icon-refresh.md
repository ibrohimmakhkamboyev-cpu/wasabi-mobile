# Auth Icon Refresh Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace dated bare authentication icons with a consistent premium Wasabi Sushi icon-tile system.

**Architecture:** Add one private `_AuthFieldIcon` widget in `auth_screen.dart` and use it wherever the registration and login form currently use a bare leading or calendar icon. The widget owns colors, size, and rounded geometry so the form continues using its current behavior and only its visual hierarchy changes.

**Tech Stack:** Flutter, Material 3, flutter_test.

---

### Task 1: Add a focused visual regression widget test

**Files:**
- Modify: `test/widget_test.dart`
- Test: `test/widget_test.dart`

- [ ] **Step 1: Write the failing test**

Add this test near the existing authentication tests:

```dart
testWidgets('registration form uses branded field icons', (tester) async {
  await tester.pumpWidget(
    AppScope(
      state: AppState(),
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const AuthScreen(),
      ),
    ),
  );

  await tester.tap(find.text("Ro'yxatdan o'tish"));
  await tester.pumpAndSettle();

  expect(find.byKey(const Key('auth-field-icon')), findsNWidgets(4));
});
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/widget_test.dart --plain-name "registration form uses branded field icons"`

Expected: FAIL because the branded icon key does not exist.

- [ ] **Step 3: Implement the minimal icon component**

In `lib/ui/screens/auth_screen.dart`, add a private stateless `_AuthFieldIcon` with an `IconData`, semantic label, and primary/neutral color variant. Give its outer container `const Key('auth-field-icon')`; render it as a 36px rounded container with a 20px rounded Material icon and a subtle pale Wasabi background.

- [ ] **Step 4: Replace bare form icons**

Use `_AuthFieldIcon` for the name, phone, birthday, and calendar controls in the auth form. Use the matching rounded SMS icon for the login and registration actions. Do not change controllers, callbacks, labels, input formatters, or validation.

- [ ] **Step 5: Run the focused test to verify it passes**

Run: `flutter test test/widget_test.dart --plain-name "registration form uses branded field icons"`

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/ui/screens/auth_screen.dart test/widget_test.dart
git commit -m "feat: refresh authentication form icons"
```

### Task 2: Verify the complete auth flow

**Files:**
- Modify: none
- Test: `test/widget_test.dart`, `test/auth_input_formatting_test.dart`

- [ ] **Step 1: Run the auth tests**

Run: `flutter test test/widget_test.dart test/auth_input_formatting_test.dart`

Expected: PASS with no render overflows or exceptions.

- [ ] **Step 2: Run the full suite**

Run: `flutter test`

Expected: PASS.

- [ ] **Step 3: Commit verification-only changes if any test fixture requires an intentional update**

```bash
git add test/widget_test.dart
git commit -m "test: cover authentication icon styling"
```
