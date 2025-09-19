import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/pin_input.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  String _enteredPin = '';
  bool _isLoading = false;
  bool _canUseBiometrics = false;
  bool _biometricsEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final canUse = await _authService.canUseBiometrics();
    final isEnabled = await _authService.isBiometricsEnabled();
    
    setState(() {
      _canUseBiometrics = canUse;
      _biometricsEnabled = isEnabled;
    });
    
    // 생체 인증이 활성화되어 있으면 자동으로 시도
    if (_biometricsEnabled) {
      _tryBiometricAuth();
    }
  }

  Future<void> _tryBiometricAuth() async {
    if (!_canUseBiometrics || !_biometricsEnabled) return;
    
    try {
      final authenticated = await _authService.authenticateWithBiometrics();
      if (authenticated) {
        _navigateToChat();
      }
    } catch (e) {
      // 생체 인증 실패 시 PIN 입력으로 대체
    }
  }

  Future<void> _verifyPin(String pin) async {
    setState(() {
      _isLoading = true;
    });

    final isValid = await _authService.verifyPassword(pin);
    
    setState(() {
      _isLoading = false;
    });

    if (isValid) {
      _navigateToChat();
    } else {
      _showSnackBar('PIN이 올바르지 않습니다');
      setState(() {
        _enteredPin = '';
      });
    }
  }

  void _navigateToChat() {
    Navigator.of(context).pushReplacementNamed('/chat');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,  // 키보드로 인한 리사이즈 방지
      body: SafeArea(
        child: SingleChildScrollView(  // 전체를 스크롤 가능하게 감쌈
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top,
            ),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    
                    // 앱 로고
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.teal.shade300, Colors.teal.shade600],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.park,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    Text(
                      'Serenitree',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade700,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      '당신만의 안전한 공간',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    
                    const SizedBox(height: 48),
                    
                    // 생체 인증 버튼 (활성화된 경우)
                    if (_canUseBiometrics && _biometricsEnabled) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: OutlinedButton.icon(
                          onPressed: _tryBiometricAuth,
                          icon: Icon(
                            Icons.fingerprint,
                            size: 28,
                            color: Colors.teal.shade600,
                          ),
                          label: Text(
                            '생체 인증으로 로그인',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.teal.shade600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.teal.shade600, width: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey.shade300)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              '또는',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.grey.shade300)),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                    ],
                    
                    // PIN 입력 제목
                    Text(
                      'PIN을 입력하세요',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // PIN 표시
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (index) {
                        final isFilledBox = index < _enteredPin.length;
                        
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: isFilledBox 
                            ? Colors.teal.shade600
                            : Theme.of(context).brightness == Brightness.dark 
                              ? Colors.grey.shade600
                              : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isFilledBox 
                            ? Colors.teal.shade600
                            : Theme.of(context).brightness == Brightness.dark 
                              ? Colors.grey.shade800
                              : Colors.grey.shade400,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: isFilledBox
                                ? const Icon(
                                    Icons.circle,
                                    color: Colors.white,
                                    size: 16,
                                  )
                                : null,
                          ),
                        );
                      }),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // 로딩 표시 또는 숫자 키패드
                    if (_isLoading)
                      const CircularProgressIndicator()
                    else
                      NumericKeypad(
                        onNumberPressed: (number) {
                          if (_enteredPin.length < 4) {
                            setState(() {
                              _enteredPin += number;
                            });
                            
                            // PIN이 4자리가 되면 자동 검증
                            if (_enteredPin.length == 4) {
                              _verifyPin(_enteredPin);
                            }
                          }
                        },
                        onDeletePressed: () {
                          if (_enteredPin.isNotEmpty) {
                            setState(() {
                              _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
                            });
                          }
                        },
                      ),
                    
                    const SizedBox(height: 40),
                    
                    // 하단 도움말
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? const Color(0xFF2C2C2C)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.grey.shade600,
                            size: 20,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'PIN을 잊으셨나요?',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '현재는 PIN 재설정 기능이 없습니다.\n앱을 재설치하여 새로 설정할 수 있습니다.',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}