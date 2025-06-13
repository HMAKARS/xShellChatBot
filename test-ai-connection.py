#!/usr/bin/env python3
"""
Ollama AI 연결 테스트 스크립트
XShell 챗봇의 AI 기능 연결 상태를 확인합니다.
"""

import os
import sys
import requests
import json
from typing import Dict, Any, List

# Django 설정 추가
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'xshell_chatbot.settings')

try:
    import django
    django.setup()
    from ai_backend.services import AIService, OllamaClient
    from django.conf import settings
    DJANGO_AVAILABLE = True
except Exception as e:
    print(f"⚠️ Django 설정 로드 실패: {e}")
    DJANGO_AVAILABLE = False

def test_ollama_connection():
    """Ollama 기본 연결 테스트"""
    print("🔍 Ollama 연결 테스트")
    print("=" * 50)
    
    base_url = "http://localhost:11434"
    
    # 1. 기본 연결 테스트
    try:
        response = requests.get(f"{base_url}/", timeout=5)
        if response.status_code == 200:
            print("✅ Ollama 서비스 연결 성공")
            print(f"   응답: {response.text.strip()}")
        else:
            print(f"❌ Ollama 서비스 응답 오류: {response.status_code}")
            return False
    except requests.RequestException as e:
        print(f"❌ Ollama 서비스 연결 실패: {e}")
        print("   해결 방법: ollama serve 명령어로 서비스를 시작하세요")
        return False
    
    # 2. 모델 목록 확인
    try:
        response = requests.get(f"{base_url}/api/tags", timeout=5)
        if response.status_code == 200:
            models = response.json().get('models', [])
            print(f"✅ 설치된 모델 개수: {len(models)}")
            for model in models:
                print(f"   - {model['name']} ({model.get('size', 'unknown')})")
            
            if not models:
                print("⚠️ 설치된 모델이 없습니다.")
                print("   해결 방법: ollama pull llama3.2:3b")
                return False
        else:
            print(f"❌ 모델 목록 조회 실패: {response.status_code}")
            return False
    except requests.RequestException as e:
        print(f"❌ 모델 목록 조회 오류: {e}")
        return False
    
    return True

def test_api_endpoints():
    """API 엔드포인트 테스트"""
    print("\n🌐 API 엔드포인트 테스트")
    print("=" * 50)
    
    base_url = "http://localhost:11434"
    
    # 사용할 테스트 모델 찾기
    try:
        response = requests.get(f"{base_url}/api/tags", timeout=5)
        models = response.json().get('models', [])
        if not models:
            print("❌ 테스트할 모델이 없습니다.")
            return False
        
        test_model = models[0]['name']
        print(f"📋 테스트 모델: {test_model}")
        
    except Exception as e:
        print(f"❌ 테스트 모델 선택 실패: {e}")
        return False
    
    # 1. /api/generate 테스트
    print("\n🧪 /api/generate 엔드포인트 테스트")
    try:
        payload = {
            "model": test_model,
            "prompt": "Hello, what is 2+2? Answer briefly.",
            "stream": False,
            "options": {
                "temperature": 0.1,
                "num_predict": 50
            }
        }
        
        response = requests.post(
            f"{base_url}/api/generate", 
            json=payload, 
            timeout=30
        )
        
        if response.status_code == 200:
            result = response.json()
            print("✅ /api/generate 성공")
            print(f"   응답: {result.get('response', '응답 없음')[:100]}...")
            print(f"   소요 시간: {result.get('total_duration', 0) / 1e9:.1f}초")
        else:
            print(f"❌ /api/generate 실패: {response.status_code}")
            print(f"   오류: {response.text}")
            return False
            
    except requests.RequestException as e:
        print(f"❌ /api/generate 오류: {e}")
        return False
    
    # 2. /api/chat 테스트
    print("\n💬 /api/chat 엔드포인트 테스트")
    try:
        payload = {
            "model": test_model,
            "messages": [
                {"role": "user", "content": "Hello, what is 2+2? Answer briefly."}
            ],
            "stream": False
        }
        
        response = requests.post(
            f"{base_url}/api/chat", 
            json=payload, 
            timeout=30
        )
        
        if response.status_code == 200:
            result = response.json()
            print("✅ /api/chat 성공")
            message = result.get('message', {})
            print(f"   응답: {message.get('content', '응답 없음')[:100]}...")
        elif response.status_code == 404:
            print("⚠️ /api/chat 엔드포인트 없음 (이전 버전 Ollama)")
            print("   /api/generate 엔드포인트를 사용합니다")
        else:
            print(f"❌ /api/chat 실패: {response.status_code}")
            print(f"   오류: {response.text}")
            
    except requests.RequestException as e:
        print(f"❌ /api/chat 오류: {e}")
    
    return True

