import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_colors.dart';
import '../widgets/message_overlay.dart';

class NetworkSelectionScreen extends StatefulWidget {
  const NetworkSelectionScreen({Key? key}) : super(key: key);

  @override
  State<NetworkSelectionScreen> createState() => _NetworkSelectionScreenState();
}

class _NetworkSelectionScreenState extends State<NetworkSelectionScreen> {
  String _selectedNetwork = 'feedback'; // Default to feedback network
  String _feedbackNetworkUrl = '';
  String _neuralNetworkUrl = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNetworkSettings();
  }

  Future<void> _loadNetworkSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      setState(() {
        _feedbackNetworkUrl = 'http://143.179.147.112:5009';
        _neuralNetworkUrl = 'http://143.179.147.112:5010';
        _selectedNetwork = prefs.getString('selected_network') ?? 'feedback';
        _isLoading = false;
      });

      // Update the environment configuration based on selected network
      await _updateActiveNetwork();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        MessageOverlay.showError(
          context,
          message: 'Failed to load network settings: $e',
        );
      }
    }
  }

  Future<void> _updateActiveNetwork() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Use separate keys for active network URLs to avoid conflicts with other systems
      if (_selectedNetwork == 'feedback') {
        await prefs.setString('ACTIVE_NETWORK_URL', _feedbackNetworkUrl);
        await prefs.setString('ACTIVE_NETWORK_TYPE', 'feedback');
      } else {
        await prefs.setString('ACTIVE_NETWORK_URL', _neuralNetworkUrl);
        await prefs.setString('ACTIVE_NETWORK_TYPE', 'neural');
      }

      await prefs.setString('selected_network', _selectedNetwork);
    } catch (e) {
      if (mounted) {
        MessageOverlay.showError(
          context,
          message: 'Failed to update network settings: $e',
        );
      }
    }
  }

  Future<void> _switchNetwork(String networkType) async {
    setState(() {
      _selectedNetwork = networkType;
    });

    await _updateActiveNetwork();

    if (mounted) {
      final networkName =
          networkType == 'feedback' ? 'Feedback Network' : 'Neural Network';
      MessageOverlay.showSuccess(context, message: 'Switched to $networkName');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Network Selection')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Network Selection'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Active Network',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose which network to use for workout predictions and feedback.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),

            // Feedback Network Card
            _buildNetworkCard(
              title: 'Feedback Network',
              subtitle: 'Advanced feedback-based prediction system',
              ipAddress: _feedbackNetworkUrl,
              networkType: 'feedback',
              icon: Icons.feedback,
              isSelected: _selectedNetwork == 'feedback',
            ),

            const SizedBox(height: 16),

            // Neural Network Card
            _buildNetworkCard(
              title: 'Neural Network',
              subtitle: 'Traditional neural network prediction model',
              ipAddress: _neuralNetworkUrl,
              networkType: 'neural',
              icon: Icons.psychology,
              isSelected: _selectedNetwork == 'neural',
            ),

            const SizedBox(height: 32),

            // Current Selection Info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Current Selection',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedNetwork == 'feedback'
                        ? 'Feedback Network is currently active'
                        : 'Neural Network is currently active',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Active URL: ${_selectedNetwork == 'feedback' ? _feedbackNetworkUrl : _neuralNetworkUrl}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkCard({
    required String title,
    required String subtitle,
    required String ipAddress,
    required String networkType,
    required IconData icon,
    required bool isSelected,
  }) {
    return Card(
      elevation: isSelected ? 4 : 2,
      child: InkWell(
        onTap: () => _switchNetwork(networkType),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border:
                isSelected
                    ? Border.all(color: AppColors.primary, width: 2)
                    : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? AppColors.primary.withOpacity(0.1)
                                    : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            icon,
                            color: isSelected ? AppColors.primary : Colors.grey,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? AppColors.primary : null,
                                ),
                              ),
                              Text(
                                subtitle,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'ACTIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'IP Address:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ipAddress,
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
