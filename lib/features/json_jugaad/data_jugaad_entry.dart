import 'package:flutter/material.dart';

import 'view_models/json_jugaad_view_model.dart';
import 'views/json_jugaad_view.dart';

JsonJugaadViewModel? _sharedViewModel;

JsonJugaadViewModel _viewModel() => _sharedViewModel ??= JsonJugaadViewModel();

Widget buildDataJugaadPage({required VoidCallback onToggleTheme}) {
  return JsonJugaadView(
    viewModel: _viewModel(),
    onToggleTheme: onToggleTheme,
  );
}
