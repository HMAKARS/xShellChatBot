import json
import asyncio
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async
from django.contrib.auth.models import User

from .models import ChatSession, ChatMessage, XShellSession
from ai_backend.services import AIService
from xshell_integration.services import XShellService


class ChatConsumer(AsyncWebsocketConsumer):
    """실시간 채팅을 위한 WebSocket 컨슈머"""
    
    async def connect(self):
        self.session_id = self.scope['url_route']['kwargs']['session_id']
        self.room_group_name = f'chat_{self.session_id}'
        
        # 그룹에 조인
        await self.channel_layer.group_add(
            self.room_group_name,
            self.channel_name
        )
        
        await self.accept()
        
        # 세션 존재 확인 및 생성
        await self.ensure_chat_session()
    
    async def disconnect(self, close_code):
        # 그룹에서 제거
        await self.channel_layer.group_discard(
            self.room_group_name,
            self.channel_name
        )
    
    async def receive(self, text_data):
        try:
            text_data_json = json.loads(text_data)
            message_type = text_data_json.get('type', 'message')
            
            if message_type == 'message':
                await self.handle_chat_message(text_data_json)
            elif message_type == 'command':
                await self.handle_command_execution(text_data_json)
            elif message_type == 'typing':
                await self.handle_typing_indicator(text_data_json)
                
        except json.JSONDecodeError:
            await self.send(text_data=json.dumps({
                'error': 'Invalid JSON format'
            }))
        except Exception as e:
            await self.send(text_data=json.dumps({
                'error': f'Error processing message: {str(e)}'
            }))
    
    async def handle_chat_message(self, data):
        """일반 채팅 메시지 처리"""
        message_content = data.get('message', '')
        shell_type = data.get('shell_type')
        command_mode = data.get('command_mode', False)
        
        if not message_content.strip():
            return
        
        # 메타데이터 구성
        metadata = {}
        if shell_type:
            metadata['shell_type'] = shell_type
        if command_mode:
            metadata['command_mode'] = command_mode
        
        # 사용자 메시지 저장
        user_message = await self.save_message('user', message_content, metadata)
        
        # 사용자 메시지 브로드캐스트
        await self.channel_layer.group_send(
            self.room_group_name,
            {
                'type': 'chat_message',
                'message': {
                    'id': user_message.id,
                    'type': 'user',
                    'content': message_content,
                    'timestamp': user_message.timestamp.isoformat(),
                    'metadata': metadata
                }
            }
        )
        
        # AI 응답 생성 (비동기)
        asyncio.create_task(self.generate_ai_response(message_content, shell_type, command_mode))
    
    async def handle_command_execution(self, data):
        """명령어 실행 처리"""
        command = data.get('command', '')
        session_name = data.get('session_name', 'default')
        
        if not command.strip():
            return
        
        # 명령어 메시지 저장
        command_message = await self.save_message('command', command)
        
        # 명령어 메시지 브로드캐스트
        await self.channel_layer.group_send(
            self.room_group_name,
            {
                'type': 'chat_message',
                'message': {
                    'id': command_message.id,
                    'type': 'command',
                    'content': command,
                    'timestamp': command_message.timestamp.isoformat()
                }
            }
        )
        
        # 명령어 실행 (비동기)
        asyncio.create_task(self.execute_command_async(command, session_name))
    
    async def handle_typing_indicator(self, data):
        """타이핑 인디케이터 처리"""
        is_typing = data.get('is_typing', False)
        
        await self.channel_layer.group_send(
            self.room_group_name,
            {
                'type': 'typing_indicator',
                'is_typing': is_typing,
                'user': 'user'  # 실제로는 사용자 정보 사용
            }
        )
    
    async def generate_ai_response(self, message_content, shell_type=None, command_mode=False):
        """AI 응답 생성"""
        try:
            # 타이핑 인디케이터 시작
            await self.channel_layer.group_send(
                self.room_group_name,
                {
                    'type': 'typing_indicator',
                    'is_typing': True,
                    'user': 'ai'
                }
            )
            
            # AI 서비스 호출 - 추가 컨텍스트 전달
            ai_service = AIService()
            
            # 메시지 타입 결정
            message_type = 'command' if command_mode else 'user'
            
            # 컨텍스트에 Shell 정보 추가
            context = {
                'shell_type': shell_type,
                'command_mode': command_mode,
                'session_id': self.session_id
            }
            
            ai_response = await database_sync_to_async(
                ai_service.process_message
            )(message_content, self.session_id, message_type, context)
            
            # AI 응답 메타데이터 구성
            response_metadata = ai_response.get('metadata', {})
            if shell_type:
                response_metadata['recommended_shell'] = shell_type
            if command_mode:
                response_metadata['triggered_by_command_mode'] = True
            
            # AI 응답 저장
            ai_message = await self.save_message(
                'ai', 
                ai_response['content'],
                response_metadata
            )
            
            # 타이핑 인디케이터 종료
            await self.channel_layer.group_send(
                self.room_group_name,
                {
                    'type': 'typing_indicator',
                    'is_typing': False,
                    'user': 'ai'
                }
            )
            
            # AI 응답 브로드캐스트
            await self.channel_layer.group_send(
                self.room_group_name,
                {
                    'type': 'chat_message',
                    'message': {
                        'id': ai_message.id,
                        'type': 'ai',
                        'content': ai_response['content'],
                        'timestamp': ai_message.timestamp.isoformat(),
                        'metadata': response_metadata
                    }
                }
            )
            
        except Exception as e:
            # 오류 메시지 전송
            await self.channel_layer.group_send(
                self.room_group_name,
                {
                    'type': 'chat_message',
                    'message': {
                        'type': 'system',
                        'content': f'AI 응답 생성 중 오류가 발생했습니다: {str(e)}',
                        'timestamp': None
                    }
                }
            )
    
    async def execute_command_async(self, command, session_name):
        """명령어 비동기 실행"""
        try:
            # XShell 서비스 호출
            xshell_service = XShellService()
            result = await database_sync_to_async(
                xshell_service.execute_command
            )(command, session_name)
            
            # 결과 메시지 저장
            result_message = await self.save_message(
                'result', 
                result['output'],
                {
                    'exit_code': result.get('exit_code'),
                    'execution_time': result.get('execution_time'),
                    'command': command
                }
            )
            
            # 결과 브로드캐스트
            await self.channel_layer.group_send(
                self.room_group_name,
                {
                    'type': 'chat_message',
                    'message': {
                        'id': result_message.id,
                        'type': 'result',
                        'content': result['output'],
                        'timestamp': result_message.timestamp.isoformat(),
                        'metadata': result_message.metadata
                    }
                }
            )
            
        except Exception as e:
            # 오류 메시지 전송
            await self.channel_layer.group_send(
                self.room_group_name,
                {
                    'type': 'chat_message',
                    'message': {
                        'type': 'system',
                        'content': f'명령어 실행 중 오류가 발생했습니다: {str(e)}',
                        'timestamp': None
                    }
                }
            )
    
    async def chat_message(self, event):
        """채팅 메시지 전송"""
        message = event['message']
        
        await self.send(text_data=json.dumps({
            'type': 'message',
            'message': message
        }))
    
    async def typing_indicator(self, event):
        """타이핑 인디케이터 전송"""
        await self.send(text_data=json.dumps({
            'type': 'typing',
            'is_typing': event['is_typing'],
            'user': event['user']
        }))
    
    @database_sync_to_async
    def ensure_chat_session(self):
        """채팅 세션 존재 확인 및 생성"""
        session, created = ChatSession.objects.get_or_create(
            session_id=self.session_id,
            defaults={'title': f'세션 {self.session_id[:8]}'}
        )
        return session
    
    @database_sync_to_async
    def save_message(self, message_type, content, metadata=None):
        """메시지 저장"""
        session = ChatSession.objects.get(session_id=self.session_id)
        return ChatMessage.objects.create(
            session=session,
            message_type=message_type,
            content=content,
            metadata=metadata or {}
        )


