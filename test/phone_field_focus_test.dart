import 'package:bsbschool/core/utils/az_phone.dart';
import 'package:bsbschool/dr/theme/dr_theme.dart';
import 'package:bsbschool/dr/widgets/dr_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The field on its own, with a second one to move the focus to.
Widget _app(TextEditingController controller) {
  return MaterialApp(
    theme: DrTheme.dark,
    home: Scaffold(
      body: Column(
        children: [
          DrPhoneField(
            label: 'Telefon',
            hint: '+994 50 123 45 67',
            controller: controller,
          ),
          const DrTextField(hint: 'başqa sahə'),
        ],
      ),
    ),
  );
}

void main() {
  testWidgets('the country code appears as soon as the field is entered',
      (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_app(controller));
    expect(controller.text, '');

    await tester.tap(find.byType(TextField).first);
    await tester.pump();

    expect(controller.text, AzPhone.prefix);
    // And the caret is past it, ready for the first digit.
    expect(controller.selection.baseOffset, AzPhone.prefix.length);
  });

  testWidgets('leaving the field untouched takes the prefix away again',
      (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_app(controller));
    await tester.tap(find.byType(TextField).first);
    await tester.pump();
    expect(controller.text, AzPhone.prefix);

    // Focus moves on without a digit being typed.
    await tester.tap(find.byType(TextField).last);
    await tester.pump();

    // A bare `+994 ` would read as an abandoned number; the hint says more.
    expect(controller.text, '');
    expect(AzPhone.e164(controller.text), '');
  });

  testWidgets('a number that was typed survives leaving the field',
      (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_app(controller));
    await tester.tap(find.byType(TextField).first);
    await tester.pump();

    await tester.enterText(find.byType(TextField).first, '${AzPhone.prefix}501234567');
    await tester.pump();
    expect(controller.text, '+994 50 123 45 67');

    await tester.tap(find.byType(TextField).last);
    await tester.pump();

    expect(controller.text, '+994 50 123 45 67');
    expect(AzPhone.e164(controller.text), '+994501234567');
  });

  testWidgets('a number already on the account opens formatted', (tester) async {
    // What the profile sheet seeds the field with, from whatever the backend
    // stored.
    final controller = TextEditingController(text: AzPhone.format('0501234567'));
    addTearDown(controller.dispose);

    await tester.pumpWidget(_app(controller));
    expect(controller.text, '+994 50 123 45 67');

    await tester.tap(find.byType(TextField).first);
    await tester.pump();

    // Focus must not disturb a field that already holds a number.
    expect(controller.text, '+994 50 123 45 67');
  });
}
