#!/usr/bin/env python3
"""
pexpect 수정 후 테스트
"""

import os
import sys

# Django 설정
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'xshell_chatbot.settings')

try:
    import django
    django.setup()
    
    print("🔍 pexpect 수정 후 테스트 시작...")
    
    # 테스트 1: 기본 Django 설정
    print("[1/4] Django 설정 확인...")
    from django.conf import settings
    print("✅ Django 설정 로드 성공")
    
    # 테스트 2: 모델 import
    print("[2/4] 모델 import 확인...")
    from chatbot.models import ChatSession, ChatMessage, XShellSession, CommandHistory, AIModel
    print("✅ 모든 모델 import 성공")
    
    # 테스트 3: AI 서비스 import
    print("[3/4] AI 서비스 import 확인...")
    from ai_backend.services import AIService
    print("✅ AI 서비스 import 성공")
    
    # 테스트 4: XShell 서비스 import (pexpect 수정됨)
    print("[4/4] XShell 서비스 import 확인...")
    from xshell_integration.services import XShellService, WindowsShellService
    print("✅ XShell 서비스 import 성공")
    
    # 추가 테스트: 서비스 인스턴스 생성
    print("\n🧪 서비스 인스턴스 생성 테스트...")
    xshell_service = XShellService()
    print(f"   XShellService: {xshell_service}")
    print(f"   Windows 환경: {xshell_service.is_windows}")
    
    if xshell_service.is_windows:
        windows_shell = WindowsShellService()
        print(f"   WindowsShellService: {windows_shell}")
    
    print("\n🎉 모든 테스트 통과!")
    print("✅ pexpect 수정이 성공적으로 완료되었습니다!")
    
except Exception as e:
    print(f"❌ 오류: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)
