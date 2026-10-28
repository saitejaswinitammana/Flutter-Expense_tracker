import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../models/expense.dart';
import 'expense_form_screen.dart';

/// The main dashboard screen showing expense summaries, category filters,
/// and the list of recorded expenses with CRUD actions.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  List<Expense> _expenses = [];
  double _totalSpent = 0.0;
  bool _isLoading = true;
  String _selectedCategory = 'All';

  final List<String> _filterCategories = [
    'All',
    'Food',
    'Travel',
    'Shopping',
    'Bills',
    'Health',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  /// [READ]: Fetch expenses and recalculate total spent from SQLite.
  Future<void> _loadExpenses() async {
    setState(() => _isLoading = true);

    final expenses = await _dbHelper.getAll(
      category: _selectedCategory == 'All' ? null : _selectedCategory,
    );
    final total = await _dbHelper.getTotalSpent(
      category: _selectedCategory == 'All' ? null : _selectedCategory,
    );

    setState(() {
      _expenses = expenses;
      _totalSpent = total;
      _isLoading = false;
    });
  }

  /// Navigate to Add Expense screen and show SnackBar upon successful insert.
  Future<void> _navigateToAddExpense() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const ExpenseFormScreen(),
      ),
    );

    if (result == true) {
      await _loadExpenses();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expense added successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Navigate to Edit Expense screen with selected item and show SnackBar upon update.
  Future<void> _navigateToEditExpense(Expense expense) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ExpenseFormScreen(expense: expense),
      ),
    );

    if (result == true) {
      await _loadExpenses();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expense updated successfully!'),
          backgroundColor: Colors.teal,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// [DELETE]: Confirm and delete expense by ID from SQLite.
  Future<void> _deleteExpense(Expense expense) async {
    if (expense.id == null) return;

    await _dbHelper.delete(expense.id!);
    await _loadExpenses();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deleted "${expense.title}"'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Dialog to confirm expense deletion before executing.
  Future<bool> _showDeleteConfirmation(Expense expense) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Expense?'),
        content: Text(
          'Are you sure you want to delete "${expense.title}" for \$${expense.amount.toStringAsFixed(2)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    return shouldDelete ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadExpenses,
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Top Summary Card
          _buildSummaryCard(theme),

          // 2. Category Filter Chips
          _buildCategoryFilters(theme),

          const Divider(height: 1),

          // 3. Main Expenses List or Empty State
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _expenses.isEmpty
                    ? _buildEmptyState()
                    : _buildExpenseList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddExpense,
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
    );
  }

  /// Renders top summary card displaying total spent.
  Widget _buildSummaryCard(ThemeData theme) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.secondaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _selectedCategory == 'All'
                ? 'Total Expenditure'
                : '$_selectedCategory Spending',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${_totalSpent.toStringAsFixed(2)}',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_expenses.length} transaction${_expenses.length == 1 ? '' : 's'} recorded',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  /// Horizontal scrolling category filter chips.
  Widget _buildCategoryFilters(ThemeData theme) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _filterCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = _filterCategories[index];
          final isSelected = _selectedCategory == category;

          return FilterChip(
            selected: isSelected,
            label: Text(category),
            avatar: category != 'All'
                ? Icon(
                    _getCategoryIcon(category),
                    size: 16,
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.primary,
                  )
                : null,
            onSelected: (selected) {
              setState(() {
                _selectedCategory = category;
              });
              _loadExpenses();
            },
          );
        },
      ),
    );
  }

  /// Empty state UI when no expenses are recorded.
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              _selectedCategory == 'All'
                  ? 'No expenses recorded yet'
                  : 'No expenses for "$_selectedCategory"',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the "+ Add Expense" button to add your first transaction.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// ListView with Dismissible swipe-to-delete and tap-to-edit cards.
  Widget _buildExpenseList() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: _expenses.length,
      itemBuilder: (context, index) {
        final expense = _expenses[index];

        return Dismissible(
          key: ValueKey(expense.id ?? index),
          direction: DismissDirection.endToStart,
          // Confirmation dialog before deletion occurs
          confirmDismiss: (direction) async {
            return await _showDeleteConfirmation(expense);
          },
          onDismissed: (direction) {
            _deleteExpense(expense);
          },
          // Red swipe background indicating delete action
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.shade600,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.delete, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Delete',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              onTap: () => _navigateToEditExpense(expense),
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: _getCategoryColor(expense.category).withValues(alpha: 0.15),
                child: Icon(
                  _getCategoryIcon(expense.category),
                  color: _getCategoryColor(expense.category),
                ),
              ),
              title: Text(
                expense.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        expense.category,
                        style: TextStyle(
                          fontSize: 12,
                          color: _getCategoryColor(expense.category),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '• ${DateFormat('dd MMM yyyy').format(expense.date)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  if (expense.note != null && expense.note!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      expense.note!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '\$${expense.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.redAccent,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.grey),
                    tooltip: 'Delete',
                    onPressed: () async {
                      final confirmed = await _showDeleteConfirmation(expense);
                      if (confirmed) {
                        _deleteExpense(expense);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Maps category string to an appropriate Material icon.
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food':
        return Icons.restaurant;
      case 'Travel':
        return Icons.directions_car;
      case 'Shopping':
        return Icons.shopping_bag;
      case 'Bills':
        return Icons.receipt_long;
      case 'Health':
        return Icons.medical_services;
      case 'Other':
      default:
        return Icons.more_horiz;
    }
  }

  /// Maps category string to an accent color.
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Food':
        return Colors.orange.shade700;
      case 'Travel':
        return Colors.blue.shade700;
      case 'Shopping':
        return Colors.purple.shade700;
      case 'Bills':
        return Colors.red.shade700;
      case 'Health':
        return Colors.green.shade700;
      case 'Other':
      default:
        return Colors.blueGrey;
    }
  }
}
