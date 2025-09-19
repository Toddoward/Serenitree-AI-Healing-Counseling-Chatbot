import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  static const String _keyStorageKey = 'encryption_key';
  static const int _keyLength = 32; // 256비트 키

  String? _encryptionKey;

  // 암호화 키 초기화 또는 로드
  Future<void> initializeKey() async {
    if (_encryptionKey != null) return;

    final prefs = await SharedPreferences.getInstance();
    String? storedKey = prefs.getString(_keyStorageKey);

    if (storedKey == null) {
      // 새로운 키 생성
      _encryptionKey = _generateSecureKey();
      await prefs.setString(_keyStorageKey, _encryptionKey!);
    } else {
      _encryptionKey = storedKey;
    }
  }

  // 안전한 암호화 키 생성
  String _generateSecureKey() {
    final random = Random.secure();
    final keyBytes = Uint8List(_keyLength);
    
    for (int i = 0; i < _keyLength; i++) {
      keyBytes[i] = random.nextInt(256);
    }
    
    return base64.encode(keyBytes);
  }

  // 텍스트 암호화 (AES-like XOR with random salt)
  Future<String> encrypt(String plaintext) async {
    await initializeKey();
    
    if (plaintext.isEmpty) return '';
    
    try {
      // 랜덤 솔트 생성
      final random = Random.secure();
      final salt = List.generate(16, (_) => random.nextInt(256));
      
      // 키와 솔트를 결합하여 암호화 키 생성
      final keyBytes = base64.decode(_encryptionKey!);
      final combinedKey = _combineKeyWithSalt(keyBytes, salt);
      
      // 텍스트 암호화
      final plaintextBytes = utf8.encode(plaintext);
      final encrypted = _xorEncrypt(plaintextBytes, combinedKey);
      
      // 솔트와 암호화된 데이터 결합
      final result = [...salt, ...encrypted];
      
      return base64.encode(result);
    } catch (e) {
      print('암호화 오류: $e');
      return '';
    }
  }

  // 텍스트 복호화
  Future<String> decrypt(String ciphertext) async {
    await initializeKey();
    
    if (ciphertext.isEmpty) return '';
    
    try {
      final cipherBytes = base64.decode(ciphertext);
      
      // 솔트와 암호화된 데이터 분리
      final salt = cipherBytes.sublist(0, 16);
      final encrypted = cipherBytes.sublist(16);
      
      // 키와 솔트를 결합하여 복호화 키 생성
      final keyBytes = base64.decode(_encryptionKey!);
      final combinedKey = _combineKeyWithSalt(keyBytes, salt);
      
      // 복호화
      final decrypted = _xorEncrypt(encrypted, combinedKey);
      
      return utf8.decode(decrypted);
    } catch (e) {
      print('복호화 오류: $e');
      return '';
    }
  }

  // 키와 솔트 결합
  List<int> _combineKeyWithSalt(List<int> key, List<int> salt) {
    final combined = <int>[];
    final hmacSha256 = Hmac(sha256, key);
    final digest = hmacSha256.convert(salt);
    
    // HMAC 결과를 키로 사용
    return digest.bytes;
  }

  // XOR 암호화/복호화
  List<int> _xorEncrypt(List<int> data, List<int> key) {
    final result = <int>[];
    
    for (int i = 0; i < data.length; i++) {
      result.add(data[i] ^ key[i % key.length]);
    }
    
    return result;
  }

  // 메시지 해시 생성 (무결성 검증용)
  String generateHash(String message) {
    final bytes = utf8.encode(message);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // 해시 검증
  bool verifyHash(String message, String hash) {
    return generateHash(message) == hash;
  }

  // 암호화 키 재생성 (주의: 기존 데이터 복호화 불가)
  Future<void> regenerateKey() async {
    _encryptionKey = _generateSecureKey();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyStorageKey, _encryptionKey!);
  }

  // 암호화 키 삭제 (앱 초기화 시 사용)
  Future<void> clearKey() async {
    _encryptionKey = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyStorageKey);
  }

  // 현재 키 상태 확인
  bool get isInitialized => _encryptionKey != null;
}