import 'package:flutter/material.dart';
import 'package:ledger_master/core/responsive.dart';

class ResponsiveScaffold extends StatelessWidget {
  final Widget body;
  final Widget? navigation;
  final Widget? bottomNavigation;
  final String title;

  const ResponsiveScaffold({
    super.key,
    required this.body,
    this.navigation,
    this.bottomNavigation,
    this.title = '',
  });

  @override
  Widget build(BuildContext context) {
    final device = Responsive.getDeviceType(MediaQuery.of(context));
    if (device == DeviceType.desktop) {
      return Row(
        children: [
          if (navigation != null) SizedBox(width: 280, child: navigation),
          Expanded(
            child: Scaffold(
              appBar: AppBar(title: Text(title)),
              body: body,
            ),
          ),
        ],
      );
    } else if (device == DeviceType.tablet) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        drawer: navigation,
        body: body,
        bottomNavigationBar: bottomNavigation,
      );
    } else {
      // mobile
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        drawer: navigation,
        body: body,
        bottomNavigationBar: bottomNavigation,
      );
    }
  }
}
