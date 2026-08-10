abstract final class AppRoutes {
  static const home = '/';
  static const dataJugaad = '/data_jugaad';

  /// Legacy bookmark path. Redirects to [dataJugaad].
  static const jsonParser = '/jsonParser';

  static const knownRoutes = [
    home,
    dataJugaad,
    jsonParser,
  ];
}
