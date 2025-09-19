import 'dart:async';
import 'package:flutter/material.dart';
import '../models/message.dart';
import '../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocus = FocusNode();
  
  List<Message> _messages = [];
  bool _isTyping = false;
  bool _showScrollToBottom = false;
  bool _hasNewMessage = false;
  bool _hasTriggeredWarmup = false;  // 워밍업 플래그 추가
  late AnimationController _typingAnimationController;
  late Animation<double> _typingAnimation;
  Timer? _timestampUpdateTimer;

  @override
  void initState() {
    super.initState();
    
    // 타이핑 애니메이션 초기화
    _typingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _typingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _typingAnimationController,
      curve: Curves.easeInOut,
    ));
    
    // 스크롤 리스너
    _scrollController.addListener(_onScroll);
    
    // 초기 메시지 로드
    _loadMessages();
    
    // 타임스탬프 갱신 타이머 시작
    _startTimestampUpdateTimer();
    
    // 화면 로드 후 최하단으로 스크롤
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocus.dispose();
    _typingAnimationController.dispose();
    _timestampUpdateTimer?.cancel();
    super.dispose();
  }

  void _loadMessages() async {
    try {
      final messages = await _chatService.getMessages();
      
      setState(() {
        _messages = messages;
      });
      
      // 첫 접속 시 AI 인사말 추가
      if (_messages.isEmpty) {
        final welcomeMessage = Message(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: "안녕하세요. 오늘은 어떤 하루를 보내고 계신가요?",
          isFromUser: false,
          timestamp: DateTime.now(),
          status: MessageStatus.delivered,
        );
        
        setState(() {
          _messages.add(welcomeMessage);
        });
        
        await _chatService.addMessage(welcomeMessage);
      }
      
      // 메시지 로드 후 최하단으로 스크롤
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom(animated: false);
      });
      
    } catch (e) {
      print('메시지 로드 오류: $e');
      // 오류 발생 시 기본 인사말만 표시
      final welcomeMessage = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: "안녕하세요. 오늘은 어떤 하루를 보내고 계신가요?",
        isFromUser: false,
        timestamp: DateTime.now(),
        status: MessageStatus.delivered,
      );
      
      setState(() {
        _messages = [welcomeMessage];
      });
      
      await _chatService.addMessage(welcomeMessage);
    }
  }

  void _startTimestampUpdateTimer() {
    _timestampUpdateTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {
          // 타임스탬프만 갱신하기 위한 setState
        });
      }
    });
  }

  void _onScroll() {
    final isAtBottom = _scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 100;
    
    setState(() {
      _showScrollToBottom = !isAtBottom;
      if (isAtBottom) {
        _hasNewMessage = false;
      }
    });
  }

  void _scrollToBottom({bool animated = true}) {
    if (animated) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
    
    setState(() {
      _showScrollToBottom = false;
      _hasNewMessage = false;
    });
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    _messageController.clear();
    
    // 사용자 메시지 추가
    final userMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: messageText,
      isFromUser: true,
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
    );
    
    setState(() {
      _messages.add(userMessage);
      _isTyping = true;
    });
    
          await _chatService.addMessage(userMessage);
    
    // 타이핑 애니메이션 시작
    _typingAnimationController.repeat();
    
    // 최하단으로 스크롤
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    try {
      // 서버 전송
      await _chatService.sendMessage(messageText);
      
      // 순차적 AI 응답 받기
      final aiResponses = await _chatService.getAIResponseSequential(messageText);
      
      // 타이핑 애니메이션 중지
      setState(() {
        _isTyping = false;
      });
      _typingAnimationController.stop();
      
      // 응답이 여러 개인 경우 순차적으로 표시
      if (aiResponses.length > 1) {
        await _chatService.addMessagesSequentially(
          aiResponses,
          (message) {
            // UI 업데이트 콜백
            setState(() {
              _messages.add(message);
            });
            
            // 새 메시지가 있음을 표시 (사용자가 위로 스크롤한 경우)
            if (_showScrollToBottom) {
              setState(() {
                _hasNewMessage = true;
              });
            } else {
              // 최하단으로 스크롤
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollToBottom();
              });
            }
          },
          delay: const Duration(milliseconds: 1500), // 1.5초 딜레이
        );
      } else if (aiResponses.isNotEmpty) {
        // 단일 응답인 경우
        final aiResponse = aiResponses.first;
        setState(() {
          _messages.add(aiResponse);
        });
        await _chatService.addMessage(aiResponse);
        
        // 새 메시지가 있음을 표시 (사용자가 위로 스크롤한 경우)
        if (_showScrollToBottom) {
          setState(() {
            _hasNewMessage = true;
          });
        } else {
          // 최하단으로 스크롤
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        }
      }
      
    } catch (e) {
      setState(() {
        _isTyping = false;
      });
      _typingAnimationController.stop();
      
      // 에러 처리
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('메시지 전송에 실패했습니다')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF4FC3F7),
                    const Color(0xFF26A69A),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.park,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Serenitree',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '항상 함께 있어요',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF1E1E1E)  // 다크모드: 어두운 회색
            : Colors.white,            // 라이트모드: 흰색
        foregroundColor: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFFE0E0E0)
            : Colors.grey.shade800,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).pushNamed('/settings');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 메시지 목록
          Expanded(
            child: Stack(
              children: [
                ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length + (_isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length && _isTyping) {
                      return _buildTypingIndicator();
                    }
                    
                    final message = _messages[index];
                    return _buildMessageBubble(message);
                  },
                ),
                
                // 최하단 스크롤 버튼
                if (_showScrollToBottom)
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: FloatingActionButton.small(
                      onPressed: _scrollToBottom,
                      backgroundColor: _hasNewMessage 
                          ? const Color(0xFF4FC3F7)
                          : Colors.grey.shade600,
                      child: _hasNewMessage
                          ? Stack(
                              children: [
                                const Icon(Icons.chat_bubble, color: Colors.white),
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 8,
                                      minHeight: 8,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
          
          // 메시지 입력 영역
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: message.isFromUser 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isFromUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF4FC3F7),
                    const Color(0xFF26A69A),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.park,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],
          
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: message.isFromUser 
                    ? const Color(0xFF4FC3F7)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(18).copyWith(
                  bottomLeft: message.isFromUser 
                      ? const Radius.circular(18) 
                      : const Radius.circular(4),
                  bottomRight: message.isFromUser 
                      ? const Radius.circular(4) 
                      : const Radius.circular(18),
                ),
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  color: message.isFromUser ? Colors.white : Colors.grey.shade800,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // 모든 메시지에 타임스탬프 표시
          Text(
            _formatTime(message.timestamp),
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF4FC3F7),
                  const Color(0xFF26A69A),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.park,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? const Color(0xFF2C2C2C)  // 다크모드: 부드러운 어두운 회색
                  : Colors.grey.shade200,    // 라이트모드: 기존 색상
              borderRadius: BorderRadius.circular(18).copyWith(
                bottomLeft: const Radius.circular(4),
              ),
            ),
            child: AnimatedBuilder(
              animation: _typingAnimation,
              builder: (context, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTypingDot(0),
                    const SizedBox(width: 3),
                    _buildTypingDot(1),
                    const SizedBox(width: 3),
                    _buildTypingDot(2),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    final delay = index * 0.2;
    return AnimatedBuilder(
      animation: _typingAnimationController,
      builder: (context, child) {
        final value = (_typingAnimationController.value - delay).clamp(0.0, 1.0);
        final opacity = (value * 2).clamp(0.3, 1.0);
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.grey.shade600.withOpacity(opacity),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF1E1E1E)  // 다크모드: 어두운 회색
            : Colors.white,            // 라이트모드: 흰색
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? const Color(0xFF2C2C2C)  // 다크모드: 입력창 배경
                    : Colors.grey.shade100,    // 라이트모드: 기존 색상
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                focusNode: _messageFocus,
                maxLines: 5,
                minLines: 1,
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? const Color(0xFFE0E0E0)
                      : Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: '메시지를 입력하세요...',
                  hintStyle: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? const Color(0xFF888888)
                        : Colors.grey.shade600,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                onSubmitted: (_) => _sendMessage(),
                textInputAction: TextInputAction.send,
                onChanged: (text) {
                  // 워밍업 기능 추가
                  if (!_hasTriggeredWarmup && text.isNotEmpty) {
                    _hasTriggeredWarmup = true;
                    _chatService.warmupModel();
                  }
                  if (text.isEmpty) {
                    _hasTriggeredWarmup = false;
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF4FC3F7),
                    const Color(0xFF26A69A),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return '방금 전';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}시간 전';
    } else if (difference.inDays == 1) {
      return '어제';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      // 일주일 이상 된 메시지는 날짜 표시
      return '${timestamp.month}/${timestamp.day}';
    }
  }
}