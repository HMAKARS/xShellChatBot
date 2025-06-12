import requests
import json
import re
import logging
from typing import Dict, List, Optional, Any
from django.conf import settings
from django.core.cache import cache

from chatbot.models import ChatSession, ChatMessage, AIModel

logger = logging.getLogger('xshell_chatbot')


class OllamaClient:
    """Ollama AI 클라이언트"""
    
    def __init__(self, base_url: str = None, model: str = None):
        self.base_url = base_url or settings.OLLAMA_BASE_URL
        self.model = model or settings.DEFAULT_AI_MODEL
        self.timeout = 30
    
    def generate(self, prompt: str, system_prompt: str = "", stream: bool = False) -> Dict[str, Any]:
        """텍스트 생성"""
        payload = {
            "model": self.model,
            "prompt": prompt,
            "system": system_prompt,
            "stream": stream,
            "options": {
                "temperature": 0.7,
                "top_p": 0.9,
                "top_k": 40
            }
        }
        
        try:
            response = requests.post(
                f"{self.base_url}/api/generate",
                json=payload,
                timeout=self.timeout
            )
            response.raise_for_status()
            
            if stream:
                return response
            else:
                return response.json()
                
        except requests.RequestException as e:
            logger.error(f"Ollama API 호출 실패: {e}")
            raise Exception(f"AI 서비스에 연결할 수 없습니다: {e}")
    
    def chat(self, messages: List[Dict[str, str]]) -> Dict[str, Any]:
        """채팅 형식 생성"""
        payload = {
            "model": self.model,
            "messages": messages,
            "stream": False
        }
        
        try:
            response = requests.post(
                f"{self.base_url}/api/chat",
                json=payload,
                timeout=self.timeout
            )
            response.raise_for_status()
            return response.json()
            
        except requests.RequestException as e:
            logger.error(f"Ollama Chat API 호출 실패: {e}")
            raise Exception(f"AI 서비스에 연결할 수 없습니다: {e}")
    
    def is_available(self) -> bool:
        """Ollama 서비스 사용 가능 여부 확인"""
        try:
            response = requests.get(f"{self.base_url}/api/tags", timeout=5)
            return response.status_code == 200
        except:
            return False