def test_django_ai_service():
    """Django AI 서비스 테스트"""
    if not DJANGO_AVAILABLE:
        print("\n⚠️ Django AI 서비스 테스트 건너뜀 (Django 로드 실패)")
        return False
        
    print("\n🤖 Django AI 서비스 테스트")
    print("=" * 50)
    
    try:
        # AI 서비스 초기화
        ai_service = AIService()
        print(f"✅ AI 서비스 초기화 성공")
        print(f"   Ollama 사용 가능: {ai_service.ollama_available}")
        
        if not ai_service.ollama_available:
            print("❌ Ollama 서비스 사용 불가")
            return False
        
        # 사용 가능한 모델 확인
        models = ai_service.get_available_models()
        print(f"✅ 사용 가능한 모델: {len(models)}개")
        for model in models[:3]:  # 최대 3개만 표시
            print(f"   - {model['name']}")
        
        # 테스트 메시지 처리
        test_message = "안녕하세요. 간단한 테스트입니다."
        session_id = "test_session"
        
        print(f"\n📝 테스트 메시지: {test_message}")
        
        result = ai_service.process_message(
            test_message, 
            session_id, 
            'user',
            {'shell_type': 'auto'}
        )
        
        print("✅ 메시지 처리 성공")
        print(f"   응답 길이: {len(result.get('content', ''))} 문자")
        print(f"   응답 미리보기: {result.get('content', '')[:150]}...")
        
        return True
        
    except Exception as e:
        print(f"❌ Django AI 서비스 테스트 실패: {e}")
        import traceback
        traceback.print_exc()
        return False

def test_client_classes():
    """클라이언트 클래스 직접 테스트"""
    if not DJANGO_AVAILABLE:
        return False
        
    print("\n🔧 클라이언트 클래스 테스트")
    print("=" * 50)
    
    try:
        # OllamaClient 직접 테스트
        client = OllamaClient()
        print("✅ OllamaClient 생성 성공")
        
        # 서비스 사용 가능 여부 확인
        available = client.is_available()
        print(f"   서비스 사용 가능: {available}")
        
        if available:
            # 간단한 생성 테스트
            response = client.generate(
                "Hello, respond with just 'Hi'",
                "You are a helpful assistant. Keep responses very short.",
            )
            print("✅ 텍스트 생성 테스트 성공")
            print(f"   응답: {response.get('response', 'No response')[:50]}...")
            
            # 채팅 테스트 (폴백 포함)
            messages = [
                {"role": "user", "content": "Hello, respond with just 'Hi'"}
            ]
            chat_response = client.chat(messages)
            print("✅ 채팅 테스트 성공")
            
            # 응답 형식 확인
            if 'message' in chat_response:
                content = chat_response['message'].get('content', '')
            else:
                content = chat_response.get('response', '')
                
            print(f"   채팅 응답: {content[:50]}...")
        
        return True
        
    except Exception as e:
        print(f"❌ 클라이언트 클래스 테스트 실패: {e}")
        import traceback
        traceback.print_exc()
        return False

def print_troubleshooting():
    """문제 해결 방법 출력"""
    print("\n🔧 문제 해결 방법")
    print("=" * 50)
    
    print("\n1. Ollama 서비스가 실행되지 않는 경우:")
    print("   - 명령어: ollama serve")
    print("   - 백그라운드: start /min ollama serve")
    print("   - 상태 확인: curl http://localhost:11434")
    
    print("\n2. 모델이 설치되지 않은 경우:")
    print("   - 경량 모델: ollama pull llama3.2:3b")
    print("   - 고성능 모델: ollama pull llama3.1:8b")
    print("   - 모델 확인: ollama list")
    
    print("\n3. API 오류가 발생하는 경우:")
    print("   - 포트 확인: netstat -an | findstr 11434")
    print("   - 재시작: taskkill /f /im ollama.exe && ollama serve")
    print("   - 로그 확인: ollama logs")
    
    print("\n4. Django 연동 오류:")
    print("   - 가상환경 확인: .venv\\Scripts\\activate")
    print("   - 패키지 설치: pip install requests")
    print("   - 서버 재시작: run-daphne.bat")
    
    print("\n5. 성능 개선:")
    print("   - GPU 사용: CUDA 설치 확인")
    print("   - 메모리 확인: 최소 8GB RAM 권장")
    print("   - 모델 변경: 더 작은 모델 사용")

def main():
    """메인 테스트 실행"""
    print("🚀 XShell 챗봇 AI 연결 테스트")
    print("=" * 50)
    print()
    
    results = {
        'ollama_connection': False,
        'api_endpoints': False,
        'django_service': False,
        'client_classes': False
    }
    
    # 1. Ollama 기본 연결 테스트
    results['ollama_connection'] = test_ollama_connection()
    
    # 2. API 엔드포인트 테스트
    if results['ollama_connection']:
        results['api_endpoints'] = test_api_endpoints()
    
    # 3. Django AI 서비스 테스트
    if results['ollama_connection']:
        results['django_service'] = test_django_ai_service()
    
    # 4. 클라이언트 클래스 테스트
    if results['ollama_connection']:
        results['client_classes'] = test_client_classes()
    
    # 결과 요약
    print("\n📊 테스트 결과 요약")
    print("=" * 50)
    
    for test_name, success in results.items():
        status = "✅ 성공" if success else "❌ 실패"
        print(f"{test_name}: {status}")
    
    all_passed = all(results.values())
    if all_passed:
        print("\n🎉 모든 테스트 통과! AI 기능을 사용할 수 있습니다.")
        print("   run-daphne.bat을 실행해서 서버를 시작하세요.")
    else:
        print("\n⚠️ 일부 테스트 실패. 문제 해결이 필요합니다.")
        print_troubleshooting()

if __name__ == "__main__":
    main()
