import 'package:flutter/material.dart';

import '../../features/json_jugaad/data_jugaad_entry.dart' deferred as data_jugaad;

class DeferredDataJugaadPage extends StatefulWidget {
  const DeferredDataJugaadPage({
    super.key,
    required this.onToggleTheme,
  });

  final VoidCallback onToggleTheme;

  @override
  State<DeferredDataJugaadPage> createState() => _DeferredDataJugaadPageState();
}

class _DeferredDataJugaadPageState extends State<DeferredDataJugaadPage> {
  late final Future<void> _libraryFuture = data_jugaad.loadLibrary();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _libraryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return data_jugaad.buildDataJugaadPage(
          onToggleTheme: widget.onToggleTheme,
        );
      },
    );
  }
}
