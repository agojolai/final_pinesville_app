#  Automated Testing Guide

## Overview
This project uses Flutter's testing framework with automated test execution through VS Code tasks and GitHub Actions CI/CD.

## Test Structure

```
test/
 unit/                          # Unit tests (fast, no UI)
    late_fee_test.dart        # Late fee calculation tests
    bill_model_test.dart      # Bill model tests
    billing_repository_test.dart (todo)
 widget/                        # Widget tests (UI components)
    (todo)
 old tests/                     # Legacy tests
     onboarding_repository_test.dart
     user_profile_test.dart

integration_test/                  # Integration tests (full workflows)
 (todo)
```

---

##  Running Tests

### Method 1: VS Code Tasks (Recommended)
Press Ctrl+Shift+P  Type "Run Task"  Select:

- **Run All Tests** - Execute all tests
- **Run Tests with Coverage** - Generate coverage report
- **Run Unit Tests Only** - Only unit tests
- **Run Widget Tests Only** - Only widget tests
- **Test Late Fee Calculation** - Specific test file
- **Test Billing Repository** - Specific test file

### Method 2: Terminal Commands

```powershell
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/unit/late_fee_test.dart

# Run only unit tests
flutter test test/unit/

# Run only widget tests
flutter test test/widget/

# Watch mode (re-run on file save) - requires package
flutter test --watch
```

### Method 3: Automated (GitHub Actions)
Tests run automatically on:
-  Push to main or playground branch
-  Pull requests to main or playground
-  See results in GitHub Actions tab

---

##  Test Coverage

### View Coverage Locally

```powershell
# Generate coverage
flutter test --coverage

# View coverage report (requires lcov/genhtml)
# Windows: Install lcov via Chocolatey
choco install lcov

# Generate HTML report
perl C:\ProgramData\chocolatey\lib\lcov\tools\bin\genhtml coverage/lcov.info -o coverage/html

# Open in browser
start coverage/html/index.html
```

### View Coverage on GitHub
- Coverage reports are generated automatically by GitHub Actions
- Download artifacts from Actions tab
- View coverage-report artifact

---

##  Test Types

### 1. Unit Tests (test/unit/)
**Purpose:** Test individual functions, methods, classes in isolation

**Example:** late_fee_test.dart
```dart
test('should calculate 150 peso late fee after 1 week past grace period', () {
  final now = DateTime.now();
  final dueDate = now.subtract(const Duration(days: 14));
  
  final lateFee = LateFeeDetails.calculate(
    isPaid: false,
    dueDate: dueDate,
    gracePeriodDays: 7,
    lateFeePerWeek: 150.0,
  );
  
  expect(lateFee.lateFeeAmount, 150.0);
  expect(lateFee.weeksOverdue, 1);
});
```

**Characteristics:**
-  Very fast (milliseconds)
-  No Firebase, no UI
-  Test business logic only

### 2. Widget Tests (test/widget/)
**Purpose:** Test UI components and user interactions

**Example:** (todo)
```dart
testWidgets('Create Bill button appears for units without bills', (tester) async {
  await tester.pumpWidget(MyApp());
  
  expect(find.text('Create Bill'), findsOneWidget);
  
  await tester.tap(find.text('Create Bill'));
  await tester.pumpAndSettle();
  
  expect(find.byType(AdminCreateBillScreen), findsOneWidget);
});
```

**Characteristics:**
-  Fast (seconds)
-  Tests widgets, not full app
-  Can simulate taps, scrolls, etc.

### 3. Integration Tests (integration_test/)
**Purpose:** Test complete workflows end-to-end

**Example:** (todo)
```dart
testWidgets('Admin can create bill and tenant can view it', (tester) async {
  // Login as admin
  // Navigate to billing management
  // Create bill for Unit 301
  // Verify bill appears in Firestore
  // Logout and login as tenant
  // Verify tenant sees the bill
});
```

**Characteristics:**
-  Slow (minutes)
-  Uses real Firebase (or emulator)
-  Tests entire user flows

