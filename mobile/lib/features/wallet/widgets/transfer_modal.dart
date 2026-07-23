import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/api_client.dart';
import '../../../core/services/auth_provider.dart';

class TransferModal extends StatefulWidget {
  const TransferModal({super.key});

  @override
  State<TransferModal> createState() => _TransferModalState();
}

class _TransferModalState extends State<TransferModal> {
  final _formKey = GlobalKey<FormState>();
  String _recipientHandle = '';
  double _amount = 0.0;
  String _note = '';
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _submitTransfer() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final apiClient = ApiClient(baseUrl: 'https://your-kivo-backend.com/api', authProvider: authProvider);

    try {
      // Execute the P2P transfer against the Cloud Run backend
      await apiClient.post('/wallet/transfer', {
        'senderId': authProvider.userId,
        // In a real app, you'd resolve the recipientHandle to their exact user ID first, 
        // or pass the handle to the backend and let the backend resolve it.
        'recipientId': _recipientHandle, 
        'amount': _amount,
        'note': _note,
      });

      if (mounted) {
        Navigator.pop(context, true); // Success
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16, right: 16, top: 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Send JMD', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.red.shade100,
                child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Recipient Kivo Handle'),
              validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              onSaved: (value) => _recipientHandle = value!,
            ),
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Amount (JMD)', prefixText: '\$'),
              keyboardType: TextInputType.number,
              validator: (value) => value == null || double.tryParse(value) == null ? 'Invalid amount' : null,
              onSaved: (value) => _amount = double.parse(value!),
            ),
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Note / Emoji'),
              onSaved: (value) => _note = value ?? '',
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitTransfer,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 16)),
              child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text('Send Payment', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
