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
  AdminUserAccount? _selectedUser;

  final List<String> _quickReasons = [
    'Account Top-up Grant',
    'Dispute Resolution Refund',
    'Merchant Settlement Payout',
    'Fee Reimbursement',
    'TAJ Tax Correction',
    'Administrative Audit Adjustment',
  ];

  final List<double> _quickAmounts = [500, 1000, 5000, 25000, 100000];

  @override
  void initState() {
    super.initState();
    _reasonController.text = _quickReasons.first;
  }

  @override
  void dispose() {
    _userController.dispose();
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _selectUser(AdminUserAccount user, WalletProvider wallet) {
    setState(() {
      _selectedUser = user;
      _userController.text = user.userId;
    });
  }

  Future<void> _executeAdjustment() async {
    final userIdentifier = _userController.text.trim();
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final reason = _reasonController.text.trim().isNotEmpty ? _reasonController.text.trim() : 'Administrative Manual Adjustment';

    if (userIdentifier.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text('Please select or enter a valid user ID and positive amount.'),
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);
    final walletProvider = context.read<WalletProvider>();
    final targetName = _selectedUser?.name ?? userIdentifier;

    final success = await context.read<AdminProvider>().adjustUserBalance(
      userIdentifier: userIdentifier,
      targetUserName: targetName,
      amount: amount,
      isCredit: _isCredit,
      reason: reason,
      walletProvider: walletProvider,
    );

    if (mounted) {
      setState(() => _isProcessing = false);
      if (success) {
        _amountController.clear();
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: KivoDarkTheme.surfaceElevated,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(_isCredit ? Icons.add_circle : Icons.remove_circle,
                    color: _isCredit ? KivoDarkTheme.primaryEmerald : KivoDarkTheme.accentRose, size: 28),
                const SizedBox(width: 10),
                Text(_isCredit ? 'Balance Credited' : 'Balance Debited',
                    style: const TextStyle(color: KivoDarkTheme.textPrimary, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Successfully ${_isCredit ? "credited" : "debited"} JMD \$${amount.toStringAsFixed(2)} to "$targetName".',
                  style: const TextStyle(color: KivoDarkTheme.textPrimary, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: KivoDarkTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified, color: KivoDarkTheme.primaryEmerald, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Audit Memo: $reason',
                          style: const TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isCredit ? KivoDarkTheme.primaryEmerald : KivoDarkTheme.accentRose,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Done', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final wallet = context.watch<WalletProvider>();

    return Scaffold(
      backgroundColor: KivoDarkTheme.background,
      appBar: AppBar(
        title: const Text('Credit / Debit User Balances', style: TextStyle(fontWeight: FontWeight.bold, color: KivoDarkTheme.textPrimary)),
        backgroundColor: KivoDarkTheme.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Mode Selector: Credit vs Debit
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isCredit = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _isCredit ? KivoDarkTheme.primaryEmerald.withOpacity(0.2) : KivoDarkTheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _isCredit ? KivoDarkTheme.primaryEmerald : KivoDarkTheme.surfaceBorder,
                          width: _isCredit ? 2 : 1,
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_circle, color: KivoDarkTheme.primaryEmerald, size: 20),
                          SizedBox(width: 8),
                          Text('CREDIT (+)', style: TextStyle(color: KivoDarkTheme.primaryEmerald, fontWeight: FontWeight.bold, fontSize: 14)),
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
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: !_isCredit ? KivoDarkTheme.accentRose : KivoDarkTheme.surfaceBorder,
                          width: !_isCredit ? 2 : 1,
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.remove_circle, color: KivoDarkTheme.accentRose, size: 20),
                          SizedBox(width: 8),
                          Text('DEBIT (-)', style: TextStyle(color: KivoDarkTheme.accentRose, fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 2. Quick User Account Selector
            const Text(
              'Select Target Account or Merchant',
              style: TextStyle(color: KivoDarkTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: KivoDarkTheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: KivoDarkTheme.surfaceBorder),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<AdminUserAccount>(
                  value: _selectedUser,
                  isExpanded: true,
                  dropdownColor: KivoDarkTheme.surfaceElevated,
                  hint: const Text('Choose registered user / merchant...', style: TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 13)),
                  items: admin.registeredUsers.map((user) {
                    final isCurr = user.isCurrentUser;
                    final bal = isCurr ? wallet.jmdBalance : user.balanceJMD;
                    return DropdownMenuItem<AdminUserAccount>(
                      value: user,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: isCurr ? KivoDarkTheme.accentAmber : KivoDarkTheme.primaryEmerald,
                            child: Text(user.name[0], style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(user.name, style: const TextStyle(color: KivoDarkTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                                Text('${user.handle} • ${user.accountType}', style: const TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 10)),
                              ],
                            ),
                          ),
                          Text('JMD \$${bal.toStringAsFixed(0)}', style: const TextStyle(color: KivoDarkTheme.primaryEmerald, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (u) {
                    if (u != null) _selectUser(u, wallet);
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),

            // User ID Input field (with manual entry fallback)
            TextField(
              controller: _userController,
              style: const TextStyle(color: KivoDarkTheme.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                labelText: 'Target User Identifier / ID / Phone',
                labelStyle: const TextStyle(color: KivoDarkTheme.textSecondary),
                prefixIcon: const Icon(Icons.person_pin, color: KivoDarkTheme.primaryEmerald, size: 20),
                filled: true,
                fillColor: KivoDarkTheme.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: KivoDarkTheme.surfaceBorder)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: KivoDarkTheme.surfaceBorder)),
              ),
            ),
            const SizedBox(height: 20),

            // 3. Amount Input & Quick Chips
            const Text(
              'Adjustment Amount (JMD)',
              style: TextStyle(color: KivoDarkTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: KivoDarkTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixText: 'JMD \$ ',
                prefixStyle: TextStyle(
                  color: _isCredit ? KivoDarkTheme.primaryEmerald : KivoDarkTheme.accentRose,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                hintText: '0.00',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: KivoDarkTheme.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: KivoDarkTheme.surfaceBorder)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: KivoDarkTheme.surfaceBorder)),
              ),
            ),
            const SizedBox(height: 10),

            // Quick Amount Chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickAmounts.map((amt) {
                return ActionChip(
                  label: Text('+\$${amt.toInt()}', style: const TextStyle(color: KivoDarkTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                  backgroundColor: KivoDarkTheme.surfaceElevated,
                  side: const BorderSide(color: KivoDarkTheme.surfaceBorder),
                  onPressed: () {
                    final cur = double.tryParse(_amountController.text) ?? 0.0;
                    _amountController.text = (cur + amt).toStringAsFixed(0);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // 4. Audit Reason & Presets
            const Text(
              'Mandatory Audit Reason / Memo',
              style: TextStyle(color: KivoDarkTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _reasonController,
              style: const TextStyle(color: KivoDarkTheme.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.edit_note, color: KivoDarkTheme.accentAmber, size: 20),
                filled: true,
                fillColor: KivoDarkTheme.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: KivoDarkTheme.surfaceBorder)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: KivoDarkTheme.surfaceBorder)),
              ),
            ),
            const SizedBox(height: 10),

            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _quickReasons.map((r) {
                final isSelected = _reasonController.text == r;
                return ChoiceChip(
                  label: Text(r, style: TextStyle(color: isSelected ? Colors.black : KivoDarkTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
                  selected: isSelected,
                  selectedColor: KivoDarkTheme.accentAmber,
                  backgroundColor: KivoDarkTheme.surface,
                  onSelected: (selected) {
                    if (selected) setState(() => _reasonController.text = r);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // 5. Submit Button
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _executeAdjustment,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isCredit ? KivoDarkTheme.primaryEmerald : KivoDarkTheme.accentRose,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: _isProcessing
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : Icon(_isCredit ? Icons.add_circle : Icons.remove_circle, size: 22),
              label: Text(
                _isCredit ? 'EXECUTE CREDIT ADJUSTMENT' : 'EXECUTE DEBIT ADJUSTMENT',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5),
              ),
            ),
            const SizedBox(height: 32),

            // 6. Real-time Audit History Stream
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Balance Audit Trail',
                  style: TextStyle(color: KivoDarkTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: KivoDarkTheme.primaryEmerald.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('LIVE SYNC ⚡', style: TextStyle(color: KivoDarkTheme.primaryEmerald, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (admin.auditLogs.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: KivoDarkTheme.surface, borderRadius: BorderRadius.circular(14)),
                child: const Center(
                  child: Text('No adjustments recorded yet.', style: TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 13)),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: admin.auditLogs.length,
                itemBuilder: (context, idx) {
                  final log = admin.auditLogs[idx];
                  final isCr = log.action == 'CREDIT';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: KivoDarkTheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: KivoDarkTheme.surfaceBorder),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: isCr ? KivoDarkTheme.primaryEmerald.withOpacity(0.2) : KivoDarkTheme.accentRose.withOpacity(0.2),
                          child: Icon(
                            isCr ? Icons.add : Icons.remove,
                            color: isCr ? KivoDarkTheme.primaryEmerald : KivoDarkTheme.accentRose,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(log.userName, style: const TextStyle(color: KivoDarkTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 2),
                              Text(log.reason, style: const TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 11)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${isCr ? "+" : "-"}JMD \$${log.amount.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: isCr ? KivoDarkTheme.primaryEmerald : KivoDarkTheme.accentRose,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(color: Colors.white30, fontSize: 10),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
