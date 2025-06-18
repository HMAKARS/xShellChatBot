from django.shortcuts import render, get_object_or_404, redirect
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_http_methods
from django.views.generic import TemplateView
from django.core.files.storage import default_storage
from django.core.files.base import ContentFile
from django.utils.decorators import method_decorator
from django.views.decorators.cache import never_cache
from django.core.exceptions import ValidationError
from django.conf import settings
from django.contrib.auth import authenticate, login, logout
from django.contrib.auth.decorators import login_required
from django.contrib.auth.forms import AuthenticationForm
from django.contrib.auth.models import User
from django.contrib import messages
import json
import uuid
import os
import logging
import time
from datetime import datetime, timedelta

from .models import ChatSession, ChatMessage
from ai_backend.services import GeminiClient
from ai_backend.file_processor import FileProcessor

# 보안 로깅 설정
security_logger = logging.getLogger('security')

# Rate limiting을 위한 간단한 메모리 저장소
request_counts = {}
RATE_LIMIT_WINDOW = 60  # 1분
RATE_LIMIT_MAX_REQUESTS = 30  # 분당 최대 30회 요청
UPLOAD_RATE_LIMIT = 5  # 파일 업로드는 분당 5회


def get_client_ip(request):
    """클라이언트 IP 주소 안전하게 가져오기"""
    x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
    if x_forwarded_for:
        ip = x_forwarded_for.split(',')[0].strip()
    else:
        ip = request.META.get('REMOTE_ADDR')
    return ip


def rate_limit_check(request, limit=RATE_LIMIT_MAX_REQUESTS):
    """Rate limiting 검사"""
    client_ip = get_client_ip(request)
    current_time = time.time()
    
    # 오래된 기록 정리
    expired_time = current_time - RATE_LIMIT_WINDOW
    request_counts[client_ip] = [
        timestamp for timestamp in request_counts.get(client_ip, [])
        if timestamp > expired_time
    ]
    
    # 현재 요청 수 확인
    if len(request_counts.get(client_ip, [])) >= limit:
        security_logger.warning(
            f"Rate limit exceeded for IP {client_ip}. "
            f"Requests: {len(request_counts[client_ip])}"
        )
        return False
    
    # 현재 요청 기록
    if client_ip not in request_counts:
        request_counts[client_ip] = []
    request_counts[client_ip].append(current_time)
    
    return True


def validate_session_id(session_id):
    """세션 ID 검증"""
    if not session_id:
        return False
    
    # UUID 형식 검증
    try:
        uuid_obj = uuid.UUID(session_id)
        return str(uuid_obj) == session_id
    except ValueError:
        return False


def sanitize_input(text, max_length=10000):
    """입력 텍스트 sanitization"""
    if not isinstance(text, str):
        return ""
    
    # 길이 제한
    if len(text) > max_length:
        text = text[:max_length]
    
    # 위험한 패턴 제거
    import re
    dangerous_patterns = [
        r'<script[^>]*>.*?</script>',
        r'javascript:',
        r'vbscript:',
        r'on\w+\s*=',
    ]
    
    for pattern in dangerous_patterns:
        text = re.sub(pattern, '', text, flags=re.IGNORECASE)
    
    return text.strip()


def log_security_event(request, event_type, details):
    """보안 이벤트 로깅"""
    client_ip = get_client_ip(request)
    user_agent = request.META.get('HTTP_USER_AGENT', 'Unknown')
    
    security_logger.info(
        f"Security Event: {event_type} | "
        f"IP: {client_ip} | "
        f"User-Agent: {user_agent} | "
        f"Details: {details}"
    )


class ChatbotHomeView(TemplateView):
    """챗봇 메인 페이지"""
    template_name = 'chatbot/index.html'
    
    @method_decorator(login_required)
    def dispatch(self, *args, **kwargs):
        return super().dispatch(*args, **kwargs)
    
    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        
        # 메시지가 있는 세션만 가져와서 마지막 메시지 시간 순으로 정렬
        from django.db.models import Max
        context['chat_sessions'] = ChatSession.objects.filter(
            user=self.request.user, 
            is_active=True,
            messages__isnull=False  # 메시지가 있는 세션만
        ).annotate(
            last_message_time=Max('messages__timestamp')  # 마지막 메시지 시간
        ).order_by('-last_message_time')[:10]  # 마지막 대화 시간 순으로 정렬
        
        return context


