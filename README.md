# 🌳 Serenitree

**트라우마 치유를 위한 AI 동반자 챗봇**

Serenitree는 트라우마 피해자들에게 안전한 대화 공간을 제공하는 AI 상담 챗봇 애플리케이션입니다. 판단하지 않는 따뜻한 AI 친구와의 자연스러운 대화를 통해 감정 관리와 심리적 안정감을 지원합니다.

> <img width="1920" height="1080" alt="스플래시" src="https://github.com/user-attachments/assets/7f3630c9-6e4e-4186-a3a5-d922f2443082" />

## ✨ 주요 특징

- **완전한 프라이버시**: 모든 대화 내용이 로컬 SQLite 데이터베이스에 암호화되어 저장
- **기다려주는 AI**: 트라우마 치유 특화 프롬프트로 기다림과 공감 제공
- **안전한 인증**: PIN 및 생체 인증을 통한 개인정보 보호
- **실제같은 대화**: AI의 SNS같은 단답식 응답으로 실제 대화같은 느낌 연출
- **오프라인 우선**: 로컬 처리 중심으로 데이터 외부 유출 방지

> <img width="1920" height="1080" alt="온보딩화면들" src="https://github.com/user-attachments/assets/c6dcdd5a-7af9-4aa2-99e8-b581410fe30f" />

## 🛠️ 기술 스택

