import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/services/voice_soundbox_service.dart';
import '../../../core/services/marketplace_provider.dart';
import '../../../core/models/product_model.dart';
import '../../../core/theme/dark_theme.dart';

class PosCashierScreen extends StatefulWidget {
  final String merchantName;
  final String staffName;

  const PosCashierScreen({
    super.key,
    this.merchantName = 'Kivo Flagship Store',
    this.staffName = 'Cashier #01 (Default)',
  });

  @override
  State<PosCashierScreen> createState() => _PosCashierScreenState();
}

class _PosCashierScreenState extends State<PosCashierScreen> {
  // Cashier State
  late String _currentCashier;
  final List<Map<String, String>> _cashiers = [
    {'name': 'Cashier #01 (Shenseea P.)', 'id': 'EMP-101', 'pin': '1234'},
    {'name': 'Cashier #02 (Marcus Sterling)', 'id': 'EMP-102', 'pin': '5678'},
    {'name': 'Manager (Admin Override)', 'id': 'EMP-001', 'pin': '9999'},
  ];

  // Mode: 0 = Store Catalog, 1 = Manual Keypad
  int _activeMode = 0;

  // Manual Keypad Amount
  String _inputAmount = '0';

  // Active Ticket / Cart for Store Products
  final Map<String, int> _ticketItems = {};

  // Today Sales Log
  final List<Map<String, dynamic>> _todaySales = [];

