#!/usr/bin/env python
"""
Django 모듈 import 테스트 스크립트
"""

import os
import sys
import django

# Django 설정
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'xshell_chatbot.settings')

def test_imports():
    """모든 모듈 import 테스트"""
    
    print("🔍 Django 모듈 import 테스트 시작...")
    print()
    
    try:
        # Django 설정 초기화
        print("[1/6] Django 설정 초기화...")
        django.setup()
        print("✅ Django 설정 초기화 성공")
        
    except Exception as e:
        print(f"❌ Django 설정 초기화 실패: {e}")
        return False
    
    try:
        # 1. 기본 Django 모듈 테스트
        print("[2/6] 기본 Django 모듈 테스트...")
        from django.db import models
        from django.contrib.auth.models import User
        from django.utils import timezone
        print("✅ 기본 Django 모듈 import 성공")
        
    except Exception as e:
        print(f"❌ 기본 Django 모듈 import 실패: {e}")
        return False
    
    try:
        # 2. chatbot 모델 테스트
        print("[3/6] chatbot 모델 테스트...")
        from chatbot.models import ChatSession, ChatMessage, XShellSession
        from chatbot.models import CommandHistory, AIModel
        print("✅ chatbot 모델 import 성공")
        
        # 모델 클래스 확인
        print(f"   - ChatSession: {ChatSession}")
        print(f"   - ChatMessage: {ChatMessage}")
        print(f"   - XShellSession: {XShellSession}")
        print(f"   - CommandHistory: {CommandHistory}")
        print(f"   - AIModel: {AIModel}")
        
    except Exception as e:
        print(f"❌ chatbot 모델 import 실패: {e}")
        import traceback
        traceback.print_exc()
        return False
    
    try:
        # 3. ai_backend 서비스 테스트
        print("[4/6] ai_backend 서비스 테스트...")
        from ai_backend.services import AIService, OllamaClient
        print("✅ ai_backend 서비스 import 성공")
        
        # 서비스 클래스 확인
        print(f"   - AIService: {AIService}")
        print(f"   - OllamaClient: {OllamaClient}")
        
    except Exception as e:
        print(f"❌ ai_backend 서비스 import 실패: {e}")
        import traceback
        traceback.print_exc()
        return False
    
    try:
        # 4. xshell_integration 서비스 테스트
        print("[5/6] xshell_integration 서비스 테스트...")
        from xshell_integration.services import XShellService, WindowsShellService
        print("✅ xshell_integration 서비스 import 성공")
        
        # 서비스 클래스 확인
        print(f"   - XShellService: {XShellService}")
        print(f"   - WindowsShellService: {WindowsShellService}")
        
    except Exception as e:
        print(f"❌ xshell_integration 서비스 import 실패: {e}")
        import traceback
        traceback.print_exc()
        return False
    
    try:
        # 5. 뷰 모듈 테스트
        print("[6/6] 뷰 모듈 테스트...")
        from chatbot.views import ChatbotHomeView
        from ai_backend.views import generate_response
        from xshell_integration.views import execute_command
        print("✅ 뷰 모듈 import 성공")
        
        # 뷰 함수/클래스 확인
        print(f"   - ChatbotHomeView: {ChatbotHomeView}")
        print(f"   - generate_response: {generate_response}")
        print(f"   - execute_command: {execute_command}")
        
    except Exception as e:
        print(f"❌ 뷰 모듈 import 실패: {e}")
        import traceback
        traceback.print_exc()
        return False
    
    print()
    print("🎉 모든 Django 모듈 import 테스트 성공!")
    return True


if __name__ == "__main__":
    success = test_imports()
    
    if success:
        print()
        print("✅ Django 프로젝트 구조가 정상입니다!")
        print("다음 단계:")
        print("  1. python manage.py makemigrations")
        print("  2. python manage.py migrate")
        print("  3. python manage.py runserver")
        sys.exit(0)
    else:
        print()
        print("❌ Django 프로젝트에 문제가 있습니다.")
        print("위의 오류 메시지를 확인하고 해결해주세요.")
        sys.exit(1)