def login_view(request):
    """로그인 페이지"""
    if request.user.is_authenticated:
        return redirect('chatbot:home')
    
    if request.method == 'POST':
        form = AuthenticationForm(request, data=request.POST)
        if form.is_valid():
            username = form.cleaned_data.get('username')
            password = form.cleaned_data.get('password')
            user = authenticate(username=username, password=password)
            if user is not None:
                login(request, user)
                messages.success(request, f'{username}님, 환영합니다!')
                return redirect('chatbot:home')
        else:
            messages.error(request, '로그인 정보가 올바르지 않습니다.')
    else:
        form = AuthenticationForm()
    
    return render(request, 'chatbot/login.html', {'form': form})


def logout_view(request):
    """로그아웃"""
    logout(request)
    messages.success(request, '로그아웃되었습니다.')
    return redirect('chatbot:login')


def register_view(request):
    """회원가입 페이지"""
    if request.user.is_authenticated:
        return redirect('chatbot:home')
    
    if request.method == 'POST':
        username = request.POST.get('username')
        email = request.POST.get('email')
        password1 = request.POST.get('password1')
        password2 = request.POST.get('password2')
        
        # 기본 검증
        if not all([username, email, password1, password2]):
            messages.error(request, '모든 필드를 입력해주세요.')
        elif password1 != password2:
            messages.error(request, '비밀번호가 일치하지 않습니다.')
        elif len(password1) < 8:
            messages.error(request, '비밀번호는 8자 이상이어야 합니다.')
        elif User.objects.filter(username=username).exists():
            messages.error(request, '이미 존재하는 사용자명입니다.')
        elif User.objects.filter(email=email).exists():
            messages.error(request, '이미 존재하는 이메일입니다.')
        else:
            try:
                user = User.objects.create_user(
                    username=username,
                    email=email,
                    password=password1
                )
                messages.success(request, '회원가입이 완료되었습니다. 로그인해주세요.')
                return redirect('chatbot:login')
            except Exception as e:
                messages.error(request, '회원가입 중 오류가 발생했습니다.')
    
    return render(request, 'chatbot/register.html')


@csrf_exempt
@require_http_methods(["POST"])
@login_required
def create_chat_session(request):
    """새로운 채팅 세션 생성"""
    try:
        data = json.loads(request.body)
        title = data.get('title', '새로운 채팅')
        
        session = ChatSession.objects.create(
            user=request.user,
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
@login_required
def send_message(request):
    """메시지 전송 및 AI 응답 생성 (보안 강화)"""
    try:
        # Rate limiting 검사
        if not rate_limit_check(request):
            log_security_event(request, "RATE_LIMIT_EXCEEDED", "Message sending")
            return JsonResponse({
                'success': False,
                'error': '요청이 너무 많습니다. 잠시 후 다시 시도해주세요.'
            }, status=429)
        
        # Content-Type 검증
        if request.content_type != 'application/json':
            log_security_event(request, "INVALID_CONTENT_TYPE", f"Expected JSON, got {request.content_type}")
            return JsonResponse({
                'success': False,
                'error': '잘못된 요청 형식입니다.'
            }, status=400)
        
        # JSON 파싱 및 검증
        try:
            data = json.loads(request.body)
        except json.JSONDecodeError:
            log_security_event(request, "INVALID_JSON", "Failed to parse JSON")
            return JsonResponse({
                'success': False,
                'error': '잘못된 JSON 형식입니다.'
            }, status=400)
        
        # 입력 검증 및 sanitization
        session_id = data.get('session_id', '').strip()
        message_content = sanitize_input(data.get('message', ''), max_length=5000)
        
        if not validate_session_id(session_id):
            log_security_event(request, "INVALID_SESSION_ID", f"Session ID: {session_id}")
            return JsonResponse({
                'success': False,
                'error': '유효하지 않은 세션 ID입니다.'
            }, status=400)
        
        if not message_content:
            return JsonResponse({
                'success': False,
                'error': '메시지를 입력해주세요.'
            }, status=400)
        
        # 세션 찾기 또는 생성
        session, created = ChatSession.objects.get_or_create(
            session_id=session_id,
            defaults={'title': message_content[:50], 'user': request.user}
        )
        
        # 사용자 메시지 저장
        user_message = ChatMessage.objects.create(
            session=session,
            message_type='user',
            content=message_content
        )
        
        # 대화 컨텍스트 가져오기 (최근 10개만)
        recent_messages = session.messages.order_by('-timestamp')[:10]
        context = []
        for msg in reversed(recent_messages):
            if msg.message_type == 'user':
                context.append({'user': msg.content[:1000]})  # 컨텍스트도 길이 제한
            else:
                context.append({'assistant': msg.content[:1000]})
        
        # AI 서비스 호출
        try:
            gemini_client = GeminiClient()
            ai_result = gemini_client.handle_chat(message_content, context)
        except Exception as e:
            log_security_event(request, "AI_SERVICE_ERROR", str(e))
            return JsonResponse({
                'success': False,
                'error': 'AI 서비스에 일시적인 문제가 발생했습니다.'
            }, status=500)
        
        # AI 응답 저장
        ai_message = ChatMessage.objects.create(
            session=session,
            message_type='ai',
            content=ai_result['response']
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
                'timestamp': ai_message.timestamp.isoformat()
            }
        })
        
    except Exception as e:
        log_security_event(request, "UNEXPECTED_ERROR", str(e))
        return JsonResponse({
            'success': False,
            'error': '서버 오류가 발생했습니다.'
        }, status=500)


