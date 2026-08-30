/// Human phrasing for a lead time expressed in days.
///
/// Used everywhere a lead time is shown — chips, explanations, notification
/// copy — so the app never tells the user "9 months" in one place and
/// "39 weeks" in another.
String leadTimeLabel(int days) {
  if (days >= 365) {
    final years = days ~/ 365;
    return years == 1 ? '1 year' : '$years years';
  }
  final months = (days / 30).round();
  if (months <= 1) return '1 month';
  return '$months months';
}
