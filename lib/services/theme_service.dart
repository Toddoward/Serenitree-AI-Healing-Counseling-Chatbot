import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static ThemeService? _instance;
  static ThemeService get instance => _instance ??= ThemeService._internal();
  
  ThemeService._internal();
  
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;
  
  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeIndex = prefs.getInt('theme_mode') ?? 0;
    _themeMode = ThemeMode.values[themeModeIndex];
    notifyListeners();
  }
  
  Future<void> setTheme(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', mode.index);
    _themeMode = mode;
    notifyListeners();
  }
}

class AppThemes {
  // 커스텀 다크 색상 (채도 낮고 어두운 회색)
  static const Color darkBackground = Color(0xFF121212);      // 매우 어두운 회색
  static const Color darkSurface = Color(0xFF1E1E1E);        // 어두운 회색 (카드, 입력창)
  static const Color darkSurfaceVariant = Color(0xFF2C2C2C); // 조금 더 밝은 회색 (PIN 박스)
  static const Color darkOnSurface = Color(0xFFE0E0E0);      // 텍스트 색상
  static const Color darkOnSurfaceVariant = Color(0xFFB0B0B0); // 보조 텍스트
  
  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF4FC3F7),
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      fontFamily: 'NotoSansKR',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        scrolledUnderElevation: 0,
      ),
    );
  }
  
  static ThemeData get darkTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF4FC3F7),
        brightness: Brightness.dark,
        surface: darkSurface,
        background: darkBackground,
        onSurface: darkOnSurface,
        onBackground: darkOnSurface,
      ),
      useMaterial3: true,
      fontFamily: 'NotoSansKR',
      scaffoldBackgroundColor: darkBackground,
      cardColor: darkSurface,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: Color(0xFFE0E0E0),
        elevation: 1,
        scrolledUnderElevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade600),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade600),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4FC3F7), width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkSurface,
          foregroundColor: darkOnSurface,
        ),
      ),
    );
  }
}