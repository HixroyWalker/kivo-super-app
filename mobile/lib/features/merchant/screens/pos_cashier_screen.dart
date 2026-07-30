import 'package:flutter/material.dart';

class PosCashierScreen extends StatefulWidget {
  final String merchantName;
  final String staffName;

  const PosCashierScreen({
    super.key,
    required this.merchantName,
    required this.staffName,
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

  void _processPayment(String paymentMethod) {
    double amount = double.tryParse(_inputAmount) ?? 0.0;
    if (amount <= 0) return;

    final txId = 'POS-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    setState(() {
      _todaySales.insert(0, {
        'id': txId,
        'amount': amount,
        'method': paymentMethod,
        'time': DateTime.now().toString().split(' ')[1].substring(0, 5),
      });
      _inputAmount = '0';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment \$${amount.toStringAsFixed(2)} JMD Received via $paymentMethod ($txId) ✔'),
        backgroundColor: Colors.green,
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
            Text('Cashier: ${widget.staffName} (Role: POS Staff)', style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'Print Receipt (Thermal Printer)',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Printing Thermal Receipt via Bluetooth POS...')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.lock_person),
            tooltip: 'Exit POS Mode',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Row(
        children: [
          // Left Side: Charge Keypad
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Amount Display Screen
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Charge Amount (JMD)', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 8),
                        Text(
                          '\$$_inputAmount',
                          style: const TextStyle(color: Colors.greenAccent, fontSize: 36, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Keypad Grid
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 3,
                      childAspectRatio: 1.4,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      children: [
                        '1', '2', '3',
                        '4', '5', '6',
                        '7', '8', '9',
                        'C', '0', '⌫'
                      ].map((key) {
                        return ElevatedButton(
                          onPressed: () => _onKeyPress(key),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: (key == 'C' || key == '⌫') ? Colors.orange.shade800 : Colors.grey.shade800,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(key, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        );
                      }).toList(),
                    ),
                  ),

                  // Payment Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _processPayment('Kivo QR Code'),
                          icon: const Icon(Icons.qr_code_scanner),
                          label: const Text('Charge Kivo QR'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 54),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _processPayment('Cash / Lynk'),
                          icon: const Icon(Icons.payments),
                          label: const Text('Charge Cash/Lynk'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 54),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Right Side: Shift Sales Log (Sensitive Balances Hidden)
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.grey.shade100,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Shift Sales Log', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('Count: ${_todaySales.length}', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Shift Total Collected:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('\$${todayTotal.toStringAsFixed(2)} JMD',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade900, fontSize: 14)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _todaySales.length,
                      itemBuilder: (context, index) {
                        final sale = _todaySales[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            dense: true,
                            leading: const CircleAvatar(
                              radius: 14,
                              backgroundColor: Colors.green,
                              child: Icon(Icons.check, size: 16, color: Colors.white),
                            ),
                            title: Text('\$${sale['amount']} JMD', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${sale['method']} • ${sale['time']}'),
                            trailing: Text(sale['id'], style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