class XShellConsumer(AsyncWebsocketConsumer):
    """XShell 터미널을 위한 WebSocket 컨슈머"""
    
    async def connect(self):
        self.session_name = self.scope['url_route']['kwargs']['session_name']
        self.room_group_name = f'xshell_{self.session_name}'
        
        # 그룹에 조인
        await self.channel_layer.group_add(
            self.room_group_name,
            self.channel_name
        )
        
        await self.accept()
    
    async def disconnect(self, close_code):
        # 그룹에서 제거
        await self.channel_layer.group_discard(
            self.room_group_name,
            self.channel_name
        )
    
    async def receive(self, text_data):
        try:
            text_data_json = json.loads(text_data)
            command_type = text_data_json.get('type', 'command')
            
            if command_type == 'command':
                command = text_data_json.get('command', '')
                await self.execute_command(command)
            elif command_type == 'interrupt':
                await self.interrupt_command()
                
        except json.JSONDecodeError:
            await self.send(text_data=json.dumps({
                'error': 'Invalid JSON format'
            }))
    
    async def execute_command(self, command):
        """명령어 실행"""
        try:
            xshell_service = XShellService()
            result = await database_sync_to_async(
                xshell_service.execute_command_stream
            )(command, self.session_name)
            
            # 결과를 실시간으로 스트리밍
            for output_chunk in result:
                await self.send(text_data=json.dumps({
                    'type': 'output',
                    'content': output_chunk
                }))
                
        except Exception as e:
            await self.send(text_data=json.dumps({
                'type': 'error',
                'content': f'Error: {str(e)}'
            }))
    
    async def interrupt_command(self):
        """명령어 중단"""
        try:
            xshell_service = XShellService()
            await database_sync_to_async(
                xshell_service.interrupt_command
            )(self.session_name)
            
            await self.send(text_data=json.dumps({
                'type': 'interrupted',
                'content': 'Command interrupted'
            }))
            
        except Exception as e:
            await self.send(text_data=json.dumps({
                'type': 'error',
                'content': f'Error interrupting command: {str(e)}'
            }))
