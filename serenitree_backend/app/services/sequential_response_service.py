import asyncio
import re
from typing import List

class SequentialResponseService:
    """
    긴 AI 응답을 여러 개의 짧은 메시지로 나누어 순차적으로 전송하는 서비스
    """
    
    def __init__(self):
        self.delay_between_messages = 1.5  # 메시지 간 딜레이 (초)
    
    def split_response(self, text: str) -> List[str]:
        """
        긴 텍스트를 자연스러운 단위로 분할
        """
        if not text.strip():
            return [text]
        
        # 문장 단위로 분할 (한국어 문장 부호 고려)
        sentences = re.split(r'[.!?。！？]\s*', text.strip())
        sentences = [s.strip() for s in sentences if s.strip()]
        
        # 마지막 요소가 비어있으면 제거
        if sentences and not sentences[-1]:
            sentences.pop()
        
        # 문장이 2개 이하면 분할하지 않음
        if len(sentences) <= 2:
            return [text]
        
        # 문장들을 1-2문장씩 그룹핑
        chunks = []
        i = 0
        while i < len(sentences):
            # 첫 번째 문장
            chunk = sentences[i]
            
            # 두 번째 문장이 있고, 첫 번째 문장이 너무 짧으면 합치기
            if (i + 1 < len(sentences) and 
                len(sentences[i]) < 30 and 
                len(sentences[i + 1]) < 50):
                chunk += ". " + sentences[i + 1]
                i += 2
            else:
                chunk += "."
                i += 1
            
            chunks.append(chunk)
        
        return chunks
    
    def should_split_response(self, text: str) -> bool:
        """
        응답을 분할해야 하는지 판단
        """
        # 문장 수 확인
        sentence_count = len(re.findall(r'[.!?。！？]', text))
        
        # 3문장 이상이거나 길이가 100자 이상이면 분할
        return sentence_count >= 3 or len(text) > 100
    
    async def send_sequential_response(
        self, 
        full_response: str,
        callback_func,
        delay: float = None
    ):
        """
        응답을 순차적으로 전송
        
        Args:
            full_response: 전체 응답 텍스트
            callback_func: 각 메시지를 전송할 콜백 함수
            delay: 메시지 간 딜레이 (기본값: self.delay_between_messages)
        """
        if delay is None:
            delay = self.delay_between_messages
            
        # 분할이 필요한지 확인
        if not self.should_split_response(full_response):
            # 분할하지 않고 바로 전송
            await callback_func(full_response, is_final=True)
            return
        
        # 메시지 분할
        chunks = self.split_response(full_response)
        
        # 순차적으로 전송
        for i, chunk in enumerate(chunks):
            is_final = (i == len(chunks) - 1)
            await callback_func(chunk, is_final=is_final)
            
            # 마지막 메시지가 아니면 딜레이
            if not is_final:
                await asyncio.sleep(delay)

# 전역 인스턴스
sequential_service = SequentialResponseService()