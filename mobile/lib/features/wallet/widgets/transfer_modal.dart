import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';
import '../../../core/theme/dark_theme.dart';
import '../../../core/services/wallet_provider.dart';
import '../../../core/services/recurring_transfer_service.dart';
import '../../../core/models/recurring_transfer_model.dart';

class TransferModal extends StatefulWidget {
  const TransferModal({super.key});

  @override
  State<TransferModal> createState() => _TransferModalState();
}

class _TransferModalState extends State<TransferModal> {
  final _formKey = GlobalKey<FormState>();
  final _recipientController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isLoading = false;
  String? _errorMessage;

  // Recurring transfer state
  bool _isRecurring = false;
  RecurringFrequency _frequency = RecurringFrequency.monthly;

  final List<String> _recentContacts = [
    'Marcus Sterling',
    'Shenseea P.',
    'Mavis Bank Agro',
    'Island Grocers',
  ];

  Future<void> _submitTransfer() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _errorMessage = 'Please enter a valid amount');
      return;
    }

    final recipient = _recipientController.text.trim();
    final note = _noteController.text.trim();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // 1. Biometric verification if available
    try {
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      if (canCheckBiometrics) {
        final bool didAuthenticate = await _localAuth.authenticate(
          localizedReason: 'Authorize JMD \$${amount.toStringAsFixed(2)} transfer to $recipient',
          options: const AuthenticationOptions(biometricOnly: false),
        );
        if (!didAuthenticate) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Biometric authentication cancelled';
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('Biometric fallback: $e');
    }

    // 2. Execute transfer via WalletProvider
    final wallet = context.read<WalletProvider>();
    final success = wallet.sendMoney(recipient, amount, note.isEmpty ? 'P2P Transfer' : note);

    if (success) {
      // 3. If Recurring is selected, register schedule
      if (_isRecurring) {
        try {
          await context.read<RecurringTransferService>().createSchedule(
            recipientIdentifier: recipient.toLowerCase().replaceAll(' ', '_') + '@kivowebb.app',
            recipientName: recipient,
            amount: amount,
            frequency: _frequency,
            startDate: DateTime.now(),
            note: note.isEmpty ? 'Recurring Transfer' : note,
          );
        } catch (e) {
          debugPrint('Failed to save recurring schedule: $e');
        }
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: KivoDarkTheme.surfaceElevated,
            content: Text(
              _isRecurring
                  ? 'Sent JMD \$${amount.toStringAsFixed(2)} to $recipient and scheduled ${_frequency.name.toUpperCase()} recurring transfer! 🔁'
                  : 'Successfully sent JMD \$${amount.toStringAsFixed(2)} to $recipient! 🎉',
              style: const TextStyle(color: KivoDarkTheme.primaryEmerald, fontWeight: FontWeight.bold),
            ),
          ),
        );
      }
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Insufficient wallet balance for this transfer';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 20,
      ),
      decoration: const BoxDecoration(
        color: KivoDarkTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.send_rounded, color: KivoDarkTheme.primaryEmerald),
                  SizedBox(width: 10),
                  Text(
                    'Instant P2P Transfer',
                    style: TextStyle(
                      color: KivoDarkTheme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: KivoDarkTheme.accentRose.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: KivoDarkTheme.accentRose.withOpacity(0.3)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: KivoDarkTheme.accentRose, fontSize: 13),
                  ),
                ),

              // Recent contacts picker
              const Text('Recent Recipients', style: TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 12)),
              const SizedBox(height: 8),
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _recentContacts.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _recipientController.text = _recentContacts[i];
                        });
                      },
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: KivoDarkTheme.surfaceElevated,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: KivoDarkTheme.surfaceBorder),
                        ),
                        child: Text(
                          _recentContacts[i],
                          style: const TextStyle(color: KivoDarkTheme.textPrimary, fontSize: 12),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _recipientController,
                style: const TextStyle(color: KivoDarkTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Recipient Name or @handle',
                  prefixIcon: Icon(Icons.person_outline, color: KivoDarkTheme.textSecondary),
                ),
                validator: (value) => value == null || value.trim().isEmpty ? 'Enter a recipient' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: KivoDarkTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  labelText: 'Amount (JMD)',
                  prefixText: 'JMD \$ ',
                  prefixStyle: TextStyle(color: KivoDarkTheme.primaryEmerald, fontWeight: FontWeight.bold),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Enter amount';
                  if (double.tryParse(value) == null) return 'Invalid amount';
                  return null;
                },
              ),
              const SizedBox(height: 10),

              // Quick amount pills
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [500, 1000, 2500, 5000].map((amt) {
                  return InkWell(
                    onTap: () => setState(() => _amountController.text = amt.toString()),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: KivoDarkTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: KivoDarkTheme.surfaceBorder),
                      ),
                      child: Text('+\$$amt', style: const TextStyle(color: KivoDarkTheme.accentCyan, fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _noteController,
                style: const TextStyle(color: KivoDarkTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Note / Reason (e.g. Lunch, Groceries 🍔)',
                  prefixIcon: Icon(Icons.note_alt_outlined, color: KivoDarkTheme.textSecondary),
                ),
              ),
              const SizedBox(height: 16),

              // Recurring Transfer Toggle Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: KivoDarkTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _isRecurring ? KivoDarkTheme.primaryEmerald.withOpacity(0.4) : KivoDarkTheme.surfaceBorder,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.autorenew, color: KivoDarkTheme.primaryEmerald, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Make this a recurring transfer',
                              style: TextStyle(color: KivoDarkTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        Switch(
                          value: _isRecurring,
                          activeColor: KivoDarkTheme.primaryEmerald,
                          onChanged: (val) => setState(() => _isRecurring = val),
                        ),
                      ],
                    ),
                    if (_isRecurring) ...[
                      const Divider(color: KivoDarkTheme.surfaceBorder),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Frequency:', style: TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 12)),
                          DropdownButton<RecurringFrequency>(
                            value: _frequency,
                            dropdownColor: KivoDarkTheme.surfaceElevated,
                            underline: const SizedBox(),
                            style: const TextStyle(color: KivoDarkTheme.accentCyan, fontWeight: FontWeight.bold, fontSize: 13),
                            items: const [
                              DropdownMenuItem(value: RecurringFrequency.daily, child: Text('Daily')),
                              DropdownMenuItem(value: RecurringFrequency.weekly, child: Text('Weekly')),
                              DropdownMenuItem(value: RecurringFrequency.fortnightly, child: Text('Fortnightly (Every 2 wks)')),
                              DropdownMenuItem(value: RecurringFrequency.monthly, child: Text('Monthly')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _frequency = val);
                            },
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton.icon(
                onPressed: _isLoading ? null : _submitTransfer,
                icon: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : Icon(_isRecurring ? Icons.schedule_send : Icons.lock_outline, size: 20),
                label: Text(_isLoading
                    ? 'Authorizing...'
                    : _isRecurring
                        ? 'Authorize & Schedule Recurring Transfer'
                        : 'Authorize & Send Payment'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
