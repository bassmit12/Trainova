import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:version/version.dart';
import 'package:package_info_plus/package_info_plus.dart';

class GitHubApiService {
  final String owner;
  final String repository;
  static const String baseUrl = 'https://api.github.com';

  GitHubApiService({required this.owner, required this.repository});

  // Get all releases from GitHub
  Future<List<dynamic>> getAllReleases() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/repos/$owner/$repository/releases'),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> releases = json.decode(response.body);
        if (releases.isEmpty) {
          print('No releases found for $owner/$repository');
          return [];
        }
        return releases;
      } else {
        print(
          'Failed to load releases: ${response.statusCode} - ${response.body}',
        );
        return [];
      }
    } catch (e) {
      print('Error fetching releases: $e');
      return [];
    }
  }

  // Get the latest release by comparing version numbers
  Future<Map<String, dynamic>> getLatestRelease() async {
    try {
      final releases = await getAllReleases();

      if (releases.isEmpty) {
        print('No releases found for $owner/$repository');
        return {
          'tag_name': '0.0.0',
          'body': 'No releases available yet',
          'html_url': 'https://github.com/$owner/$repository/releases',
          'published_at': DateTime.now().toIso8601String(),
          'assets': [],
        };
      }

      // Sort releases by version number (not by release date)
      releases.sort((a, b) {
        try {
          final versionA = Version.parse(
            a['tag_name'].toString().replaceAll('v', ''),
          );
          final versionB = Version.parse(
            b['tag_name'].toString().replaceAll('v', ''),
          );
          return versionB.compareTo(versionA); // Descending order
        } catch (e) {
          print('Error parsing version: $e');
          return 0;
        }
      });

      // Return the highest version
      return releases.first;
    } catch (e) {
      print('Error processing latest release: $e');
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
      final String rawCurrentVersion = packageInfo.version;

      // Ensure we can parse the current version
      Version currentVersion;
      try {
        currentVersion = Version.parse(rawCurrentVersion);
      } catch (e) {
        print('Error parsing current app version: $e');
        return false;
      }

      final releases = await getAllReleases();
      if (releases.isEmpty) {
        print('No releases found to compare versions with');
        return false;
      }

      // Find the highest version number from all releases
      Version? highestVersion;
      Map<String, dynamic>? highestVersionRelease;

      for (final release in releases) {
        try {
          final String tagName = release['tag_name'].toString();
          final String versionString =
              tagName.startsWith('v') ? tagName.substring(1) : tagName;

          final releaseVersion = Version.parse(versionString);

          if (highestVersion == null || releaseVersion > highestVersion) {
            highestVersion = releaseVersion;
            highestVersionRelease = release;
          }
        } catch (e) {
          print('Error parsing version for ${release['tag_name']}: $e');
          // Continue to the next release if this one has an invalid version
        }
      }

      if (highestVersion == null) {
        print('No valid version tags found in releases');
        return false;
      }

      print(
        'Current version: $currentVersion, Latest version: $highestVersion',
      );

      // Log detailed version comparison to help debug
      final isUpdateNeeded = highestVersion > currentVersion;
      print(
        'Is update needed: $isUpdateNeeded (${highestVersion.toString()} > ${currentVersion.toString()})',
      );

      return isUpdateNeeded;
    } catch (e) {
      // If there's an error, return false to prevent forcing updates when the check fails
      print('Error checking for updates: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> getUpdateInfo() async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final releaseData = await getLatestRelease();

      // Extract version from tag_name, removing 'v' prefix if present
      String tagName = releaseData['tag_name'].toString();
      final latestVersion =
          tagName.startsWith('v') ? tagName.substring(1) : tagName;

      // Find the appropriate download URL for the platform
      final assets = releaseData['assets'] as List;
      String? downloadUrl;
      String? apkAssetName;

      // Get direct download URL for APK
      for (var asset in assets) {
        if (asset['name'].toString().toLowerCase().endsWith('.apk')) {
          downloadUrl = asset['browser_download_url'];
          apkAssetName = asset['name'];
          break;
        }
      }

      // Get APK size if available
      int? apkSize;
      if (assets.isNotEmpty) {
        for (var asset in assets) {
          if (asset['name'].toString().toLowerCase().endsWith('.apk')) {
            apkSize = asset['size'] as int?;
            break;
          }
        }
      }

      // Log the versions being compared
      print(
        'Update info - Current version: $currentVersion, Latest version: $latestVersion',
      );

      return {
        'currentVersion': currentVersion,
        'latestVersion': latestVersion,
        'releaseNotes': releaseData['body'],
        'downloadUrl': downloadUrl,
        'apkAssetName': apkAssetName,
        'apkSize': apkSize,
        'htmlUrl': releaseData['html_url'],
        'releaseDate': releaseData['published_at'],
      };
    } catch (e) {
      print('Error getting update info: $e');
      // Return a fallback object to prevent crashes
      return {
        'currentVersion': '0.0.0',
        'latestVersion': '0.0.0',
        'releaseNotes': 'Unable to fetch update information.',
      };
    }
  }
}
