/// Which languages a document is printed in, judged from what was read off it.
///
/// The first look at a photograph has to guess: nothing has been read yet, so
/// the app leads with Chinese — a Chinese model reads Latin well enough, while
/// a Latin model turns Chinese into nonsense. But that first look *is* evidence,
/// and every later pass over the same document (the crop, the close-up of the
/// number) can be read with the models the document actually needs.
///
/// Script is decided by Unicode block, which needs no model and cannot be
/// fooled by a misread: a Hangul syllable is Korean whatever it says. Within
/// Chinese, traditional and simplified are told apart by the characters that
/// differ between them — 銀 against 银, 國 against 国 — counted rather than
/// trusted one at a time.
///
/// The answer is an ordered list in Vision's language codes, most likely
/// first, always ending with English: every document tracked here carries
/// Latin print somewhere, if only its numbers.
List<String> languagesForText(String text, {required List<String> fallback}) {
  final tally = ScriptTally.of(text);
  final ordered = tally.languages();
  if (ordered.isEmpty) {
    // Plenty of writing and not one character of any script but Latin: the
    // document is Latin, and the Latin model is the better reader of it — and
    // of its digits. With almost nothing read there is nothing to go on.
    if (tally.latin >= 12) return const ['en-US'];
    return fallback;
  }

  return [
    ...ordered,
    // The fallback's Chinese, behind what was found, so a Japanese card with
    // a Chinese bank name on it still has a model for both.
    for (final language in fallback)
      if (!ordered.contains(language) && language != 'en-US') language,
    'en-US',
  ];
}

/// How much of each script a piece of text contains.
class ScriptTally {
  int han = 0;
  int simplified = 0;
  int traditional = 0;
  int kana = 0;
  int hangul = 0;
  int cyrillic = 0;
  int ukrainian = 0;
  int arabic = 0;
  int thai = 0;
  int vietnamese = 0;
  int latin = 0;
  int german = 0;
  int french = 0;
  int spanish = 0;
  int portuguese = 0;

  ScriptTally._();

  factory ScriptTally.of(String text) {
    final t = ScriptTally._();
    for (final rune in text.runes) {
      if (rune >= 0x4E00 && rune <= 0x9FFF ||
          rune >= 0x3400 && rune <= 0x4DBF) {
        t.han++;
        final char = String.fromCharCode(rune);
        if (_simplifiedOnly.contains(char)) t.simplified++;
        if (_traditionalOnly.contains(char)) t.traditional++;
      } else if (rune >= 0x3040 && rune <= 0x30FF ||
          rune >= 0x31F0 && rune <= 0x31FF) {
        // The middle dot and the prolonged-sound mark sit in this block and
        // turn up in Chinese print too; neither says Japanese.
        if (rune != 0x30FB && rune != 0x30FC) t.kana++;
      } else if (rune >= 0xAC00 && rune <= 0xD7AF ||
          rune >= 0x1100 && rune <= 0x11FF ||
          rune >= 0x3130 && rune <= 0x318F) {
        t.hangul++;
      } else if (rune >= 0x0400 && rune <= 0x04FF) {
        t.cyrillic++;
        if (_ukrainianOnly.contains(rune)) t.ukrainian++;
      } else if (rune >= 0x0600 && rune <= 0x06FF ||
          rune >= 0x0750 && rune <= 0x077F) {
        t.arabic++;
      } else if (rune >= 0x0E00 && rune <= 0x0E7F) {
        t.thai++;
      } else if (rune >= 0x1EA0 && rune <= 0x1EF9 ||
          _vietnameseOnly.contains(rune)) {
        // The stacked-diacritic block is Vietnamese and almost nothing else.
        t.vietnamese++;
        t.latin++;
      } else if (rune >= 0x41 && rune <= 0x5A || rune >= 0x61 && rune <= 0x7A) {
        t.latin++;
      } else if (rune >= 0xC0 && rune <= 0x24F) {
        t.latin++;
        final char = String.fromCharCode(rune);
        if ('äöüßÄÖÜ'.contains(char)) t.german++;
        if ('èêëçœÈÊËÇŒîïûÎÏÛ'.contains(char)) t.french++;
        if ('ñ¿¡Ñ'.contains(char)) t.spanish++;
        if ('ãõÃÕ'.contains(char)) t.portuguese++;
      }
    }
    return t;
  }

