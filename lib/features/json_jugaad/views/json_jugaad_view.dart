import 'package:flutter/material.dart';

import 'package:jugaadkit/core/constants/app_constants.dart';
import 'package:jugaadkit/core/seo/seo_constants.dart';
import 'package:jugaadkit/core/seo/seo_metadata.dart';
import 'package:jugaadkit/features/json_jugaad/constants/json_jugaad_constants.dart';
import 'package:jugaadkit/features/json_jugaad/models/json_jugaad_ui_state.dart';
import 'package:jugaadkit/features/json_jugaad/view_models/json_jugaad_view_model.dart';
import 'package:jugaadkit/features/json_jugaad/widgets/input_panel.dart';
import 'package:jugaadkit/features/json_jugaad/widgets/output_panel.dart';
import 'package:jugaadkit/features/json_jugaad/widgets/tool_header.dart';
import 'package:jugaadkit/widgets/common/app_header.dart';

class JsonJugaadView extends StatefulWidget {
  const JsonJugaadView({
    super.key,
    required this.viewModel,
    required this.onToggleTheme,
  });

  final JsonJugaadViewModel viewModel;
  final VoidCallback onToggleTheme;

  @override
  State<JsonJugaadView> createState() => _JsonJugaadViewState();
}

class _JsonJugaadViewState extends State<JsonJugaadView> {
  late final TextEditingController _inputController;

  @override
  void initState() {
    super.initState();
    _inputController = TextEditingController(text: widget.viewModel.state.input);
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SeoMetadata.apply(
      title: SeoConstants.jsonJugaadTitle,
      description: SeoConstants.jsonJugaadDescription,
    );

    return Scaffold(
      body: Column(
        children: [
          AppHeader(onToggleTheme: widget.onToggleTheme),
          Expanded(
            child: ListenableBuilder(
              listenable: widget.viewModel,
              builder: (context, _) {
                final state = widget.viewModel.state;
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppConstants.maxContentWidth,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const ToolHeader(),
                          const SizedBox(height: 24),
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final isDesktop = constraints.maxWidth >=
                                    AppConstants.desktopBreakpoint;

                                final transformationSteps = state.result?.steps ??
                                    state.error?.partialSteps ??
                                    const [];

                                final inputPanel = InputPanel(
                                  controller: _inputController,
                                  onChanged: widget.viewModel.updateInput,
                                  onClear: () {
                                    _inputController.clear();
                                    widget.viewModel.clearInput();
                                  },
                                  isProcessing:
                                      state.status == JsonJugaadStatus.processing,
                                  transformationSteps: transformationSteps,
                                  showExplorerHint:
                                      state.status == JsonJugaadStatus.success,
                                );

                                final outputPanel = OutputPanel(
                                  status: state.status,
                                  result: state.result,
                                  error: state.error,
                                );

                                if (isDesktop) {
                                  return Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(
                                        flex: JsonJugaadConstants.inputPanelFlex,
                                        child: inputPanel,
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        flex: JsonJugaadConstants.outputPanelFlex,
                                        child: outputPanel,
                                      ),
                                    ],
                                  );
                                }

                                return Column(
                                  children: [
                                    Expanded(child: inputPanel),
                                    const SizedBox(height: 16),
                                    Expanded(child: outputPanel),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
