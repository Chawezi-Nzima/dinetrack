import 'package:flutter/material.dart';
import 'package:universal_io/io.dart';
import 'package:flutter/foundation.dart';

class ResponsiveHelper {
  static bool get isMobile {
    if (kIsWeb) {
      return false;
    }
    return Platform.isAndroid || Platform.isIOS;
  }

  static bool get isDesktop {
    if (kIsWeb) {
      return false;
    }
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  static bool get isWeb {
    return kIsWeb;
  }

  static bool isMobileScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 768;
  }

  static bool isTabletScreen(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 768 && width < 1024;
  }

  static bool isDesktopScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1024;
  }

  static Widget buildResponsiveLayout({
    required BuildContext context,
    required Widget mobileLayout,
    required Widget desktopLayout,
    Widget? tabletLayout,
  }) {
    if (isMobileScreen(context)) {
      return mobileLayout;
    } else if (isTabletScreen(context) && tabletLayout != null) {
      return tabletLayout;
    } else {
      return desktopLayout;
    }
  }

  static String getDeviceType(BuildContext context) {
    if (isMobileScreen(context)) return 'Mobile';
    if (isTabletScreen(context)) return 'Tablet';
    return 'Desktop';
  }

  static double getResponsiveValue({
    required BuildContext context,
    required double mobile,
    required double desktop,
    double? tablet,
  }) {
    if (isMobileScreen(context)) return mobile;
    if (isTabletScreen(context)) return tablet ?? (mobile + desktop) / 2;
    return desktop;
  }
}