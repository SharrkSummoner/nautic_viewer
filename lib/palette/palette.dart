//palette.dart
import 'package:flutter/material.dart';
class Palette {
  static const MaterialColor kToLight = MaterialColor(
    0xff7685e8, // 0% comes in here, this will be color picked if no shade is selected when defining a Color property which doesn’t require a swatch.
    const <int, Color>{
      50: const Color(0xff7685e8),//10%
      100: const Color(0xff85bfeb),//20%
      200: const Color(0xff93eded),//30%
      300: const Color(0xffa2f0cf),//40%
      400: const Color(0xffb1f2ba),//50%
      500: const Color(0xffcef5bf),//60%
      600: const Color(0xffebf7ce),//70%
      700: const Color(0xfffaf6df),//80%
      800: const Color(0xfffcf4ee),//90%
      900: const Color(0xffffffff),//100%
    },
  );
}