import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/message.dart';
import 'database_helper.dart';
import 'encryption_service.dart';

class ChatService {
  static const String _baseUrl = 'http://10.0.2.2:8000'; // Android 에뮬레이터용 서버 주소
  
  // SQLite 데이터베이스 헬퍼
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final EncryptionService _encryptionService = EncryptionService();
  
  // 초기화
  Future<void> initialize() async {
    await _encryptionService.initializeKey();
  }
  
  // 메시지 길이에 따른 응답 딜레이 계산
  Duration calculateResponseDelay(String message) {
    final words = message.trim().split(' ');
    final sentences = message.split(RegExp(r'[.!?]')).where((s) => s.trim().isNotEmpty).length;
    
    // 기본 딜레이 (1-2초)
    int baseDelaySeconds = 1 + Random().nextInt(2);
    
    // 단어 수에 따른 추가 딜레이
    int wordDelay = (words.length / 10).ceil(); // 10단어당 1초
    
    // 문장 수에 따른 추가 딜레이
    int sentenceDelay = sentences > 1 ? sentences : 0;
    
    // 총 딜레이 계산 (최대 5초)
    int totalSeconds = (baseDelaySeconds + wordDelay + sentenceDelay).clamp(1, 5);
    
    return Duration(seconds: totalSeconds);
  }
  
  // 모델 워밍업 (타이핑 시작 시 호출)
  Future<void> warmupModel() async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/v1/chat/warmup'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        print('모델 워밍업 완료');
      }
    } catch (e) {
      // 워밍업 실패는 무시 (백그라운드 작업)
      print('모델 워밍업 실패: $e');
    }
  }

  // 서버 상태 확인
  Future<bool> checkServerHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      print('서버 연결 실패: $e');
      return false;
    }
  }
  
  // 메시지 전송 (서버로)
  Future<bool> sendMessage(String content) async {
    try {
      final message = Message(
        id: _generateId(),
        content: content,
        isFromUser: true,
        timestamp: DateTime.now(),
        status: MessageStatus.sending,
      );
      
      await addMessage(message);
      
      // 메시지 상태 업데이트 (전송 완료)
      final updatedMessage = message.copyWith(status: MessageStatus.sent);
      await addMessage(updatedMessage);
      
      return true;
    } catch (e) {
      print('메시지 전송 실패: $e');
      return false;
    }
  }
  
  // 순차적 AI 응답 받기 (서버 통신)
  Future<List<Message>> getAIResponseSequential(String userMessage) async {
    try {
      // 서버 상태 확인
      final isServerHealthy = await checkServerHealth();
      if (!isServerHealthy) {
        return [_createErrorMessage('서버에 연결할 수 없습니다. 잠시 후 다시 시도해주세요.')];
      }
      
      // API 요청 데이터
      final requestData = {
        'message': userMessage,
        'temperature': 0.7,
      };
      
      // 순차적 응답 엔드포인트로 요청 전송
      final response = await http.post(
        Uri.parse('$_baseUrl/api/v1/chat/send-sequential'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestData),
      ).timeout(const Duration(seconds: 60));
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['success'] == true) {
          final responses = List<String>.from(responseData['responses'] ?? []);
          
          // 각 응답을 Message 객체로 변환
          List<Message> messages = responses.map((responseText) {
            return Message(
              id: _generateId(),
              content: responseText,
              isFromUser: false,
              timestamp: DateTime.now(),
              status: MessageStatus.delivered,
            );
          }).toList();
          
          return messages;
        } else {
          // 서버에서 오류 응답
          return [_createErrorMessage(
            responseData['responses']?[0] ?? '서버에서 오류가 발생했습니다.'
          )];
        }
      } else {
        // HTTP 오류
        return [_createErrorMessage('서버 응답 오류 (${response.statusCode})')];
      }
      
    } catch (e) {
      print('AI 응답 요청 실패: $e');
      
      // 오류 유형에 따른 다른 메시지
      if (e.toString().contains('TimeoutException')) {
        return [_createErrorMessage('응답 시간이 초과되었습니다. 잠시 후 다시 시도해주세요.')];
      } else if (e.toString().contains('SocketException')) {
        return [_createErrorMessage('네트워크 연결을 확인해주세요.')];
      } else {
        return [_createErrorMessage('일시적인 오류가 발생했습니다. 잠시 후 다시 시도해주세요.')];
      }
    }
  }
  
  // 순차적 메시지 추가 (콜백 함수로 하나씩 추가)
  Future<void> addMessagesSequentially(
    List<Message> messages, 
    Function(Message) onMessageAdded,
    {Duration delay = const Duration(seconds: 2)}
  ) async {
    for (int i = 0; i < messages.length; i++) {
      // SQLite에 메시지 저장
      await addMessage(messages[i]);
      
      // 콜백 함수 호출 (UI 업데이트용)
      onMessageAdded(messages[i]);
      
      // 마지막 메시지가 아니면 딜레이
      if (i < messages.length - 1) {
        await Future.delayed(delay);
      }
    }
  }
  
  // 오류 메시지 생성 헬퍼
  Message _createErrorMessage(String errorMessage) {
    return Message(
      id: _generateId(),
      content: errorMessage,
      isFromUser: false,
      timestamp: DateTime.now(),
      status: MessageStatus.error,
    );
  }
  
  // 저장된 메시지 목록 가져오기 (SQLite에서 로드)
  Future<List<Message>> getMessages() async {
    try {
      await initialize();
      return await _databaseHelper.getRecentMessages(limit: 100);
    } catch (e) {
      print('메시지 로드 실패: $e');
      return [];
    }
  }
  
  // 메시지 추가 (SQLite에 저장)
  Future<void> addMessage(Message message) async {
    try {
      await initialize();
      await _databaseHelper.insertMessage(message);
    } catch (e) {
      print('메시지 저장 실패: $e');
    }
  }
  
  // ID 생성
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           Random().nextInt(1000).toString();
  }
  
  // 메시지 삭제 (전체) - SQLite에서 모든 메시지 삭제
  Future<void> clearMessages() async {
    try {
      await initialize();
      await _databaseHelper.deleteAllMessages();
    } catch (e) {
      print('메시지 삭제 실패: $e');
    }
  }
  
  // 메시지 개수 조회
  Future<int> getMessageCount() async {
    try {
      await initialize();
      return await _databaseHelper.getMessageCount();
    } catch (e) {
      print('메시지 개수 조회 실패: $e');
      return 0;
    }
  }
  
  // 데이터베이스 백업 생성
  Future<String> exportMessages() async {
    try {
      await initialize();
      return await _databaseHelper.exportMessages();
    } catch (e) {
      print('메시지 내보내기 실패: $e');
      return '{"error": "백업 생성 실패"}';
    }
  }
  
  // 오래된 메시지 정리
  Future<int> cleanOldMessages({int daysToKeep = 30}) async {
    try {
      await initialize();
      return await _databaseHelper.cleanOldMessages(daysToKeep: daysToKeep);
    } catch (e) {
      print('오래된 메시지 정리 실패: $e');
      return 0;
    }
  }
}