### Frontend (Flutter)
![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)
![SQLite](https://img.shields.io/badge/sqlite-%2307405e.svg?style=for-the-badge&logo=sqlite&logoColor=white)

- **Framework**: Flutter 3.x
- **언어**: Dart
- **상태관리**: Provider
- **로컬 저장소**: SQLite + 암호화
- **인증**: Local Auth (지문/얼굴 인식)
- **의존성 관리**: pubspec.yaml

### Backend (FastAPI)
![FastAPI](https://img.shields.io/badge/FastAPI-005571?style=for-the-badge&logo=fastapi)
![Python](https://img.shields.io/badge/python-3670A0?style=for-the-badge&logo=python&logoColor=ffdd54)
![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white)

- **Framework**: FastAPI
- **언어**: Python 3.x
- **AI 모델**: Ollama + Gemma3:4b
- **비동기 처리**: AsyncIO
- **CORS**: 모바일 앱 연동 지원

## 📁 프로젝트 구조

```
serenitree/
├── lib/                              # Flutter 앱 코드
│   ├── main.dart                     # 앱 진입점 및 라우팅
│   ├── models/
│   │   └── message.dart              # 메시지 데이터 모델
│   ├── screens/
│   │   ├── onboarding_screen.dart    # 온보딩 화면
│   │   ├── login_screen.dart         # PIN/생체인증 로그인
│   │   ├── chat_screen.dart          # 메인 채팅 인터페이스
│   │   └── settings_screen.dart      # 설정 및 데이터 관리
│   ├── services/
│   │   ├── auth_service.dart         # 인증 관리
│   │   ├── chat_service.dart         # 채팅 로직 및 API 통신
│   │   ├── database_helper.dart      # SQLite 데이터베이스 관리
│   │   ├── encryption_service.dart   # 메시지 암호화
│   │   └── theme_service.dart        # 다크/라이트 테마
│   └── widgets/
│       └── pin_input.dart            # 커스텀 PIN 입력 위젯

serenitree_backend/
├── app/
│   ├── main.py                       # FastAPI 서버 진입점
│   ├── api/
│   │   └── chat.py                   # 채팅 API 엔드포인트
│   ├── services/
│   │   ├── ollama_service.py         # Ollama AI 모델 연동
│   │   └── sequential_response_service.py # 순차 메시지 분할
│   └── core/
│       └── config.py                 # 서버 설정 관리
├── requirements.txt                  # Python 의존성
└── .env                             # 환경 변수 설정
```

## 🚀 핵심 기능 및 구현

### 🔐 1. 보안 중심 설계

**암호화된 로컬 저장소**
```dart
// 메시지 암호화 저장
final encryptedContent = _encrypt(message.content);
await db.insert('messages', {
  'encrypted_content': encryptedContent,
  'timestamp': DateTime.now().millisecondsSinceEpoch,
});
```

**다층 인증 시스템**
- PIN 인증: SHA-256 해시로 안전한 저장
- 생체 인증: Flutter Local Auth 패키지 활용
- 첫 실행시 안내 문구를 통한 보안 안내

> <img width="1920" height="1080" alt="로그인화면" src="https://github.com/user-attachments/assets/2f58ef1b-3824-4681-828d-f02dd02b07c0" />

### 🤖 2. 트라우마 특화 AI 대화

**공감적 시스템 프롬프트**
```python
DEFAULT_SYSTEM_PROMPT = """
당신은 Serenitree라는 따뜻한 AI 친구입니다.

중요한 대화 원칙:
1. 항상 1-2문장으로 짧고 자연스럽게 응답하세요
2. 직접적인 질문보다는 "괜찮으신가요?" 같은 부드러운 관심을 표현하세요
3. 판단하지 말고 무조건적으로 수용하고 공감하세요
4. 채팅하는 친구처럼 자연스럽고 편안한 톤을 사용하세요
"""
```

**순차적 메시지 전송**
- 긴 AI 응답을 자연스러운 문장 단위로 분할
- 순차 전송하여 실제 대화감 연출

> <img width="1920" height="1080" alt="채팅" src="https://github.com/user-attachments/assets/ff3ea72f-e22e-4159-accc-3548abf67212" />

### 🎨 3. 사용자 경험 최적화

**적응형 UI 디자인**
- 디바이스 환경 설정에따라 다크/라이트 테마 자동 전환
- 트라우마 사용자 고려한 부드러운 색상 팔레트
- 직관적인 네비게이션과 최소한의 인터페이스

**성능 최적화**
- AI 모델 워밍업으로 응답 지연 최소화
- 로컬 우선 처리로 빠른 반응성
- 메모리 효율적인 메시지 로딩 (최근 100개)

### 💾 4. 데이터 관리 및 백업

**안전한 데이터 관리**
```dart
// 메시지 개수 조회 및 정리
Future<int> cleanOldMessages({int daysToKeep = 30}) async {
  final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
  return await db.delete('messages', 
    where: 'timestamp < ?', 
    whereArgs: [cutoffDate.millisecondsSinceEpoch]);
}
```

**완전한 앱 초기화**
- 모든 대화 내용 삭제
- 인증 정보 완전 제거
- 초기 화면으로 안전한 재설정

> <img width="1920" height="1080" alt="데이터관리" src="https://github.com/user-attachments/assets/e796685c-f80e-4fdb-961c-d9abaeaf6726" />

## ⚡ 설치 및 실행

### 📱 앱 빌드
```bash
# APK 빌드
flutter build apk --release

# 의존성 설치
flutter pub get
```

### 🖥️ 서버 실행
```bash
# 가상환경 생성 및 활성화
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# 의존성 설치
pip install -r requirements.txt

# Ollama 모델 설치 (최초 1회)
ollama pull gemma3:4b

# 서버 실행
python main.py
```

## 💡 개발 의도

이 프로젝트는 트라우마 피해자들이 안전하고 편안하게 감정을 표현할 수 있는 디지털 공간을 만들기 위해 개발되었습니다. 전문적인 치료를 대체하는 것이 아니라, 일상적인 감정 관리와 초기 심리적 지원을 제공하는 것을 목표로 합니다.

## 📄 라이선스

이 프로젝트는 비상업적 목적으로 개발되었습니다.

---

> **⚠️ 중요**: 이 앱은 전문적인 심리치료를 대체할 수 없습니다. 심각한 위기상황에서는 전문가의 도움을 받으시기 바랍니다.
> 
> - 생명의전화: 1588-9191
> - 청소년전화: 1388  
> - 정신건강위기상담전화: 1577-0199
