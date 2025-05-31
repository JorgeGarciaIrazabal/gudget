import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/transaction_model.dart';
import '../services/hive_service.dart';
import 'add_transaction_dialog.dart';

class MonthlyRecordsScreen extends StatefulWidget {
  final DateTime selectedMonth;

  const MonthlyRecordsScreen({super.key, required this.selectedMonth});

  @override
  State<MonthlyRecordsScreen> createState() => _MonthlyRecordsScreenState();
}

class _MonthlyRecordsScreenState extends State<MonthlyRecordsScreen> {
  @override

  Widget build(BuildContext context) {
    final budgetService = Provider.of<BudgetService>(context);
    final NumberFormat currencyFormatter = NumberFormat.currency(locale: 'en_US', symbol: '\$');

    final monthlyTransactions = budgetService.getTransactionsForMonth(
      widget.selectedMonth.year,
      widget.selectedMonth.month,
    );

    if (monthlyTransactions.isEmpty) {
      return Center(
        child: Text(
          'No transactions for ${DateFormat.yMMMM().format(widget.selectedMonth)}.',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      );
    }

    double monthlyIncome = 0;
    double monthlyExpense = 0;
    for (var t in monthlyTransactions) {
      if (t.type == TransactionType.income) {
        monthlyIncome += t.amount;
      } else {
        monthlyExpense += t.amount;
      }
    }

    return Scaffold(
      body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  const Text("Income", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(currencyFormatter.format(monthlyIncome), style: const TextStyle(color: Colors.green, fontSize: 16)),
                ],
              ),
              Column(
                children: [
                  const Text("Expenses", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(currencyFormatter.format(monthlyExpense), style: const TextStyle(color: Colors.red, fontSize: 16)),
                ],
              ),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: ListView.builder(
            itemCount: monthlyTransactions.length,
            itemBuilder: (context, index) {
              final transaction = monthlyTransactions[index];
              final bool isIncome = transaction.type == TransactionType.income;
              return Slidable(
                key: Key(transaction.id), // Important for Slidable
                endActionPane: ActionPane(
                  motion: const StretchMotion(), // Or other motions like ScrollMotion, BehindMotion
                  children: [
                    SlidableAction(
                      onPressed: (context) {
                        // TODO: Implement Edit Action
                        print('Not Implemented yet: ${transaction.description}');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('(Not implemented) Edit: ${transaction.description}')),
                        );
                      },
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      icon: Icons.edit,
                      label: 'Edit',
                    ),
                    SlidableAction(
                      onPressed: (context) {
                        // Show confirmation dialog before deleting
                        showDialog(
                          context: context,
                          builder: (BuildContext dialogContext) {
                            return AlertDialog(
                              title: const Text('Confirm Deletion'),
                              content: Text('Are you sure you want to delete "${transaction.description}"? This action cannot be undone.'),
                              actions: <Widget>[
                                TextButton(
                                  child: const Text('No'),
                                  onPressed: () {
                                    Navigator.of(dialogContext).pop(); // Close the dialog
                                  },
                                ),
                                TextButton(
                                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                                  child: const Text('Delete'),
                                  onPressed: () {
                                    Navigator.of(dialogContext).pop(); // Close the dialog
                                    budgetService.deleteTransaction(transaction.id);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('${transaction.description} deleted')),
                                    );
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      },
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      icon: Icons.delete,
                      label: 'Delete',
                    ),
                  ],
                ),
                child: ListTile(
                  leading: Icon(
                    isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                    color: isIncome ? Colors.green : Colors.red,
                  ),
                  title: Text(transaction.description),
                  subtitle: Text(DateFormat.yMMMd().format(transaction.date)),
                  trailing: Text(
                    '${isIncome ? '+' : '-'}${currencyFormatter.format(transaction.amount)}',
                    style: TextStyle(
                      color: isIncome ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(1.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AddTransactionDialog(
                      transactionType: TransactionType.income,
                      onSave: (transaction) {
                        budgetService.addTransaction(transaction);
                      },
                    );
                  },
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Income'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AddTransactionDialog(
                      transactionType: TransactionType.expense,
                      onSave: (transaction) {
                        budgetService.addTransaction(transaction);
                      },
                    );
                  },
                );
              },
              icon: const Icon(Icons.remove),
              label: const Text('Add Expense'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