  String _searchProductQuery = '';
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _currentCashier = widget.staffName;
  }

  // Calculate ticket subtotal from store inventory
  double _calculateTicketSubtotal(List<ProductModel> products) {
    double total = 0.0;
    _ticketItems.forEach((productId, qty) {
      final p = products.firstWhere((item) => item.id == productId, orElse: () => products.first);
      total += p.price * qty;
    });
    return total;
  }

  double _getCurrentTotalAmount(List<ProductModel> products) {
    if (_activeMode == 0) {
      return _calculateTicketSubtotal(products);
    } else {
      return double.tryParse(_inputAmount) ?? 0.0;
    }
  }

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

  // Add/Remove item in ticket
  void _updateTicketItem(String productId, int delta) {
    setState(() {
      final current = _ticketItems[productId] ?? 0;
      final updated = current + delta;
      if (updated <= 0) {
        _ticketItems.remove(productId);
      } else {
        _ticketItems[productId] = updated;
      }
    });
  }

  void _clearTicket() {
    setState(() {
      _ticketItems.clear();
      _inputAmount = '0';
    });
  }

  // Cashier Management Dialog
  void _showCashierManagementModal() {
    final nameController = TextEditingController();
    final pinController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: KivoDarkTheme.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Select or Add Cashier', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ..._cashiers.map((c) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: _currentCashier == c['name'] ? KivoDarkTheme.primaryEmerald : KivoDarkTheme.surface,
                      child: Icon(Icons.person, color: _currentCashier == c['name'] ? Colors.black : Colors.white70),
                    ),
                    title: Text(c['name']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text('ID: ${c['id']} • PIN: ****', style: const TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 12)),
                    trailing: _currentCashier == c['name']
                        ? const Icon(Icons.check_circle, color: KivoDarkTheme.primaryEmerald)
                        : TextButton(
                            onPressed: () {
                              setState(() => _currentCashier = c['name']!);
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Switched active cashier to ${c['name']}')),
                              );
                            },
                            child: const Text('Switch', style: TextStyle(color: KivoDarkTheme.accentCyan)),
                          ),
                  )),
              const Divider(color: KivoDarkTheme.surfaceBorder),
              const Text('Create New Cashier Profile', style: TextStyle(color: KivoDarkTheme.accentCyan, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 10),
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Cashier Full Name', hintText: 'e.g. Usain Bolt'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: pinController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: '4-Digit Terminal Access PIN', hintText: '1234'),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () {
                  if (nameController.text.trim().isEmpty || pinController.text.trim().length < 4) return;
                  final newCashier = {
                    'name': 'Cashier #${_cashiers.length + 1} (${nameController.text.trim()})',
                    'id': 'EMP-${100 + _cashiers.length + 1}',
                    'pin': pinController.text.trim(),
                  };
                  setState(() {
                    _cashiers.add(newCashier);
                    _currentCashier = newCashier['name']!;
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('New cashier ${newCashier['name']} created and activated!')),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Save & Assign Cashier'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: KivoDarkTheme.primaryEmerald,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 44),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Show Payment Selector Modal (Cash vs Wallet QR)
  void _showPaymentModal(double amount, List<ProductModel> products) {
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select products or enter an amount first.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: KivoDarkTheme.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Collect Payment: JMD \$${amount.toStringAsFixed(2)}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text('Cashier: $_currentCashier', textAlign: TextAlign.center, style: const TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 12)),
            const SizedBox(height: 24),

            // Option 1: Cash Payment
            InkWell(
              onTap: () {
                Navigator.pop(ctx);
                _showCashTenderedModal(amount, products);
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: KivoDarkTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.greenAccent.withOpacity(0.4)),
                ),
                child: const Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Color(0x2600E676),
                      radius: 22,
                      child: Icon(Icons.payments_outlined, color: KivoDarkTheme.primaryEmerald, size: 24),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Cash Payment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('Enter cash received & calculate change', style: TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.white54),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Option 2: Live Dynamic QR Payment
            InkWell(
              onTap: () {
                Navigator.pop(ctx);
                _showLiveDynamicQRModal(amount, products);
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: KivoDarkTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: KivoDarkTheme.accentCyan.withOpacity(0.4)),
                ),
                child: const Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Color(0x2600E5FF),
                      radius: 22,
                      child: Icon(Icons.qr_code_2, color: KivoDarkTheme.accentCyan, size: 24),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Kivo / Jam-Dex Live QR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('Dynamic charge QR for Kivo & Lynk wallets', style: TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.white54),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Cash Tendered & Change Due Calculator Modal
  void _showCashTenderedModal(double amountDue, List<ProductModel> products) {
    final tenderedController = TextEditingController(text: amountDue.toStringAsFixed(0));
    double changeDue = 0.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: KivoDarkTheme.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setCashState) {
          final tendered = double.tryParse(tenderedController.text.trim()) ?? amountDue;
          changeDue = tendered >= amountDue ? tendered - amountDue : 0.0;

          return Padding(
            padding: EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Cash Tendered Calculator', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: KivoDarkTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Amount Due:', style: TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 14)),
                      Text('JMD \$${amountDue.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: tenderedController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: KivoDarkTheme.primaryEmerald, fontSize: 22, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    labelText: 'Cash Received (JMD)',
                    prefixText: 'JMD \$ ',
                    prefixStyle: TextStyle(color: KivoDarkTheme.primaryEmerald, fontWeight: FontWeight.bold),
                  ),
                  onChanged: (val) => setCashState(() {}),
                ),
                const SizedBox(height: 10),
                // Quick Cash Pills
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [amountDue, 1000.0, 2000.0, 5000.0, 10000.0].map((quickVal) {
                    return InkWell(
                      onTap: () {
                        setCashState(() {
                          tenderedController.text = quickVal.toStringAsFixed(0);
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: KivoDarkTheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: KivoDarkTheme.surfaceBorder),
                        ),
                        child: Text(
                          quickVal == amountDue ? 'Exact' : '\$${quickVal.toInt()}',
                          style: const TextStyle(color: KivoDarkTheme.accentCyan, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Change Due Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: KivoDarkTheme.primaryEmerald.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: KivoDarkTheme.primaryEmerald.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Change Due to Customer:', style: TextStyle(color: KivoDarkTheme.primaryEmerald, fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('JMD \$${changeDue.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                ElevatedButton.icon(
                  onPressed: tendered < amountDue
                      ? null
                      : () {
                          Navigator.pop(ctx);
                          _finalizeSale(
                            amount: amountDue,
                            paymentMethod: 'Cash',
                            cashTendered: tendered,
                            changeDue: changeDue,
                            products: products,
                          );
                        },
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Confirm Cash Sale & Issue Receipt'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KivoDarkTheme.primaryEmerald,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Live Dynamic QR Modal
  void _showLiveDynamicQRModal(double amount, List<ProductModel> products) {
    final orderId = 'POS-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final payload = 'kivo://pay?merchant=${Uri.encodeComponent(widget.merchantName)}&cashier=${Uri.encodeComponent(_currentCashier)}&amount=$amount&orderId=$orderId&currency=JMD';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: KivoDarkTheme.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Scan to Pay JMD \$${amount.toStringAsFixed(2)}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Dynamic QR code • Scan with Kivo, Lynk, or NCB Jam-Dex',
              textAlign: TextAlign.center,
              style: TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 20),

            // Dynamic Rendered QR Image
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: QrImageView(
                  data: payload,
                  version: QrVersions.auto,
                  size: 200.0,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _finalizeSale(
                  amount: amount,
                  paymentMethod: 'Kivo / Jam-Dex QR',
                  products: products,
                );
              },
              icon: const Icon(Icons.bolt),
              label: const Text('Simulate Customer Payment Received'),
              style: ElevatedButton.styleFrom(
                backgroundColor: KivoDarkTheme.primaryEmerald,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Finalize Sale, Trigger Voice Soundbox & Log
  void _finalizeSale({
    required double amount,
    required String paymentMethod,
    double? cashTendered,
    double? changeDue,
    required List<ProductModel> products,
  }) {
    final txId = 'POS-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    // Compile line items
    final List<Map<String, dynamic>> itemsList = [];
    if (_activeMode == 0 && _ticketItems.isNotEmpty) {
      _ticketItems.forEach((productId, qty) {
        final p = products.firstWhere((item) => item.id == productId, orElse: () => products.first);
        itemsList.add({
          'name': p.name,
          'qty': qty,
          'unitPrice': p.price,
          'total': p.price * qty,
        });
      });
    } else {
      itemsList.add({
        'name': 'Custom POS Charge',
        'qty': 1,
        'unitPrice': amount,
        'total': amount,
      });
    }

    final saleRecord = {
      'id': txId,
      'amount': amount,
      'method': paymentMethod,
      'cashier': _currentCashier,
      'time': '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
      'date': '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}',
      'cashTendered': cashTendered,
      'changeDue': changeDue,
      'items': itemsList,
    };

    setState(() {
      _todaySales.insert(0, saleRecord);
      _clearTicket();
    });

    // Announce via Soundbox speaker
    try {
      context.read<VoiceSoundboxService>().announcePayment(
        amountJMD: amount,
        senderName: 'Customer',
      );
    } catch (_) {}

    _showReceiptActionModal(saleRecord);
  }

  // Post-Sale Receipt Modal (Print / Save PDF / Share)
  void _showReceiptActionModal(Map<String, dynamic> saleRecord) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: KivoDarkTheme.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.check_circle, color: KivoDarkTheme.primaryEmerald, size: 54),
            const SizedBox(height: 12),
            Text(
              'Payment Received: JMD \$${(saleRecord['amount'] as double).toStringAsFixed(2)}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text('Transaction ID: ${saleRecord['id']}', textAlign: TextAlign.center, style: const TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 12)),
            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _printReceiptPdf(saleRecord);
              },
              icon: const Icon(Icons.print),
              label: const Text('Print Receipt (AirPrint / Bluetooth)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: KivoDarkTheme.primaryEmerald,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 10),

            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _shareReceiptPdf(saleRecord);
              },
              icon: const Icon(Icons.share, color: KivoDarkTheme.accentCyan),
              label: const Text('Email / Share PDF to Client', style: TextStyle(color: KivoDarkTheme.accentCyan)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: KivoDarkTheme.accentCyan),
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Generate PDF Invoice Document
  Future<pw.Document> _buildReceiptPdfDocument(Map<String, dynamic> sale) async {
    final pdf = pw.Document();
    final items = sale['items'] as List<dynamic>? ?? [];
    final double amount = (sale['amount'] as num?)?.toDouble() ?? 0.0;
    final double subtotal = amount / 1.15;
    final double gct = amount - subtotal;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(child: pw.Text(widget.merchantName, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold))),
              pw.Center(child: pw.Text('Kingston, Jamaica • TAJ GCT Reg: #102-948-311', style: const pw.TextStyle(fontSize: 9))),
              pw.Divider(thickness: 1),
              pw.Text('Date: ${sale['date']} ${sale['time']}', style: const pw.TextStyle(fontSize: 9)),
              pw.Text('Receipt #: ${sale['id']}', style: const pw.TextStyle(fontSize: 9)),
              pw.Text('Cashier: ${sale['cashier']}', style: const pw.TextStyle(fontSize: 9)),
              pw.Text('Payment: ${sale['method']}', style: const pw.TextStyle(fontSize: 9)),
              pw.Divider(thickness: 1),
              pw.Text('ITEMS', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              ...items.map((item) => pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('${item['qty']}x ${item['name']}', style: const pw.TextStyle(fontSize: 9)),
                      pw.Text('\$${(item['total'] as num).toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 9)),
                    ],
                  )),
              pw.Divider(thickness: 1),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Subtotal (excl. GCT):', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text('JMD \$${subtotal.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('15% Standard GCT Tax:', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text('JMD \$${gct.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL PAID:', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.Text('JMD \$${amount.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              if (sale['cashTendered'] != null) ...[
                pw.SizedBox(height: 4),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Cash Tendered:', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text('JMD \$${(sale['cashTendered'] as num).toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Change Given:', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text('JMD \$${(sale['changeDue'] as num).toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
              ],
              pw.Divider(thickness: 1),
              pw.Center(child: pw.Text('Thank you for your business! 🇯🇲', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
              pw.Center(child: pw.Text('Powered by Kivo Super App', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700))),
            ],
          );
        },
      ),
    );
    return pdf;
  }

  // Trigger AirPrint / Thermal Print
  Future<void> _printReceiptPdf(Map<String, dynamic> sale) async {
    final pdf = await _buildReceiptPdfDocument(sale);
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  // Share / Email PDF to client without wallet
  Future<void> _shareReceiptPdf(Map<String, dynamic> sale) async {
    final pdf = await _buildReceiptPdfDocument(sale);
    final bytes = await pdf.save();
    await Printing.sharePdf(bytes: bytes, filename: 'Kivo_Receipt_${sale['id']}.pdf');
  }

  void _showSoundboxSettings() {
    final soundbox = context.read<VoiceSoundboxService>();
    showModalBottomSheet(
      context: context,
      backgroundColor: KivoDarkTheme.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('🔊 Merchant Audio Soundbox', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  Switch(
                    value: soundbox.isEnabled,
                    activeColor: KivoDarkTheme.primaryEmerald,
                    onChanged: (val) {
                      soundbox.toggleSoundbox(val);
                      setModalState(() {});
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Announces incoming QR and Lynk customer payments aloud through the device speaker.',
                style: TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => soundbox.testAnnouncement(),
                icon: const Icon(Icons.volume_up),
                label: const Text('Test Voice Announcement'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: KivoDarkTheme.primaryEmerald,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 44),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final marketplace = context.watch<MarketplaceProvider>();
    final products = marketplace.products;
    final filteredProducts = products.where((p) {
      final matchesQuery = p.name.toLowerCase().contains(_searchProductQuery.toLowerCase());
      final matchesCategory = _selectedCategory == 'All' || p.category == _selectedCategory;
      return matchesQuery && matchesCategory;
    }).toList();

    final currentTotal = _getCurrentTotalAmount(products);

    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: _showCashierManagementModal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${widget.merchantName} POS', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Text(_currentCashier, style: const TextStyle(fontSize: 11, color: KivoDarkTheme.accentCyan)),
                  const Icon(Icons.arrow_drop_down, color: KivoDarkTheme.accentCyan, size: 16),
                ],
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up_outlined, color: KivoDarkTheme.primaryEmerald),
            tooltip: 'Soundbox Settings',
            onPressed: _showSoundboxSettings,
          ),
          IconButton(
            icon: const Icon(Icons.person_add_outlined, color: Colors.white),
            tooltip: 'Add / Switch Cashier',
            onPressed: _showCashierManagementModal,
          ),
        ],
      ),
      body: Column(
        children: [
          // Mode Switcher: Store Catalog vs Keypad
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: KivoDarkTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: KivoDarkTheme.surfaceBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _activeMode = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _activeMode == 0 ? KivoDarkTheme.primaryEmerald.withOpacity(0.2) : Colors.transparent,
                        borderRadius: BorderRadius.circular(11),
                        border: _activeMode == 0 ? Border.all(color: KivoDarkTheme.primaryEmerald) : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.storefront, size: 18, color: _activeMode == 0 ? KivoDarkTheme.primaryEmerald : KivoDarkTheme.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            'Store Catalog 🛍️',
                            style: TextStyle(
                              color: _activeMode == 0 ? KivoDarkTheme.primaryEmerald : KivoDarkTheme.textSecondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _activeMode = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _activeMode == 1 ? KivoDarkTheme.accentCyan.withOpacity(0.2) : Colors.transparent,
                        borderRadius: BorderRadius.circular(11),
                        border: _activeMode == 1 ? Border.all(color: KivoDarkTheme.accentCyan) : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.dialpad, size: 18, color: _activeMode == 1 ? KivoDarkTheme.accentCyan : KivoDarkTheme.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            'Keypad 🔢',
                            style: TextStyle(
                              color: _activeMode == 1 ? KivoDarkTheme.accentCyan : KivoDarkTheme.textSecondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main Screen Content based on Active Mode
          Expanded(
            child: _activeMode == 0
                ? _buildStoreCatalogView(filteredProducts, products)
                : _buildKeypadView(),
          ),

          // Bottom Charge & Checkout Bar
          _buildCheckoutBar(currentTotal, products),
        ],
      ),
    );
  }

  Widget _buildStoreCatalogView(List<ProductModel> filtered, List<ProductModel> allProducts) {
    return Column(
      children: [
        // Search & Category Filters
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: TextField(
            onChanged: (val) => setState(() => _searchProductQuery = val),
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Search products in store...',
              prefixIcon: const Icon(Icons.search, size: 18, color: KivoDarkTheme.textSecondary),
              filled: true,
              fillColor: KivoDarkTheme.surface,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ),

        // Product Grid
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('No matching products found in store inventory.', style: TextStyle(color: KivoDarkTheme.textSecondary)))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final p = filtered[index];
                    final inTicket = _ticketItems[p.id] ?? 0;

                    return Container(
                      decoration: BoxDecoration(
                        color: KivoDarkTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: inTicket > 0 ? KivoDarkTheme.primaryEmerald : KivoDarkTheme.surfaceBorder,
                          width: inTicket > 0 ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                                  child: CachedNetworkImage(
                                    imageUrl: p.imageUrl,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                if (inTicket > 0)
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: KivoDarkTheme.primaryEmerald,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '$inTicket',
                                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                const SizedBox(height: 2),
                                Text('JMD \$${p.price.toStringAsFixed(2)}', style: const TextStyle(color: KivoDarkTheme.primaryEmerald, fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    if (inTicket > 0)
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline, color: KivoDarkTheme.accentRose, size: 20),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () => _updateTicketItem(p.id, -1),
                                      ),
                                    const Spacer(),
                                    ElevatedButton(
                                      onPressed: () => _updateTicketItem(p.id, 1),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: KivoDarkTheme.primaryEmerald,
                                        foregroundColor: Colors.black,
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      child: const Text('+ Add', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildKeypadView() {
    return SingleChildScrollView(
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
                const Text('Custom Charge Amount (JMD)', style: TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 12)),
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
              final isAction = key == 'C' || key == '⌫';
              return ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isAction ? KivoDarkTheme.surfaceElevated : KivoDarkTheme.surface,
                  foregroundColor: isAction ? KivoDarkTheme.accentRose : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: KivoDarkTheme.surfaceBorder),
                  ),
                ),
                onPressed: () => _onKeyPress(key),
                child: Text(key, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutBar(double totalAmount, List<ProductModel> products) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KivoDarkTheme.surfaceElevated,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _activeMode == 0 ? 'Ticket Total (${_ticketItems.values.fold(0, (a, b) => a + b)} items)' : 'Total Charge',
                    style: const TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 12),
                  ),
                  Text(
                    'JMD \$${totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              if (_ticketItems.isNotEmpty || _inputAmount != '0')
                TextButton(
                  onPressed: _clearTicket,
                  child: const Text('Clear', style: TextStyle(color: KivoDarkTheme.accentRose, fontSize: 12)),
                ),
              ElevatedButton.icon(
                onPressed: totalAmount <= 0 ? null : () => _showPaymentModal(totalAmount, products),
                icon: const Icon(Icons.point_of_sale, size: 20),
                label: const Text('Charge & Pay'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: KivoDarkTheme.primaryEmerald,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
