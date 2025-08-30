import 'package:flutter/widgets.dart';

enum DeviceType { mobile, tablet, desktop }

class Responsive {
  static DeviceType getDeviceType(MediaQueryData mq) {
    final width = mq.size.width;
    if (width >= 1100) return DeviceType.desktop;
    if (width >= 700) return DeviceType.tablet;
    return DeviceType.mobile;
  }

  static bool isMobile(BuildContext context) =>
      getDeviceType(MediaQuery.of(context)) == DeviceType.mobile;
  static bool isTablet(BuildContext context) =>
      getDeviceType(MediaQuery.of(context)) == DeviceType.tablet;
  static bool isDesktop(BuildContext context) =>
      getDeviceType(MediaQuery.of(context)) == DeviceType.desktop;
}
