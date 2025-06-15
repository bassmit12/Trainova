import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/secure_config.dart';

class ConfigService with ChangeNotifier {
  String? _currentNeuralNetworkApiUrl;
  String? _currentFeedbackApiUrl;

  // Initialize the configuration service
  Future<void> initialize() async {
    // Initialize secure config first
    await SecureConfig.instance.initialize();
    await _loadSavedUrls();
  }

  // Load saved URLs from secure storage
  Future<void> _loadSavedUrls() async {
    final prefs = await SharedPreferences.getInstance();
    _currentNeuralNetworkApiUrl = prefs.getString('NEURAL_NETWORK_API_URL');
    _currentFeedbackApiUrl = prefs.getString('FEEDBACK_API_URL');
    notifyListeners();
  }

  // Getter for the neural network API URL
  String get neuralNetworkApiUrl {
    // Use secure config instead of hardcoded fallbacks
    return SecureConfig.instance.neuralNetworkApiUrl;
  }

  // Getter for the feedback API URL
  String get feedbackApiUrl {
    return SecureConfig.instance.feedbackApiUrl;
  }

  // Update the neural network API URL
  Future<void> updateNeuralNetworkApiUrl(String url) async {
    await SecureConfig.instance.updateApiUrl('NEURAL_NETWORK_API_URL', url);
    _currentNeuralNetworkApiUrl = url;
    notifyListeners();
  }

  // Update the feedback API URL
  Future<void> updateFeedbackApiUrl(String url) async {
    await SecureConfig.instance.updateApiUrl('FEEDBACK_API_URL', url);
    _currentFeedbackApiUrl = url;
    notifyListeners();
  }
}