@csrf_exempt
@require_http_methods(["POST"])
@login_required
def analyze_file(request):
    """파일 업로드 및 분석 (보안 강화)"""
    try:
        # 파일 업로드 전용 Rate limiting (더 엄격)
        if not rate_limit_check(request, limit=UPLOAD_RATE_LIMIT):
            log_security_event(request, "UPLOAD_RATE_LIMIT_EXCEEDED", "File upload")
            return JsonResponse({
                'success': False,
                'error': '파일 업로드 요청이 너무 많습니다. 잠시 후 다시 시도해주세요.'
            }, status=429)
        
        # 파일 존재 확인
        if 'file' not in request.FILES:
            log_security_event(request, "NO_FILE_UPLOADED", "File missing")
            return JsonResponse({
                'success': False,
                'error': '파일이 업로드되지 않았습니다.'
            }, status=400)
        
        uploaded_file = request.FILES['file']
        session_id = request.POST.get('session_id', '').strip()
        question = sanitize_input(request.POST.get('question', '이 파일의 내용을 분석해주세요.'), max_length=1000)
        
        # 세션 ID 검증
        if session_id and not validate_session_id(session_id):
            log_security_event(request, "INVALID_SESSION_ID_UPLOAD", f"Session ID: {session_id}")
            return JsonResponse({
                'success': False,
                'error': '유효하지 않은 세션 ID입니다.'
            }, status=400)
        
        # 파일명 검증 및 sanitization
        safe_filename = FileProcessor.sanitize_filename(uploaded_file.name)
        
        # 기본 파일 검증
        if not FileProcessor.is_supported_file(safe_filename):
            log_security_event(request, "UNSUPPORTED_FILE_TYPE", f"File: {safe_filename}")
            return JsonResponse({
                'success': False,
                'error': f'지원되지 않는 파일 형식입니다. 지원 형식: {", ".join(FileProcessor.SUPPORTED_EXTENSIONS.keys())}'
            }, status=400)
        
        # 파일 크기 1차 검증
        if uploaded_file.size > FileProcessor.MAX_FILE_SIZE:
            log_security_event(request, "FILE_TOO_LARGE", f"Size: {uploaded_file.size}, File: {safe_filename}")
            return JsonResponse({
                'success': False,
                'error': f'파일 크기가 너무 큽니다. 최대 {FileProcessor.MAX_FILE_SIZE // (1024*1024)}MB까지 지원됩니다.'
            }, status=400)
        
        # 세션 찾기 또는 생성
        if session_id:
            session, created = ChatSession.objects.get_or_create(
                session_id=session_id,
                defaults={'title': f'파일 분석: {safe_filename}', 'user': request.user}
            )
        else:
            session = ChatSession.objects.create(
                session_id=str(uuid.uuid4()),
                title=f'파일 분석: {safe_filename}',
                user=request.user
            )
        
        # 파일 내용 안전하게 읽기
        try:
            file_content = uploaded_file.read()
        except Exception as e:
            log_security_event(request, "FILE_READ_ERROR", f"File: {safe_filename}, Error: {str(e)}")
            return JsonResponse({
                'success': False,
                'error': '파일을 읽는 중 오류가 발생했습니다.'
            }, status=400)
        
        # 파일에서 텍스트 추출 (보안 검증 포함)
        extraction_result = FileProcessor.extract_text_from_file(file_content, uploaded_file.name)
        
        if not extraction_result['success']:
            # 보안 오류인 경우 특별 로깅
            if extraction_result.get('metadata', {}).get('security_error'):
                log_security_event(request, "FILE_SECURITY_ERROR", f"File: {safe_filename}, Error: {extraction_result['error']}")
            
            return JsonResponse({
                'success': False,
                'error': extraction_result['error']
            }, status=400)
        
        # 파일 정보 메시지 저장
        file_info = FileProcessor.get_file_summary(extraction_result['text'], extraction_result['metadata'])
        file_message_content = f"📎 파일 업로드: {safe_filename}\n📊 {file_info}"
        
        file_message = ChatMessage.objects.create(
            session=session,
            message_type='system',
            content=file_message_content,
            metadata={
                'file_name': safe_filename,
                'original_filename': uploaded_file.name,
                'file_size': uploaded_file.size,
                'file_type': extraction_result['metadata'].get('file_type'),
                'file_hash': extraction_result['metadata'].get('file_hash'),
                'extraction_metadata': extraction_result['metadata'],
                'security_validated': True
            }
        )
        
        # 사용자 질문 저장
        user_message = ChatMessage.objects.create(
            session=session,
            message_type='user',
            content=question
        )
        
        # AI에게 파일 내용과 질문 전달 (텍스트 길이 제한)
        limited_text = extraction_result['text'][:50000]  # 50KB로 제한
        if len(extraction_result['text']) > 50000:
            limited_text += "\n\n[텍스트가 너무 길어 일부가 생략되었습니다]"
        
        full_prompt = f"""
파일 정보:
- 파일명: {safe_filename}
- {file_info}

파일 내용:
{limited_text}

사용자 질문: {question}

위 파일의 내용을 바탕으로 사용자의 질문에 답변해주세요.
"""
        
        # 대화 컨텍스트 가져오기 (최근 5개만, 파일 분석시에는 제한적으로)
        recent_messages = session.messages.order_by('-timestamp')[:5]
        context = []
        for msg in reversed(recent_messages):
            if msg.message_type == 'user':
                context.append({'user': msg.content[:500]})
            elif msg.message_type == 'ai':
                context.append({'assistant': msg.content[:500]})
        
        # Gemini API 호출
        try:
            gemini_client = GeminiClient()
            ai_result = gemini_client.handle_chat(full_prompt, context)
        except Exception as e:
            log_security_event(request, "AI_SERVICE_ERROR_FILE", str(e))
            return JsonResponse({
                'success': False,
                'error': 'AI 파일 분석 서비스에 일시적인 문제가 발생했습니다.'
            }, status=500)
        
        # AI 응답 저장
        ai_message = ChatMessage.objects.create(
            session=session,
            message_type='ai',
            content=ai_result['response'],
            metadata={
                'analyzed_file': safe_filename,
                'file_analysis': True,
                'file_hash': extraction_result['metadata'].get('file_hash')
            }
        )
        
        # 성공 로깅
        log_security_event(request, "FILE_ANALYSIS_SUCCESS", f"File: {safe_filename}, Hash: {extraction_result['metadata'].get('file_hash', 'unknown')}")
        
        return JsonResponse({
            'success': True,
            'session_id': session.session_id,
            'file_message': {
                'id': file_message.id,
                'content': file_message.content,
                'type': file_message.message_type,
                'timestamp': file_message.timestamp.isoformat(),
                'metadata': file_message.metadata
            },
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
            },
            'file_info': {
                'name': safe_filename,
                'size': uploaded_file.size,
                'type': extraction_result['metadata'].get('file_type'),
                'summary': file_info,
                'hash': extraction_result['metadata'].get('file_hash')
            }
        })
        
    except Exception as e:
        log_security_event(request, "FILE_UPLOAD_UNEXPECTED_ERROR", str(e))
        return JsonResponse({
            'success': False,
            'error': '파일 분석 중 서버 오류가 발생했습니다.'
        }, status=500)