  /// The non-English languages this text shows real evidence of, strongest
  /// first.
  ///
  /// Real evidence means more than a stray character. A recogniser that has
  /// been handed a busy picture will now and then return one glyph of a
  /// script nobody printed, and a single misfire must not reorder the models
  /// for the whole document.
  List<String> languages() {
    final found = <(String, int)>[];

    if (kana >= 2) found.add(('ja-JP', kana + han));
    if (hangul >= 2) found.add(('ko-KR', hangul));
    if (han >= 2 && kana < 2) {
      // Both Chinese scripts, the one the text leans to first. Plenty of
      // characters are the same in both, so a tie is no evidence either way
      // and leaves simplified — the more common — in front.
      final first = traditional > simplified ? 'zh-Hant' : 'zh-Hans';
      final second = first == 'zh-Hant' ? 'zh-Hans' : 'zh-Hant';
      found
        ..add((first, han))
        ..add((second, han - 1));
    }
    if (cyrillic >= 3) {
      found.add((ukrainian > 0 ? 'uk-UA' : 'ru-RU', cyrillic));
    }
    if (arabic >= 3) found.add(('ar-SA', arabic));
    if (thai >= 3) found.add(('th-TH', thai));
    if (vietnamese >= 2) found.add(('vi-VT', vietnamese * 4));
    if (german >= 2) found.add(('de-DE', german));
    if (french >= 2) found.add(('fr-FR', french));
    if (spanish >= 1) found.add(('es-ES', spanish));
    if (portuguese >= 2) found.add(('pt-BR', portuguese));

    found.sort((a, b) => b.$2.compareTo(a.$2));
    return [for (final (language, _) in found) language];
  }
}

/// Characters that exist only in simplified Chinese, chosen from the words
/// that appear on documents: banks, cards, licences, the state.
const _simplifiedOnly = {
  '银',
  '国',
  '证',
  '华',
  '号',
  '发',
  '业',
  '险',
  '码',
  '联',
  '储',
  '记',
  '贷',
  '开',
  '户',
  '驾',
  '驶',
  '车',
  '辆',
  '签',
  '机',
  '关',
  '护',
  '门',
  '东',
  '广',
  '万',
  '农',
  '营',
  '亚',
  '际',
  '实',
  '体',
  '经',
  '济',
  '贸',
  '区',
  '务',
  '运',
  '输',
  '员',
  '会',
  '书',
  '电',
  '话',
  '网',
  '岁',
  '长',
  '时',
  '间',
  '据',
  '还',
  '额',
  '费',
  '账',
  '单',
  '汇',
  '兑',
  '币',
  '个',
  '为',
  '于',
};

/// And their traditional counterparts.
const _traditionalOnly = {
  '銀',
  '國',
  '證',
  '華',
  '號',
  '發',
  '業',
  '險',
  '碼',
  '聯',
  '儲',
  '記',
  '貸',
  '開',
  '戶',
  '駕',
  '駛',
  '車',
  '輛',
  '簽',
  '機',
  '關',
  '護',
  '門',
  '東',
  '廣',
  '萬',
  '農',
  '營',
  '亞',
  '際',
  '實',
  '體',
  '經',
  '濟',
  '貿',
  '區',
  '務',
  '運',
  '輸',
  '員',
  '會',
  '書',
  '電',
  '話',
  '網',
  '歲',
  '長',
  '時',
  '間',
  '據',
  '還',
  '額',
  '費',
  '賬',
  '單',
  '匯',
  '兌',
  '幣',
  '個',
  '為',
  '於',
  '臺',
  '灣',
};

/// Cyrillic letters Ukrainian has and Russian does not: і ї є ґ.
const _ukrainianOnly = {
  0x0456,
  0x0457,
  0x0454,
  0x0491,
  0x0406,
  0x0407,
  0x0404,
  0x0490,
};

/// Vietnamese letters outside the stacked-diacritic block: ơ ư đ.
const _vietnameseOnly = {0x01A0, 0x01A1, 0x01AF, 0x01B0, 0x0110, 0x0111};
