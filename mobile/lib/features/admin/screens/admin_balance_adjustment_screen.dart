import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/dark_theme.dart';
import '../../../core/services/admin_provider.dart';
import '../../../core/services/wallet_provider.dart';

class AdminBalanceAdjustmentScreen extends StatefulWidget {
  const AdminBalanceAdjustmentScreen({super.key});

  @override
  State<AdminBalanceAdjustmentScreen> createState() => _AdminBalanceAdjustmentScreenState();
}

class _AdminBalanceAdjustmentScreenState extends State<AdminBalanceAdjustmentScreen> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  bool _isCredit = true; // true = Credit (+), false = Debit (-)
  bool _isProcessing = false;

  final List<String> _quickReasons = [
    'Account Top-up Refund',
    'Administrative Top-up Grant',
    'Dispute Resolution Adjustment',
    'Chargeback Reversal',
    'TAJ Tax Correction',
  ];

  @override
  void dispose() {
    _userController.dispose();
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _executeAdjustment() async {
    final user = _userController.text.trim();
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final reason = _reasonController.text.trim().isNotEmpty ? _reasonController.text.trim() : 'Admin Manual Adjustment';

    if (user.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text('Please enter a valid user ID and positive amount.'),
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);
    final walletProvider = context.read<WalletProvider>();
    final success = await context.read<AdminProvider>().adjustUserBalance(
      userIdentifier: user,
      amount: amount,
      isCredit: _isCredit,
      reason: reason,
      walletProvider: walletProvider,
    );

    if (mounted) {
      setState(() => _isProcessing = false);
      if (success) {
        _amountController.clear();
        _reasonController.clear();
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: KivoDarkTheme.surfaceElevated,
            title: Row(
              children: [
                Icon(_isCredit ? Icons.add_circle : Icons.remove_circle,
                    color: _isCredit ? KivoDarkTheme.primaryEmerald : KivoDarkTheme.accentRose),
                const SizedBox(width: 10),
                Text(_isCredit ? 'Balance Credited' : 'Balance Debited',
                    style: const TextStyle(color: KivoDarkTheme.textPrimary, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Text(
              'Successfully ${_isCredit ? "credited" : "debited"} JMD \$${amount.toStringAsFixed(2)} for user "$user". Audit log recorded.',
              style: const TextStyle(color: KivoDarkTheme.textSecondary),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();

    return Scaffold(
      backgroundColor: KivoDarkTheme.background,
      appBar: AppBar(
        title: const Text('Credit / Debit User Balances', style: TextStyle(fontWeight: FontWeight.bold, color: KivoDarkTheme.textPrimary)),
        backgroundColor: KivoDarkTheme.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mode Selector: Credit vs Debit
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isCredit = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _isCredit ? KivoDarkTheme.primaryEmerald.withOpacity(0.2) : KivoDarkTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _isCredit ? KivoDarkTheme.primaryEmerald : KivoDarkTheme.surfaceBorder),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_circle, color: _isCredit ? KivoDarkTheme.primaryEmerald : KivoDarkTheme.textSecondary, size: 20),
                          const SizedBox(width: 8),
                          Text('Credit User (+)', style: TextStyle(color: _isCredit ? KivoDarkTheme.primaryEmerald : KivoDarkTheme.textSecondary, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isCredit = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: !_isCredit ? KivoDarkTheme.accentRose.withOpacity(0.2) : KivoDarkTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: !_isCredit ? KivoDarkTheme.accentRose : KivoDarkTheme.surfaceBorder),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.remove_circle, color: !_isCredit ? KivoDarkTheme.accentRose : KivoDarkTheme.textSecondary, size: 20),
                          const SizedBox(width: 8),
                          Text('Debit User (-)', style: TextStyle(color: !_isCredit ? KivoDarkTheme.accentRose : KivoDarkTheme.textSecondary, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // User Selection
            const Text('User Email or Identifier:', style: TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _userController,
              style: const TextStyle(color: KivoDarkTheme.textPrimary),
              decoration: InputDecoration(
                filled: true,
                fillColor: KivoDarkTheme.surface,
                prefixIcon: const Icon(Icons.person, color: KivoDarkTheme.accentCyan),
                hintText: 'user@kivowebb.app or handle',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 18),

            // Amount Input
            const Text('Adjustment Amount (JMD):', style: TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(
                color: _isCredit ? KivoDarkTheme.primaryEmerald : KivoDarkTheme.accentRose,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: KivoDarkTheme.surface,
                prefixText: 'JMD \$ ',
                prefixStyle: TextStyle(
                  color: _isCredit ? KivoDarkTheme.primaryEmerald : KivoDarkTheme.accentRose,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
                hintText: '5,000.00',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 18),

            // Reason / Audit Memo
            const Text('Adjustment Reason (Audit Log):', style: TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonController,
              style: const TextStyle(color: KivoDarkTheme.textPrimary),
              decoration: InputDecoration(
                filled: true,
                fillColor: KivoDarkTheme.surface,
                prefixIcon: const Icon(Icons.assignment, color: KivoDarkTheme.accentAmber),
                hintText: 'e.g. Approved Merchant Grant',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),

            // Quick Reasons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickReasons.map((r) {
                return ActionChip(
                  label: Text(r, style: const TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 11)),
                  backgroundColor: KivoDarkTheme.surfaceElevated,
                  onPressed: () => setState(() => _reasonController.text = r),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),

            // Live Vault Reference
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: KivoDarkTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: KivoDarkTheme.surfaceBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.security, color: KivoDarkTheme.accentCyan, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Live Treasury Balance: ${wallet.formattedBalance}',
                      style: const TextStyle(color: KivoDarkTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _executeAdjustment,
                icon: _isProcessing
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : Icon(_isCredit ? Icons.add_circle : Icons.remove_circle, color: Colors.black),
                label: Text(
                  _isProcessing ? 'Processing Transaction...' : (_isCredit ? 'Credit JMD Balance' : 'Debit JMD Balance'),
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isCredit ? KivoDarkTheme.primaryEmerald : KivoDarkTheme.accentRose,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
