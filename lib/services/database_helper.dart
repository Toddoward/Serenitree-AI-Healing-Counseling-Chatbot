import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/message.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  static const String _tableName = 'messages';
  static const int _databaseVersion = 1;

  // 암호화 키 (실제로는 더 안전한 방식으로 관리해야 함)
  static const String _encryptionKey = 'serenitree_secret_key_2024';

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'serenitree.db');
    
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id TEXT PRIMARY KEY,
        content TEXT NOT NULL,
        isFromUser INTEGER NOT NULL,
        timestamp INTEGER NOT NULL,
        status INTEGER NOT NULL,
        encrypted_content TEXT NOT NULL
      )
    ''');
  }

  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    // 향후 데이터베이스 스키마 변경 시 사용
    if (oldVersion < newVersion) {
      // 필요한 마이그레이션 로직 추가
    }
  }

  // 텍스트 암호화 (간단한 XOR 암호화 사용)
  String _encrypt(String text) {
    List<int> textBytes = utf8.encode(text);
    List<int> keyBytes = utf8.encode(_encryptionKey);
    List<int> encrypted = [];
    
    for (int i = 0; i < textBytes.length; i++) {
      encrypted.add(textBytes[i] ^ keyBytes[i % keyBytes.length]);
    }
    
    return base64.encode(encrypted);
  }

  // 텍스트 복호화
  String _decrypt(String encryptedText) {
    try {
      List<int> encryptedBytes = base64.decode(encryptedText);
      List<int> keyBytes = utf8.encode(_encryptionKey);
      List<int> decrypted = [];
      
      for (int i = 0; i < encryptedBytes.length; i++) {
        decrypted.add(encryptedBytes[i] ^ keyBytes[i % keyBytes.length]);
      }
      
      return utf8.decode(decrypted);
    } catch (e) {
      print('복호화 오류: $e');
      return '';
    }
  }

  // 메시지 저장
  Future<int> insertMessage(Message message) async {
    final db = await database;
    
    // 메시지 내용 암호화
    final encryptedContent = _encrypt(message.content);
    
    final messageMap = {
      'id': message.id,
      'content': message.content, // 검색용 원본 (실제 앱에서는 제거 권장)
      'isFromUser': message.isFromUser ? 1 : 0,
      'timestamp': message.timestamp.millisecondsSinceEpoch,
      'status': message.status.index,
      'encrypted_content': encryptedContent,
    };
    
    return await db.insert(
      _tableName, 
      messageMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // 모든 메시지 조회
  Future<List<Message>> getAllMessages() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      orderBy: 'timestamp ASC',
    );

    return List.generate(maps.length, (i) {
      // 암호화된 내용 복호화
      final encryptedContent = maps[i]['encrypted_content'] as String;
      final decryptedContent = _decrypt(encryptedContent);
      
      return Message(
        id: maps[i]['id'],
        content: decryptedContent.isNotEmpty ? decryptedContent : maps[i]['content'],
        isFromUser: maps[i]['isFromUser'] == 1,
        timestamp: DateTime.fromMillisecondsSinceEpoch(maps[i]['timestamp']),
        status: MessageStatus.values[maps[i]['status']],
      );
    });
  }

  // 최근 메시지 조회 (개수 제한)
  Future<List<Message>> getRecentMessages({int limit = 100}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    // 시간순으로 정렬하여 반환
    return List.generate(maps.length, (i) {
      final encryptedContent = maps[i]['encrypted_content'] as String;
      final decryptedContent = _decrypt(encryptedContent);
      
      return Message(
        id: maps[i]['id'],
        content: decryptedContent.isNotEmpty ? decryptedContent : maps[i]['content'],
        isFromUser: maps[i]['isFromUser'] == 1,
        timestamp: DateTime.fromMillisecondsSinceEpoch(maps[i]['timestamp']),
        status: MessageStatus.values[maps[i]['status']],
      );
    }).reversed.toList();
  }

  // 특정 메시지 삭제
  Future<int> deleteMessage(String messageId) async {
    final db = await database;
    return await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  // 모든 메시지 삭제
  Future<int> deleteAllMessages() async {
    final db = await database;
    return await db.delete(_tableName);
  }

  // 메시지 개수 조회
  Future<int> getMessageCount() async {
    final db = await database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $_tableName')
    );
    return count ?? 0;
  }

  // 날짜별 메시지 조회
  Future<List<Message>> getMessagesByDate(DateTime date) async {
    final db = await database;
    
    // 해당 날짜의 시작과 끝 시간
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'timestamp >= ? AND timestamp <= ?',
      whereArgs: [
        startOfDay.millisecondsSinceEpoch,
        endOfDay.millisecondsSinceEpoch,
      ],
      orderBy: 'timestamp ASC',
    );

    return List.generate(maps.length, (i) {
      final encryptedContent = maps[i]['encrypted_content'] as String;
      final decryptedContent = _decrypt(encryptedContent);
      
      return Message(
        id: maps[i]['id'],
        content: decryptedContent.isNotEmpty ? decryptedContent : maps[i]['content'],
        isFromUser: maps[i]['isFromUser'] == 1,
        timestamp: DateTime.fromMillisecondsSinceEpoch(maps[i]['timestamp']),
        status: MessageStatus.values[maps[i]['status']],
      );
    });
  }

  // 데이터베이스 백업 (JSON 형태로 내보내기)
  Future<String> exportMessages() async {
    final messages = await getAllMessages();
    final messageList = messages.map((message) => message.toMap()).toList();
    
    final exportData = {
      'export_date': DateTime.now().toIso8601String(),
      'message_count': messages.length,
      'messages': messageList,
    };
    
    return json.encode(exportData);
  }

  // 데이터베이스 정리 (오래된 메시지 삭제)
  Future<int> cleanOldMessages({int daysToKeep = 30}) async {
    final db = await database;
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
    
    return await db.delete(
      _tableName,
      where: 'timestamp < ?',
      whereArgs: [cutoffDate.millisecondsSinceEpoch],
    );
  }

  // 데이터베이스 연결 종료
  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}