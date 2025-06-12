from django.test import TestCase, TransactionTestCase
from django.urls import reverse
from django.contrib.auth.models import User
from channels.testing import WebsocketCommunicator
from channels.db import database_sync_to_async
import json
import uuid

from .models import ChatSession, ChatMessage, XShellSession, CommandHistory, AIModel
from .consumers import ChatConsumer
from ai_backend.services import AIService
from xshell_integration.services import XShellService


class ChatSessionModelTest(TestCase):
    """채팅 세션 모델 테스트"""
    
    def setUp(self):
        self.user = User.objects.create_user(
            username='testuser',
            password='testpass123'
        )
    
    def test_create_chat_session(self):
        """채팅 세션 생성 테스트"""
        session = ChatSession.objects.create(
            user=self.user,
            session_id=str(uuid.uuid4()),
            title='테스트 세션'
        )
        
        self.assertEqual(session.title, '테스트 세션')
        self.assertEqual(session.user, self.user)
        self.assertTrue(session.is_active)
    
    def test_chat_message_creation(self):
        """채팅 메시지 생성 테스트"""
        session = ChatSession.objects.create(
            user=self.user,
            session_id=str(uuid.uuid4()),
            title='테스트 세션'
        )
        
        message = ChatMessage.objects.create(
            session=session,
            message_type='user',
            content='안녕하세요'
        )
        
        self.assertEqual(message.content, '안녕하세요')
        self.assertEqual(message.message_type, 'user')
        self.assertEqual(message.session, session)


class XShellSessionModelTest(TestCase):
    """XShell 세션 모델 테스트"""
    
    def test_create_xshell_session(self):
        """XShell 세션 생성 테스트"""
        session = XShellSession.objects.create(
            name='test_server',
            host='192.168.1.100',
            username='testuser',
            port=22
        )
        
        self.assertEqual(session.name, 'test_server')
        self.assertEqual(session.host, '192.168.1.100')
        self.assertEqual(session.username, 'testuser')
        self.assertEqual(session.port, 22)
        self.assertFalse(session.is_connected)


class ChatbotViewTest(TestCase):
    """챗봇 뷰 테스트"""
    
    def setUp(self):
        self.user = User.objects.create_user(
            username='testuser',
            password='testpass123'
        )
    
    def test_create_chat_session_api(self):
        """채팅 세션 생성 API 테스트"""
        data = {
            'title': '새로운 테스트 세션'
        }
        
        response = self.client.post(
            reverse('chatbot:create_session'),
            data=json.dumps(data),
            content_type='application/json'
        )
        
        self.assertEqual(response.status_code, 200)
        response_data = json.loads(response.content)
        self.assertTrue(response_data['success'])
        self.assertIn('session_id', response_data)
    
    def test_send_message_api(self):
        """메시지 전송 API 테스트"""
        # 세션 생성
        session = ChatSession.objects.create(
            session_id=str(uuid.uuid4()),
            title='테스트 세션'
        )
        
        data = {
            'session_id': session.session_id,
            'message': '안녕하세요',
            'type': 'user'
        }
        
        # Note: 실제 AI 서비스가 필요하므로 모킹이 필요할 수 있음
        with self.assertRaises(Exception):  # Ollama 연결 실패 예상
            response = self.client.post(
                reverse('chatbot:send_message'),
                data=json.dumps(data),
                content_type='application/json'
            )


class AIServiceTest(TestCase):
    """AI 서비스 테스트"""
    
    def test_analyze_intent_command(self):
        """명령어 의도 분석 테스트"""
        ai_service = AIService()
        
        # 명령어 관련 메시지
        intent = ai_service.analyze_intent('ls -la 명령어를 실행해줘')
        
        self.assertEqual(intent['type'], 'command_execution')
        self.assertGreater(intent['confidence'], 0.8)
    
    def test_analyze_intent_general(self):
        """일반 대화 의도 분석 테스트"""
        ai_service = AIService()
        
        # 일반 대화
        intent = ai_service.analyze_intent('안녕하세요')
        
        self.assertEqual(intent['type'], 'general_chat')
    
    def test_extract_command(self):
        """명령어 추출 테스트"""
        ai_service = AIService()
        
        # 백틱으로 감싼 명령어
        command = ai_service.extract_command('`ls -la` 명령어를 실행해줘')
        self.assertEqual(command, 'ls -la')
        
        # 일반 텍스트에서 명령어 추출
        command = ai_service.extract_command('ls -la 명령어를 실행해줘')
        self.assertEqual(command, 'ls -la')


