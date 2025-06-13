from django.http import JsonResponse, StreamingHttpResponse
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_http_methods
from django.utils import timezone
from datetime import timedelta
import json
import time

from .services import XShellService
from chatbot.models import XShellSession


@csrf_exempt
@require_http_methods(["POST"])
def execute_command(request):
    """명령어 실행 API"""
    try:
        data = json.loads(request.body)
        command = data.get('command', '')
        session_name = data.get('session_name', 'default')
        
        if not command:
            return JsonResponse({
                'success': False,
                'error': '명령어가 필요합니다.'
            }, status=400)
        
        xshell_service = XShellService()
        result = xshell_service.execute_command(command, session_name)
        
        return JsonResponse({
            'success': True,
            'result': result
        })
        
    except Exception as e:
        return JsonResponse({
            'success': False,
            'error': str(e)
        }, status=500)


@csrf_exempt
def execute_command_stream(request):
    """스트리밍 명령어 실행 API"""
    if request.method != 'POST':
        return JsonResponse({'error': 'POST method required'}, status=405)
    
    try:
        data = json.loads(request.body)
        command = data.get('command', '')
        session_name = data.get('session_name', 'default')
        
        if not command:
            return JsonResponse({
                'success': False,
                'error': '명령어가 필요합니다.'
            }, status=400)
        
        def stream_output():
            xshell_service = XShellService()
            try:
                for output_chunk in xshell_service.execute_command_stream(command, session_name):
                    yield f"data: {json.dumps({'output': output_chunk})}\n\n"
                    time.sleep(0.1)  # 스트리밍 속도 조절
                yield f"data: {json.dumps({'status': 'completed'})}\n\n"
            except Exception as e:
                yield f"data: {json.dumps({'error': str(e)})}\n\n"
        
        response = StreamingHttpResponse(
            stream_output(),
            content_type='text/event-stream'
        )
        response['Cache-Control'] = 'no-cache'
        response['Connection'] = 'keep-alive'
        return response
        
    except Exception as e:
        return JsonResponse({
            'success': False,
            'error': str(e)
        }, status=500)


def health_check(request):
    """XShell 서비스 상태 확인"""
    try:
        xshell_service = XShellService()
        
        # 활성 세션 수 확인
        active_sessions = XShellSession.objects.filter(is_connected=True).count()
        total_sessions = XShellSession.objects.count()
        
        # 최근 명령어 실행 확인
        from chatbot.models import CommandHistory
        recent_commands = CommandHistory.objects.filter(
            timestamp__gte=timezone.now() - timedelta(hours=1)
        ).count()
        
        return JsonResponse({
            'success': True,
            'status': 'healthy',
            'active_sessions': active_sessions,
            'total_sessions': total_sessions,
            'recent_commands': recent_commands,
            'xshell_path': xshell_service.xshell_path,
            'sessions_path': xshell_service.sessions_path
        })
        
    except Exception as e:
        return JsonResponse({
            'success': False,
            'error': str(e)
        }, status=500)


@csrf_exempt
@require_http_methods(["POST"])
def create_session(request):
    """XShell 세션 생성 API"""
    try:
        data = json.loads(request.body)
        name = data.get('name', '')
        host = data.get('host', '')
        username = data.get('username', '')
        password = data.get('password', '')
        private_key_path = data.get('private_key_path', '')
        port = data.get('port', 22)
        
        if not all([name, host, username]):
            return JsonResponse({
                'success': False,
                'error': '이름, 호스트, 사용자명이 필요합니다.'
            }, status=400)
        
        xshell_service = XShellService()
        session = xshell_service.create_xshell_session(
            name=name,
            host=host,
            username=username,
            password=password,
            private_key_path=private_key_path,
            port=port
        )
        
        return JsonResponse({
            'success': True,
            'session': {
                'id': session.id,
                'name': session.name,
                'host': session.host,
                'username': session.username,
                'port': session.port
            }
        })
        
    except Exception as e:
        return JsonResponse({
            'success': False,
            'error': str(e)
        }, status=500)


def list_sessions(request):
    """XShell 세션 목록 조회"""
    try:
        sessions = XShellSession.objects.all().order_by('-last_used')
        
        session_list = []
        for session in sessions:
            session_list.append({
                'id': session.id,
                'name': session.name,
                'host': session.host,
                'username': session.username,
                'port': session.port,
                'is_connected': session.is_connected,
                'last_used': session.last_used.isoformat(),
                'created_at': session.created_at.isoformat()
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
@require_http_methods(["POST"])
def test_session(request, session_name):
    """XShell 세션 연결 테스트"""
    try:
        if not session_name:
            return JsonResponse({
                'success': False,
                'error': '세션명이 필요합니다.'
            }, status=400)
        
        xshell_service = XShellService()
        test_result = xshell_service.test_xshell_session(session_name)
        
        return JsonResponse({
            'success': test_result['success'],
            'message': test_result['message']
        })
        
    except Exception as e:
        return JsonResponse({
            'success': False,
            'error': str(e)
        }, status=500)


def get_command_history(request, session_name):
    """명령어 히스토리 조회"""
    try:
        limit = int(request.GET.get('limit', 20))
        
        xshell_service = XShellService()
        history = xshell_service.get_command_history(session_name, limit)
        
        return JsonResponse({
            'success': True,
            'history': history
        })
        
    except Exception as e:
        return JsonResponse({
            'success': False,
            'error': str(e)
        }, status=500)


@csrf_exempt
@require_http_methods(["DELETE"])
def delete_session(request, session_name):
    """XShell 세션 삭제"""
    try:
        session = XShellSession.objects.get(name=session_name)
        session.delete()
        
        return JsonResponse({
            'success': True,
            'message': f'세션 "{session_name}"이 삭제되었습니다.'
        })
        
    except XShellSession.DoesNotExist:
        return JsonResponse({
            'success': False,
            'error': '세션을 찾을 수 없습니다.'
        }, status=404)
    except Exception as e:
        return JsonResponse({
            'success': False,
            'error': str(e)
        }, status=500)
