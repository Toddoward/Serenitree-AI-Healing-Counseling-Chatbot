import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _passwordKey = 'user_password_hash';
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _firstLaunchKey = 'first_launch';
  
  final LocalAuthentication _localAuth = LocalAuthentication();
  
  // 최초 실행 여부 확인
  Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_firstLaunchKey) ?? true;
  }
  
  // 최초 실행 완료 표시
  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstLaunchKey, false);
  }
  
  // 비밀번호 해시 생성
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  // 비밀번호 설정
  Future<bool> setPassword(String password) async {
    try {
      if (password.length < 4) {
        return false; // 너무 짧은 비밀번호
      }
      
      final prefs = await SharedPreferences.getInstance();
      final hashedPassword = _hashPassword(password);
      await prefs.setString(_passwordKey, hashedPassword);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // 비밀번호 확인
  Future<bool> verifyPassword(String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedHash = prefs.getString(_passwordKey);
      
      if (storedHash == null) return false;
      
      final inputHash = _hashPassword(password);
      return storedHash == inputHash;
    } catch (e) {
      return false;
    }
  }
  
  // 비밀번호 삭제 - 새로 추가된 메서드
  Future<bool> clearPassword() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_passwordKey);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // 모든 인증 데이터 초기화 - 새로 추가된 메서드  
  Future<bool> resetAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_passwordKey);
      await prefs.remove(_biometricEnabledKey);
      await prefs.setBool(_firstLaunchKey, true); // 다시 온보딩 필요
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // 생체 인증 가능 여부 확인
  Future<bool> canUseBiometrics() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      if (!isAvailable) return false;
      
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
  
  // 생체 인증 설정
  Future<bool> enableBiometrics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_biometricEnabledKey, true);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // 생체 인증 비활성화
  Future<void> disableBiometrics() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, false);
  }
  
  // 생체 인증 활성화 여부 확인
  Future<bool> isBiometricsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }
  
  // 생체 인증 실행
  Future<bool> authenticateWithBiometrics() async {
    try {
      final isEnabled = await isBiometricsEnabled();
      if (!isEnabled) return false;
      
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Serenitree에 안전하게 접근하기 위해 인증해주세요',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      
      return authenticated;
    } catch (e) {
      return false;
    }
  }
  
  // 비밀번호 설정 여부 확인
  Future<bool> hasPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_passwordKey) != null;
  }
}