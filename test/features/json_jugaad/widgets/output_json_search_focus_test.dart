import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jugaadkit/features/json_jugaad/widgets/output_json_search_focus.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('requestFocus selects existing query', () {
    final focusTarget = OutputJsonSearchFocus();
    final controller = TextEditingController(text: 'needle');
    final focusNode = FocusNode();

    focusTarget.register(
      focusNode: focusNode,
      controller: controller,
    );

    focusTarget.requestFocus();

    expect(controller.selection.textInside(controller.text), 'needle');

    focusNode.dispose();
    controller.dispose();
  });
}
