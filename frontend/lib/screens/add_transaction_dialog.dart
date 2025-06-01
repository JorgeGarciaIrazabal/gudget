import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart'; // Ensure this is imported
import '../models/transaction_model.dart';
import '../services/hive_service.dart'; // For uuid

class AddTransactionDialog extends StatefulWidget {
  final Function(TransactionModel) onSave;
  final TransactionType transactionType;
  final TransactionModel? transactionToEdit;

  const AddTransactionDialog({
    super.key, 
    required this.transactionType, 
    required this.onSave,
    this.transactionToEdit,
  });

  @override
  State<AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends State<AddTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _description;
  late double _amount;
  late DateTime _selectedDate;
  late TransactionType _selectedType;

  // 1. Declare a FocusNode
  late FocusNode _amountFocusNode;
  late TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _amountFocusNode = FocusNode();
    _amountController = TextEditingController();
    
    // Initialize form fields based on whether we're editing or creating
    if (widget.transactionToEdit != null) {
      _description = widget.transactionToEdit!.description;
      _amount = widget.transactionToEdit!.amount;
      _selectedDate = widget.transactionToEdit!.date;
      _selectedType = widget.transactionToEdit!.type;
    } else {
      _description = '';
      _amount = 0.0;
      _selectedDate = DateTime.now();
      _selectedType = widget.transactionType;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_amountFocusNode);
      _amountController.text = _amount.toString();
      _amountController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _amountController.text.length,
      );
    });
  }

  @override
  void dispose() {
    // 4. Dispose the FocusNode when the widget is disposed
    _amountFocusNode.dispose();
    _amountController.dispose();
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
      final transaction = widget.transactionToEdit != null
          ? TransactionModel(
              id: widget.transactionToEdit!.id, // Keep same ID when editing
              description: _description,
              amount: _amount,
              date: _selectedDate,
              type: _selectedType,
            )
          : TransactionModel(
              id: uuid.v4(), // Generate new ID when creating
              description: _description,
              amount: _amount,
              date: _selectedDate,
              type: _selectedType,
            );
      widget.onSave(transaction);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.transactionToEdit != null ? 'Edit Transaction' : 'Add Transaction'),
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
                controller: _amountController,
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
