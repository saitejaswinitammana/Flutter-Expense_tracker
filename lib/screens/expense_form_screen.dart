import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../models/expense.dart';

/// Screen for creating a new expense or editing an existing one.
/// If [expense] is passed, the form behaves in "Edit Mode"; otherwise, "Add Mode".
class ExpenseFormScreen extends StatefulWidget {
  final Expense? expense;

  const ExpenseFormScreen({super.key, this.expense});

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  // GlobalKey uniquely identifies the Form and allows validation
  final _formKey = GlobalKey<FormState>();

  // Text editing controllers to manage input values
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late final TextEditingController _dateController;

  // Selected values
  late String _selectedCategory;
  late DateTime _selectedDate;

  // Predefined expense categories
  final List<String> _categories = [
    'Food',
    'Travel',
    'Shopping',
    'Bills',
    'Health',
    'Other',
  ];

  // Helper check for mode
  bool get isEditMode => widget.expense != null;

  @override
  void initState() {
    super.initState();

    // Initialize with existing expense values if editing, or default values if adding
    final existing = widget.expense;

    _titleController = TextEditingController(text: existing?.title ?? '');
    _amountController = TextEditingController(
      text: existing != null ? existing.amount.toStringAsFixed(2) : '',
    );
    _noteController = TextEditingController(text: existing?.note ?? '');

    _selectedCategory = existing?.category ?? _categories.first;
    _selectedDate = existing?.date ?? DateTime.now();

    _dateController = TextEditingController(
      text: DateFormat('EEE, dd MMM yyyy').format(_selectedDate),
    );
  }

  @override
  void dispose() {
    // Clean up controllers to prevent memory leaks
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  /// Opens Flutter's native date picker modal.
  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('EEE, dd MMM yyyy').format(picked);
      });
    }
  }

  /// Validates and saves expense data to SQLite database.
  Future<void> _saveExpense() async {
    // Validate all form fields; exits early if any field is invalid
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final title = _titleController.text.trim();
    final amount = double.parse(_amountController.text.trim());
    final note = _noteController.text.trim().isEmpty
        ? null
        : _noteController.text.trim();

    final expenseToSave = Expense(
      id: widget.expense?.id, // Keep original id if editing
      title: title,
      amount: amount,
      category: _selectedCategory,
      date: _selectedDate,
      note: note,
    );

    final dbHelper = DatabaseHelper.instance;

    if (isEditMode) {
      await dbHelper.update(expenseToSave);
    } else {
      await dbHelper.insert(expenseToSave);
    }

    if (!mounted) return;

    // Return true to indicate to HomeScreen that data changed
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Expense' : 'Add Expense'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title Field
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title *',
                  hintText: 'e.g., Grocery shopping, Metro pass',
                  prefixIcon: const Icon(Icons.title),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Amount Field
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Amount (\$) *',
                  hintText: '0.00',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an amount';
                  }
                  final parsed = double.tryParse(value.trim());
                  if (parsed == null) {
                    return 'Please enter a valid numeric amount';
                  }
                  if (parsed <= 0) {
                    return 'Amount must be greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category *',
                  prefixIcon: const Icon(Icons.category_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Row(
                      children: [
                        Icon(
                          _getCategoryIcon(category),
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Text(category),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedCategory = newValue;
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a category';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Date Picker Field (read-only TextFormField tapped to pick date)
              TextFormField(
                controller: _dateController,
                readOnly: true,
                onTap: _pickDate,
                decoration: InputDecoration(
                  labelText: 'Date *',
                  prefixIcon: const Icon(Icons.calendar_today),
                  suffixIcon: const Icon(Icons.arrow_drop_down),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please choose a date';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Optional Note Field
              TextFormField(
                controller: _noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Note (Optional)',
                  hintText: 'Add extra details or reminders...',
                  prefixIcon: const Icon(Icons.notes),
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Action Button
              FilledButton.icon(
                onPressed: _saveExpense,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(isEditMode ? Icons.check_circle : Icons.save),
                label: Text(
                  isEditMode ? 'Update Expense' : 'Save Expense',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
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
}
