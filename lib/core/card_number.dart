import 'package:flutter/services.dart';

/// A payment card number written the way it is embossed on the card.
///
/// Sixteen digits in an unbroken row cannot be checked against the card in
/// your hand — the eye loses its place halfway and starts again. The grouping
/// is not decoration; it is what makes the number readable, which is why every
/// card in the world is printed with it.
///
/// American Express prints 4-6-5 and everyone else 4-4-4-4, with the tail of a
/// 19-digit UnionPay number simply running short. Matching each scheme's own
/// grouping means the number on screen and the number on the card break in the
/// same places.
String groupCardNumber(String number) {
  // Only a number that is *only* digits. An identity number ending in a check
  // letter is the same length as a card number, and spacing it into fours
  // would be wrong rather than merely unfamiliar.
  if (!RegExp(r'^[0-9 -]*$').hasMatch(number)) return number;

  final digits = number.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.length < 12 || digits.length > 19) return number;

  final groups = digits.startsWith('34') || digits.startsWith('37')
      ? const [4, 6, 5]
      : const [4, 4, 4, 4, 3];

  final out = StringBuffer();
  var at = 0;
  for (final size in groups) {
    if (at >= digits.length) break;
    if (at > 0) out.write(' ');
    final end = at + size < digits.length ? at + size : digits.length;
    out.write(digits.substring(at, end));
    at = end;
  }
  // Anything left over from a number longer than the pattern expects, rather
  // than silently dropping digits.
  if (at < digits.length) out.write(' ${digits.substring(at)}');

  return out.toString();
}

/// Keeps a card number grouped as it is typed.
///
/// The caret is placed by counting *digits* rather than characters, so
/// inserting a digit mid-number does not throw the cursor to the end — which
/// is what makes correcting a single misread figure bearable.
class CardNumberFormatter extends TextInputFormatter {
  const CardNumberFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue before,
    TextEditingValue after,
  ) {
    final raw = after.text;
    final grouped = groupCardNumber(raw);
    if (grouped == raw) return after;

    // How many digits precede the caret; the caret goes back to the same
    // place, counted the same way.
    final upToCaret = raw.substring(0, after.selection.baseOffset);
    final digitsBefore = upToCaret.replaceAll(RegExp(r'[^0-9]'), '').length;

    var offset = 0;
    var counted = 0;
    while (offset < grouped.length && counted < digitsBefore) {
      if (RegExp(r'[0-9]').hasMatch(grouped[offset])) counted++;
      offset++;
    }

    return TextEditingValue(
      text: grouped,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}
