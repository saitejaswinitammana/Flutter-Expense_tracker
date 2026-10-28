# 💰 Personal Expense Tracker — Flutter Mini-Project

A mobile application designed to manage structured financial data using a persistent SQLite database. The application provides an intuitive user interface built using Flutter's core widgets (`Form`, `TextFormField`, `DropdownButtonFormField`, `ListView`, `Dismissible`, etc.) and demonstrates full **CRUD (Create, Read, Update, Delete)** operations.

---

## 📱 Features

- **Structured Data Modeling**: Manage structured records with `id`, `title`, `amount`, `category`, `date`, and `note`.
- **Form Input & Validation**:
  - `Form` with `GlobalKey<FormState>` to orchestrate input checks.
  - `TextFormField` with custom validators for required text and numeric positive numbers.
  - `DropdownButtonFormField` for category selection (Food, Travel, Shopping, Bills, Health, Other).
  - Date picker dialog integration for selecting transaction dates.
- **Data Presentation**:
  - Dynamic `ListView.builder` displaying structured expense cards with category icons, color tags, formatted currency, and dates.
  - Category filter pills horizontally scrollable with `ListView.separated`.
  - Gradient header card showing dynamic total expenditure and transaction count.
  - Clean empty state illustration when no entries match.
- **Database Operations (SQLite via `sqflite` & `sqflite_common_ffi`)**:
  - **Create**: Insert new transactions into the local SQLite database.
  - **Read**: Fetch all expenses, support category filtering, and compute real-time sum totals.
  - **Update**: Tap any item to open the pre-populated edit form and save modifications.
  - **Delete**: Swipe-to-delete with `Dismissible` and explicit trash icon button with confirmation `AlertDialog`.
- **Cross-Platform Compatibility**:
  - Mobile (Android & iOS) via native `sqflite`.
  - Desktop (Windows & Linux) via `sqflite_common_ffi`.
  - Web fallback with an in-memory repository for browser testing.

---

## 📂 Project Structure

```
expense_tracker/
├── lib/
│   ├── database/
│   │   └── db_helper.dart            # SQLite database singleton helper (CRUD operations)
│   ├── models/
│   │   └── expense.dart              # Structured data model with toMap() / fromMap()
│   ├── screens/
│   │   ├── home_screen.dart          # Dashboard with ListView, summary card & filters
│   │   └── expense_form_screen.dart  # Form, TextFormField, DropdownButton for Add/Edit
│   └── main.dart                     # App entry point, FFI initialization, Material 3 theme
├── test/
│   ├── expense_test.dart             # Model serialization & Database CRUD tests
│   └── widget_test.dart              # UI smoke test
└── pubspec.yaml                      # Dependencies (sqflite, sqflite_common_ffi, intl, path)
```

---

## 🛠️ Flutter Core Widgets Demonstrated

| Widget | Purpose | File Location |
| :--- | :--- | :--- |
| `Form` | Container for grouping and validating input fields | [`expense_form_screen.dart`](file:///lib/screens/expense_form_screen.dart) |
| `TextFormField` | User text & numeric input with live validation | [`expense_form_screen.dart`](file:///lib/screens/expense_form_screen.dart) |
| `DropdownButtonFormField` | Category selection with dropdown list | [`expense_form_screen.dart`](file:///lib/screens/expense_form_screen.dart) |
| `ListView.builder` | Efficient scrolling list of expense cards | [`home_screen.dart`](file:///lib/screens/home_screen.dart) |
| `ListView.separated` | Horizontal category filter selection bar | [`home_screen.dart`](file:///lib/screens/home_screen.dart) |
| `Dismissible` | Swipe-to-delete gesture with background indicators | [`home_screen.dart`](file:///lib/screens/home_screen.dart) |
| `AlertDialog` | Deletion confirmation modal | [`home_screen.dart`](file:///lib/screens/home_screen.dart) |
| `FloatingActionButton` | Quick navigation to add a new record | [`home_screen.dart`](file:///lib/screens/home_screen.dart) |
| `Card` & `ListTile` | Clean structured layout for each database row | [`home_screen.dart`](file:///lib/screens/home_screen.dart) |

---

## 💾 Database Operations Summary

```dart
// CREATE: Insert structured record
await DatabaseHelper.instance.insert(expense);

// READ: Fetch all or filtered records
List<Expense> items = await DatabaseHelper.instance.getAll(category: 'Food');
double total = await DatabaseHelper.instance.getTotalSpent();

// UPDATE: Update existing record by ID
await DatabaseHelper.instance.update(modifiedExpense);

// DELETE: Remove record by ID
await DatabaseHelper.instance.delete(expenseId);
```

---

## 🚀 How to Run the Application

### 1. Set Workspace
Open this folder in VS Code or Android Studio:
```
C:\Users\tejas\.gemini\antigravity\scratch\expense_tracker
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Run the App
- **Windows Desktop**:
  ```bash
  flutter run -d windows
  ```
- **Android Emulator / Device**:
  ```bash
  flutter run -d <device-id>
  ```
- **Chrome (Web preview)**:
  ```bash
  flutter run -d chrome
  ```

### 4. Run Tests
```bash
flutter test
```
All unit tests for models, database CRUD operations, and widget rendering will execute.