class AIService:
    """AI 서비스 메인 클래스"""
    
    def __init__(self):
        self.ollama_client = OllamaClient()
        self.code_client = OllamaClient(model=settings.CODE_AI_MODEL)
        
    def process_message(self, message: str, session_id: str, message_type: str = 'user') -> Dict[str, Any]:
        """메시지 처리 및 적절한 AI 응답 생성"""
        
        # 의도 분석
        intent = self.analyze_intent(message)
        
        # 세션 컨텍스트 가져오기
        context = self.get_session_context(session_id)
        
        # 의도에 따른 처리
        if intent['type'] == 'command_execution':
            return self.handle_command_request(message, context, intent)
        elif intent['type'] == 'code_analysis':
            return self.handle_code_analysis(message, context, intent)
        elif intent['type'] == 'system_admin':
            return self.handle_system_admin(message, context, intent)
        elif intent['type'] == 'general_chat':
            return self.handle_general_chat(message, context, intent)
        else:
            return self.handle_default(message, context)
    
    def analyze_intent(self, message: str) -> Dict[str, Any]:
        """사용자 메시지의 의도 분석"""
        
        # 명령어 실행 관련 키워드
        command_keywords = [
            '실행', '명령어', 'execute', 'run', 'command', '터미널',
            'ls', 'cd', 'pwd', 'ps', 'kill', 'grep', 'find', 'cat',
            'tail', 'head', 'chmod', 'chown', 'mkdir', 'rm', 'cp', 'mv'
        ]
        
        # 코드 분석 관련 키워드
        code_keywords = [
            '코드', 'code', '스크립트', 'script', '분석', 'analyze',
            '디버그', 'debug', '오류', 'error', '버그', 'bug'
        ]
        
        # 시스템 관리 관련 키워드
        system_keywords = [
            '시스템', 'system', '서버', 'server', '모니터링', 'monitoring',
            '성능', 'performance', '로그', 'log', '설정', 'config'
        ]
        
        message_lower = message.lower()
        
        # 명령어 패턴 감지
        if any(keyword in message_lower for keyword in command_keywords):
            extracted_command = self.extract_command(message)
            return {
                'type': 'command_execution',
                'confidence': 0.9,
                'extracted_command': extracted_command,
                'details': {'command': extracted_command}
            }
        
        # 코드 분석 패턴 감지
        elif any(keyword in message_lower for keyword in code_keywords):
            return {
                'type': 'code_analysis',
                'confidence': 0.8,
                'details': {}
            }
        
        # 시스템 관리 패턴 감지
        elif any(keyword in message_lower for keyword in system_keywords):
            return {
                'type': 'system_admin',
                'confidence': 0.8,
                'details': {}
            }
        
        # 일반 대화
        else:
            return {
                'type': 'general_chat',
                'confidence': 0.6,
                'details': {}
            }
    
    def extract_command(self, message: str) -> Optional[str]:
        """메시지에서 실행할 명령어 추출"""
        
        # 백틱으로 감싸진 명령어 찾기
        backtick_match = re.search(r'`([^`]+)`', message)
        if backtick_match:
            return backtick_match.group(1).strip()
        
        # 명령어 키워드 다음의 텍스트 추출
        command_patterns = [
            r'실행해(?:주세요|줘)?\s*:?\s*(.+)',
            r'명령어\s*:?\s*(.+)',
            r'execute\s*:?\s*(.+)',
            r'run\s*:?\s*(.+)',
        ]
        
        for pattern in command_patterns:
            match = re.search(pattern, message, re.IGNORECASE)
            if match:
                return match.group(1).strip()
        
        # AI를 사용한 명령어 추출
        try:
            prompt = f"""
            다음 텍스트에서 실행할 리눅스/유닉스 명령어를 추출해주세요.
            명령어만 반환하고 다른 설명은 하지 마세요.
            명령어가 없으면 'NONE'을 반환하세요.
            
            텍스트: "{message}"
            """
            
            response = self.code_client.generate(prompt)
            extracted = response.get('response', '').strip()
            
            if extracted and extracted != 'NONE' and not extracted.startswith('명령어'):
                return extracted
                
        except Exception as e:
            logger.warning(f"AI 명령어 추출 실패: {e}")
        
        return None
    
    def get_session_context(self, session_id: str, limit: int = 10) -> List[Dict[str, str]]:
        """세션의 최근 대화 컨텍스트 가져오기"""
        
        cache_key = f"session_context_{session_id}"
        cached_context = cache.get(cache_key)
        
        if cached_context:
            return cached_context
        
        try:
            session = ChatSession.objects.get(session_id=session_id)
            messages = session.messages.order_by('-timestamp')[:limit]
            
            context = []
            for msg in reversed(messages):
                role = 'user' if msg.message_type == 'user' else 'assistant'
                context.append({
                    'role': role,
                    'content': msg.content
                })
            
            # 캐시에 저장 (5분)
            cache.set(cache_key, context, 300)
            return context
            
        except ChatSession.DoesNotExist:
            return []
    
    def handle_command_request(self, message: str, context: List[Dict], intent: Dict) -> Dict[str, Any]:
        """명령어 실행 요청 처리"""
        
        command = intent['details'].get('command')
        
        if not command:
            # OS별 예시 명령어 제공
            import platform
            if platform.system().lower() == 'windows':
                examples = [
                    '`dir` - 현재 디렉토리 파일 목록 보기',
                    '`Get-Process` - 실행 중인 프로세스 목록 (PowerShell)',
                    '`systeminfo` - 시스템 정보 확인'
                ]
            else:
                examples = [
                    '`ls -la` - 현재 디렉토리 파일 목록 보기',
                    '`ps aux` - 실행 중인 프로세스 목록',
                    '`df -h` - 디스크 사용량 확인'
                ]
            
            example_text = '\n'.join(examples)
            
            return {
                'content': f"실행할 명령어를 명확히 지정해주세요.\n\n**예시:**\n{example_text}\n\n"
                          "또는 자연어로 '파일 목록 보여줘', '프로세스 확인해줘' 등으로 요청하세요.",
                'metadata': {
                    'type': 'command_help',
                    'os_type': platform.system(),
                    'suggested_format': '`command` 또는 "command 실행해줘"'
                }
            }
        
        # 위험한 명령어 체크
        from xshell_integration.services import XShellService
        xshell_service = XShellService()
        
        if xshell_service.is_dangerous_command(command):
            return {
                'content': f"⚠️ 위험한 명령어가 감지되었습니다: `{command}`\n"
                          "이 명령어는 시스템에 손상을 줄 수 있어서 실행을 권장하지 않습니다.",
                'metadata': {
                    'type': 'dangerous_command',
                    'command': command
                }
            }
        
        # 명령어 설명 및 실행 안내
        explanation = self.explain_command(command)
        
        return {
            'content': f"명령어 `{command}`를 실행하겠습니다.\n\n"
                      f"**명령어 설명:**\n{explanation}\n\n"
                      f"실행하려면 아래 버튼을 클릭하거나 '실행'이라고 입력해주세요.",
            'metadata': {
                'type': 'command_ready',
                'command': command,
                'explanation': explanation,
                'execute_button': True
            }
        }
    
    def handle_code_analysis(self, message: str, context: List[Dict], intent: Dict) -> Dict[str, Any]:
        """코드 분석 요청 처리"""
        
        system_prompt = """당신은 코드 분석 전문가입니다. 
        사용자가 제공한 코드나 오류를 분석하고 해결책을 제시하세요."""
        
        # 이전 컨텍스트 포함
        context_str = self.format_context(context)
        
        prompt = f"""
        컨텍스트:
        {context_str}
        
        사용자 요청: {message}
        
        코드 분석 요청입니다. 다음을 포함해서 분석해주세요:
        1. 코드/오류 분석
        2. 문제점 식별
        3. 해결 방안 제시
        4. 추가 권장사항
        """
        
        try:
            response = self.code_client.generate(prompt, system_prompt)
            return {
                'content': response.get('response', 'AI 응답을 생성할 수 없습니다.'),
                'metadata': {
                    'type': 'code_analysis',
                    'model_used': self.code_client.model
                }
            }
        except Exception as e:
            return {
                'content': f"코드 분석 중 오류가 발생했습니다: {str(e)}",
                'metadata': {'type': 'error'}
            }
    
    def handle_system_admin(self, message: str, context: List[Dict], intent: Dict) -> Dict[str, Any]:
        """시스템 관리 요청 처리"""
        
        system_prompt = """당신은 시스템 관리 전문가입니다.
        리눅스/유닉스 시스템 관리, 모니터링, 트러블슈팅에 대한 조언을 제공하세요."""
        
        context_str = self.format_context(context)
        
        prompt = f"""
        컨텍스트:
        {context_str}
        
        시스템 관리 요청: {message}
        
        시스템 관리자 관점에서 답변해주세요:
        1. 문제 분석
        2. 해결 방법
        3. 예방 조치
        4. 관련 명령어 (있다면)
        """
        
        try:
            response = self.ollama_client.generate(prompt, system_prompt)
            return {
                'content': response.get('response', 'AI 응답을 생성할 수 없습니다.'),
                'metadata': {
                    'type': 'system_admin',
                    'model_used': self.ollama_client.model
                }
            }
        except Exception as e:
            return {
                'content': f"시스템 관리 조언 생성 중 오류가 발생했습니다: {str(e)}",
                'metadata': {'type': 'error'}
            }
    
    def handle_general_chat(self, message: str, context: List[Dict], intent: Dict) -> Dict[str, Any]:
        """일반 대화 처리"""
        
        system_prompt = """당신은 XShell 터미널 도우미입니다.
        친근하고 도움이 되는 방식으로 대화하며, 필요시 터미널 작업을 도와주세요."""
        
        # Chat API 사용
        messages = context + [{'role': 'user', 'content': message}]
        
        try:
            response = self.ollama_client.chat(messages)
            return {
                'content': response.get('message', {}).get('content', 'AI 응답을 생성할 수 없습니다.'),
                'metadata': {
                    'type': 'general_chat',
                    'model_used': self.ollama_client.model
                }
            }
        except Exception as e:
            return {
                'content': f"대화 처리 중 오류가 발생했습니다: {str(e)}",
                'metadata': {'type': 'error'}
            }
    
    def handle_default(self, message: str, context: List[Dict]) -> Dict[str, Any]:
        """기본 처리"""
        return {
            'content': "안녕하세요! XShell 터미널 도우미입니다.\n"
                      "다음과 같은 도움을 드릴 수 있습니다:\n\n"
                      "🔧 **명령어 실행**: `ls -la` 또는 '파일 목록 보여줘'\n"
                      "💻 **코드 분석**: 오류 메시지나 스크립트 분석\n"
                      "⚙️ **시스템 관리**: 서버 관리 및 모니터링 조언\n"
                      "💬 **일반 대화**: 궁금한 것들을 자유롭게 물어보세요\n\n"
                      "무엇을 도와드릴까요?",
            'metadata': {
                'type': 'welcome',
                'capabilities': ['command_execution', 'code_analysis', 'system_admin', 'general_chat']
            }
        }
    
    def explain_command(self, command: str) -> str:
        """명령어 설명 생성 - OS별 명령어 지원"""
        
        import platform
        is_windows = platform.system().lower() == 'windows'
        
        try:
            if is_windows:
                system_prompt = """당신은 Windows 명령어 전문가입니다. 
                Windows Command Prompt와 PowerShell 명령어를 간단히 설명해주세요."""
                
                prompt = f"""
                다음 Windows 명령어를 간단히 설명해주세요:
                
                명령어: {command}
                
                설명은 다음 형식으로 해주세요:
                - 기능: 명령어가 수행하는 작업
                - Shell: Command Prompt 또는 PowerShell 여부
                - 옵션: 사용된 주요 옵션들의 의미 (있다면)
                - 주의사항: 실행 시 주의할 점 (있다면)
                
                2-3줄로 간단히 설명해주세요.
                """
            else:
                system_prompt = """당신은 리눅스/유닉스 명령어 전문가입니다. 
                명령어를 간단히 설명해주세요."""
                
                prompt = f"""
                다음 리눅스/유닉스 명령어를 간단히 설명해주세요:
                
                명령어: {command}
                
                설명은 다음 형식으로 해주세요:
                - 기능: 명령어가 수행하는 작업
                - 옵션: 사용된 주요 옵션들의 의미 (있다면)
                - 주의사항: 실행 시 주의할 점 (있다면)
                
                2-3줄로 간단히 설명해주세요.
                """
            
            response = self.code_client.generate(prompt, system_prompt)
            return response.get('response', f'`{command}` 명령어입니다.')
            
        except Exception:
            # AI가 실패하면 기본 설명 제공
            if is_windows:
                return f'`{command}` Windows 명령어입니다.'
            else:
                return f'`{command}` 리눅스/유닉스 명령어입니다.'
    
    def format_context(self, context: List[Dict]) -> str:
        """컨텍스트를 문자열로 포맷"""
        if not context:
            return "이전 대화 없음"
        
        formatted = []
        for msg in context[-5:]:  # 최근 5개만
            role = "사용자" if msg['role'] == 'user' else "AI"
            formatted.append(f"{role}: {msg['content'][:100]}...")
        
        return "\n".join(formatted)
    
    def get_available_models(self) -> List[Dict[str, str]]:
        """사용 가능한 AI 모델 목록"""
        try:
            response = requests.get(f"{self.ollama_client.base_url}/api/tags")
            if response.status_code == 200:
                models = response.json().get('models', [])
                return [{'name': model['name'], 'size': model.get('size', 'Unknown')} 
                       for model in models]
        except:
            pass
        
        return [
            {'name': settings.DEFAULT_AI_MODEL, 'size': 'Unknown'},
            {'name': settings.CODE_AI_MODEL, 'size': 'Unknown'}
        ]
