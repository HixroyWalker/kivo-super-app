import 'dart:convert';
import 'package:flutter/material.dart';

class AccountingScreen extends StatefulWidget {
  const AccountingScreen({super.key});

  @override
  State<AccountingScreen> createState() => _AccountingScreenState();
}

class _AccountingScreenState extends State<AccountingScreen> {
  // Mock Invoices
  final List<Map<String, dynamic>> _invoices = [
    {
      'id': 'INV-1001',
      'customerName': 'Kingston Wholesale Ltd',
      'subtotal': 45000.0,
      'gctAmount': 6750.0,
      'totalAmount': 51750.0,
      'status': 'PAID',
      'dueDate': '2026-08-10',
    },
    {
      'id': 'INV-1002',
      'customerName': 'Montego Bay Beach Resort',
      'subtotal': 120000.0,
      'gctAmount': 18000.0,
      'totalAmount': 138000.0,
      'status': 'PENDING',
      'dueDate': '2026-08-15',
    },
  ];

  // Mock Expenses
  final List<Map<String, dynamic>> _expenses = [
    {
      'id': 'EXP-501',
      'category': 'Inventory',
      'description': 'Bulk Coffee Beans & Spices',
      'amount': 28000.0,
      'gctPaid': 4200.0,
      'date': '2026-07-28',
    },
    {
      'id': 'EXP-502',
      'category': 'Utilities',
      'description': 'JPS Electricity Bill',
      'amount': 14500.0,
      'gctPaid': 2175.0,
      'date': '2026-07-25',
    },
  ];

