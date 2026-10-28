import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:expense_tracker/database/db_helper.dart';
import 'package:expense_tracker/models/expense.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Expense Model Tests', () {
    test('toMap and fromMap work correctly', () {
      final now = DateTime.now();
      final expense = Expense(
        id: 1,
        title: 'Books',
        amount: 25.50,
        category: 'Education',
        date: now,
        note: 'Study material',
      );

      final map = expense.toMap();
      expect(map['id'], 1);
      expect(map['title'], 'Books');
      expect(map['amount'], 25.50);
      expect(map['category'], 'Education');
      expect(map['note'], 'Study material');

      final reconstructed = Expense.fromMap(map);
      expect(reconstructed.id, expense.id);
      expect(reconstructed.title, expense.title);
      expect(reconstructed.amount, expense.amount);
      expect(reconstructed.category, expense.category);
      expect(reconstructed.note, expense.note);
    });

    test('copyWith updates fields as expected', () {
      final expense = Expense(
        id: 1,
        title: 'Lunch',
        amount: 12.0,
        category: 'Food',
        date: DateTime(2026, 1, 1),
      );

      final updated = expense.copyWith(
        amount: 15.0,
        title: 'Dinner',
      );

      expect(updated.id, 1);
      expect(updated.title, 'Dinner');
      expect(updated.amount, 15.0);
      expect(updated.category, 'Food');
    });
  });

  group('DatabaseHelper CRUD Tests', () {
    final dbHelper = DatabaseHelper.instance;

    test('Insert, read, update, and delete expense', () async {
      // 1. Insert
      final newExpense = Expense(
        title: 'Coffee',
        amount: 4.50,
        category: 'Food',
        date: DateTime.now(),
        note: 'Morning espresso',
      );

      final insertedId = await dbHelper.insert(newExpense);
      expect(insertedId, isPositive);

      // 2. Read
      final items = await dbHelper.getAll();
      final item = items.firstWhere((e) => e.id == insertedId);
      expect(item.title, 'Coffee');
      expect(item.amount, 4.50);

      // 3. Update
      final modifiedItem = item.copyWith(
        title: 'Iced Latte',
        amount: 5.75,
      );
      final rowsUpdated = await dbHelper.update(modifiedItem);
      expect(rowsUpdated, 1);

      final updatedItems = await dbHelper.getAll();
      final verifiedItem = updatedItems.firstWhere((e) => e.id == insertedId);
      expect(verifiedItem.title, 'Iced Latte');
      expect(verifiedItem.amount, 5.75);

      // 4. Delete
      final rowsDeleted = await dbHelper.delete(insertedId);
      expect(rowsDeleted, 1);

      final remainingItems = await dbHelper.getAll();
      expect(remainingItems.any((e) => e.id == insertedId), isFalse);
    });
  });
}