---

##  Current Test Coverage

### Unit Tests
-  **Late Fee Calculation** (7 tests)
  - Zero fee when not overdue
  - Zero fee during grace period
  - 150 after 1 week
  - 300 after 2 weeks
  - 900 after 6 weeks (eviction threshold)
  - Zero fee if paid
  - Partial week handling

-  **Bill Model** (4 tests)
  - Total calculation
  - Paid bill identification
  - Partially paid bill identification
  - Overdue bill identification

-  **Billing Period** (3 tests)
  - Creation
  - JSON serialization
  - JSON deserialization

-  **Utility Charge** (2 tests)
  - Charge calculation
  - Zero consumption handling

**Total: 16 unit tests **

### Widget Tests
-  Not yet implemented

### Integration Tests
-  Not yet implemented

---

##  Writing New Tests

### Unit Test Template

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:application_pinesville/path/to/your/file.dart';

void main() {
  group('YourClass Tests', () {
    test('should do something correctly', () {
      // Arrange
      final input = 'test';
      
      // Act
      final result = yourFunction(input);
      
      // Assert
      expect(result, 'expected value');
    });
  });
}
```

### Widget Test Template

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:application_pinesville/path/to/screen.dart';

void main() {
  testWidgets('should display correct text', (tester) async {
    // Build widget
    await tester.pumpWidget(
      MaterialApp(home: YourScreen()),
    );
    
    // Verify
    expect(find.text('Expected Text'), findsOneWidget);
  });
}
```

---

##  Testing Best Practices

### 1. Test Naming
 **Good:** should calculate late fee correctly when 1 week overdue
 **Bad:** 	est1

### 2. Test Organization
```dart
group('FeatureName', () {
  group('SubFeature', () {
    test('specific behavior', () {});
  });
});
```

### 3. Arrange-Act-Assert Pattern
```dart
test('description', () {
  // Arrange - Set up test data
  final input = 'test';
  
  // Act - Execute the code
  final result = function(input);
  
  // Assert - Verify results
  expect(result, 'expected');
});
```

### 4. Test Independence
- Each test should be independent
- Don't rely on test execution order
- Clean up after tests

### 5. Mock External Dependencies
```dart
// Mock Firestore
final mockFirestore = MockFirebaseFirestore();
when(mockFirestore.collection('Bills')).thenReturn(...);
```

---

##  Debugging Tests

### Run Single Test
```dart
test('specific test', () {
  print('Debug info: ');
  expect(variable, expected);
});
```

### Run Test File
```powershell
flutter test test/unit/late_fee_test.dart --plain-name="should calculate"
```

### VS Code Debugging
1. Set breakpoints in test file
2. Click "Debug" above test
3. Step through execution

---

##  Next Steps

### High Priority
1.  Create billing_repository_test.dart
2.  Create payment_model_test.dart
3.  Create widget tests for billing screens

### Medium Priority
4.  Add integration tests for bill creation workflow
5.  Add integration tests for payment workflow
6.  Set up Firebase emulator for testing

### Low Priority
7.  Increase coverage to 80%+
8.  Add performance tests
9.  Add accessibility tests

---

##  Troubleshooting

### Tests Failing After Package Update
```powershell
flutter clean
flutter pub get
flutter test
```

### Coverage Not Generated
```powershell
# Make sure lcov is installed
flutter test --coverage
```

### Firebase Tests Failing
- Use Firebase emulator
- Mock Firebase services
- Check authentication state

---

##  Resources

- [Flutter Testing Documentation](https://docs.flutter.dev/testing)
- [Effective Dart: Testing](https://dart.dev/guides/language/effective-dart/usage#testing)
- [Mockito Package](https://pub.dev/packages/mockito)
- [Integration Testing](https://docs.flutter.dev/testing/integration-tests)

---

**Last Updated:** October 3, 2025
**Test Count:** 16 unit tests 
**Coverage:** ~30% (unit tests only)
**Target Coverage:** 80%+
