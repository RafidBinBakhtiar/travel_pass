class AppFonts {
  static const bengali = 'Kalpurush';
  static const english = 'Geist';

  static String forLocale(String languageCode) {
    return languageCode == 'bn' ? bengali : english;
  }
}