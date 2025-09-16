import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Responsive {
  static Widget builder({required Widget child}) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, childWidget) => childWidget!,
      child: child,
    );
  }
}

/// ScrollBehavior that does NOT build any scrollbar widget.
class NoScrollbarBehavior extends ScrollBehavior {
  const NoScrollbarBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    // return the child directly so no scrollbar is drawn
    return child;
  }

  // allow mouse wheel & touch scrolling on desktop
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.unknown,
  };
}
