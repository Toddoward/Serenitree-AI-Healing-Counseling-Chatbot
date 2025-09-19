from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import uvicorn

from app.core.config import settings
from app.api import chat

# FastAPI 앱 초기화
app = FastAPI(
    title=settings.PROJECT_NAME,
    version="1.0.0",
    description="Serenitree - 트라우마 치유 AI 상담챗봇 백엔드"
)

# 앱 시작 이벤트 - 모델 워밍업
@app.on_event("startup")
async def startup_event():
    print("🌟 Serenitree 서버 시작 중...")
    print("🔥 AI 모델 워밍업을 시작합니다...")
    
    try:
        from app.services.ollama_service import ollama_service
        
        # 더미 요청으로 모델을 메모리에 로딩
        warmup_result = await ollama_service.generate_response(
            prompt="안녕하세요",
            system_prompt="간단히 인사해주세요.",
            temperature=0.1,
            max_tokens=50
        )
        
        if warmup_result["success"]:
            print(f"✅ AI 모델 워밍업 완료: {warmup_result['model']}")
        else:
            print(f"⚠️ 워밍업 실패: {warmup_result['error']}")
            
    except Exception as e:
        print(f"❌ 워밍업 중 오류 발생: {e}")
    
    print("🚀 Serenitree 서버가 준비되었습니다!")

# CORS 설정 (Flutter 앱에서 접근 허용)
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["*"],
)

# API 라우터 등록
app.include_router(
    chat.router,
    prefix=settings.API_V1_STR + "/chat",
    tags=["chat"]
)

# 기본 헬스체크 엔드포인트
@app.get("/")
async def health_check():
    return JSONResponse({
        "status": "healthy",
        "message": "Serenitree Backend Server",
        "version": "1.0.0"
    })

# 서버 정보 엔드포인트
@app.get("/info")
async def server_info():
    return JSONResponse({
        "project": settings.PROJECT_NAME,
        "ollama_url": settings.OLLAMA_BASE_URL,
        "model": settings.DEFAULT_MODEL,
        "debug_mode": settings.DEBUG
    })

# 개발 서버 실행 (python main.py로 직접 실행 가능)
if __name__ == "__main__":
    uvicorn.run(
        "app.main:app",
        host=settings.HOST,
        port=settings.PORT,
        reload=settings.DEBUG
    )