  void _showCreateInvoiceDialog() {
    final nameController = TextEditingController();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Invoice'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Customer Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Subtotal Amount (JMD)'),
            ),
            const SizedBox(height: 12),
            const Text(
              '15% GCT will be calculated automatically.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isEmpty || amountController.text.isEmpty) return;
              final sub = double.tryParse(amountController.text) ?? 0.0;
              final gct = sub * 0.15;
              setState(() {
                _invoices.insert(0, {
                  'id': 'INV-${1000 + _invoices.length + 1}',
                  'customerName': nameController.text,
                  'subtotal': sub,
                  'gctAmount': gct,
                  'totalAmount': sub + gct,
                  'status': 'PENDING',
                  'dueDate': '2026-08-20',
                });
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Invoice created & sent to customer!')),
              );
            },
            child: const Text('Create & Send'),
          ),
        ],
      ),
    );
  }

  void _showAddExpenseDialog() {
    final descController = TextEditingController();
    final amountController = TextEditingController();
    String category = 'Inventory';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Record Business Expense'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: category,
                items: ['Inventory', 'Utilities', 'Rent', 'Payroll', 'Marketing', 'Supplies']
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (val) => setDialogState(() => category = val!),
                decoration: const InputDecoration(labelText: 'Expense Category'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description / Vendor'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Total Amount (JMD)'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (amountController.text.isEmpty) return;
                final amt = double.tryParse(amountController.text) ?? 0.0;
                setState(() {
                  _expenses.insert(0, {
                    'id': 'EXP-${500 + _expenses.length + 1}',
                    'category': category,
                    'description': descController.text.isEmpty ? category : descController.text,
                    'amount': amt,
                    'gctPaid': amt * 0.15,
                    'date': DateTime.now().toString().split(' ')[0],
                  });
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Expense logged successfully!')),
                );
              },
              child: const Text('Save Expense'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kivo QuickBooks Suite'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
              Tab(icon: Icon(Icons.receipt_long), text: 'Invoices'),
              Tab(icon: Icon(Icons.money_off), text: 'Expenses'),
              Tab(icon: Icon(Icons.pie_chart), text: 'P&L & Tax'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildOverviewTab(),
            _buildInvoicesTab(),
            _buildExpensesTab(),
            _buildPnLTab(),
          ],
        ),
      ),
    );
  }

  // --- TAB 1: OVERVIEW ---
  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green.shade700,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Monthly Net Cashflow', style: TextStyle(color: Colors.white70)),
                SizedBox(height: 8),
                Text('JMD \$125,750.00',
                    style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Inflow: +JMD \$189,750.00', style: TextStyle(color: Colors.white)),
                    Text('Total Expenses: -JMD \$64,000.00', style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Quick Financial Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showCreateInvoiceDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('New Invoice'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showAddExpenseDialog,
                  icon: const Icon(Icons.remove_circle_outline),
                  label: const Text('Log Expense'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- TAB 2: INVOICES ---
  Widget _buildInvoicesTab() {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateInvoiceDialog,
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _invoices.length,
        itemBuilder: (context, index) {
          final inv = _invoices[index];
          final isPaid = inv['status'] == 'PAID';

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text('${inv['customerName']} (${inv['id']})',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Subtotal: \$${inv['subtotal']} + GCT (15%): \$${inv['gctAmount']}'),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('JMD \$${inv['totalAmount']}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isPaid ? Colors.green.shade100 : Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      inv['status'],
                      style: TextStyle(
                        fontSize: 12,
                        color: isPaid ? Colors.green.shade900 : Colors.orange.shade900,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- TAB 3: EXPENSES ---
  Widget _buildExpensesTab() {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddExpenseDialog,
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _expenses.length,
        itemBuilder: (context, index) {
          final exp = _expenses[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.orangeAccent,
                child: Icon(Icons.shopping_bag, color: Colors.white),
              ),
              title: Text(exp['description'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Category: ${exp['category']} • Date: ${exp['date']}'),
              trailing: Text(
                '- JMD \$${exp['amount']}',
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- TAB 4: PROFIT & LOSS (P&L) & TAX ---
  Widget _buildPnLTab() {
    double totalRevenue = _invoices.where((i) => i['status'] == 'PAID').fold(0.0, (s, i) => s + (i['subtotal'] as double));
    double totalExpenses = _expenses.fold(0.0, (s, e) => s + (e['amount'] as double));
    double gctCollected = _invoices.where((i) => i['status'] == 'PAID').fold(0.0, (s, i) => s + (i['gctAmount'] as double));
    double gctPaid = _expenses.fold(0.0, (s, e) => s + (e['gctPaid'] as double));
    double netIncome = totalRevenue - totalExpenses;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Profit & Loss Statement (P&L)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildReportRow('Total Revenue (Sales)', 'JMD \$${totalRevenue.toStringAsFixed(2)}', Colors.green),
                  const Divider(),
                  _buildReportRow('Total Operating Expenses', '- JMD \$${totalExpenses.toStringAsFixed(2)}', Colors.red),
                  const Divider(thickness: 2),
                  _buildReportRow('Net Operating Income', 'JMD \$${netIncome.toStringAsFixed(2)}',
                      netIncome >= 0 ? Colors.green.shade900 : Colors.red.shade900, isBold: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Jamaican GCT Tax Summary (15%)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildReportRow('GCT Collected (Output Tax)', 'JMD \$${gctCollected.toStringAsFixed(2)}', Colors.blue.shade900),
                  const Divider(),
                  _buildReportRow('GCT Paid on Expenses (Input Tax)', '- JMD \$${gctPaid.toStringAsFixed(2)}', Colors.blue.shade900),
                  const Divider(thickness: 2),
                  _buildReportRow('Net GCT Tax Payable to TAJ', 'JMD \$${(gctCollected - gctPaid).toStringAsFixed(2)}',
                      Colors.indigo, isBold: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Exporting P&L Statement & Tax Report to CSV...')),
                );
              },
              icon: const Icon(Icons.download),
              label: const Text('Export P&L & GCT Report (CSV/PDF)'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportRow(String label, String value, Color color, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: isBold ? 16 : 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontSize: isBold ? 16 : 14, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
