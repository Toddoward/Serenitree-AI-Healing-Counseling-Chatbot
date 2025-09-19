import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';  // AuthService 추가

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _serverUrlController = TextEditingController();
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService(); // AuthService 인스턴스 추가
  String _serverUrl = 'http://localhost:8000';
  bool _isLoading = false;
  int _messageCount = 0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadMessageCount();
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    // SharedPreferences에서 서버 URL 로드
    setState(() {
      _serverUrlController.text = _serverUrl;
    });
  }

  Future<void> _loadMessageCount() async {
    try {
      final count = await _chatService.getMessageCount();
      setState(() {
        _messageCount = count;
      });
    } catch (e) {
      print('메시지 개수 로드 실패: $e');
    }
  }

  Future<void> _createBackup() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final backupData = await _chatService.exportMessages();
      
      // 백업 성공 메시지
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              const Text('백업이 생성되었습니다'),
            ],
          ),
          backgroundColor: Colors.green.shade600,
        ),
      );
      
      // 실제 앱에서는 파일 시스템에 저장하거나 공유 기능 추가 가능
      print('백업 데이터: $backupData');
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('백업 생성에 실패했습니다'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red.shade600),
            const SizedBox(width: 8),
            const Text('앱 초기화'),
          ],
        ),
        content: const Text(
          '정말로 모든 데이터를 삭제하시겠습니까?\n\n'
          '삭제되는 내용:\n'
          '• 모든 대화 내용\n'
          '• 저장된 설정\n'
          '• 비밀번호 정보\n\n'
          '이 작업은 되돌릴 수 없습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _resetApp();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('삭제하기'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetApp() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. 모든 대화 내용 삭제
      await _chatService.clearMessages();
      
      // 2. 인증 데이터 초기화 (비밀번호, 생체인증 설정 등)
      await _authService.resetAuthData();
      
      // 3. 메시지 개수 초기화
      setState(() {
        _messageCount = 0;
      });
      
      // 4. 성공 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              const Text('앱이 초기화되었습니다'),
            ],
          ),
          backgroundColor: Colors.green.shade600,
        ),
      );
      
      // 5. 채팅 화면을 초기화하기 위해 온보딩 화면으로 이동
      // 모든 스택을 제거하고 온보딩 화면으로 이동
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/onboarding',
        (route) => false,
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('초기화에 실패했습니다'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    // 설정 저장 로직
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('설정이 저장되었습니다'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  void _showPrecautions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('주의사항'),
        content: const SingleChildScrollView(
          child: Text(
            '''이 앱은 심리적 지원을 위한 AI 동반자입니다.

중요한 주의사항:
• 이 앱은 전문적인 심리 치료나 정신건강 서비스를 대체할 수 없습니다.
• 심각한 위기 상황이나 자해 위험이 있을 때는 즉시 전문가의 도움을 받으세요.
• 모든 대화 내용은 안전하게 암호화되어 저장됩니다.
• 개인정보는 외부로 전송되지 않습니다.

응급상황 연락처:
• 생명의전화: 1588-9191
• 청소년전화: 1388
• 정신건강위기상담전화: 1577-0199

이 앱은 당신의 일상적인 감정 관리와 스트레스 완화를 도와주는 친구 역할을 합니다. 전문적인 치료가 필요한 상황에서는 반드시 전문가와 상담하세요.''',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('설정'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  // 테마 설정 섹션
                  _buildSectionTitle('외관'),
                  const SizedBox(height: 8),
                  _buildSettingCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '테마',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...ThemeMode.values.map((mode) {
                          String title;
                          String subtitle;
                          IconData icon;
                          
                          switch (mode) {
                            case ThemeMode.system:
                              title = '시스템 설정';
                              subtitle = '기기 설정을 따름';
                              icon = Icons.phone_android;
                              break;
                            case ThemeMode.light:
                              title = '라이트 모드';
                              subtitle = '밝은 테마';
                              icon = Icons.light_mode;
                              break;
                            case ThemeMode.dark:
                              title = '다크 모드';
                              subtitle = '어두운 테마';
                              icon = Icons.dark_mode;
                              break;
                          }
                          
                          return Consumer<ThemeService>(
                            builder: (context, themeService, child) {
                              return RadioListTile<ThemeMode>(
                                title: Text(title),
                                subtitle: Text(
                                  subtitle,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                                secondary: Icon(
                                  icon,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                                value: mode,
                                groupValue: themeService.themeMode,
                                onChanged: (value) {
                                  if (value != null) {
                                    themeService.setTheme(value);
                                  }
                                },
                                contentPadding: EdgeInsets.zero,
                                activeColor: Theme.of(context).colorScheme.primary,
                              );
                            },
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // 데이터 관리 섹션
                  _buildSectionTitle('데이터 관리'),
                  const SizedBox(height: 8),
                  _buildSettingCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 저장된 메시지 개수 표시
                        Row(
                          children: [
                            Icon(Icons.chat_bubble_outline, color: Colors.blue.shade600, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '저장된 대화',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '$_messageCount개의 메시지',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton.icon(
                              onPressed: _loadMessageCount,
                              icon: Icon(Icons.refresh, size: 16),
                              label: Text('새로고침'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.blue.shade600,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 16),
                        
                        // 백업 생성
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.backup,
                              color: Colors.green.shade600,
                              size: 24,
                            ),
                          ),
                          title: const Text('대화 백업'),
                          subtitle: const Text('내 대화 내용을 안전하게 보관하세요'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: _isLoading ? null : _createBackup,
                          contentPadding: EdgeInsets.zero,
                        ),
                        
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        
                        // 초기화 버튼
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.delete_forever,
                              color: Colors.red.shade600,
                              size: 24,
                            ),
                          ),
                          title: const Text(
                            '앱 초기화',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: const Text('모든 대화 내용과 설정이 삭제됩니다'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.red),
                          onTap: _isLoading ? null : _showResetDialog,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // 서버 설정 섹션 (테스트용)
                  _buildSectionTitle('개발자 설정'),
                  const SizedBox(height: 8),
                  _buildSettingCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '서버 URL',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '테스트용 서버 주소를 설정하세요',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _serverUrlController,
                          decoration: InputDecoration(
                            hintText: 'http://localhost:8000',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // 정보 섹션
                  _buildSectionTitle('정보'),
                  const SizedBox(height: 8),
                  _buildSettingCard(
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF4FC3F7), // 라이트 블루
                              const Color(0xFF26A69A), // 틸
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.warning,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      title: const Text('주의사항'),
                      subtitle: const Text('앱 사용 전 반드시 확인하세요'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: _showPrecautions,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
            
            // 저장 버튼
            Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF4FC3F7), // 라이트 블루
                    const Color(0xFF26A69A), // 틸
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        '설정 저장',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _buildSettingCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: child,
    );
  }
}