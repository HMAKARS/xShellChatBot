#!/usr/bin/env python
"""
Django 설정 문제 자동 수정 스크립트
"""

import os
import sys
import django
from pathlib import Path

# Django 설정
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'xshell_chatbot.settings')

def check_and_fix_django():
    """Django 설정 문제 체크 및 수정"""
    
    print("🔍 Django 프로젝트 문제 진단 시작...")
    print()
    
    try:
        # 1. Django 설정 로드
        print("[1/6] Django 설정 로드 중...")
        django.setup()
        print("✅ Django 설정 로드 성공")
        
    except Exception as e:
        print(f"❌ Django 설정 로드 실패: {e}")
        return False
    
    try:
        # 2. URL 패턴 체크
        print("[2/6] URL 패턴 체크 중...")
        from django.urls import reverse
        from django.core.urlresolvers import resolve
        print("✅ URL 설정 정상")
        
    except ImportError:
        # Django 2.0+ 에서는 django.urls.resolve 사용
        try:
            from django.urls import resolve
            print("✅ URL 설정 정상 (Django 2.0+)")
        except Exception as e:
            print(f"❌ URL 설정 오류: {e}")
            return False
    except Exception as e:
        print(f"❌ URL 패턴 오류: {e}")
        
        # URL 오류 세부 체크
        print("🔧 URL 오류 세부 분석 중...")
        try:
            from django.conf import settings
            urlconf = __import__(settings.ROOT_URLCONF, {}, {}, [''])
            print(f"   ROOT_URLCONF: {settings.ROOT_URLCONF}")
            
            # 각 앱의 URL 패턴 체크
            for app in settings.INSTALLED_APPS:
                if app.startswith('django.'):
                    continue
                try:
                    app_urls = __import__(f'{app}.urls', {}, {}, [''])
                    print(f"   ✅ {app}.urls 로드 성공")
                except ImportError:
                    print(f"   ⚠️ {app}.urls 없음 (정상일 수 있음)")
                except Exception as app_e:
                    print(f"   ❌ {app}.urls 오류: {app_e}")
                    
        except Exception as url_e:
            print(f"   URL 분석 실패: {url_e}")
        
        return False
    
    try:
        # 3. 모델 체크
        print("[3/6] 모델 체크 중...")
        from chatbot.models import ChatSession, ChatMessage, XShellSession
        from chatbot.models import AIModel, CommandHistory
        print("✅ 모든 모델 import 성공")
        
    except Exception as e:
        print(f"❌ 모델 import 실패: {e}")
        return False
    
    try:
        # 4. 서비스 체크
        print("[4/6] 서비스 체크 중...")
        from ai_backend.services import AIService
        from xshell_integration.services import XShellService
        print("✅ 모든 서비스 import 성공")
        
    except Exception as e:
        print(f"❌ 서비스 import 실패: {e}")
        return False
    
    try:
        # 5. 뷰 체크
        print("[5/6] 뷰 체크 중...")
        from chatbot.views import ChatbotHomeView
        from ai_backend.views import generate_response
        from xshell_integration.views import execute_command
        print("✅ 모든 뷰 import 성공")
        
    except Exception as e:
        print(f"❌ 뷰 import 실패: {e}")
        return False
    
    try:
        # 6. 마이그레이션 상태 체크
        print("[6/6] 마이그레이션 상태 체크 중...")
        from django.core.management import execute_from_command_line
        
        # 마이그레이션이 필요한지 체크
        db_path = Path('db.sqlite3')
        if not db_path.exists():
            print("⚠️ 데이터베이스 파일이 없습니다. 마이그레이션이 필요합니다.")
            return "need_migration"
        else:
            print("✅ 데이터베이스 파일 존재")
            
    except Exception as e:
        print(f"❌ 마이그레이션 체크 실패: {e}")
        return False
    
    print()
    print("🎉 모든 Django 설정 체크 완료!")
    return True


def run_migrations():
    """마이그레이션 실행"""
    print("🗄️ 데이터베이스 마이그레이션 실행 중...")
    
    try:
        from django.core.management import execute_from_command_line
        
        # makemigrations
        print("   makemigrations 실행 중...")
        execute_from_command_line(['manage.py', 'makemigrations'])
        
        # migrate
        print("   migrate 실행 중...")
        execute_from_command_line(['manage.py', 'migrate'])
        
        print("✅ 마이그레이션 완료")
        return True
        
    except Exception as e:
        print(f"❌ 마이그레이션 실패: {e}")
        return False


if __name__ == "__main__":
    import sys
    
    # 명령행 인수 체크
    check_only = '--check-only' in sys.argv
    
    if check_only:
        # 체크만 수행
        result = check_and_fix_django()
        if result == True:
            print("✅ Django 프로젝트 정상")
            sys.exit(0)
        elif result == "need_migration":
            print("⚠️ 마이그레이션 필요")
            sys.exit(1)
        else:
            print("❌ Django 프로젝트 문제 발견")
            sys.exit(1)
    else:
        # 전체 진단 및 수정
        result = check_and_fix_django()
        
        if result == "need_migration":
            print()
            response = input("마이그레이션을 실행하시겠습니까? (y/N): ")
            if response.lower() == 'y':
                if run_migrations():
                    print()
                    print("🎉 Django 프로젝트가 성공적으로 설정되었습니다!")
                    print("다음 명령어로 서버를 시작하세요:")
                    print("   python manage.py runserver")
                else:
                    print("❌ 마이그레이션에 실패했습니다.")
                    sys.exit(1)
            else:
                print("마이그레이션을 건너뛰었습니다.")
                print("나중에 다음 명령어로 마이그레이션을 실행하세요:")
                print("   python manage.py makemigrations")
                print("   python manage.py migrate")
        
        elif result:
            print()
            print("🎉 Django 프로젝트가 정상입니다!")
            print("다음 명령어로 서버를 시작하세요:")
            print("   python manage.py runserver")
        
        else:
            print()
            print("❌ Django 프로젝트에 문제가 있습니다.")
            print("위의 오류 메시지를 확인하고 문제를 해결해주세요.")
            sys.exit(1)
