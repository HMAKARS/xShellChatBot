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
        """텍스트 생성 - 안전한 오류 처리 포함"""
        
        # 입력 검증
        if not prompt.strip():
            raise Exception("빈 프롬프트는 처리할 수 없습니다")
        
        payload = {
            "model": self.model,
            "prompt": prompt.strip(),
            "system": system_prompt,
            "stream": stream,
            "options": {
                "temperature": 0.7,
                "top_p": 0.9,
                "top_k": 40,
                "num_predict": 500,  # 응답 길이 제한
                "stop": ["\n\n\n"]  # 과도한 빈 줄 방지
            }
        }
        
        try:
            response = requests.post(
                f"{self.base_url}/api/generate",
                json=payload,
                timeout=self.timeout
            )
            
            # 상태 코드별 구체적인 오류 처리
            if response.status_code == 404:
                raise Exception("Ollama generate API를 찾을 수 없습니다. Ollama 설치를 확인하세요.")
            elif response.status_code == 500:
                raise Exception(f"Ollama 내부 오류가 발생했습니다. 모델 '{self.model}'이 손상되었거나 메모리가 부족할 수 있습니다.")
            elif response.status_code == 400:
                raise Exception(f"잘못된 요청입니다. 모델 '{self.model}'이 존재하지 않을 수 있습니다.")
            elif response.status_code != 200:
                raise Exception(f"Ollama API 오류 (코드: {response.status_code}): {response.text}")
            
            if stream:
                return response
            else:
                result = response.json()
                
                # 응답 검증
                if not result.get('response'):
                    raise Exception("Ollama에서 빈 응답을 반환했습니다")
                
                return result
                
        except requests.Timeout:
            raise Exception(f"Ollama 응답 시간 초과 ({self.timeout}초). 더 작은 모델을 사용하거나 시간 제한을 늘려보세요.")
        except requests.ConnectionError:
            raise Exception("Ollama 서비스에 연결할 수 없습니다. 'ollama serve' 명령어로 서비스를 시작하세요.")
        except requests.RequestException as e:
            logger.error(f"Ollama API 호출 실패: {e}")
            raise Exception(f"AI 서비스 오류: {e}")
        except json.JSONDecodeError:
            raise Exception("Ollama에서 잘못된 응답 형식을 반환했습니다")
        except Exception as e:
            if "AI 서비스" in str(e) or "Ollama" in str(e):
                raise e
            else:
                raise Exception(f"예상치 못한 오류가 발생했습니다: {e}")
    
    def chat(self, messages: List[Dict[str, str]]) -> Dict[str, Any]:
        """채팅 형식 생성 - /api/chat 또는 /api/generate 사용"""
        
        # 입력 검증
        if not messages or not isinstance(messages, list):
            raise Exception("유효한 메시지 목록이 필요합니다")
        
        # 첫 번째 시도: /api/chat (최신 버전)
        chat_payload = {
            "model": self.model,
            "messages": messages,
            "stream": False,
            "options": {
                "temperature": 0.7,
                "num_predict": 500
            }
        }
        
        try:
            response = requests.post(
                f"{self.base_url}/api/chat",
                json=chat_payload,
                timeout=self.timeout
            )
            
            if response.status_code == 200:
                result = response.json()
                # 응답 형식 검증
                if result.get('message', {}).get('content'):
                    return result
                else:
                    logger.warning("Chat API에서 빈 응답 반환, generate로 폴백")
                    return self._fallback_to_generate(messages)
                    
            elif response.status_code == 404:
                # /api/chat이 없으면 /api/generate로 폴백
                logger.info("Ollama /api/chat 엔드포인트가 없음, /api/generate 사용")
                return self._fallback_to_generate(messages)
                
            elif response.status_code == 500:
                logger.warning("Chat API 500 오류, generate로 폴백 시도")
                return self._fallback_to_generate(messages)
                
            else:
                # 다른 오류는 즉시 발생
                if response.status_code == 400:
                    raise Exception(f"잘못된 채팅 요청입니다. 모델 '{self.model}'을 확인하세요.")
                else:
                    raise Exception(f"Chat API 오류 (코드: {response.status_code}): {response.text}")
                
        except requests.Timeout:
            logger.warning("Chat API 시간 초과, generate로 폴백")
            return self._fallback_to_generate(messages)
        except requests.ConnectionError:
            raise Exception("Ollama 서비스에 연결할 수 없습니다. 'ollama serve' 명령어로 서비스를 시작하세요.")
        except requests.RequestException as e:
            logger.warning(f"Chat API 실패, generate로 폴백: {e}")
            return self._fallback_to_generate(messages)
    
    def _fallback_to_generate(self, messages: List[Dict[str, str]]) -> Dict[str, Any]:
        """chat API 실패시 generate API로 폴백"""
        
        # 메시지들을 하나의 프롬프트로 변환
        system_prompt = ""
        user_prompt = ""
        
        for msg in messages:
            role = msg.get('role', '')
            content = msg.get('content', '')
            
            if role == 'system':
                system_prompt = content
            elif role == 'user':
                if user_prompt:
                    user_prompt += f"\n사용자: {content}"
                else:
                    user_prompt = content
            elif role == 'assistant':
                user_prompt += f"\n도우미: {content}"
        
        # generate API 호출
        try:
            result = self.generate(user_prompt.strip(), system_prompt)
            
            # chat API 형식으로 응답 변환
            return {
                "message": {
                    "role": "assistant",
                    "content": result.get("response", "응답을 생성할 수 없습니다.")
                },
                "model": self.model,
                "created_at": result.get("created_at"),
                "done": result.get("done", True),
                "fallback_used": True  # 폴백 사용 표시
            }
            
        except Exception as e:
            logger.error(f"Generate API도 실패: {e}")
            # 더 구체적인 오류 메시지
            if "500" in str(e):
                raise Exception("AI 모델에 문제가 있습니다. fix-ollama-500.bat을 실행하거나 시스템을 재시작해보세요.")
            elif "404" in str(e):
                raise Exception("Ollama API를 찾을 수 없습니다. Ollama가 올바르게 설치되었는지 확인하세요.")
            elif "연결" in str(e):
                raise Exception("Ollama 서비스가 실행되지 않습니다. 'ollama serve' 명령어로 시작하세요.")
            else:
                raise Exception(f"AI 서비스 오류: {e}")
    
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
        # Ollama 연결 상태 확인 (더 안전하게)
        self.ollama_available = False
        self.error_message = ""
        
        try:
            # 1. 기본 연결 확인
            response = requests.get(f"{settings.OLLAMA_BASE_URL}/", timeout=3)
            if response.status_code != 200:
                self.error_message = f"Ollama 서비스 응답 오류: {response.status_code}"
                return
            
            # 2. API 엔드포인트 확인
            response = requests.get(f"{settings.OLLAMA_BASE_URL}/api/tags", timeout=5)
            if response.status_code != 200:
                self.error_message = f"Ollama API 오류: {response.status_code}"
                return
            
            # 3. 모델 확인
            models = response.json().get('models', [])
            if not models:
                self.error_message = "사용 가능한 모델이 없습니다"
                return
            
            # 4. 클라이언트 초기화
            self.ollama_client = OllamaClient()
            self.code_client = OllamaClient(model=settings.CODE_AI_MODEL)
            
            # 5. 간단한 동작 테스트
            test_result = self._test_basic_functionality()
            if test_result:
                self.ollama_available = True
            else:
                self.error_message = "Ollama 기능 테스트 실패"
                
        except requests.RequestException as e:
            self.error_message = f"Ollama 연결 실패: {e}"
        except Exception as e:
            self.error_message = f"Ollama 초기화 오류: {e}"
    
    def _test_basic_functionality(self):
        """기본 기능 테스트"""
        try:
            # 가장 간단한 요청으로 테스트
            response = requests.post(
                f"{settings.OLLAMA_BASE_URL}/api/generate",
                json={
                    "model": settings.DEFAULT_AI_MODEL,
                    "prompt": "Hi",
                    "stream": False,
                    "options": {
                        "num_predict": 3,  # 매우 짧은 응답
                        "temperature": 0.1
                    }
                },
                timeout=10
            )
            return response.status_code == 200
        except:
            return False
        
    def process_message(self, message: str, session_id: str, message_type: str = 'user', context: Dict = None) -> Dict[str, Any]:
        """메시지 처리 및 적절한 AI 응답 생성"""
        
        context = context or {}
        
        # 의도 분석 - 컨텍스트 정보 활용
        intent = self.analyze_intent(message, context)
        
        # 세션 컨텍스트 가져오기
        session_context = self.get_session_context(session_id)
        
        # 의도에 따른 처리
        if intent['type'] == 'command_execution':
            return self.handle_command_request(message, session_context, intent, context)
        elif intent['type'] == 'code_analysis':
            return self.handle_code_analysis(message, session_context, intent, context)
        elif intent['type'] == 'system_admin':
            return self.handle_system_admin(message, session_context, intent, context)
        elif intent['type'] == 'general_chat':
            return self.handle_general_chat(message, session_context, intent, context)
        else:
            return self.handle_default(message, session_context, context)
    
    def analyze_intent(self, message: str, context: Dict = None) -> Dict[str, Any]:
        """사용자 메시지의 의도 분석 - 컨텍스트 고려"""
        
        context = context or {}
        shell_type = context.get('shell_type')
        command_mode = context.get('command_mode', False)
        
        # 명령어 모드인 경우 자동으로 명령어 실행 의도로 분류
        if command_mode:
            return {
                'type': 'command_execution',
                'confidence': 0.95,
                'extracted_command': message.strip(),
                'details': {
                    'command': message.strip(),
                    'shell_type': shell_type,
                    'explicit_command_mode': True
                }
            }
        
        # OS별 명령어 키워드 정의
        import platform
        is_windows = platform.system().lower() == 'windows'
        
        if is_windows or shell_type in ['powershell', 'cmd']:
            # Windows 명령어 키워드
            command_keywords = [
                '실행', '명령어', 'execute', 'run', 'command', '터미널',
                # Windows 특화 명령어
                'dir', 'cls', 'type', 'copy', 'del', 'md', 'rd', 'cd', 'pushd', 'popd',
                'tasklist', 'taskkill', 'systeminfo', 'ipconfig', 'netstat', 'ping',
                # PowerShell 명령어
                'get-process', 'get-service', 'get-childitem', 'get-location',
                'set-location', 'new-item', 'remove-item', 'copy-item', 'move-item',
                'get-content', 'set-content', 'select-string', 'measure-object',
                'where-object', 'foreach-object', 'get-wmiobject', 'get-computerinfo'
            ]
        else:
            # Unix/Linux 명령어 키워드
            command_keywords = [
                '실행', '명령어', 'execute', 'run', 'command', '터미널',
                'ls', 'cd', 'pwd', 'ps', 'kill', 'grep', 'find', 'cat',
                'tail', 'head', 'chmod', 'chown', 'mkdir', 'rm', 'cp', 'mv',
                'df', 'du', 'top', 'htop', 'free', 'uname', 'whoami', 'id',
                'tar', 'gzip', 'wget', 'curl', 'ssh', 'scp', 'rsync'
            ]
        
        # 코드 분석 관련 키워드
        code_keywords = [
            '코드', 'code', '스크립트', 'script', '분석', 'analyze',
            '디버그', 'debug', '오류', 'error', '버그', 'bug', 'exception',
            'python', 'java', 'javascript', 'c++', 'c#', 'go', 'rust'
        ]
        
        # 시스템 관리 관련 키워드
        system_keywords = [
            '시스템', 'system', '서버', 'server', '모니터링', 'monitoring',
            '성능', 'performance', '로그', 'log', '설정', 'config',
            '네트워크', 'network', '방화벽', 'firewall', '보안', 'security'
        ]
        
        message_lower = message.lower()
        
        # 명령어 패턴 감지
        if any(keyword in message_lower for keyword in command_keywords):
            extracted_command = self.extract_command(message)
            return {
                'type': 'command_execution',
                'confidence': 0.9,
                'extracted_command': extracted_command,
                'details': {
                    'command': extracted_command,
                    'shell_type': shell_type
                }
            }
        
        # 코드 분석 패턴 감지
        elif any(keyword in message_lower for keyword in code_keywords):
            return {
                'type': 'code_analysis',
                'confidence': 0.8,
                'details': {'shell_type': shell_type}
            }
        
        # 시스템 관리 패턴 감지
        elif any(keyword in message_lower for keyword in system_keywords):
            return {
                'type': 'system_admin',
                'confidence': 0.8,
                'details': {'shell_type': shell_type}
            }
        
        # 일반 대화
        else:
            return {
                'type': 'general_chat',
                'confidence': 0.6,
                'details': {'shell_type': shell_type}
            }
    
    def extract_command(self, message: str) -> Optional[str]:
        """메시지에서 실행할 명령어 추출 - Windows/Linux 명령어 지원"""
        
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
            import platform
            is_windows = platform.system().lower() == 'windows'
            
            if is_windows:
                system_prompt = """당신은 Windows 명령어 전문가입니다.
                사용자의 자연어 요청에서 실행할 Windows 명령어를 추출하세요."""
                
                prompt = f"""
                다음 텍스트에서 실행할 Windows 명령어(Command Prompt 또는 PowerShell)를 추출해주세요.
                명령어만 반환하고 다른 설명은 하지 마세요.
                명령어가 없으면 'NONE'을 반환하세요.
                
                텍스트: "{message}"
                
                예시:
                - "파일 목록 보여줘" → dir
                - "프로세스 확인해줘" → Get-Process
                - "시스템 정보 알려줘" → systeminfo
                """
            else:
                system_prompt = """당신은 리눅스/유닉스 명령어 전문가입니다.
                사용자의 자연어 요청에서 실행할 명령어를 추출하세요."""
                
                prompt = f"""
                다음 텍스트에서 실행할 리눅스/유닉스 명령어를 추출해주세요.
                명령어만 반환하고 다른 설명은 하지 마세요.
                명령어가 없으면 'NONE'을 반환하세요.
                
                텍스트: "{message}"
                
                예시:
                - "파일 목록 보여줘" → ls -la
                - "프로세스 확인해줘" → ps aux
                - "디스크 사용량 확인해줘" → df -h
                """
            
            response = self.code_client.generate(prompt, system_prompt)
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
    
    def handle_command_request(self, message: str, context: List[Dict], intent: Dict, user_context: Dict = None) -> Dict[str, Any]:
        """명령어 실행 요청 처리"""
        
        user_context = user_context or {}
        command = intent['details'].get('command')
        shell_type = user_context.get('shell_type') or intent['details'].get('shell_type')
        
        if not command:
            # OS별 예시 명령어 제공
            import platform
            detected_os = platform.system().lower()
            
            # 사용자가 지정한 shell_type이 있으면 그것을 우선으로, 없으면 OS에 따라 결정
            if shell_type == 'powershell' or (not shell_type and detected_os == 'windows'):
                examples = [
                    '`Get-ChildItem` - 현재 디렉토리 파일 목록 보기',
                    '`Get-Process` - 실행 중인 프로세스 목록',
                    '`Get-ComputerInfo` - 컴퓨터 정보 확인',
                    '`Test-Connection google.com` - 네트워크 연결 테스트'
                ]
                shell_name = "PowerShell"
            elif shell_type == 'cmd' or (not shell_type and detected_os == 'windows'):
                examples = [
                    '`dir` - 현재 디렉토리 파일 목록 보기',
                    '`tasklist` - 실행 중인 프로세스 목록',
                    '`systeminfo` - 시스템 정보 확인',
                    '`ping google.com` - 네트워크 연결 테스트'
                ]
                shell_name = "Command Prompt"
            else:
                examples = [
                    '`ls -la` - 현재 디렉토리 파일 목록 보기',
                    '`ps aux` - 실행 중인 프로세스 목록',
                    '`df -h` - 디스크 사용량 확인',
                    '`ping google.com` - 네트워크 연결 테스트'
                ]
                shell_name = "Unix Shell"
            
            example_text = '\n'.join(examples)
            
            return {
                'content': f"실행할 명령어를 명확히 지정해주세요.\n\n"
                          f"**{shell_name} 예시:**\n{example_text}\n\n"
                          "또는 자연어로 '파일 목록 보여줘', '프로세스 확인해줘' 등으로 요청하세요.",
                'metadata': {
                    'type': 'command_help',
                    'os_type': detected_os,
                    'shell_type': shell_type,
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
                    'command': command,
                    'shell_type': shell_type
                }
            }
        
        # 명령어 설명 및 실행 안내
        explanation = self.explain_command(command, shell_type)
        
        return {
            'content': f"명령어 `{command}`를 실행하겠습니다.\n\n"
                      f"**명령어 설명:**\n{explanation}\n\n"
                      f"실행하려면 아래 버튼을 클릭하거나 '실행'이라고 입력해주세요.",
            'metadata': {
                'type': 'command_ready',
                'command': command,
                'explanation': explanation,
                'shell_type': shell_type,
                'execute_button': True
            }
        }
    
    def handle_code_analysis(self, message: str, context: List[Dict], intent: Dict, user_context: Dict = None) -> Dict[str, Any]:
        """코드 분석 요청 처리"""
        
        user_context = user_context or {}
        shell_type = user_context.get('shell_type')
        
        system_prompt = """당신은 코드 분석 전문가입니다. 
        사용자가 제공한 코드나 오류를 분석하고 해결책을 제시하세요."""
        
        # 이전 컨텍스트 포함
        context_str = self.format_context(context)
        
        # Shell 타입별 컨텍스트 추가
        shell_context = ""
        if shell_type:
            shell_context = f"\n실행 환경: {shell_type}"
        
        prompt = f"""
        컨텍스트:
        {context_str}{shell_context}
        
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
                    'model_used': self.code_client.model,
                    'shell_type': shell_type
                }
            }
        except Exception as e:
            return {
                'content': f"코드 분석 중 오류가 발생했습니다: {str(e)}",
                'metadata': {'type': 'error'}
            }
    
    def handle_system_admin(self, message: str, context: List[Dict], intent: Dict, user_context: Dict = None) -> Dict[str, Any]:
        """시스템 관리 요청 처리"""
        
        user_context = user_context or {}
        shell_type = user_context.get('shell_type')
        
        # Shell 타입에 따른 시스템 프롬프트
        if shell_type in ['powershell', 'cmd']:
            system_prompt = """당신은 Windows 시스템 관리 전문가입니다.
            Windows 시스템 관리, 모니터링, 트러블슈팅에 대한 조언을 제공하세요."""
        else:
            system_prompt = """당신은 시스템 관리 전문가입니다.
            리눅스/유닉스 시스템 관리, 모니터링, 트러블슈팅에 대한 조언을 제공하세요."""
        
        context_str = self.format_context(context)
        
        # Shell 타입별 컨텍스트 추가
        shell_context = ""
        if shell_type:
            shell_context = f"\n실행 환경: {shell_type}"
        
        prompt = f"""
        컨텍스트:
        {context_str}{shell_context}
        
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
                    'model_used': self.ollama_client.model,
                    'shell_type': shell_type
                }
            }
        except Exception as e:
            return {
                'content': f"시스템 관리 조언 생성 중 오류가 발생했습니다: {str(e)}",
                'metadata': {'type': 'error'}
            }
    
    def handle_general_chat(self, message: str, context: List[Dict], intent: Dict, user_context: Dict = None) -> Dict[str, Any]:
        """일반 대화 처리"""
        
        user_context = user_context or {}
        shell_type = user_context.get('shell_type')
        
        # Ollama가 사용 불가능한 경우 상세한 안내
        if not self.ollama_available:
            error_details = self.error_message or "알 수 없는 오류"
            
            return {
                'content': f"💔 **AI 서비스 연결 오류**\n\n"
                          f"**오류 내용:** {error_details}\n\n"
                          f"**해결 방법:**\n\n"
                          f"🔧 **즉시 해결**\n"
                          f"1. `fix-ollama-500.bat` 실행 (자동 진단 및 수정)\n"
                          f"2. 또는 `test-ollama.bat` 실행 (상세 진단)\n\n"
                          f"🚀 **수동 해결**\n"
                          f"1. Ollama 재시작: `ollama serve`\n"
                          f"2. 모델 설치: `ollama pull llama3.2:3b`\n"
                          f"3. 시스템 재시작 (권장)\n\n"
                          f"📥 **Ollama 설치가 필요한 경우**\n"
                          f"• 자동 설치: `install-ollama-simple.bat`\n"
                          f"• 수동 설치: https://ollama.com/download\n\n"
                          f"**현재 사용 가능한 기능:**\n"
                          f"• XShell 세션 연결 및 명령어 실행\n"
                          f"• 터미널 작업 지원\n\n"
                          f"AI 기능이 복구되면 지능적인 대화와 코드 분석을 이용할 수 있습니다! 🤖",
                'metadata': {
                    'type': 'ai_service_error',
                    'error_details': error_details,
                    'shell_type': shell_type,
                    'capabilities': ['command_execution', 'xshell_integration'],
                    'repair_tools': ['fix-ollama-500.bat', 'test-ollama.bat', 'install-ollama-simple.bat']
                }
            }
        
        # Shell 타입별 시스템 프롬프트
        if shell_type in ['powershell', 'cmd']:
            system_prompt = """당신은 Windows XShell 터미널 도우미입니다.
            친근하고 도움이 되는 방식으로 대화하며, 필요시 Windows 터미널 작업을 도와주세요."""
        else:
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
                    'model_used': self.ollama_client.model,
                    'shell_type': shell_type
                }
            }
        except Exception as e:
            # 구체적인 오류 분석
            error_str = str(e)
            if "500" in error_str:
                repair_message = "🔧 **Ollama 500 오류 해결 방법:**\n" \
                               "1. `fix-ollama-500.bat` 실행 (자동 수정)\n" \
                               "2. 시스템 재시작 후 재시도\n" \
                               "3. 더 작은 모델 사용: `ollama pull llama3.2:1b`"
            elif "404" in error_str:
                repair_message = "🔧 **API 엔드포인트 오류:**\n" \
                               "Ollama 버전이 낮을 수 있습니다. 최신 버전으로 업데이트하세요."
            elif "timeout" in error_str.lower():
                repair_message = "⏱️ **응답 시간 초과:**\n" \
                                "모델이 너무 크거나 메모리가 부족할 수 있습니다.\n" \
                                "더 작은 모델을 사용해보세요."
            elif "connection" in error_str.lower():
                repair_message = "🔌 **연결 오류:**\n" \
                                "`ollama serve` 명령어로 서비스를 시작하세요."
            else:
                repair_message = "🛠️ **일반적인 해결 방법:**\n" \
                                "1. `fix-ollama-500.bat` 실행\n" \
                                "2. Ollama 서비스 재시작\n" \
                                "3. 시스템 재시작"
            
            return {
                'content': f"😅 **AI 응답 생성 중 오류가 발생했습니다**\n\n"
                          f"**오류 내용:** {error_str}\n\n"
                          f"{repair_message}\n\n"
                          f"**임시 해결책:**\n"
                          f"XShell 기능(명령어 실행, 터미널 작업)은 정상적으로 사용 가능합니다.\n"
                          f"AI 기능이 복구되면 더 스마트한 도움을 받을 수 있습니다! 🚀",
                'metadata': {
                    'type': 'ai_error',
                    'error_details': error_str,
                    'shell_type': shell_type
                }
            }
    
    def handle_default(self, message: str, context: List[Dict], user_context: Dict = None) -> Dict[str, Any]:
        """기본 처리"""
        
        user_context = user_context or {}
        shell_type = user_context.get('shell_type')
        
        # OS/Shell별 환영 메시지
        if shell_type == 'powershell':
            examples = [
                "🔧 **PowerShell 명령어**: `Get-Process` 또는 '프로세스 확인해줘'",
                "💻 **코드 분석**: PowerShell 스크립트 분석",
                "⚙️ **시스템 관리**: Windows 서버 관리 및 모니터링 조언"
            ]
        elif shell_type == 'cmd':
            examples = [
                "🔧 **CMD 명령어**: `dir` 또는 '파일 목록 보여줘'",
                "💻 **배치 파일**: .bat 스크립트 분석",
                "⚙️ **시스템 관리**: Windows 시스템 관리 조언"
            ]
        else:
            examples = [
                "🔧 **명령어 실행**: `ls -la` 또는 '파일 목록 보여줘'",
                "💻 **코드 분석**: 오류 메시지나 스크립트 분석",
                "⚙️ **시스템 관리**: 서버 관리 및 모니터링 조언"
            ]
        
        example_text = '\n'.join(examples)
        
        return {
            'content': "안녕하세요! XShell 터미널 도우미입니다.\n"
                      "다음과 같은 도움을 드릴 수 있습니다:\n\n"
                      f"{example_text}\n"
                      "💬 **일반 대화**: 궁금한 것들을 자유롭게 물어보세요\n\n"
                      "무엇을 도와드릴까요?",
            'metadata': {
                'type': 'welcome',
                'capabilities': ['command_execution', 'code_analysis', 'system_admin', 'general_chat'],
                'shell_type': shell_type
            }
        }
    
    def explain_command(self, command: str, shell_type: str = None) -> str:
        """명령어 설명 생성 - OS별 명령어 지원"""
        
        import platform
        is_windows = platform.system().lower() == 'windows'
        
        # shell_type이 지정되면 그것을 우선으로, 없으면 OS에 따라 결정
        if shell_type == 'powershell' or (not shell_type and is_windows):
            target_shell = 'powershell'
        elif shell_type == 'cmd':
            target_shell = 'cmd'
        else:
            target_shell = 'unix'
        
        try:
            if target_shell == 'powershell':
                system_prompt = """당신은 PowerShell 전문가입니다. 
                PowerShell 명령어를 간단히 설명해주세요."""
                
                prompt = f"""
                다음 PowerShell 명령어를 간단히 설명해주세요:
                
                명령어: {command}
                
                설명은 다음 형식으로 해주세요:
                - 기능: 명령어가 수행하는 작업
                - 매개변수: 사용된 주요 매개변수들의 의미 (있다면)
                - 주의사항: 실행 시 주의할 점 (있다면)
                
                2-3줄로 간단히 설명해주세요.
                """
            elif target_shell == 'cmd':
                system_prompt = """당신은 Windows Command Prompt 전문가입니다. 
                CMD 명령어를 간단히 설명해주세요."""
                
                prompt = f"""
                다음 Command Prompt 명령어를 간단히 설명해주세요:
                
                명령어: {command}
                
                설명은 다음 형식으로 해주세요:
                - 기능: 명령어가 수행하는 작업
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
            if target_shell == 'powershell':
                return f'`{command}` PowerShell 명령어입니다.'
            elif target_shell == 'cmd':
                return f'`{command}` Command Prompt 명령어입니다.'
            else:
                return f'`{command}` Unix/Linux 명령어입니다.'
    
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
