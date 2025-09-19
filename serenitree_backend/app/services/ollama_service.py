import httpx
import json
from typing import Dict, List, Optional
from app.core.config import settings

class OllamaService:
    def __init__(self):
        self.base_url = settings.OLLAMA_BASE_URL
        self.default_model = settings.DEFAULT_MODEL
    
    async def generate_response(
        self,
        prompt: str,
        model: Optional[str] = None,
        system_prompt: Optional[str] = None,
        temperature: float = 0.7,
        max_tokens: int = 2048
    ) -> Dict:
        """
        Ollama API를 통해 응답 생성
        """
        try:
            model = model or self.default_model
            
            # 메시지 구성
            messages = []
            if system_prompt:
                messages.append({"role": "system", "content": system_prompt})
            messages.append({"role": "user", "content": prompt})
            
            # Ollama API 요청 데이터
            request_data = {
                "model": model,
                "messages": messages,
                "stream": False,
                "keep_alive": settings.OLLAMA_KEEP_ALIVE,
                "options": {
                    "temperature": temperature,
                    "num_predict": max_tokens
                }
            }
            
            async with httpx.AsyncClient(timeout=60.0) as client:
                response = await client.post(
                    f"{self.base_url}/api/chat",
                    json=request_data
                )
                response.raise_for_status()
                
                result = response.json()
                return {
                    "success": True,
                    "content": result["message"]["content"],
                    "model": model,
                    "tokens": result.get("eval_count", 0)
                }
                
        except httpx.TimeoutException:
            return {
                "success": False,
                "error": "Request timeout - Ollama server may be slow",
                "content": "죄송합니다. 서버 응답이 지연되고 있습니다. 잠시 후 다시 시도해주세요."
            }
        except httpx.ConnectError:
            return {
                "success": False,
                "error": "Connection failed - Ollama server not available",
                "content": "서버에 연결할 수 없습니다. Ollama가 실행 중인지 확인해주세요."
            }
        except Exception as e:
            return {
                "success": False,
                "error": f"Unexpected error: {str(e)}",
                "content": "시스템 오류가 발생했습니다. 잠시 후 다시 시도해주세요."
            }
    
    async def check_health(self) -> bool:
        """
        Ollama 서버 상태 확인
        """
        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                response = await client.get(f"{self.base_url}/api/tags")
                return response.status_code == 200
        except:
            return False
    
    async def list_models(self) -> List[str]:
        """
        사용 가능한 모델 목록 조회
        """
        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                response = await client.get(f"{self.base_url}/api/tags")
                if response.status_code == 200:
                    data = response.json()
                    return [model["name"] for model in data.get("models", [])]
                return []
        except:
            return []

# 전역 인스턴스
ollama_service = OllamaService()