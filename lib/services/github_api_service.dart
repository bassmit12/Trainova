import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:version/version.dart';
import 'package:package_info_plus/package_info_plus.dart';

class GitHubApiService {
  final String owner;
  final String repository;
  static const String baseUrl = 'https://api.github.com';

  GitHubApiService({
    required this.owner,
    required this.repository,
  });

  Future<Map<String, dynamic>> getLatestRelease() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/repos/$owner/$repository/releases/latest'),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        // If no releases are found, return a dummy response so the app won't crash
        print('No releases found for $owner/$repository');
        return {
          'tag_name': '0.0.0',
          'body': 'No releases available yet',
          'html_url': 'https://github.com/$owner/$repository/releases',
          'published_at': DateTime.now().toIso8601String(),
          'assets': [],
        };
      } else {
        throw Exception('Failed to load latest release: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching latest release: $e');
      // Return a dummy response to prevent crashes
      return {
        'tag_name': '0.0.0',
        'body': 'Error fetching releases',
        'html_url': 'https://github.com/$owner/$repository/releases',
        'published_at': DateTime.now().toIso8601String(),
        'assets': [],
      };
    }
  }

  Future<bool> isUpdateAvailable() async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = Version.parse(packageInfo.version);
      
      final releaseData = await getLatestRelease();
      final latestVersion = Version.parse(releaseData['tag_name'].toString().replaceAll('v', ''));
      
      return latestVersion > currentVersion;
    } catch (e) {
      // If there's an error, return false to prevent forcing updates when the check fails
      print('Error checking for updates: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> getUpdateInfo() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;
    
    final releaseData = await getLatestRelease();
    final latestVersion = releaseData['tag_name'].toString().replaceAll('v', '');
    
    // Find the appropriate download URL for the platform
    final assets = releaseData['assets'] as List;
    String? downloadUrl;
    
    // Default to APK for Android
    for (var asset in assets) {
      if (asset['name'].toString().endsWith('.apk')) {
        downloadUrl = asset['browser_download_url'];
        break;
      }
    }
    
    return {
      'currentVersion': currentVersion,
      'latestVersion': latestVersion,
      'releaseNotes': releaseData['body'],
      'downloadUrl': downloadUrl,
      'htmlUrl': releaseData['html_url'], // Include the HTML URL for the release page
      'releaseDate': releaseData['published_at'],
    };
  }
}