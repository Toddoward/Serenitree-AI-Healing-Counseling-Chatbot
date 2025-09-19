import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/pin_input.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final AuthService _authService = AuthService();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,  // 키보드로 인한 리사이즈 방지
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          onPageChanged: (page) {
            setState(() {
              _currentPage = page;
            });
          },
          children: [
            _buildWelcomePage(),
            _buildSecurityExplanationPage(),
            _buildPasswordSetupPage(),
            _buildBiometricsSetupPage(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            
            // 앱 아이콘/로고 영역
            Container(
              width: 120,
              height: 120,
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
                size: 60,
                color: Colors.white,
              ),
            ),
            
            const SizedBox(height: 32),
            
            Text(
              'Serenitree',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade700,
              ),
            ),
            
            const SizedBox(height: 16),
            
            Text(
              '안전한 대화 공간',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            
            const SizedBox(height: 40),
            
            // 설명 텍스트
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark 
                      ? const Color(0xFF2C2C2C)  // 다크모드: 입력창 배경
                      : Colors.grey.shade100,    // 라이트모드: 기존 색상
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.teal.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lock, color: Colors.teal.shade600, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '완전한 프라이버시',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('모든 대화는 안전하게 보호됩니다'),
                  
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Icon(Icons.favorite, color: Colors.pink.shade400, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '판단하지 않는 친구',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('어떤 이야기든 편하게 나누세요'),
                  
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Icon(Icons.access_time, color: Colors.orange.shade400, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '언제든지 함께',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('24시간 당신 곁에 있을게요'),
                ],
              ),
            ),
            
            const SizedBox(height: 48),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '시작하기',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityExplanationPage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 40),
            
            Icon(
              Icons.security,
              size: 80,
              color: Colors.teal.shade600,
            ),
            
            const SizedBox(height: 32),
            
            Text(
              '안전한 공간을 만들어요',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 24),
            
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark 
                      ? const Color(0xFF2C2C2C)  // 다크모드: 입력창 배경
                      : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '이 앱은 완전히 당신만의 안전한 공간입니다',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text('• 모든 대화가 안전하게 암호화됩니다'),
                  SizedBox(height: 8),
                  Text('• 오직 당신만 접근할 수 있습니다'),
                  SizedBox(height: 8),
                  Text('• 개인정보는 외부로 전송되지 않습니다'),
                  SizedBox(height: 8),
                  Text('• 언제든지 모든 내용을 삭제할 수 있습니다'),
                ],
              ),
            ),
            
            const SizedBox(height: 48),
            
            const Text(
              '이제 당신만의 비밀번호를 설정해보세요',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '비밀번호 설정하기',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordSetupPage() {
    String enteredPin = '';
    String confirmPin = '';
    bool isConfirmMode = false;

    return StatefulBuilder(
      builder: (context, setState) {
        return SingleChildScrollView(  // 스크롤 가능하게 감싸기
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 40),
                
                Icon(
                  Icons.lock_outline,
                  size: 80,
                  color: Colors.teal.shade600,
                ),
                
                const SizedBox(height: 32),
                
                Text(
                  isConfirmMode ? 'PIN 확인' : 'PIN 설정',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade700,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  isConfirmMode 
                      ? '동일한 4자리 PIN을 다시 입력해주세요'
                      : '4자리 숫자 PIN을 설정해주세요.\n이 PIN으로 앱을 보호할 수 있습니다.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                
                const SizedBox(height: 40),
                
                // PIN 입력 표시
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    final currentPin = isConfirmMode ? confirmPin : enteredPin;
                    final isFilledBox = index < currentPin.length;
                    
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
                
                const SizedBox(height: 40),
                
                // 숫자 키패드
                NumericKeypad(
                  onNumberPressed: (number) {
                    setState(() {
                      if (isConfirmMode) {
                        if (confirmPin.length < 4) {
                          confirmPin += number;
                        }
                      } else {
                        if (enteredPin.length < 4) {
                          enteredPin += number;
                        }
                      }
                    });
                    
                    // PIN이 4자리가 되면 처리
                    if (isConfirmMode && confirmPin.length == 4) {
                      _handleConfirmPin(confirmPin, enteredPin, setState);
                    } else if (!isConfirmMode && enteredPin.length == 4) {
                      setState(() {
                        isConfirmMode = true;
                      });
                    }
                  },
                  onDeletePressed: () {
                    setState(() {
                      if (isConfirmMode) {
                        if (confirmPin.isNotEmpty) {
                          confirmPin = confirmPin.substring(0, confirmPin.length - 1);
                        }
                      } else {
                        if (enteredPin.isNotEmpty) {
                          enteredPin = enteredPin.substring(0, enteredPin.length - 1);
                        }
                      }
                    });
                  },
                ),
                
                const SizedBox(height: 20),
                
                if (isConfirmMode)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        isConfirmMode = false;
                        confirmPin = '';
                      });
                    },
                    child: const Text('다시 설정하기'),
                  ),
                
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleConfirmPin(String confirmPin, String enteredPin, StateSetter setState) async {
    if (confirmPin == enteredPin) {
      final success = await _authService.setPassword(enteredPin);
      if (success) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        _showSnackBar('PIN 설정에 실패했습니다');
      }
    } else {
      _showSnackBar('PIN이 일치하지 않습니다');
      setState(() {
        confirmPin = '';
      });
    }
  }

  Widget _buildBiometricsSetupPage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 40),
            
            Icon(
              Icons.fingerprint,
              size: 80,
              color: Colors.teal.shade600,
            ),
            
            const SizedBox(height: 32),
            
            Text(
              '생체 인증',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade700,
              ),
            ),
            
            const SizedBox(height: 16),
            
            const Text(
              '지문이나 얼굴 인식으로 더 쉽고 안전하게\n앱에 접근할 수 있습니다.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            
            const SizedBox(height: 32),
            
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark 
                      ? const Color(0xFF2C2C2C)  // 다크모드: 입력창 배경
                      : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green.shade600,
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '더 빠른 접근',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('비밀번호를 매번 입력할 필요가 없습니다'),
                ],
              ),
            ),
            
            const SizedBox(height: 48),
            
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      final canUse = await _authService.canUseBiometrics();
                      if (canUse) {
                        final success = await _authService.enableBiometrics();
                        if (success) {
                          await _authService.completeOnboarding();
                          _navigateToChat();
                        } else {
                          _showSnackBar('생체 인증 설정에 실패했습니다');
                        }
                      } else {
                        _showSnackBar('생체 인증을 사용할 수 없습니다');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '생체 인증 사용하기',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () async {
                      await _authService.completeOnboarding();
                      _navigateToChat();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.teal.shade600,
                      side: BorderSide(color: Colors.teal.shade600),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '나중에 설정하기',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade300,
      ),
    );
  }

  void _navigateToChat() {
    Navigator.of(context).pushReplacementNamed('/chat');
  }
}