import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart' as dotenv;

class ConfigService with ChangeNotifier {
  static const String _neuralNetworkApiUrlKey = 'neural_network_api_url';
  static final ConfigService _instance = ConfigService._internal();
  
  // Singleton pattern
  factory ConfigService() => _instance;
  
  ConfigService._internal();
  
  // Current API URL value
  String? _currentNeuralNetworkApiUrl;
  
  // Getter for the current API URL
  String get currentNeuralNetworkApiUrl => 
      _currentNeuralNetworkApiUrl ?? dotenv.dotenv.env['NEURAL_NETWORK_API_URL'] ?? 'http://192.168.178.109:8000';
  
  // Save the neural network API URL to persistent storage
  Future<bool> saveNeuralNetworkApiUrl(String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Update the local variable
      _currentNeuralNetworkApiUrl = url;
      
      // Update the environment variable
      dotenv.dotenv.env['NEURAL_NETWORK_API_URL'] = url;
      
      // Save to SharedPreferences
      final result = await prefs.setString(_neuralNetworkApiUrlKey, url);
      
      if (result) {
        notifyListeners();
      }
      
      return result;
    } catch (e) {
      debugPrint('Error saving neural network API URL: $e');
      return false;
    }
  }
  
  // Load the neural network API URL from persistent storage
  Future<String?> loadNeuralNetworkApiUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final url = prefs.getString(_neuralNetworkApiUrlKey);
      
      // Update local variable and environment variable if URL exists in SharedPreferences
      if (url != null && url.isNotEmpty) {
        _currentNeuralNetworkApiUrl = url;
        dotenv.dotenv.env['NEURAL_NETWORK_API_URL'] = url;
      }
      
      return url;
    } catch (e) {
      debugPrint('Error loading neural network API URL: $e');
      return null;
    }
  }
  
  // Initialize the configuration service
  Future<void> initialize() async {
    await loadNeuralNetworkApiUrl();
  }
}