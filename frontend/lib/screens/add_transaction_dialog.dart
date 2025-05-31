import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart'; // Ensure this is imported
import '../models/transaction_model.dart';
import '../services/hive_service.dart'; // For uuid

class AddTransactionDialog extends StatefulWidget {
  final Function(TransactionModel) onSave;
  final TransactionType transactionType;

  const AddTransactionDialog({super.key, required this.transactionType, required this.onSave});

  @override
  State<AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends State<AddTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  String _description = '';
  double _amount = 0.0;
  DateTime _selectedDate = DateTime.now();
  TransactionType _selectedType = TransactionType.expense;

  // 1. Declare a FocusNode
  late FocusNode _amountFocusNode;

  @override
  void initState() {
    super.initState();
    // 2. Initialize the FocusNode
    _amountFocusNode = FocusNode();
    // 3. Request focus after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_amountFocusNode);
    });
  }

  @override
  void dispose() {
    // 4. Dispose the FocusNode when the widget is disposed
    _amountFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final newTransaction = TransactionModel(
        id: uuid.v4(), // Generate unique ID
        description: _description,
        amount: _amount,
        date: _selectedDate,
        type: _selectedType,
      );
      widget.onSave(newTransaction);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    _selectedType = widget.transactionType;
    return AlertDialog(
      title: const Text('Add Transaction'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                  decoration: const InputDecoration(labelText: 'Description'),
                  onSaved: (value) {
                    if (value == null || value.isEmpty) {
                      _description = _selectedType == TransactionType.income ? 'Income' : 'Expense';
                    } else {
                      _description = value;
                    }
                  }
              ),
              TextFormField(
                // 5. Assign the FocusNode to the TextFormField
                focusNode: _amountFocusNode,
                decoration: const InputDecoration(labelText: 'Amount in \$'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  if (double.parse(value) <= 0) {
                    return 'Amount must be positive';
                  }
                  return null;
                },
                onSaved: (value) => _amount = double.parse(value!),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(DateFormat.yMMMd().format(_selectedDate)),
                  ),
                  TextButton(
                    onPressed: () => _pickDate(context),
                    child: const Text('Select Date'),
                  ),
                ],
              ),
              DropdownButtonFormField<TransactionType>(
                value: _selectedType,
                decoration: const InputDecoration(labelText: 'Type'),
                items: TransactionType.values.map((TransactionType type) {
                  return DropdownMenuItem<TransactionType>(
                    value: type,
                    child: Text(type.toString().split('.').last.capitalize()),
                  );
                }).toList(),
                onChanged: (TransactionType? newValue) {
                  setState(() {
                    _selectedType = newValue!;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          onPressed: _submitForm,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// Helper extension for capitalizing strings
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}