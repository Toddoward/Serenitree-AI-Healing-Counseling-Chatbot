from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional, List
from app.services.ollama_service import ollama_service
from app.services.sequential_response_service import sequential_service

# API 라우터 생성
router = APIRouter()

# 트라우마 상담용 시스템 프롬프트 (공통 사용)
DEFAULT_SYSTEM_PROMPT = """
당신은 Serenitree라는 따뜻한 AI 친구입니다.

중요한 대화 원칙:
1. 항상 1-2문장으로 짧고 자연스럽게 응답하세요
2. 직접적인 질문보다는 "괜찮으신가요?" 같은 부드러운 관심을 표현하세요  
3. 사용자가 먼저 이야기할 때까지 구체적인 상황을 묻지 마세요
4. 판단하지 말고 무조건적으로 수용하고 공감하세요
5. 채팅하는 친구처럼 자연스럽고 편안한 톤을 사용하세요
6. 긴 조언이나 분석은 피하고 간단한 지지 표현을 하세요

대화 예시:
- 사용자: "오늘 힘들어요" → "많이 힘드셨군요. 어떤 기분이신지 조금은 알 것 같아요."
- 사용자: "잠이 안 와요" → "잠 못 드시는 밤이 있으시는군요. 지금 괜찮으신가요?"

절대 하지 말 것:
- 긴 문단으로 답변하기
- "무슨 일이 있었나요?" 같은 직접적 질문
- 전문적인 조언이나 해결책 제시
- 여러 개의 질문을 한 번에 하기

한국어로 대화하며, 사용자가 안전하다고 느낄 수 있도록 도와주세요.
""".strip()

# 요청 모델 정의
class ChatRequest(BaseModel):
    message: str
    system_prompt: Optional[str] = None
    temperature: Optional[float] = 0.7

# 순차적 응답 모델 정의
class SequentialChatResponse(BaseModel):
    responses: List[str]
    model: str
    success: bool
    error: Optional[str] = None
    is_sequential: bool = False

async def _generate_ai_response(request: ChatRequest) -> dict:
    """
    AI 응답 생성 공통 헬퍼 함수
    """
    system_prompt = request.system_prompt or DEFAULT_SYSTEM_PROMPT
    
    return await ollama_service.generate_response(
        prompt=request.message,
        system_prompt=system_prompt,
        temperature=request.temperature
    )

@router.post("/send-sequential", response_model=SequentialChatResponse)
async def send_message_sequential(request: ChatRequest):
    """
    사용자 메시지를 받아 순차적 AI 응답 생성 (긴 응답을 여러 메시지로 분할)
    """
    try:
        # 공통 헬퍼 함수 사용
        result = await _generate_ai_response(request)
        
        if result["success"]:
            full_response = result["content"]
            
            # 순차 전송이 필요한지 확인
            if sequential_service.should_split_response(full_response):
                # 응답을 여러 부분으로 분할
                response_chunks = sequential_service.split_response(full_response)
                return SequentialChatResponse(
                    responses=response_chunks,
                    model=result["model"],
                    success=True,
                    is_sequential=True
                )
            else:
                # 짧은 응답은 그대로 반환
                return SequentialChatResponse(
                    responses=[full_response],
                    model=result["model"],
                    success=True,
                    is_sequential=False
                )
        else:
            return SequentialChatResponse(
                responses=[result["content"]],
                model="unknown",
                success=False,
                error=result["error"],
                is_sequential=False
            )
            
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Internal server error: {str(e)}"
        )

@router.post("/warmup")
async def warmup_model():
    """
    모델 워밍업 - 사용자가 타이핑 시작할 때 호출
    """
    try:
        # 간단한 더미 요청으로 모델을 활성화
        result = await ollama_service.generate_response(
            prompt="준비",
            system_prompt="준비 완료라고 간단히 답해주세요.",
            temperature=0.1,
            max_tokens=20
        )
        
        return {
            "status": "success" if result["success"] else "failed",
            "message": "모델 워밍업 완료" if result["success"] else "워밍업 실패"
        }
        
    except Exception as e:
        return {
            "status": "failed",
            "message": f"워밍업 오류: {str(e)}"
        }

@router.options("/warmup")
async def warmup_options():
    return {"message": "OK"}

@router.get("/health")
async def check_ollama_health():
    """
    Ollama 서버 상태 확인
    """
    is_healthy = await ollama_service.check_health()
    models = await ollama_service.list_models()
    
    return {
        "ollama_status": "healthy" if is_healthy else "unhealthy",
        "available_models": models,
        "default_model": ollama_service.default_model
    }