import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/api_client.dart';
import '../../../core/services/auth_provider.dart';

class AccountingScreen extends StatefulWidget {
  const AccountingScreen({super.key});

  @override
  State<AccountingScreen> createState() => _AccountingScreenState();
}

class _AccountingScreenState extends State<AccountingScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _analytics;
  List<dynamic>? _ledger;

  @override
  void initState() {
    super.initState();
    _fetchAccountingData();
  }

  Future<void> _fetchAccountingData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final apiClient = ApiClient(baseUrl: 'https://your-kivo-backend.com/api', authProvider: authProvider);

    try {
      final response = await apiClient.get('/accounting/ledger');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _analytics = data['analytics'];
          _ledger = data['ledger'];
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load ledger');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounting & Analytics'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchAccountingData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text('Error: $_errorMessage', style: const TextStyle(color: Colors.red)))
              : Column(
                  children: [
                    _buildAnalyticsHeader(),
                    const Divider(),
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Transaction Ledger', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    Expanded(
                      child: _buildLedgerList(),
                    ),
                  ],
                ),
    );
  }

  Widget _buildAnalyticsHeader() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.green.shade50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCard('Inflow (JMD)', '\$${_analytics?['totalInflow'] ?? 0}', Colors.green),
          _buildStatCard('Outflow (JMD)', '\$${_analytics?['totalOutflow'] ?? 0}', Colors.red),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildLedgerList() {
    if (_ledger == null || _ledger!.isEmpty) {
      return const Center(child: Text('No transactions found.'));
    }

    return ListView.builder(
      itemCount: _ledger!.length,
      itemBuilder: (context, index) {
        final tx = _ledger![index];
        final isReceived = tx['type'] == 'RECEIVED';
        
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: isReceived ? Colors.green.shade100 : Colors.red.shade100,
            child: Icon(
              isReceived ? Icons.arrow_downward : Icons.arrow_upward,
              color: isReceived ? Colors.green : Colors.red,
            ),
          ),
          title: Text(isReceived ? 'Payment Received' : 'Payment Sent'),
          subtitle: Text('ID: ${tx['id'] ?? 'Unknown'}'),
          trailing: Text(
            '${isReceived ? '+' : '-'} \$${tx['amount'] ?? 0}',
            style: TextStyle(
              color: isReceived ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        );
      },
    );
  }
}
