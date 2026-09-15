import 'package:bsbschool/core/utils/az_phone.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Runs [text] through the formatter the way the field does, one value at a
/// time, and gives back what would be on screen.
String _typed(String text) {
  const formatter = AzPhoneInputFormatter();
  return formatter
      .formatEditUpdate(
        const TextEditingValue(),
        TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        ),
      )
      .text;
}

void main() {
  group('whatever shape the number arrives in', () {
    test('the national digits are the same nine', () {
      for (final raw in [
        '501234567',
        '0501234567',
        '+994501234567',
        '994501234567',
        '00994501234567',
        '+994 50 123 45 67',
        '(050) 123-45-67',
        '+994 050 123 45 67',
      ]) {
        expect(AzPhone.digitsOf(raw), '501234567', reason: raw);
        expect(AzPhone.e164(raw), '+994501234567', reason: raw);
        expect(AzPhone.format(raw), '+994 50 123 45 67', reason: raw);
      }
    });

    test('a Baku landline keeps its leading 12', () {
      expect(AzPhone.digitsOf('0121234567'), '121234567');
      expect(AzPhone.format('0121234567'), '+994 12 123 45 67');
    });

    test('a stray extra digit is cut rather than mangled', () {
      expect(AzPhone.digitsOf('5012345678'), '501234567');
    });
  });

  group('the mask as it is typed', () {
    test('the country code appears with the first digit', () {
      expect(_typed(''), '');
      expect(_typed('5'), '+994 5');
      expect(_typed('50'), '+994 50');
      expect(_typed('501'), '+994 50 1');
      expect(_typed('50123'), '+994 50 123');
      expect(_typed('5012345'), '+994 50 123 45');
      expect(_typed('501234567'), '+994 50 123 45 67');
    });

    test('deleting back through the prefix clears the field', () {
      // The parent holds backspace: the mask must not wrestle the prefix back.
      expect(_typed('+994 5'), '+994 5');
      expect(_typed('+994 '), '');
      expect(_typed('+994'), '');
      expect(_typed(''), '');
      // And that is where backspacing ends — the field is empty before the
      // country code is half-deleted, so `+99` is only ever pasted. It reads
      // as the operator code it also is (`+994 99 ...` is a real number).
      expect(_typed('+99'), '+994 99');
    });

    test('the caret stays at the end, where the typing is', () {
      const formatter = AzPhoneInputFormatter();
      final value = formatter.formatEditUpdate(
        const TextEditingValue(text: '+994 50 12'),
        const TextEditingValue(
          text: '+994 50 123',
          selection: TextSelection.collapsed(offset: 11),
        ),
      );
      expect(value.text, '+994 50 123');
      expect(value.selection.baseOffset, value.text.length);
    });
  });

  group('completeness', () {
    test('an empty field is empty, not invalid', () {
      expect(AzPhone.isEmpty(''), isTrue);
      expect(AzPhone.isEmpty('+994 '), isTrue);
      expect(AzPhone.isComplete(''), isFalse);
    });

    test('nine digits and no fewer', () {
      expect(AzPhone.isComplete('+994 50 123 45 6'), isFalse);
      expect(AzPhone.isComplete('+994 50 123 45 67'), isTrue);
      expect(AzPhone.isComplete('0501234567'), isTrue);
    });

    test('an empty field sends nothing at all', () {
      expect(AzPhone.e164(''), '');
      expect(AzPhone.e164('+994 '), '');
    });
  });
}