def get_chat_history(request, session_id):
    """채팅 히스토리 조회"""
    try:
        session = get_object_or_404(ChatSession, session_id=session_id)
        messages = session.messages.all().order_by('timestamp')
        
        message_list = []
        for msg in messages:
            message_list.append({
                'id': msg.id,
                'type': msg.message_type,
                'content': msg.content,
                'timestamp': msg.timestamp.isoformat()
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


@csrf_exempt
@require_http_methods(["POST"])
@login_required
def analyze_file(request):
    """파일 업로드 및 분석 (보안 강화)"""
    try:
        # 파일 업로드 전용 Rate limiting (더 엄격)
        if not rate_limit_check(request, limit=UPLOAD_RATE_LIMIT):
            log_security_event(request, "UPLOAD_RATE_LIMIT_EXCEEDED", "File upload")
            return JsonResponse({
                'success': False,
                'error': '파일 업로드 요청이 너무 많습니다. 잠시 후 다시 시도해주세요.'
            }, status=429)
        
        # 파일 존재 확인
        if 'file' not in request.FILES:
            log_security_event(request, "NO_FILE_UPLOADED", "File missing")
            return JsonResponse({
                'success': False,
                'error': '파일이 업로드되지 않았습니다.'
            }, status=400)
        
        uploaded_file = request.FILES['file']
        session_id = request.POST.get('session_id', '').strip()
        question = sanitize_input(request.POST.get('question', '이 파일의 내용을 분석해주세요.'), max_length=1000)
        
        # 세션 ID 검증
        if session_id and not validate_session_id(session_id):
            log_security_event(request, "INVALID_SESSION_ID_UPLOAD", f"Session ID: {session_id}")
            return JsonResponse({
                'success': False,
                'error': '유효하지 않은 세션 ID입니다.'
            }, status=400)
        
        # 파일명 검증 및 sanitization
        safe_filename = FileProcessor.sanitize_filename(uploaded_file.name)
        
        # 기본 파일 검증
        if not FileProcessor.is_supported_file(safe_filename):
            log_security_event(request, "UNSUPPORTED_FILE_TYPE", f"File: {safe_filename}")
            return JsonResponse({
                'success': False,
                'error': f'지원되지 않는 파일 형식입니다. 지원 형식: {", ".join(FileProcessor.SUPPORTED_EXTENSIONS.keys())}'
            }, status=400)
        
        # 파일 크기 1차 검증
        if uploaded_file.size > FileProcessor.MAX_FILE_SIZE:
            log_security_event(request, "FILE_TOO_LARGE", f"Size: {uploaded_file.size}, File: {safe_filename}")
            return JsonResponse({
                'success': False,
                'error': f'파일 크기가 너무 큽니다. 최대 {FileProcessor.MAX_FILE_SIZE // (1024*1024)}MB까지 지원됩니다.'
            }, status=400)
        
        # 세션 찾기 또는 생성
        if session_id:
            session, created = ChatSession.objects.get_or_create(
                session_id=session_id,
                defaults={'title': f'파일 분석: {safe_filename}', 'user': request.user}
            )
        else:
            session = ChatSession.objects.create(
                session_id=str(uuid.uuid4()),
                title=f'파일 분석: {safe_filename}',
                user=request.user
            )
        
        # 파일 내용 안전하게 읽기
        try:
            file_content = uploaded_file.read()
        except Exception as e:
            log_security_event(request, "FILE_READ_ERROR", f"File: {safe_filename}, Error: {str(e)}")
            return JsonResponse({
                'success': False,
                'error': '파일을 읽는 중 오류가 발생했습니다.'
            }, status=400)
        
        # 파일에서 텍스트 추출 (보안 검증 포함)
        extraction_result = FileProcessor.extract_text_from_file(file_content, uploaded_file.name)
        
        if not extraction_result['success']:
            # 보안 오류인 경우 특별 로깅
            if extraction_result.get('metadata', {}).get('security_error'):
                log_security_event(request, "FILE_SECURITY_ERROR", f"File: {safe_filename}, Error: {extraction_result['error']}")
            
            return JsonResponse({
                'success': False,
                'error': extraction_result['error']
            }, status=400)
        
        # 파일 정보 메시지 저장
        file_info = FileProcessor.get_file_summary(extraction_result['text'], extraction_result['metadata'])
        file_message_content = f"📎 파일 업로드: {safe_filename}\n📊 {file_info}"
        
        file_message = ChatMessage.objects.create(
            session=session,
            message_type='system',
            content=file_message_content,
            metadata={
                'file_name': safe_filename,
                'original_filename': uploaded_file.name,
                'file_size': uploaded_file.size,
                'file_type': extraction_result['metadata'].get('file_type'),
                'file_hash': extraction_result['metadata'].get('file_hash'),
                'extraction_metadata': extraction_result['metadata'],
                'security_validated': True
            }
        )
        
        # 사용자 질문 저장
        user_message = ChatMessage.objects.create(
            session=session,
            message_type='user',
            content=question
        )
        
        # AI에게 파일 내용과 질문 전달 (텍스트 길이 제한)
        limited_text = extraction_result['text'][:50000]  # 50KB로 제한
        if len(extraction_result['text']) > 50000:
            limited_text += "\n\n[텍스트가 너무 길어 일부가 생략되었습니다]"
        
        full_prompt = f"""
파일 정보:
- 파일명: {safe_filename}
- {file_info}

파일 내용:
{limited_text}

사용자 질문: {question}

위 파일의 내용을 바탕으로 사용자의 질문에 답변해주세요.
"""
        
        # 대화 컨텍스트 가져오기 (최근 5개만, 파일 분석시에는 제한적으로)
        recent_messages = session.messages.order_by('-timestamp')[:5]
        context = []
        for msg in reversed(recent_messages):
            if msg.message_type == 'user':
                context.append({'user': msg.content[:500]})
            elif msg.message_type == 'ai':
                context.append({'assistant': msg.content[:500]})
        
        # Gemini API 호출
        try:
            gemini_client = GeminiClient()
            ai_result = gemini_client.handle_chat(full_prompt, context)
        except Exception as e:
            log_security_event(request, "AI_SERVICE_ERROR_FILE", str(e))
            return JsonResponse({
                'success': False,
                'error': 'AI 파일 분석 서비스에 일시적인 문제가 발생했습니다.'
            }, status=500)
        
        # AI 응답 저장
        ai_message = ChatMessage.objects.create(
            session=session,
            message_type='ai',
            content=ai_result['response'],
            metadata={
                'analyzed_file': safe_filename,
                'file_analysis': True,
                'file_hash': extraction_result['metadata'].get('file_hash')
            }
        )
        
        # 성공 로깅
        log_security_event(request, "FILE_ANALYSIS_SUCCESS", f"File: {safe_filename}, Hash: {extraction_result['metadata'].get('file_hash', 'unknown')}")
        
        return JsonResponse({
            'success': True,
            'session_id': session.session_id,
            'file_message': {
                'id': file_message.id,
                'content': file_message.content,
                'type': file_message.message_type,
                'timestamp': file_message.timestamp.isoformat(),
                'metadata': file_message.metadata
            },
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
            },
            'file_info': {
                'name': safe_filename,
                'size': uploaded_file.size,
                'type': extraction_result['metadata'].get('file_type'),
                'summary': file_info,
                'hash': extraction_result['metadata'].get('file_hash')
            }
        })
        
    except Exception as e:
        log_security_event(request, "FILE_UPLOAD_UNEXPECTED_ERROR", str(e))
        return JsonResponse({
            'success': False,
            'error': '파일 분석 중 서버 오류가 발생했습니다.'
        }, status=500)


def get_chat_sessions(request):
    """채팅 세션 목록 조회"""
    try:
        if request.user.is_authenticated:
            sessions = ChatSession.objects.filter(
                user=request.user,
                is_active=True
            ).order_by('-updated_at')[:20]
        else:
            sessions = []
        
        session_list = []
        for session in sessions:
            session_list.append({
                'session_id': session.session_id,
                'title': session.title,
                'created_at': session.created_at.isoformat(),
                'updated_at': session.updated_at.isoformat(),
                'message_count': session.messages.count()
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
