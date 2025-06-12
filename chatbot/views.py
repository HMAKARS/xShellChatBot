from django.shortcuts import render, get_object_or_404
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_http_methods
from django.utils.decorators import method_decorator
from django.views.generic import TemplateView
from django.contrib.auth.decorators import login_required
from django.contrib.auth import login
from django.contrib.auth.models import User
import json
import uuid

from .models import ChatSession, ChatMessage, XShellSession
from ai_backend.services import AIService
from xshell_integration.services import XShellService


class ChatbotHomeView(TemplateView):
    """챗봇 메인 페이지"""
    template_name = 'chatbot/index.html'
    
    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        
        # 사용자의 세션 목록 가져오기
        if self.request.user.is_authenticated:
            context['chat_sessions'] = ChatSession.objects.filter(
                user=self.request.user, 
                is_active=True
            )[:10]
        else:
            context['chat_sessions'] = []
        
        # XShell 세션 목록
        context['xshell_sessions'] = XShellSession.objects.filter(
            is_connected=True
        )[:5]
        
        return context


@csrf_exempt
@require_http_methods(["POST"])
def create_chat_session(request):
    """새로운 채팅 세션 생성"""
    try:
        data = json.loads(request.body)
        title = data.get('title', '새로운 채팅')
        
        session = ChatSession.objects.create(
            user=request.user if request.user.is_authenticated else None,
            session_id=str(uuid.uuid4()),
            title=title
        )
        
        return JsonResponse({
            'success': True,
            'session_id': session.session_id,
            'title': session.title
        })
    except Exception as e:
        return JsonResponse({
            'success': False,
            'error': str(e)
        }, status=400)


@csrf_exempt
@require_http_methods(["POST"])
def send_message(request):
    """메시지 전송 및 AI 응답 생성"""
    try:
        data = json.loads(request.body)
        session_id = data.get('session_id')
        message_content = data.get('message', '')
        message_type = data.get('type', 'user')
        
        if not session_id or not message_content:
            return JsonResponse({
                'success': False,
                'error': '세션 ID와 메시지가 필요합니다.'
            }, status=400)
        
        # 세션 찾기 또는 생성
        session, created = ChatSession.objects.get_or_create(
            session_id=session_id,
            defaults={'title': message_content[:50]}
        )
        
        # 사용자 메시지 저장
        user_message = ChatMessage.objects.create(
            session=session,
            message_type=message_type,
            content=message_content
        )
        
        # AI 서비스 호출
        ai_service = AIService()
        ai_response = ai_service.process_message(
            message_content, 
            session_id,
            message_type
        )
        
        # AI 응답 저장
        ai_message = ChatMessage.objects.create(
            session=session,
            message_type='ai',
            content=ai_response['content'],
            metadata=ai_response.get('metadata', {})
        )
        
        return JsonResponse({
            'success': True,
            'user_message': {
                'id': user_message.id,
                'content': user_message.content,
                'type': user_message.message_type,
                'timestamp': user_message.timestamp.isoformat()
            },
            'ai_message': {
                'id': ai_message.id,
                'content': ai_message.content,
                'type': ai_message.message_type,
                'timestamp': ai_message.timestamp.isoformat(),
                'metadata': ai_message.metadata
            }
        })
        
    except Exception as e:
        return JsonResponse({
            'success': False,
            'error': str(e)
        }, status=500)


def get_chat_history(request, session_id):
    """채팅 히스토리 조회"""
    try:
        session = get_object_or_404(ChatSession, session_id=session_id)
        messages = session.messages.all()
        
        message_list = []
        for msg in messages:
            message_list.append({
                'id': msg.id,
                'type': msg.message_type,
                'content': msg.content,
                'timestamp': msg.timestamp.isoformat(),
                'metadata': msg.metadata
            })
        
        return JsonResponse({
            'success': True,
            'session': {
                'id': session.session_id,
                'title': session.title,
                'created_at': session.created_at.isoformat()
            },
            'messages': message_list
        })
        
    except Exception as e:
        return JsonResponse({
            'success': False,
            'error': str(e)
        }, status=404)


@csrf_exempt
@require_http_methods(["POST"])
def execute_command(request):
    """XShell 명령어 실행"""
    try:
        data = json.loads(request.body)
        command = data.get('command')
        session_name = data.get('session_name', 'default')
        chat_session_id = data.get('chat_session_id')
        
        if not command:
            return JsonResponse({
                'success': False,
                'error': '명령어가 필요합니다.'
            }, status=400)
        
        # XShell 서비스 호출
        xshell_service = XShellService()
        result = xshell_service.execute_command(command, session_name)
        
        # 결과를 채팅 세션에 저장 (선택적)
        if chat_session_id:
            try:
                session = ChatSession.objects.get(session_id=chat_session_id)
                
                # 명령어 메시지 저장
                ChatMessage.objects.create(
                    session=session,
                    message_type='command',
                    content=command
                )
                
                # 결과 메시지 저장
                ChatMessage.objects.create(
                    session=session,
                    message_type='result',
                    content=result['output'],
                    metadata={
                        'exit_code': result.get('exit_code'),
                        'execution_time': result.get('execution_time')
                    }
                )
            except ChatSession.DoesNotExist:
                pass
        
        return JsonResponse({
            'success': True,
            'result': result
        })
        
    except Exception as e:
        return JsonResponse({
            'success': False,
            'error': str(e)
        }, status=500)


def get_xshell_sessions(request):
    """XShell 세션 목록 조회"""
    try:
        sessions = XShellSession.objects.all()
        session_list = []
        
        for session in sessions:
            session_list.append({
                'id': session.id,
                'name': session.name,
                'host': session.host,
                'username': session.username,
                'is_connected': session.is_connected,
                'last_used': session.last_used.isoformat()
            })
        
        return JsonResponse({
            'success': True,
            'sessions': session_list
        })
        
    except Exception as e:
        return JsonResponse({
            'success': False,
            'error': str(e)
        }, status=500)


@csrf_exempt
@require_http_methods(["DELETE"])
def delete_chat_session(request, session_id):
    """채팅 세션 삭제"""
    try:
        session = get_object_or_404(ChatSession, session_id=session_id)
        
        # 권한 체크 (로그인된 사용자인 경우)
        if request.user.is_authenticated and session.user != request.user:
            return JsonResponse({
                'success': False,
                'error': '권한이 없습니다.'
            }, status=403)
        
        session.is_active = False
        session.save()
        
        return JsonResponse({'success': True})
        
    except Exception as e:
        return JsonResponse({
            'success': False,
            'error': str(e)
        }, status=500)
