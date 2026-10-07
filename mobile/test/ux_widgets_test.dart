// Shared UX widgets: reference-code picker (dropdown with text fallback),
// status colour/label resolution, and entity labels for generic links.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rmgflow_mobile/common/widgets/widgets.dart';

final _codes = FutureProvider<List<String>>((ref) async => ['USD', 'EUR', 'BDT']);
final _failingCodes = FutureProvider<List<String>>((ref) async => throw StateError('offline'));

Future<void> _pump(WidgetTester tester, Widget child, {List<Override> overrides = const []}) {
  return tester.pumpWidget(ProviderScope(
    overrides: overrides,
    child: MaterialApp(home: Scaffold(body: Form(child: child))),
  ));
}

void main() {
  testWidgets('CodePickerField offers loaded codes and writes the pick into the controller', (tester) async {
    final controller = TextEditingController(text: 'USD');
    await _pump(tester, CodePickerField(controller: controller, label: 'Currency', codes: _codes));
    await tester.pumpAndSettle();

    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    await tester.tap(find.text('USD'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('EUR').last);
    await tester.pumpAndSettle();
    expect(controller.text, 'EUR');
  });

  testWidgets('CodePickerField keeps an unknown saved code selectable', (tester) async {
    final controller = TextEditingController(text: 'GBP');
    await _pump(tester, CodePickerField(controller: controller, label: 'Currency', codes: _codes));
    await tester.pumpAndSettle();
    expect(find.text('GBP'), findsOneWidget);
  });

  testWidgets('CodePickerField falls back to a text field when codes fail to load', (tester) async {
    final controller = TextEditingController();
    await _pump(tester, CodePickerField(controller: controller, label: 'Country', codes: _failingCodes, codeLength: 2));
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'BD');
    expect(controller.text, 'BD');
  });

  test('AppStatus humanises enum constants and colours them consistently', () {
    expect(AppStatus.humanize('UNDER_REVIEW'), 'Under review');
    expect(AppStatus.humanize('inProgress'), 'In progress');
    expect(AppStatus.resolve('APPROVED').tone, StatusTone.success);
    expect(AppStatus.resolve('REJECTED').tone, StatusTone.danger);
    expect(AppStatus.resolve('SELECTED').tone, StatusTone.success);
    expect(AppStatus.resolve('CANDIDATE').tone, StatusTone.info);
    expect(AppStatus.resolve('SOMETHING_NEW').label, 'Something new');
  });
}
