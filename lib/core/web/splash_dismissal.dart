import 'splash_dismissal_stub.dart'
    if (dart.library.html) 'splash_dismissal_web.dart' as splash;

abstract final class SplashDismissal {
  static void hide() => splash.hideSplash();
}
