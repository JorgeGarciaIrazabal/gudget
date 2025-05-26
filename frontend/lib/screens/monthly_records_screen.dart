import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/transaction_model.dart';
import '../services/hive_service.dart';

class MonthlyRecordsScreen extends StatelessWidget {
  final DateTime selectedMonth;

  const MonthlyRecordsScreen({super.key, required this.selectedMonth});

  @override
  Widget build(BuildContext context) {
    final budgetService = Provider.of<BudgetService>(context);
    final NumberFormat currencyFormatter = NumberFormat.currency(locale: 'en_US', symbol: '\$');

    // Get transactions for the selected month
    final monthlyTransactions = budgetService.getTransactionsForMonth(
      selectedMonth.year,
      selectedMonth.month,
    );

    if (monthlyTransactions.isEmpty) {
      return Center(
        child: Text(
          'No transactions for ${DateFormat.yMMMM().format(selectedMonth)}.',
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

    return Column(
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
              return Dismissible(
                key: Key(transaction.id),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) {
                  budgetService.deleteTransaction(transaction.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${transaction.description} deleted')),
                  );
                },
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
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
    );
  }
}
