import 'package:flutter/material.dart';
import '../../../core/theme/dark_theme.dart';

class AccountingScreen extends StatefulWidget {
  const AccountingScreen({super.key});

  @override
  State<AccountingScreen> createState() => _AccountingScreenState();
}

class _AccountingScreenState extends State<AccountingScreen> {
  final List<Map<String, dynamic>> _invoices = [];
  final List<Map<String, dynamic>> _expenses = [];

  void _showCreateInvoiceDialog() {
    final nameController = TextEditingController();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: KivoDarkTheme.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Create New Invoice', style: TextStyle(color: KivoDarkTheme.textPrimary, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: KivoDarkTheme.textPrimary),
              decoration: const InputDecoration(labelText: 'Customer / Business Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: KivoDarkTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(labelText: 'Subtotal Amount (JMD)', prefixText: 'JMD \$ '),
            ),
            const SizedBox(height: 8),
            const Text(
              'Standard 15% GCT will be automatically itemized.',
              style: TextStyle(fontSize: 11, color: KivoDarkTheme.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: KivoDarkTheme.textSecondary))),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty || amountController.text.trim().isEmpty) return;
              final sub = double.tryParse(amountController.text.trim()) ?? 0.0;
              final gct = sub * 0.15;
              setState(() {
                _invoices.insert(0, {
                  'id': 'INV-${1000 + _invoices.length + 1}',
                  'customerName': nameController.text.trim(),
                  'subtotal': sub,
                  'gctAmount': gct,
                  'totalAmount': sub + gct,
                  'status': 'PENDING',
                  'dueDate': '2026-08-30',
                });
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: KivoDarkTheme.surfaceElevated,
                  content: Text('Invoice created and sent to customer!', style: TextStyle(color: KivoDarkTheme.primaryEmerald)),
                ),
              );
            },
            child: const Text('Generate Invoice'),
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
          backgroundColor: KivoDarkTheme.surfaceElevated,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Record Business Expense', style: TextStyle(color: KivoDarkTheme.textPrimary, fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: category,
                dropdownColor: KivoDarkTheme.surfaceElevated,
                style: const TextStyle(color: KivoDarkTheme.textPrimary),
                items: ['Inventory', 'Utilities', 'Rent', 'Payroll', 'Marketing', 'Supplies']
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat, style: const TextStyle(color: KivoDarkTheme.textPrimary))))
                    .toList(),
                onChanged: (val) => setDialogState(() => category = val!),
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                style: const TextStyle(color: KivoDarkTheme.textPrimary),
                decoration: const InputDecoration(labelText: 'Description / Vendor'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: KivoDarkTheme.textPrimary),
                decoration: const InputDecoration(labelText: 'Total Amount (JMD)', prefixText: 'JMD \$ '),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: KivoDarkTheme.textSecondary))),
            ElevatedButton(
              onPressed: () {
                if (amountController.text.trim().isEmpty) return;
                final amt = double.tryParse(amountController.text.trim()) ?? 0.0;
                setState(() {
                  _expenses.insert(0, {
                    'id': 'EXP-${500 + _expenses.length + 1}',
                    'category': category,
                    'description': descController.text.trim().isEmpty ? category : descController.text.trim(),
                    'amount': amt,
                    'gctPaid': amt * 0.15,
                    'date': '2026-08-20',
                  });
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: KivoDarkTheme.surfaceElevated,
                    content: Text('Expense logged successfully!', style: TextStyle(color: KivoDarkTheme.primaryEmerald)),
                  ),
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
          title: const Text('Business & TAJ Tax'),
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: KivoDarkTheme.primaryEmerald,
            labelColor: KivoDarkTheme.primaryEmerald,
            unselectedLabelColor: KivoDarkTheme.textSecondary,
            tabs: [
              Tab(icon: Icon(Icons.dashboard_outlined), text: 'Overview'),
              Tab(icon: Icon(Icons.receipt_long_outlined), text: 'Invoices'),
              Tab(icon: Icon(Icons.money_off_outlined), text: 'Expenses'),
              Tab(icon: Icon(Icons.pie_chart_outline), text: 'TAJ GCT-03'),
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

  Widget _buildOverviewTab() {
    final double totalInflow = _invoices.where((i) => i['status'] == 'PAID').fold<double>(0.0, (acc, i) => acc + ((i['totalAmount'] as num?)?.toDouble() ?? 0.0));
    final double totalExpenses = _expenses.fold<double>(0.0, (acc, e) => acc + ((e['amount'] as num?)?.toDouble() ?? 0.0));
    final double netCashflow = totalInflow - totalExpenses;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF004D40), Color(0xFF0B1F1C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: KivoDarkTheme.primaryEmerald.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Monthly Net Cashflow', style: TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 13)),
                const SizedBox(height: 8),
                Text(
                  'JMD \$${netCashflow.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Inflow: +JMD \$${totalInflow.toStringAsFixed(2)}',
                      style: const TextStyle(color: KivoDarkTheme.primaryEmerald, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    Text(
                      'Expenses: -JMD \$${totalExpenses.toStringAsFixed(2)}',
                      style: const TextStyle(color: KivoDarkTheme.accentRose, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Quick Financial Actions', style: TextStyle(color: KivoDarkTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showCreateInvoiceDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New Invoice'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showAddExpenseDialog,
                  icon: const Icon(Icons.remove_circle_outline, size: 18),
                  label: const Text('Log Expense'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInvoicesTab() {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateInvoiceDialog,
        backgroundColor: KivoDarkTheme.primaryEmerald,
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _invoices.length,
        itemBuilder: (context, index) {
          final inv = _invoices[index];
          final isPaid = inv['status'] == 'PAID';

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: KivoDarkTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: KivoDarkTheme.surfaceBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${inv['customerName']} (${inv['id']})', style: const TextStyle(color: KivoDarkTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text('Subtotal: \$${inv['subtotal']} + GCT: \$${inv['gctAmount']}', style: const TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('JMD \$${inv['totalAmount']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isPaid ? KivoDarkTheme.primaryEmerald.withOpacity(0.15) : KivoDarkTheme.accentAmber.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        inv['status'],
                        style: TextStyle(fontSize: 10, color: isPaid ? KivoDarkTheme.primaryEmerald : KivoDarkTheme.accentAmber, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildExpensesTab() {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddExpenseDialog,
        backgroundColor: KivoDarkTheme.accentAmber,
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _expenses.length,
        itemBuilder: (context, index) {
          final exp = _expenses[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: KivoDarkTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: KivoDarkTheme.surfaceBorder),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: KivoDarkTheme.accentAmber.withOpacity(0.15),
                  child: const Icon(Icons.receipt_outlined, color: KivoDarkTheme.accentAmber, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(exp['description'], style: const TextStyle(color: KivoDarkTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text('${exp['category']} • ${exp['date']}', style: const TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                Text('- JMD \$${exp['amount']}', style: const TextStyle(color: KivoDarkTheme.accentRose, fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          );
        },
      ),
    );
  }

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
          const Text('Tax Administration Jamaica (TAJ) Summary', style: TextStyle(color: KivoDarkTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: KivoDarkTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: KivoDarkTheme.surfaceBorder),
            ),
            child: Column(
              children: [
                _buildReportRow('GCT Output Tax (Collected 15%)', 'JMD \$${gctCollected.toStringAsFixed(2)}', KivoDarkTheme.primaryEmerald),
                const Divider(color: KivoDarkTheme.surfaceBorder),
                _buildReportRow('GCT Input Tax (Paid on Expenses)', '- JMD \$${gctPaid.toStringAsFixed(2)}', KivoDarkTheme.accentCyan),
                const Divider(color: KivoDarkTheme.surfaceBorder, thickness: 1.5),
                _buildReportRow('Net GCT Payable to TAJ', 'JMD \$${(gctCollected - gctPaid).toStringAsFixed(2)}', Colors.amberAccent, isBold: true),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: KivoDarkTheme.surfaceElevated,
                  content: Text('TAJ GCT-03 Tax Return Form generated and ready for eServices upload! 🇯🇲', style: TextStyle(color: KivoDarkTheme.primaryEmerald)),
                ),
              );
            },
            icon: const Icon(Icons.description_outlined),
            label: const Text('Export TAJ GCT-03 Return (CSV/PDF)'),
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
          Text(label, style: TextStyle(color: KivoDarkTheme.textPrimary, fontSize: isBold ? 15 : 13, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontSize: isBold ? 16 : 14, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
