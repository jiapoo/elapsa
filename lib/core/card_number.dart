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

/// The checksum every payment card number carries (ISO/IEC 7812).
bool passesLuhn(String digits) {
  if (digits.isEmpty) return false;
  var sum = 0;
  var doubling = false;
  for (var i = digits.length - 1; i >= 0; i--) {
    var digit = digits.codeUnitAt(i) - 0x30;
    if (digit < 0 || digit > 9) return false;
    if (doubling) {
      digit *= 2;
      if (digit > 9) digit -= 9;
    }
    sum += digit;
    doubling = !doubling;
  }
  return sum % 10 == 0;
}

/// Whether [digits] has a length its scheme actually issues.
///
/// Luhn alone lets one wrong number in ten through, and a reader that tries
/// runner-up readings tries many numbers. The scheme's own rules — a Visa is
/// 13, 16 or 19 digits, an American Express 15 and starting 34 or 37 — turn
/// most of those flukes away for free.
bool isPlausibleCardNumber(String digits) {
  final n = digits.length;
  if (n < 13 || n > 19 || !RegExp(r'^\d+$').hasMatch(digits)) return false;
  final two = int.parse(digits.substring(0, 2));
  return switch (digits[0]) {
    '4' => n == 13 || n == 16 || n == 19,
    '3' =>
      two == 34 || two == 37
          ? n == 15
          : two == 35
          ? n >= 16
          : (two == 30 || two == 36 || two == 38 || two == 39) && n >= 14,
    '2' || '5' => n >= 16,
    '6' => n >= 16,
    _ => false,
  };
}

/// Digits written in any of the forms a recogniser hands back, as ASCII.
///
/// A Chinese model is entitled to return full-width figures — ４３９２ — and
/// every pattern in the app is written for 4392. Folded once, on the way in.
String asciiDigits(String text) {
  final out = StringBuffer();
  for (final rune in text.runes) {
    if (rune >= 0xFF10 && rune <= 0xFF19) {
      out.writeCharCode(rune - 0xFF10 + 0x30);
    } else if (rune == 0x3000) {
      out.write(' ');
    } else if (rune == 0xFF0F) {
      out.write('/');
    } else if (rune == 0xFF0D) {
      out.write('-');
    } else {
      out.writeCharCode(rune);
    }
  }
  return out.toString();
}

/// Letters a recogniser returns in place of embossed digits.
const lookalikeDigits = {
  'O': '0',
  'D': '0',
  'Q': '0',
  'U': '0',
  'I': '1',
  'L': '1',
  '|': '1',
  '!': '1',
  'Z': '2',
  'A': '4',
  'S': '5',
  'G': '6',
  'T': '7',
  'B': '8',
  // Cyrillic. Embossed figures over artwork come back in it often enough —
  // one real scan turned 6176 into Cyrillic — and these are the letters that
  // look like the figures they replaced. Upper case only: tokens are folded
  // to upper case before they get here.
  'О': '0',
  'З': '3',
  'Ч': '4',
  'Б': '6',
  'Т': '7',
  'В': '8',
  'І': '1',
};

/// One token read as a group of digits, or null when it is not one.
///
/// Letters standing in for digits are folded back, but only in a token that
/// is already mostly digits — otherwise `GOOD` reads as `6000` and every word
/// on the card becomes a candidate. [exact] reports whether any folding was
/// needed, which is worth less as evidence than figures read as figures.
({String digits, bool exact})? digitGroup(String token) {
  final stripped = asciiDigits(token).replaceAll('-', '').toUpperCase();
  if (stripped.length < 3 || stripped.length > 19) return null;

  final digits = StringBuffer();
  var certain = 0;
  for (final char in stripped.split('')) {
    final code = char.codeUnitAt(0);
    if (code >= 0x30 && code <= 0x39) {
      certain++;
      digits.write(char);
      continue;
    }
    final substitute = lookalikeDigits[char];
    if (substitute == null) return null;
    digits.write(substitute);
  }
  if (certain < 2 || certain * 2 < stripped.length) return null;
  return (digits: digits.toString(), exact: certain == stripped.length);
}
