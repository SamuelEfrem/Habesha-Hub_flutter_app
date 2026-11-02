import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';

/// iPad needs a point to open the share popup from, or the app crashes.
Future<void> shareText(String text) async {
  final view = WidgetsBinding.instance.platformDispatcher.views.first;
  final size = view.physicalSize / view.devicePixelRatio;
  await Share.share(text,
      sharePositionOrigin: Rect.fromCenter(center: size.center(Offset.zero), width: 1, height: 1));
}
