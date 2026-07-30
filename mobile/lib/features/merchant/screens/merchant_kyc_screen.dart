import 'package:flutter/material.dart';

class MerchantKYCScreen extends StatefulWidget {
  const MerchantKYCScreen({super.key});

  @override
  State<MerchantKYCScreen> createState() => _MerchantKYCScreenState();
}

class _MerchantKYCScreenState extends State<MerchantKYCScreen> {
  final _companyNameController = TextEditingController(text: "Kingston Traders Ltd");
  final _trnController = TextEditingController(text: "123-456-789");
  
  bool _cojUploaded = true;
  bool _directorIdUploaded = true;
  bool _proofAddressUploaded = true;
  String _kycStatus = "PENDING_VERIFICATION"; // UNVERIFIED, PENDING_VERIFICATION, VERIFIED

  void _submitKYC() {
    setState(() {
      _kycStatus = "VERIFIED";
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('KYC Submitted! Verified automatically via AIV AI Engine ✔')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Merchant Business KYC'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _kycStatus == "VERIFIED" ? Colors.green.shade50 : Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kycStatus == "VERIFIED" ? Colors.green : Colors.amber),
              ),
              child: Row(
                children: [
                  Icon(
                    _kycStatus == "VERIFIED" ? Icons.verified : Icons.pending_actions,
                    color: _kycStatus == "VERIFIED" ? Colors.green : Colors.amber.shade900,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _kycStatus == "VERIFIED" ? 'Merchant Account Verified ✔' : 'Verification Pending',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _kycStatus == "VERIFIED" ? Colors.green.shade900 : Colors.amber.shade900,
                          ),
                        ),
                        Text(
                          _kycStatus == "VERIFIED"
                              ? 'Your business registration is verified with TAJ & COJ.'
                              : 'Upload required documents for AI & Admin review.',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Business Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            TextField(
              controller: _companyNameController,
              decoration: const InputDecoration(labelText: 'Registered Business Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _trnController,
              decoration: const InputDecoration(labelText: 'Tax Registration Number (TRN)'),
            ),
            const SizedBox(height: 24),
            const Text('Required Business Documents', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            _buildDocTile('COJ Certificate of Incorporation', _cojUploaded, () {
              setState(() => _cojUploaded = true);
            }),
            _buildDocTile('Director Government ID / Passport', _directorIdUploaded, () {
              setState(() => _directorIdUploaded = true);
            }),
            _buildDocTile('Proof of Business Address (Utility Bill)', _proofAddressUploaded, () {
              setState(() => _proofAddressUploaded = true);
            }),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _submitKYC,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                child: const Text('Submit Business KYC for Review', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocTile(String title, bool isUploaded, VoidCallback onUpload) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(isUploaded ? Icons.check_circle : Icons.upload_file, color: isUploaded ? Colors.green : Colors.grey),
        title: Text(title, style: const TextStyle(fontSize: 14)),
        subtitle: Text(isUploaded ? 'Document Attached ✔' : 'Tap to upload PDF/Image'),
        trailing: isUploaded ? null : TextButton(onPressed: onUpload, child: const Text('Upload')),
      ),
    );
  }
}
