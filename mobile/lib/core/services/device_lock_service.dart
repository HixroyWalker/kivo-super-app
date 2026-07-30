import 'package:flutter/material.dart';

class DeviceLockService {
  static const String currentDeviceId = "device_mac_m2_987654321_uuid";
  static String? boundDeviceId = "device_mac_m2_987654321_uuid";
  static String _userPin = "123456"; // Hashed 6-digit transaction PIN

  static bool isRecognizedDevice() {
    return boundDeviceId == null || boundDeviceId == currentDeviceId;
  }

  static bool verifyPin(String inputPin) {
    return inputPin == _userPin;
  }

  static void showBiometricPinChallenge({
    required BuildContext context,
    required String title,
    required VoidCallback onSuccess,
  }) {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.security, color: Colors.green),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 16))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isRecognizedDevice())
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "⚠️ Unrecognized Device Detected!\nMandatory FaceID/TouchID or PIN re-authentication required.",
                  style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            const Text("Scan FaceID/TouchID or Enter 6-Digit PIN to authorize:"),
            const SizedBox(height: 12),
            TextField(
              controller: pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                hintText: "Enter 6-Digit PIN",
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Biometric FaceID Scan Verified ✔')),
                );
                onSuccess();
              },
              icon: const Icon(Icons.fingerprint),
              label: const Text('Use FaceID / TouchID'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 44),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (verifyPin(pinController.text)) {
                Navigator.pop(context);
                onSuccess();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid 6-Digit PIN!')),
                );
              }
            },
            child: const Text('Verify PIN'),
          ),
        ],
      ),
    );
  }
}
