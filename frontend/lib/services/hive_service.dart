import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction_model.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart'; // For ChangeNotifier

const String transactionsBoxName = 'transactions';
var uuid = const Uuid();

class BudgetService extends ChangeNotifier {
  late Box<TransactionModel> _transactionsBox;

  List<TransactionModel> _transactions = [];
  List<TransactionModel> get transactions => _transactions;

  double get totalBalance {
    return _transactions.fold(0.0, (sum, item) {
      return item.type == TransactionType.income ? sum + item.amount : sum - item.amount;
    });
  }

  Future<void> init() async {
    // Initialize Hive and open the box
    await Hive.initFlutter();
    Hive.registerAdapter(TransactionTypeAdapter());
    Hive.registerAdapter(TransactionModelAdapter());
    _transactionsBox = await Hive.openBox<TransactionModel>(transactionsBoxName);
    _loadTransactions();
  }

  void _loadTransactions() {
    _transactions = _transactionsBox.values.toList();
    _transactions.sort((a, b) => b.date.compareTo(a.date)); // Sort by date descending
    notifyListeners();
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    await _transactionsBox.put(transaction.id, transaction);
    _loadTransactions(); // Reload and notify
  }

  Future<void> deleteTransaction(String id) async {
    await _transactionsBox.delete(id);
    _loadTransactions();
  }

  // Helper to get transactions for a specific month and year
  List<TransactionModel> getTransactionsForMonth(int year, int month) {
    return _transactions
        .where((t) => t.date.year == year && t.date.month == month)
        .toList();
  }

  // Data for evolution chart
  Map<String, Map<String, double>> getMonthlySummaries() {
    Map<String, Map<String, double>> summaries = {}; // Key: "YYYY-MM"

    // Sort transactions by date to process chronologically for balance
    List<TransactionModel> sortedTransactions = List.from(_transactions);
    sortedTransactions.sort((a,b) => a.date.compareTo(b.date));

    for (var transaction in sortedTransactions) {
      String monthKey = "${transaction.date.year}-${transaction.date.month.toString().padLeft(2, '0')}";
      summaries.putIfAbsent(monthKey, () => {'income': 0.0, 'expense': 0.0, 'balance': 0.0});

      if (transaction.type == TransactionType.income) {
        summaries[monthKey]!['income'] = (summaries[monthKey]!['income'] ?? 0) + transaction.amount;
      } else {
        summaries[monthKey]!['expense'] = (summaries[monthKey]!['expense'] ?? 0) + transaction.amount;
      }
    }
    
    // Recalculate balances chronologically for the chart
    // This ensures the balance line reflects the cumulative balance up to that month
    double cumulativeBalance = 0;
    List<String> sortedMonthKeys = summaries.keys.toList()..sort();

    Map<String, Map<String, double>> finalSummaries = {};
    for (String monthKey in sortedMonthKeys) {
        double monthIncome = summaries[monthKey]!['income']!;
        double monthExpense = summaries[monthKey]!['expense']!;
        cumulativeBalance += monthIncome;
        cumulativeBalance -= monthExpense;
        finalSummaries[monthKey] = {
            'income': monthIncome,
            'expense': monthExpense,
            'balance': cumulativeBalance,
        };
    }

    return finalSummaries;
  }


  // Ensure box is closed when app is disposed (optional but good practice)
  @override
  void dispose() {
    Hive.close(); // Closes all boxes
    super.dispose();
  }
}
