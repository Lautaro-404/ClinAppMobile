import 'package:flutter/painting.dart';

/// Radios de esquina (fuente: `DESIGN.md`).
abstract final class AppRadii {
  static const double sm = 8;
  static const double base = 16;
  static const double md = 24;
  static const double card = 28;
  static const double lg = 32;
  static const double sheet = 36;
  static const double xl = 48;
  static const double pill = 9999;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius baseAll = BorderRadius.all(Radius.circular(base));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius cardAll = BorderRadius.all(Radius.circular(card));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius pillAll = BorderRadius.all(Radius.circular(pill));
  static const BorderRadius sheetTop = BorderRadius.vertical(
    top: Radius.circular(sheet),
  );
}
