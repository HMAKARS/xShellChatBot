from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_http_methods
import json

from .services import AIService


@csrf_exempt
@require_http_methods(["POST"])
def generate_response(request):
    """AI 응답 생성 API"""
    try:
        data = json.loads(request.body)
        message = data.get('message', '')
        session_id = data.get('session_id', '')
        message_type = data.get('type', 'user')
        
        if not message:
            return JsonResponse({
                'success': False,
                'error': '메시지가 필요합니다.'
            }, status=400)
        
        ai_service = AIService()
        response = ai_service.process_message(message, session_id, message_type)
        
        return JsonResponse({
            'success': True,
            'response': response
        })
        
    except Exception as e:
        return JsonResponse({
            'success': False,
            'error': str(e)
        }, status=500)


@csrf_exempt
@require_http_methods(["POST"])
def analyze_intent(request):
    """의도 분석 API"""
    try:
        data = json.loads(request.body)
        message = data.get('message', '')
        
        if not message:
            return JsonResponse({
                'success': False,
                'error': '메시지가 필요합니다.'
            }, status=400)
        
        ai_service = AIService()
        intent = ai_service.analyze_intent(message)
        
        return JsonResponse({
            'success': True,
            'intent': intent
        })
        
    except Exception as e:
        return JsonResponse({
            'success': False,
            'error': str(e)
        }, status=500)


def get_models(request):
    """사용 가능한 AI 모델 목록"""
    try:
        ai_service = AIService()
        models = ai_service.get_available_models()
        
        return JsonResponse({
            'success': True,
            'models': models
        })
        
    except Exception as e:
        return JsonResponse({
            'success': False,
            'error': str(e)
        }, status=500)


def health_check(request):
    """AI 서비스 상태 확인"""
    try:
        ai_service = AIService()
        is_available = ai_service.ollama_client.is_available()
        
        return JsonResponse({
            'success': True,
            'ollama_available': is_available,
            'base_url': ai_service.ollama_client.base_url,
            'model': ai_service.ollama_client.model
        })
        
    except Exception as e:
        return JsonResponse({
            'success': False,
            'error': str(e)
        }, status=500)
