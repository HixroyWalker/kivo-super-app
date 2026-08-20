import 'package:flutter/material.dart';
import '../../../core/theme/dark_theme.dart';

class PosCashierScreen extends StatefulWidget {
  final String merchantName;
  final String staffName;

  const PosCashierScreen({
    super.key,
    this.merchantName = 'Kivo Flagship Store',
    this.staffName = 'Cashier #01',
  });

  @override
  State<PosCashierScreen> createState() => _PosCashierScreenState();
}

class _PosCashierScreenState extends State<PosCashierScreen> {
  String _inputAmount = '0';
  final List<Map<String, dynamic>> _todaySales = [];

  void _onKeyPress(String key) {
    setState(() {
      if (key == 'C') {
        _inputAmount = '0';
      } else if (key == '⌫') {
        if (_inputAmount.length > 1) {
          _inputAmount = _inputAmount.substring(0, _inputAmount.length - 1);
        } else {
          _inputAmount = '0';
        }
      } else {
        if (_inputAmount == '0') {
          _inputAmount = key;
        } else {
          _inputAmount += key;
        }
      }
    });
  }

  void _showDynamicQRModal(double amount) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: KivoDarkTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Scan to Pay JMD \$${amount.toStringAsFixed(2)}',
              style: const TextStyle(color: KivoDarkTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text('Customer can scan with Kivo, Lynk, or NCB Jam-Dex', style: TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 12)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.qr_code_2, size: 200, color: Colors.black),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _processPayment('Kivo QR Dynamic');
              },
              child: const Text('Simulate Customer Payment Received'),
            ),
          ],
        ),
      ),
    );
  }

  void _processPayment(String paymentMethod) {
    double amount = double.tryParse(_inputAmount) ?? 0.0;
    if (amount <= 0) return;

    final txId = 'POS-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    setState(() {
      _todaySales.insert(0, {
        'id': txId,
        'amount': amount,
        'method': paymentMethod,
        'time': '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
      });
      _inputAmount = '0';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: KivoDarkTheme.surfaceElevated,
        content: Text(
          'Payment of JMD \$${amount.toStringAsFixed(2)} Received! ($txId)',
          style: const TextStyle(color: KivoDarkTheme.primaryEmerald, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double todayTotal = _todaySales.fold(0.0, (s, item) => s + (item['amount'] as double));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${widget.merchantName} POS', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('Cashier: ${widget.staffName}', style: const TextStyle(fontSize: 11, color: KivoDarkTheme.textSecondary)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'Print Receipt',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Printing Thermal Receipt via Bluetooth POS...')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Amount Screen
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: KivoDarkTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: KivoDarkTheme.primaryEmerald.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Charge Amount (JMD)', style: TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 12)),
                  const SizedBox(height: 6),
                  Text(
                    'JMD \$$_inputAmount',
                    style: const TextStyle(color: KivoDarkTheme.primaryEmerald, fontSize: 36, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Keypad Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              childAspectRatio: 1.6,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [
                '1', '2', '3',
                '4', '5', '6',
                '7', '8', '9',
                'C', '0', '⌫'
              ].map((key) {
                final isOrange = key == 'C' || key == '⌫';
                return ElevatedButton(
                  onPressed: () => _onKeyPress(key),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isOrange ? KivoDarkTheme.accentAmber.withOpacity(0.2) : KivoDarkTheme.surfaceElevated,
                    foregroundColor: isOrange ? KivoDarkTheme.accentAmber : KivoDarkTheme.textPrimary,
                    side: BorderSide(color: isOrange ? KivoDarkTheme.accentAmber.withOpacity(0.4) : KivoDarkTheme.surfaceBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(key, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // Payment Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final amt = double.tryParse(_inputAmount) ?? 0.0;
                      if (amt > 0) {
                        _showDynamicQRModal(amt);
                      }
                    },
                    icon: const Icon(Icons.qr_code_2),
                    label: const Text('Charge QR'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _processPayment('Cash / Lynk'),
                    icon: const Icon(Icons.payments_outlined),
                    label: const Text('Cash / Lynk'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Shift Sales Log
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: KivoDarkTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: KivoDarkTheme.surfaceBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Shift Total Collected', style: TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 13)),
                      Text('JMD \$${todayTotal.toStringAsFixed(2)}', style: const TextStyle(color: KivoDarkTheme.primaryEmerald, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  if (_todaySales.isNotEmpty) ...[
                    const Divider(color: KivoDarkTheme.surfaceBorder, height: 24),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _todaySales.length,
                      itemBuilder: (context, i) {
                        final s = _todaySales[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${s['method']} (${s['time']})', style: const TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 12)),
                              Text('+JMD \$${(s['amount'] as double).toStringAsFixed(2)}', style: const TextStyle(color: KivoDarkTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
