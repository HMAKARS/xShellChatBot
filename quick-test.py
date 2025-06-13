#!/usr/bin/env python3
"""
빠른 Django import 테스트 (pexpect 수정 포함)
"""

import os
import sys

# Django 설정
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'xshell_chatbot.settings')

try:
    import django
    django.setup()
    
    # 테스트 1: 모델 import
    from chatbot.models import ChatSession, ChatMessage, XShellSession, CommandHistory, AIModel
    print("✅ 모델 import 성공")
    
    # 테스트 2: AI 서비스 import
    from ai_backend.services import AIService
    print("✅ AI 서비스 import 성공")
    
    # 테스트 3: XShell 서비스 import (pexpect 문제 해결됨)
    from xshell_integration.services import XShellService
    print("✅ XShell 서비스 import 성공")
    
    # 테스트 4: 뷰 import
    from chatbot.views import ChatbotHomeView
    print("✅ 뷰 import 성공")
    
    # 추가 테스트: Windows 환경 확인
    xshell_service = XShellService()
    if xshell_service.is_windows:
        print("✅ Windows 환경 감지됨")
    
    print("🎉 모든 테스트 통과! pexpect 수정 완료!")
    
except Exception as e:
    print(f"❌ 오류: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)
