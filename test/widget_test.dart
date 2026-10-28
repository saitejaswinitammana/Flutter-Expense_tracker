import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:expense_tracker/main.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('Expense tracker app loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ExpenseTrackerApp());
    // Pump frames to let async initState and db operations complete
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    // Verify that the title is present
    expect(find.text('Expense Tracker'), findsOneWidget);
  });
}
