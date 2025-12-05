import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:universal_io/io.dart';
import 'package:flutter/material.dart';

class PlatformDetector {
  static bool get isMobileDevice {
    if (kIsWeb) {
      return false;
    }
    return Platform.isAndroid || Platform.isIOS;
  }

  static bool get isDesktopDevice {
    if (kIsWeb) {
      return false;
    }
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  static bool get isWeb {
    return kIsWeb;
  }

  static bool get isMobileWeb {
    if (!kIsWeb) return false;

    // Detect mobile browsers in web
    final userAgent = Platform.environment['HTTP_USER_AGENT']?.toLowerCase() ?? '';
    return userAgent.contains('mobile') ||
        userAgent.contains('android') ||
        userAgent.contains('iphone') ||
        userAgent.contains('ipad');
  }

  static bool get isDesktopWeb {
    return kIsWeb && !isMobileWeb;
  }

  static bool get shouldShowWebInterface {
    // Show web interface for: Desktop devices OR Desktop browsers
    return isDesktopDevice || (isWeb && isDesktopWeb);
  }

  static bool get shouldShowMobileApp {
    // Show mobile app for: Mobile devices OR Mobile browsers
    return isMobileDevice || (isWeb && isMobileWeb);
  }

  static String get platformDescription {
    if (kIsWeb) {
      return isMobileWeb ? 'Mobile Web Browser' : 'Desktop Web Browser';
    } else if (Platform.isAndroid) {
      return 'Android App';
    } else if (Platform.isIOS) {
      return 'iOS App';
    } else if (Platform.isWindows) {
      return 'Windows App';
    } else if (Platform.isMacOS) {
      return 'macOS App';
    } else if (Platform.isLinux) {
      return 'Linux App';
    }
    return 'Unknown Platform';
  }
}

// Widget to wrap based on platform detection
class PlatformAwareWrapper extends StatelessWidget {
  final Widget mobileApp;
  final Widget webInterface;
  final Widget loadingScreen;

  const PlatformAwareWrapper({
    super.key,
    required this.mobileApp,
    required this.webInterface,
    this.loadingScreen = const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Detecting platform...'),
          ],
        ),
      ),
    ),
  });

  @override
  Widget build(BuildContext context) {
    // Check on first build
    if (PlatformDetector.shouldShowWebInterface) {
      return webInterface;
    } else if (PlatformDetector.shouldShowMobileApp) {
      return mobileApp;
    } else {
      // Fallback to mobile app for unknown cases
      return mobileApp;
    }
  }
}