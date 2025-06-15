import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/secure_config.dart';
import '../utils/app_colors.dart';
import '../utils/error_handler.dart';
import '../utils/loading_state_manager.dart';
import '../widgets/message_overlay.dart';

class NetworkSelectionScreen extends StatefulWidget {
  const NetworkSelectionScreen({Key? key}) : super(key: key);

  @override
  State<NetworkSelectionScreen> createState() => _NetworkSelectionScreenState();
}

class _NetworkSelectionScreenState extends State<NetworkSelectionScreen>
    with LoadingStateMixin {
  String _selectedNetwork = 'feedback'; // Default to feedback network
  String _feedbackNetworkUrl = '';
  String _neuralNetworkUrl = '';

  @override
  void initState() {
    super.initState();
    _loadNetworkSettings();
  }

  Future<void> _loadNetworkSettings() async {
    await executeWithLoading(
      'load_networks',
      () async {
        // Load URLs from secure configuration instead of hardcoded values
        _feedbackNetworkUrl = SecureConfig.instance.feedbackApiUrl;
        _neuralNetworkUrl = SecureConfig.instance.neuralNetworkApiUrl;

        final prefs = await SharedPreferences.getInstance();
        _selectedNetwork = prefs.getString('selected_network') ?? 'feedback';

        // Update the environment configuration based on selected network
        await _updateActiveNetwork();
      },
      loadingMessage: 'Loading network configuration...',
      onError: (error) {
        context.handleError(
          AppError.storage(
            'Failed to load network settings',
            technicalDetails: error,
            userAction: 'Please check your network configuration in settings.',
          ),
        );
      },
    );
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
      context.handleError(
        AppError.storage(
          'Failed to update network settings',
          technicalDetails: e.toString(),
          userAction: 'Please try again or restart the app.',
        ),
      );
    }
  }

  Future<void> _switchNetwork(String networkType) async {
    await executeWithLoading(
      'switch_network',
      () async {
        setState(() {
          _selectedNetwork = networkType;
        });

        await _updateActiveNetwork();

        if (mounted) {
          final networkName =
              networkType == 'feedback' ? 'Feedback Network' : 'Neural Network';
          MessageOverlay.showSuccess(
            context,
            message: 'Switched to $networkName',
          );
        }
      },
      type: LoadingType.save,
      loadingMessage: 'Switching network...',
      onError: (error) {
        context.handleError(
          AppError.network(
            'Failed to switch network',
            technicalDetails: error,
            userAction:
                'Please check your network configuration and try again.',
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LoadingStateManager>(
      builder: (context, loadingManager, child) {
        return LoadingOverlay(
          loadingState: loadingManager.getLoadingState('load_networks'),
          child: Scaffold(
            appBar: AppBar(title: const Text('Network Selection')),
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
                    url: _feedbackNetworkUrl,
                    networkType: 'feedback',
                    icon: Icons.feedback,
                    isSelected: _selectedNetwork == 'feedback',
                    loadingManager: loadingManager,
                  ),

                  const SizedBox(height: 16),

                  // Neural Network Card
                  _buildNetworkCard(
                    title: 'Neural Network',
                    subtitle: 'Traditional neural network prediction model',
                    url: _neuralNetworkUrl,
                    networkType: 'neural',
                    icon: Icons.psychology,
                    isSelected: _selectedNetwork == 'neural',
                    loadingManager: loadingManager,
                  ),

                  const SizedBox(height: 32),

                  // Current Selection Info
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                      ),
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
          ),
        );
      },
    );
  }

  Widget _buildNetworkCard({
    required String title,
    required String subtitle,
    required String url,
    required String networkType,
    required IconData icon,
    required bool isSelected,
    required LoadingStateManager loadingManager,
  }) {
    final isLoading = loadingManager.isLoading('switch_network');

    return Card(
      elevation: isSelected ? 4 : 2,
      child: InkWell(
        onTap: isLoading ? null : () => _switchNetwork(networkType),
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
                      'URL:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      url.isNotEmpty ? url : 'Not configured',
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'monospace',
                        color: url.isNotEmpty ? null : Colors.red,
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
