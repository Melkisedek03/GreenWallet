import 'package:flutter/material.dart';

class MyTheme {
  static Map<ThemeMode, ThemeData> appThemes = {
    ThemeMode.light: ThemeData(
      cardColor: LightColors.white,
      disabledColor: LightColors.lightGreen,
      dividerColor: LightColors.darkGreen,
      focusColor: LightColors.green,
      hintColor: LightColors.grey,
      primaryColor: LightColors.green,
      shadowColor: LightColors.lightGreen,
      unselectedWidgetColor: LightColors.grey,
      textTheme: TextTheme(
        labelLarge: TextStyle(
          letterSpacing: 1.4,
          fontSize: 16,
          color: DarkColors.white,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: LightColors.white,
        shape: RoundedRectangleBorder(
          //to set border radius to button
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: LightColors.green,
        foregroundColor: LightColors.white,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: LightColors.darkGreen,
        color: LightColors.white,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        shape: RoundedRectangleBorder(
          //to set border radius to button
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: LightColors.white,
        contentTextStyle: TextStyle(
          color: LightColors.green,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: LightColors.green,
          backgroundColor: LightColors.green,
          textStyle: TextStyle(
            color: LightColors.white,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: LightColors.green,
        ),
      ),
      sliderTheme: SliderThemeData(
        valueIndicatorTextStyle: TextStyle(
          color: LightColors.green,
          fontWeight: FontWeight.bold,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return LightColors.white;
          }
          return LightColors.green;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return LightColors.green;
          }
          return LightColors.white;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return LightColors.white;
          }
          return LightColors.green;
        }),
      ),
      colorScheme: ColorScheme(
        primary: LightColors.green,
        primaryContainer: LightColors.darkGreen,
        secondary: LightColors.grey,
        secondaryContainer: LightColors.lightGrey,
        surface: LightColors.white,
        error: LightColors.red,
        onPrimary: LightColors.white,
        onSecondary: LightColors.blackGreen,
        onSurface: LightColors.black,
        onError: LightColors.red,
        brightness: Brightness.light,
        tertiary: LightColors.white,
      ).copyWith(surface: LightColors.white).copyWith(error: LightColors.red),
      bottomAppBarTheme: const BottomAppBarThemeData(color: Color(0x000A5C42)),
    ),
    ThemeMode.dark: ThemeData.dark().copyWith(
      cardColor: DarkColors.green,
      disabledColor: DarkColors.darkBlue,
      dividerColor: DarkColors.lightGreen,
      focusColor: DarkColors.black,
      hintColor: DarkColors.white,
      primaryColor: DarkColors.black,
      iconTheme: IconThemeData(color: DarkColors.white),
      scaffoldBackgroundColor: DarkColors.green,
      shadowColor: DarkColors.darkBlue,
      snackBarTheme: SnackBarThemeData(
        backgroundColor: DarkColors.darkBlue,
        contentTextStyle: TextStyle(
          color: DarkColors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      sliderTheme: SliderThemeData(valueIndicatorColor: DarkColors.darkBlue),
      unselectedWidgetColor: DarkColors.white,
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.all(DarkColors.white),
      ),
      textTheme: TextTheme(
        titleLarge: TextStyle(color: DarkColors.white),
        headlineSmall: TextStyle(color: DarkColors.white),
        headlineMedium: TextStyle(color: DarkColors.white),
        displaySmall: TextStyle(color: DarkColors.white),
        displayMedium: TextStyle(color: DarkColors.white),
        displayLarge: TextStyle(color: DarkColors.white),
        titleMedium: TextStyle(color: DarkColors.white),
        titleSmall: TextStyle(color: DarkColors.white),
        bodyLarge: TextStyle(color: DarkColors.white),
        bodyMedium: TextStyle(color: DarkColors.white),
        labelLarge: TextStyle(
          letterSpacing: 1.4,
          fontSize: 16,
          color: DarkColors.white,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: DarkColors.green,
        shape: RoundedRectangleBorder(
          //to set border radius to button
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        color: DarkColors.green,
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 12),
        shape: RoundedRectangleBorder(
          //to set border radius to button
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: DarkColors.white,
          backgroundColor: DarkColors.white,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: DarkColors.black,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: TextStyle(color: DarkColors.white),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: DarkColors.white),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: DarkColors.white,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return DarkColors.white;
          }
          return DarkColors.grey;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return DarkColors.grey;
          }
          return DarkColors.white;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return DarkColors.white;
          }
          return DarkColors.grey;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.all(DarkColors.white),
      ),
      expansionTileTheme: ExpansionTileThemeData(
        iconColor: DarkColors.white,
      ),
      colorScheme: ColorScheme(
        primary: DarkColors.green,
        primaryContainer: DarkColors.white,
        secondary: DarkColors.white,
        secondaryContainer: DarkColors.grey,
        surface: DarkColors.green,
        error: DarkColors.red,
        onPrimary: DarkColors.green,
        onSecondary: DarkColors.green,
        onSurface: DarkColors.black,
        onError: DarkColors.red,
        brightness: Brightness.dark,
        tertiary: DarkColors.white,
      ).copyWith(surface: DarkColors.green).copyWith(error: DarkColors.red),
      bottomAppBarTheme: const BottomAppBarThemeData(color: Color(0x00062A20)),
    ),
  };

  static ThemeData getTheme(ThemeMode mode) {
    return appThemes[mode] ?? appThemes[ThemeMode.light]!;
  }
}

abstract class LightColors {
  static Color get black => const Color(0xFF062A20);
  static Color get blackGreen => const Color(0xFF1B3A2F);
  static Color get darkGreen => const Color(0xFF084A35);
  static Color get green => const Color(0xFF0A5C42);
  static Color get lightGreen => const Color(0xFFBFE8D6);
  static Color get grey => const Color(0xFF5A6B62);
  static Color get lightGrey => const Color(0x556B7D6E);
  static Color get white => const Color(0xFFF2F8F5);
  static Color get red => const Color(0xFFF8333C);
  static Color get yellow => const Color(0xFFFFBF46);
  static Color get mint => const Color(0xFF2FBF8F);
}

abstract class DarkColors {
  static Color get black => const Color(0xFF062A20);
  static Color get darkGreen => const Color(0xFF084A35);
  static Color get green => const Color(0xFF0A5C42);
  static Color get lightGreen => const Color(0xFF2FBF8F);
  static Color get darkBlue => const Color(0xFF0A3A2C);
  static Color get grey => const Color(0xFF8AA39A);
  static Color get white => const Color(0xFFEAF4EF);
  static Color get red => const Color(0xFFA8201A);
}
