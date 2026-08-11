import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app.dart';
import 'core/web/splash_dismissal.dart';

void main() {
  usePathUrlStrategy();
  runApp(const JugaadKitApp());
  SchedulerBinding.instance.addPostFrameCallback((_) {
    SplashDismissal.hide();
  });
}
