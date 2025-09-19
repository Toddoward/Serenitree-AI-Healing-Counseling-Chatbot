import os
from dotenv import load_dotenv

# .env 파일 로드
load_dotenv()

class Settings:
    # Ollama 설정
    OLLAMA_BASE_URL: str = os.getenv("OLLAMA_BASE_URL", "http://localhost:11434")
    DEFAULT_MODEL: str = os.getenv("DEFAULT_MODEL", "gemma3:4b")
    OLLAMA_KEEP_ALIVE: str = os.getenv("OLLAMA_KEEP_ALIVE", "10m")
    
    # FastAPI 서버 설정
    HOST: str = os.getenv("HOST", "0.0.0.0")
    PORT: int = int(os.getenv("PORT", "8000"))
    DEBUG: bool = os.getenv("DEBUG", "True").lower() == "true"
    
    # CORS 설정
    CORS_ORIGINS: list = os.getenv("CORS_ORIGINS", "").split(",")
    
    # 로깅 설정
    LOG_LEVEL: str = os.getenv("LOG_LEVEL", "INFO")
    
    # API 설정
    API_V1_STR: str = "/api/v1"
    PROJECT_NAME: str = "Serenitree Backend"

# 전역 설정 객체
settings = Settings()