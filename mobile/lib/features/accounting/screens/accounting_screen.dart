import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/dark_theme.dart';
import '../../../core/services/auth_provider.dart';
import '../../../core/services/wallet_provider.dart';
import '../../../core/services/marketplace_provider.dart';
import '../../merchant/screens/pos_cashier_screen.dart';
import '../../merchant/screens/merchant_kyc_screen.dart';

class AccountingScreen extends StatefulWidget {
  const AccountingScreen({super.key});

  @override
  State<AccountingScreen> createState() => _AccountingScreenState();
}

class _AccountingScreenState extends State<AccountingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _invoices = [
    {
      'id': 'INV-1001',
      'customerName': 'Blue Mountain Coffee Exporters',
      'subtotal': 45000.0,
      'gctAmount': 6750.0,
      'totalAmount': 51750.0,
      'status': 'PAID',
      'dueDate': '2026-08-20',
    },
    {
      'id': 'INV-1002',
      'customerName': 'Pegasus Hotel Catering',
      'subtotal': 18500.0,
      'gctAmount': 2775.0,
      'totalAmount': 21275.0,
      'status': 'PENDING',
      'dueDate': '2026-08-28',
    },
  ];

  final List<Map<String, dynamic>> _expenses = [
    {
      'description': 'Packaging & Roasted Coffee Bags',
      'category': 'Inventory & Stock',
      'amount': 14200.0,
      'gctPaid': 2130.0,
      'date': '2026-08-19',
    },
    {
      'description': 'Store Utilities & Power',
      'category': 'Operations',
      'amount': 8500.0,
      'gctPaid': 1275.0,
      'date': '2026-08-16',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showMerchantRegistrationModal(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final businessNameCtrl = TextEditingController();
    final trnCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String selectedParish = 'Kingston';
    String selectedCategory = 'Local Produce & Agro';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: KivoDarkTheme.surfaceElevated,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.storefront, color: KivoDarkTheme.primaryEmerald, size: 24),
                        SizedBox(width: 10),
                        Text('Register as Kivo Merchant', style: TextStyle(color: KivoDarkTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Upgrade your individual user account to a verified Merchant Account to unlock the POS Cashier Terminal, Marketplace store, and GCT invoicing.',
                  style: TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: businessNameCtrl,
                  style: const TextStyle(color: KivoDarkTheme.textPrimary, fontSize: 14),
                  decoration: const InputDecoration(
                    labelText: 'Registered Business or Trading Name',
                    prefixIcon: Icon(Icons.business, color: KivoDarkTheme.primaryEmerald),
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: trnCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: KivoDarkTheme.textPrimary, fontSize: 14),
                  decoration: const InputDecoration(
                    labelText: 'Tax Registration Number (TRN - 9 Digits)',
                    prefixIcon: Icon(Icons.badge, color: KivoDarkTheme.accentAmber),
                    hintText: 'XXX-XXX-XXX',
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: KivoDarkTheme.textPrimary, fontSize: 14),
                  decoration: const InputDecoration(
                    labelText: 'Business WhatsApp / Phone Number',
                    prefixIcon: Icon(Icons.phone, color: KivoDarkTheme.accentCyan),
                    hintText: '+1 (876) XXX-XXXX',
                  ),
                ),
                const SizedBox(height: 12),

                // Parish Dropdown
                const Text('Operating Parish 🇯🇲', style: TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: KivoDarkTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: KivoDarkTheme.surfaceBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedParish,
                      isExpanded: true,
                      dropdownColor: KivoDarkTheme.surfaceElevated,
                      items: MarketplaceProvider.jamaicanParishes.map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(color: KivoDarkTheme.textPrimary, fontSize: 13)))).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedParish = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                ElevatedButton.icon(
                  onPressed: () async {
                    if (businessNameCtrl.text.trim().isEmpty || trnCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(backgroundColor: Colors.redAccent, content: Text('Please provide your business name and TRN.')),
                      );
                      return;
                    }

                    await auth.registerAsMerchant(
                      businessName: businessNameCtrl.text.trim(),
                      trnNumber: trnCtrl.text.trim(),
                      parish: selectedParish,
                      category: selectedCategory,
                      contactPhone: phoneCtrl.text.trim(),
                    );

                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: KivoDarkTheme.surfaceElevated,
                        content: Text(
                          '🎉 Congratulations! "${businessNameCtrl.text.trim()}" is now registered as a Kivo Merchant.',
                          style: const TextStyle(color: KivoDarkTheme.primaryEmerald, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.check_circle, color: Colors.black),
                  label: const Text('ACTIVATE MERCHANT ACCOUNT', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KivoDarkTheme.primaryEmerald,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCreateInvoiceDialog() {
    final nameController = TextEditingController();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: KivoDarkTheme.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Create New GCT Invoice', style: TextStyle(color: KivoDarkTheme.textPrimary, fontSize: 18)),
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
              'Standard 15% TAJ GCT will be automatically computed.',
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
                  content: Text('Tax Invoice created and saved to ledger!', style: TextStyle(color: KivoDarkTheme.primaryEmerald)),
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
    String category = 'Inventory & Stock';

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
                items: ['Inventory & Stock', 'Operations & Utilities', 'Salaries & Staff', 'Marketing & Ads', 'Logistics & Fuel']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(color: KivoDarkTheme.textPrimary, fontSize: 13))))
                    .toList(),
                onChanged: (val) => setDialogState(() => category = val!),
                decoration: const InputDecoration(labelText: 'Expense Category'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                style: const TextStyle(color: KivoDarkTheme.textPrimary),
                decoration: const InputDecoration(labelText: 'Description / Vendor Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: KivoDarkTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(labelText: 'Expense Amount (JMD)', prefixText: 'JMD \$ '),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: KivoDarkTheme.textSecondary))),
            ElevatedButton(
              onPressed: () {
                if (descController.text.trim().isEmpty || amountController.text.trim().isEmpty) return;
                final amt = double.tryParse(amountController.text.trim()) ?? 0.0;
                final gctPaid = amt * 0.15;
                setState(() {
                  _expenses.insert(0, {
                    'description': descController.text.trim(),
                    'category': category,
                    'amount': amt,
                    'gctPaid': gctPaid,
                    'date': '2026-08-21',
                  });
                });
                Navigator.pop(context);
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
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Business & Merchant Hub 💼'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: KivoDarkTheme.primaryEmerald,
          labelColor: KivoDarkTheme.primaryEmerald,
          unselectedLabelColor: KivoDarkTheme.textSecondary,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview & POS 💳'),
            Tab(text: 'Invoices 🧾'),
            Tab(text: 'Expenses 📉'),
            Tab(text: 'TAJ Tax & P&L 📊'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewAndPOSTab(auth),
          _buildInvoicesTab(),
          _buildExpensesTab(),
          _buildPnLTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewAndPOSTab(AuthProvider auth) {
    final isMerchant = auth.isMerchant;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Merchant Status or Sign-up Banner
          if (!isMerchant)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A2F), Color(0xFF0F1E2A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: KivoDarkTheme.primaryEmerald),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.store, color: KivoDarkTheme.primaryEmerald, size: 24),
                      SizedBox(width: 10),
                      Text('Start Selling on Kivo Jamaica', style: TextStyle(color: KivoDarkTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Register your business to accept in-store Jam-Dex QR & Cash payments with POS Cashier management, inventory catalog, and island-wide delivery.',
                    style: TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: () => _showMerchantRegistrationModal(context),
                    icon: const Icon(Icons.app_registration, color: Colors.black, size: 18),
                    label: const Text('Sign Up as a Merchant (1-Min)', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KivoDarkTheme.primaryEmerald,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: KivoDarkTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: KivoDarkTheme.primaryEmerald.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: KivoDarkTheme.primaryEmerald,
                    radius: 20,
                    child: Icon(Icons.verified, color: Colors.black),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(auth.merchantBusinessName ?? 'Verified Kivo Merchant', style: const TextStyle(color: KivoDarkTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('TRN: ${auth.merchantTRN ?? "124-582-901"} • ${auth.merchantParish ?? "Kingston & St. Andrew"}', style: const TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 20),

          // 2. Main Merchant Tools (POS Terminal & KYC)
          const Text('Merchant Operating Tools', style: TextStyle(color: KivoDarkTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          // POS Terminal Card
          InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PosCashierScreen())),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF132F27), Color(0xFF0F1E2A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: KivoDarkTheme.primaryEmerald.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: KivoDarkTheme.primaryEmerald.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.point_of_sale, color: KivoDarkTheme.primaryEmerald, size: 28),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Merchant POS Terminal', style: TextStyle(color: KivoDarkTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
                        SizedBox(height: 4),
                        Text('Cashier PINs, Live Dynamic QR, Tender Change & PDF Receipts', style: TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, color: KivoDarkTheme.primaryEmerald, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // KYC Tier Verification
          InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MerchantKYCScreen())),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: KivoDarkTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: KivoDarkTheme.surfaceBorder),
              ),
              child: const Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Color(0x269C27B0),
                    radius: 20,
                    child: Icon(Icons.verified_user, color: Colors.purpleAccent, size: 22),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('KYC Verification Tier', style: TextStyle(color: KivoDarkTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                        SizedBox(height: 2),
                        Text('Upload Companies Office of Jamaica (COJ) & TRN', style: TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: KivoDarkTheme.textSecondary),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 3. Quick Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showCreateInvoiceDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New Invoice'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KivoDarkTheme.primaryEmerald,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showAddExpenseDialog,
                  icon: const Icon(Icons.remove_circle_outline, size: 18, color: KivoDarkTheme.accentRose),
                  label: const Text('Log Expense', style: TextStyle(color: KivoDarkTheme.textPrimary)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: KivoDarkTheme.surfaceBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
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
      backgroundColor: KivoDarkTheme.background,
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
      backgroundColor: KivoDarkTheme.background,
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: KivoDarkTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: KivoDarkTheme.surfaceBorder),
            ),
            child: Column(
              children: [
                _buildSummaryRow('Gross Invoiced Sales', 'JMD \$${totalRevenue.toStringAsFixed(2)}', KivoDarkTheme.textPrimary),
                const Divider(color: KivoDarkTheme.surfaceBorder),
                _buildSummaryRow('GCT Output Tax Collected (15%)', 'JMD \$${gctCollected.toStringAsFixed(2)}', KivoDarkTheme.primaryEmerald),
                const Divider(color: KivoDarkTheme.surfaceBorder),
                _buildSummaryRow('GCT Input Tax Paid (15%)', 'JMD \$${gctPaid.toStringAsFixed(2)}', KivoDarkTheme.accentRose),
                const Divider(color: KivoDarkTheme.surfaceBorder),
                _buildSummaryRow('Net GCT Payable to TAJ', 'JMD \$${(gctCollected - gctPaid).clamp(0.0, double.infinity).toStringAsFixed(2)}', KivoDarkTheme.accentAmber, isBold: true),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Income Statement (P&L)', style: TextStyle(color: KivoDarkTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: KivoDarkTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: KivoDarkTheme.surfaceBorder),
            ),
            child: Column(
              children: [
                _buildSummaryRow('Total Operating Revenue', 'JMD \$${totalRevenue.toStringAsFixed(2)}', KivoDarkTheme.primaryEmerald),
                const Divider(color: KivoDarkTheme.surfaceBorder),
                _buildSummaryRow('Total Operating Expenses', 'JMD \$${totalExpenses.toStringAsFixed(2)}', KivoDarkTheme.accentRose),
                const Divider(color: KivoDarkTheme.surfaceBorder),
                _buildSummaryRow('Net Operating Profit', 'JMD \$${netIncome.toStringAsFixed(2)}', netIncome >= 0 ? KivoDarkTheme.primaryEmerald : KivoDarkTheme.accentRose, isBold: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color color, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.w600)),
        ],
      ),
    );
  }
}