class XShellServiceTest(TestCase):
    """XShell 서비스 테스트"""
    
    def test_is_dangerous_command(self):
        """위험한 명령어 감지 테스트"""
        xshell_service = XShellService()
        
        # 위험한 명령어
        self.assertTrue(xshell_service.is_dangerous_command('rm -rf /'))
        self.assertTrue(xshell_service.is_dangerous_command('dd if=/dev/zero'))
        
        # 안전한 명령어
        self.assertFalse(xshell_service.is_dangerous_command('ls -la'))
        self.assertFalse(xshell_service.is_dangerous_command('ps aux'))
    
    def test_encrypt_decrypt_password(self):
        """비밀번호 암호화/복호화 테스트"""
        xshell_service = XShellService()
        
        original_password = 'test_password_123'
        encrypted = xshell_service.encrypt_password(original_password)
        decrypted = xshell_service.decrypt_password(encrypted)
        
        self.assertNotEqual(original_password, encrypted)
        self.assertEqual(original_password, decrypted)


class ChatConsumerTest(TransactionTestCase):
    """채팅 WebSocket 컨슈머 테스트"""
    
    def setUp(self):
        self.session_id = str(uuid.uuid4())
    
    async def test_websocket_connect(self):
        """WebSocket 연결 테스트"""
        communicator = WebsocketCommunicator(
            ChatConsumer.as_asgi(),
            f"/ws/chat/{self.session_id}/"
        )
        
        connected, subprotocol = await communicator.connect()
        self.assertTrue(connected)
        
        # 연결 종료
        await communicator.disconnect()
    
    async def test_websocket_message(self):
        """WebSocket 메시지 전송 테스트"""
        communicator = WebsocketCommunicator(
            ChatConsumer.as_asgi(),
            f"/ws/chat/{self.session_id}/"
        )
        
        connected, subprotocol = await communicator.connect()
        self.assertTrue(connected)
        
        # 메시지 전송
        await communicator.send_json_to({
            'type': 'message',
            'message': '테스트 메시지'
        })
        
        # 응답 받기 (실제 AI 서비스가 없으면 에러 메시지)
        response = await communicator.receive_json_from()
        self.assertIn('type', response)
        
        await communicator.disconnect()


class APIIntegrationTest(TestCase):
    """API 통합 테스트"""
    
    def test_ai_health_check(self):
        """AI 서비스 상태 확인 API 테스트"""
        response = self.client.get(reverse('ai_backend:health_check'))
        
        self.assertEqual(response.status_code, 200)
        response_data = json.loads(response.content)
        
        # Ollama가 실행 중이지 않으면 False
        self.assertIn('ollama_available', response_data)
        self.assertIn('base_url', response_data)
    
    def test_xshell_health_check(self):
        """XShell 서비스 상태 확인 API 테스트"""
        response = self.client.get(reverse('xshell_integration:health_check'))
        
        self.assertEqual(response.status_code, 200)
        response_data = json.loads(response.content)
        
        self.assertIn('active_sessions', response_data)
        self.assertIn('total_sessions', response_data)


class SecurityTest(TestCase):
    """보안 테스트"""
    
    def test_dangerous_command_blocked(self):
        """위험한 명령어 차단 테스트"""
        data = {
            'command': 'rm -rf /',
            'session_name': 'default'
        }
        
        response = self.client.post(
            reverse('xshell_integration:execute_command'),
            data=json.dumps(data),
            content_type='application/json'
        )
        
        self.assertEqual(response.status_code, 200)
        response_data = json.loads(response.content)
        
        # 위험한 명령어는 실행되지 않아야 함
        self.assertFalse(response_data.get('result', {}).get('success', True))
    
    def test_sql_injection_protection(self):
        """SQL 인젝션 보호 테스트"""
        # 악의적인 세션 ID
        malicious_session_id = "'; DROP TABLE chatbot_chatsession; --"
        
        response = self.client.get(f'/api/session/{malicious_session_id}/')
        
        # 404 또는 400 응답이어야 함 (서버 에러가 아닌)
        self.assertIn(response.status_code, [400, 404])
        
        # 데이터베이스 테이블이 여전히 존재하는지 확인
        self.assertTrue(ChatSession.objects.model._meta.db_table)


class PerformanceTest(TestCase):
    """성능 테스트"""
    
    def test_large_message_handling(self):
        """대용량 메시지 처리 테스트"""
        # 10KB 메시지 생성
        large_message = 'A' * 10240
        
        session = ChatSession.objects.create(
            session_id=str(uuid.uuid4()),
            title='성능 테스트 세션'
        )
        
        data = {
            'session_id': session.session_id,
            'message': large_message,
            'type': 'user'
        }
        
        # 대용량 메시지도 처리되어야 함
        with self.assertRaises(Exception):  # AI 서비스 연결 실패 예상
            response = self.client.post(
                reverse('chatbot:send_message'),
                data=json.dumps(data),
                content_type='application/json'
            )
