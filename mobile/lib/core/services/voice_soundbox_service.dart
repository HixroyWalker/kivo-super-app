import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class VoiceSoundboxService extends ChangeNotifier {
  final FlutterTts _flutterTts = FlutterTts();

  bool _isEnabled = true;
  double _volume = 1.0;
  double _rate = 0.5; // Optimal natural speaking rate
  double _pitch = 1.0;

  bool get isEnabled => _isEnabled;
  double get volume => _volume;
  double get rate => _rate;

  VoiceSoundboxService() {
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(_rate);
      await _flutterTts.setVolume(_volume);
      await _flutterTts.setPitch(_pitch);
    } catch (e) {
      debugPrint("VoiceSoundbox initialization error: $e");
    }
  }

  void toggleSoundbox(bool enabled) {
    _isEnabled = enabled;
    notifyListeners();
  }

  void setVolume(double vol) {
    _volume = vol;
    _flutterTts.setVolume(vol);
    notifyListeners();
  }

  void setRate(double r) {
    _rate = r;
    _flutterTts.setSpeechRate(r);
    notifyListeners();
  }

  /// Announce an incoming payment aloud through device speaker
  Future<void> announcePayment({
    required double amountJMD,
    required String senderName,
  }) async {
    if (!_isEnabled) return;

    try {
      final formattedAmount = amountJMD.toStringAsFixed(0);
      final announcement = "Received $formattedAmount dollars from $senderName via Kivo Pay.";
      await _flutterTts.speak(announcement);
    } catch (e) {
      debugPrint("Error announcing payment via TTS: $e");
    }
  }

  /// Test voice announcement for merchant preview
  Future<void> testAnnouncement() async {
    await announcePayment(amountJMD: 2500.0, senderName: "Jason Campbell");
  }
}
