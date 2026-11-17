import 'dart:math' as math;
import 'dart:ui' show Rect;

import 'package:elapsa/core/card_number.dart';
import 'package:elapsa/services/vision_channel.dart';

/// Finds a card number by putting many imperfect readings together.
///
/// An embossed number on a painted card is read badly by every single pass —
/// but badly in different places. One treatment loses the first group to the
/// artwork behind it, another the third; the recogniser's runner-up reading of
/// a group is often right where its first choice was not. No pass on its own
/// has the number, and between them they usually do.
///
/// So every reading of every pass is broken into its groups of digits and each
/// group is placed where it was seen on the card. Groups seen in the same
/// place are the same group, and each different reading of it collects the
/// support of every pass that produced it. The number is then assembled from
/// the best-supported readings, slot by slot — and the checksum, which every
/// card number carries, decides between the combinations that are left.
///
/// Trying combinations is what makes a checksum dangerous: one random number
/// in ten passes Luhn. Three things keep that in hand. Only readings that a
/// pass actually produced are ever combined. The number must have a length its
/// scheme issues. And if two different numbers fit the evidence about equally
/// well the answer is *nothing*, because a field left empty is one the user
/// fills in from the card in their hand, while a field filled in wrongly is
/// one they have no reason to check.
class CardNumberReader {
  const CardNumberReader();

  /// The card number in [passes], or null when the evidence does not settle
  /// on one.
  ///
  /// Every pass must be measured in the same frame — the card crop — so that
  /// the same printed group lands in the same place in each.
  String? read(List<List<RecognisedLine>> passes) {
    final tokens = <_Token>[];
    for (final lines in passes) {
      for (final line in lines) {
        tokens.addAll(_tokensOf(line));
      }
    }
    if (tokens.isEmpty) return null;

    final found = <String, double>{};
    for (final row in _rows(tokens)) {
      _assemble(_slots(row), found);
    }
    if (found.isEmpty) return null;

    // Part of a number is not a rival to it. The first sixteen digits of a
    // nineteen-digit UnionPay number pass the checksum one time in ten, and
    // that is the same reading, not a second opinion.
    final ranked = [
      for (final entry in found.entries)
        if (!found.entries.any(
          (other) =>
              other.key.length > entry.key.length &&
              other.key.contains(entry.key) &&
              other.value >= entry.value * 0.8,
        ))
          entry,
    ]..sort((a, b) => b.value.compareTo(a.value));
    final best = ranked.first;

    // A rival close behind is a coin toss, not an answer.
    if (ranked.length > 1 && ranked[1].value >= best.value * 0.8) return null;
    return best.key;
  }

  /// Every group of digits one line offers, each placed where it sits.
  ///
  /// All of the line's readings contribute, the first most. A group that
  /// appears in several of them is counted once, at its best rank: the
  /// runners-up of one observation are not independent witnesses.
  static Iterable<_Token> _tokensOf(RecognisedLine line) {
    final best = <String, _Token>{};
    final readings = line.readings;
    for (var rank = 0; rank < readings.length; rank++) {
      final reading = asciiDigits(readings[rank]);
      if (reading.trim().isEmpty) continue;

      // Where each token falls along the line, by its share of the
      // characters. Embossed figures are evenly spaced, so this is close.
      // Hyphens split groups as well as spaces: a recogniser reading a row of
      // embossed figures sometimes joins two of them with one, and a single
      // eight-digit token cannot be placed against the groups other passes
      // read separately.
      for (final match in RegExp(r'[^\s\-–—]+').allMatches(reading)) {
        final group = digitGroup(match.group(0)!);
        if (group == null) continue;

        final from = match.start / reading.length;
        final to = match.end / reading.length;
        final weight = (group.exact ? 1.0 : 0.7) / (1 + rank * 0.6);

        final token = _Token(
          group.digits,
          left: line.box.left + line.box.width * from,
          right: line.box.left + line.box.width * to,
          y: line.box.center.dy,
          height: line.box.height,
          weight: weight,
        );
        // Keyed on the reading and roughly where it is, so a group repeated
        // across the candidates counts once.
        final key = '${group.digits}@${(token.centre * 40).round()}';
        final previous = best[key];
        if (previous == null || previous.weight < weight) best[key] = token;
      }
    }
    return best.values;
  }

  /// Tokens grouped into the printed rows they came from.
  static List<List<_Token>> _rows(List<_Token> tokens) {
    final sorted = [...tokens]..sort((a, b) => a.y.compareTo(b.y));
    final rows = <List<_Token>>[];
    var y = 0.0;
    var height = 0.0;
    for (final token in sorted) {
      if (rows.isNotEmpty &&
          (token.y - y).abs() < math.max(height, token.height) * 0.6) {
        rows.last.add(token);
        // A running centre, so one row read slightly crooked across many
        // passes is still one row.
        final n = rows.last.length;
        y = y + (token.y - y) / n;
        height = math.max(height, token.height);
      } else {
        rows.add([token]);
        y = token.y;
        height = token.height;
      }
    }
    return rows;
  }

  /// One row's tokens gathered into the positions they were printed in.
  static List<_Slot> _slots(List<_Token> row) {
    final sorted = [...row]..sort((a, b) => a.centre.compareTo(b.centre));
    final slots = <_Slot>[];
    for (final token in sorted) {
      final last = slots.isEmpty ? null : slots.last;
      // The same position when the centres are closer than half a group's
      // width. Groups on a card are separated by a gap at least that wide.
      if (last != null &&
          (token.centre - last.centre).abs() <
              math.min(last.width, token.width) * 0.5) {
        last.add(token);
      } else {
        slots.add(_Slot()..add(token));
      }
    }
    return slots;
  }

