import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../screens/evolution_screen.dart';
import '../screens/monthly_records_screen.dart';
import '../services/hive_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late PageController _pageController;

  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _changeMonth(int increment) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + increment,
        _selectedMonth.day,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final budgetService = Provider.of<BudgetService>(context);
    final NumberFormat currencyFormatter = NumberFormat.currency(locale: 'en_US', symbol: '\$');

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // const Text('Simple Budget'),
            Padding(
              padding: const EdgeInsets.only(top: 8.0), // Add padding to the top
              child: Text(
                'Balance: \n${currencyFormatter.format(budgetService.totalBalance)}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: budgetService.totalBalance >= 0 ? Colors.green : Colors.red,
                ),
              ),
            )
          ],
        ),
        actions: _currentIndex == 0 // Show month navigation only on the first tab
            ? [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _changeMonth(-1),
                ),
                TextButton(
                  onPressed: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedMonth,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                      initialDatePickerMode: DatePickerMode.year,
                    );
                    if (picked != null && picked != _selectedMonth) {
                      setState(() {
                        _selectedMonth = DateTime(picked.year, picked.month, 1);
                      });
                    }
                  },
                  child: Text(
                    DateFormat('MMM yyyy').format(_selectedMonth),
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _changeMonth(1),
                ),
              ]
            : null,
      ),
      body: Column(
        children: [
          BottomAppBar(
            height: 30,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                IconButton(
                  icon: const Icon(Icons.list_alt),
                  tooltip: "Monthly Records",
                  color: _currentIndex == 0 ? Theme.of(context).colorScheme.secondary : Colors.grey,
                  onPressed: () => _onTabTapped(0),
                ),
                IconButton(
                  icon: const Icon(Icons.show_chart),
                  tooltip: "Evolution",
                  color: _currentIndex == 1 ? Theme.of(context).colorScheme.secondary : Colors.grey,
                  onPressed: () => _onTabTapped(1),
                ),
              ],
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              children: [
                MonthlyRecordsScreen(selectedMonth: _selectedMonth),
                const EvolutionScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