  /// Every checksum-valid number that runs of adjacent slots can spell, each
  /// with how well the evidence supports it.
  static void _assemble(List<_Slot> slots, Map<String, double> found) {
    for (var start = 0; start < slots.length; start++) {
      var chain = <_Partial>[const _Partial('', double.infinity, 1, 0, -1)];
      for (var end = start; end < slots.length && end < start + 7; end++) {
        final slot = slots[end];
        final next = <_Partial>[];
        for (final partial in chain) {
          var extended = false;
          var overlapped = false;
          for (final (reading, weight, share, left, right) in slot.readings()) {
            // Slots that overlap are two readings of the same figures — a
            // whole row read as one, beside the same row read in groups. They
            // never belong in one number together.
            if (partial.right > 0 &&
                left < partial.right - (right - left) * 0.25) {
              overlapped = true;
              continue;
            }
            final joined = partial.digits + reading;
            if (joined.length > 19) continue;
            next.add(
              _Partial(
                joined,
                math.min(partial.weakest, weight),
                partial.total * share,
                partial.groups + 1,
                right,
              ),
            );
            extended = true;
          }
          // A slot that only overlaps what this number already has is a
          // second reading of figures already in it — stepped over, not a
          // gap. A gap ends the number; this does not.
          if (!extended && overlapped) next.add(partial);
        }
        if (next.isEmpty) break;
        // Bounded: the strongest few hundred partial numbers are plenty, and
        // the weak tail is where the flukes live.
        next.sort((a, b) => b.total.compareTo(a.total));
        chain = next.take(300).toList();

        for (final partial in chain) {
          final digits = partial.digits;
          if (!isPlausibleCardNumber(digits) || !passesLuhn(digits)) continue;
          // Every group has to have been somebody's first or second choice.
          // A group only ever offered third or later, or only as letters that
          // had to be folded into figures at second hand, is too thin to put
          // a number together from.
          if (partial.weakest < 0.5) continue;
          // How much of the vote, slot by slot, this reading of the number
          // carries — a slot split evenly between two readings halves it.
          final score = partial.total;
          final previous = found[digits];
          if (previous == null || previous < score) found[digits] = score;
        }
      }
    }
  }
}

/// A number part-way assembled, and how well read its groups were.
class _Partial {
  final String digits;
  final double weakest;

  /// The product of each group's share of its slot's vote.
  final double total;
  final int groups;
  final double right;

  const _Partial(
    this.digits,
    this.weakest,
    this.total,
    this.groups,
    this.right,
  );
}

/// A run of digits, and where on the card it was seen.
class _Token {
  final String digits;
  final double left;
  final double right;
  final double y;
  final double height;
  final double weight;

  _Token(
    this.digits, {
    required this.left,
    required this.right,
    required this.y,
    required this.height,
    required this.weight,
  });

  double get centre => (left + right) / 2;
  double get width => right - left;
}

/// One printed position, and every reading of it.
class _Slot {
  final _tokens = <_Token>[];

  void add(_Token token) => _tokens.add(token);

  double get centre =>
      _tokens.map((t) => t.centre).reduce((a, b) => a + b) / _tokens.length;

  double get width =>
      _tokens.map((t) => t.width).reduce((a, b) => a + b) / _tokens.length;

  /// Each distinct reading with its summed support and the span it covers,
  /// strongest first, a handful at most.
  List<(String, double, double, double, double)> readings() {
    final support = <String, double>{};
    final left = <String, double>{};
    final right = <String, double>{};
    for (final token in _tokens) {
      support[token.digits] = (support[token.digits] ?? 0) + token.weight;
      left[token.digits] = math.min(left[token.digits] ?? 1e9, token.left);
      right[token.digits] = math.max(right[token.digits] ?? -1e9, token.right);
    }
    final ranked = support.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = ranked.first.value;
    final all = ranked.fold(0.0, (sum, e) => sum + e.value);
    return [
      for (final entry in ranked.take(4))
        // A reading far behind the leader is noise, not an alternative.
        if (entry.value >= top * 0.25)
          (
            entry.key,
            entry.value,
            entry.value / all,
            left[entry.key]!,
            right[entry.key]!,
          ),
    ];
  }
}

/// The strip of a card crop where its number most likely runs.
///
/// From what has been read already when that is enough to go on: the row with
/// the most digits in it, below the bank's name and above the bottom edge. A
/// number that was not read at all still has a place it is printed — an ID-1
/// card's embossed number runs a little below its middle — so that strip is
/// always worth a look as well.
List<Rect> numberBands(List<RecognisedLine> lines) {
  const usual = Rect.fromLTWH(0, 0.42, 1, 0.34);
  final bands = <Rect>[];

  RecognisedLine? richest;
  var most = 0;
  for (final line in lines) {
    final y = line.box.center.dy;
    if (y < 0.25 || y > 0.9) continue;
    var count = 0;
    for (final token in asciiDigits(
      line.digits ?? line.text,
    ).split(RegExp(r'\s+'))) {
      count += digitGroup(token)?.digits.length ?? 0;
    }
    if (count > most) {
      most = count;
      richest = line;
    }
  }

  if (richest != null && most >= 4) {
    final h = math.max(richest.box.height, 0.05);
    final top = (richest.box.center.dy - h * 1.4).clamp(0.0, 1.0);
    final bottom = (richest.box.center.dy + h * 1.4).clamp(0.0, 1.0);
    final hinted = Rect.fromLTRB(0, top, 1, bottom);
    bands.add(hinted);
    // The usual strip only when the hint is somewhere else; two looks at the
    // same row cost time and add nothing.
    final overlap = hinted.intersect(usual);
    if (overlap.isEmpty || overlap.height < hinted.height * 0.6) {
      bands.add(usual);
    }
  } else {
    bands.add(usual);
  }
  return bands;
}
