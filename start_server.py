#!/usr/bin/env python
"""
XShell 챗봇 서버 시작 스크립트
"""

import os
import sys
import subprocess
import threading
import time
import requests
from pathlib import Path

def check_requirements():
    """필요 사항 확인"""
    print("🔍 시스템 요구사항 확인 중...")
    
    # Python 버전 확인
    if sys.version_info < (3.8, 0):
        print("❌ Python 3.8 이상이 필요합니다.")
        return False
    
    # Django 확인
    try:
        import django
        print(f"✅ Django {django.get_version()} 설치됨")
    except ImportError:
        print("❌ Django가 설치되지 않았습니다. pip install -r requirements.txt를 실행하세요.")
        return False
    
    # Redis 연결 확인
    try:
        import redis
        r = redis.Redis(host='localhost', port=6379, decode_responses=True)
        r.ping()
        print("✅ Redis 연결 성공")
    except Exception as e:
        print(f"⚠️  Redis 연결 실패: {e}")
        print("   Redis를 설치하고 실행해주세요: https://redis.io/download")
    
    # Ollama 연결 확인
    try:
        response = requests.get('http://localhost:11434/api/tags', timeout=5)
        if response.status_code == 200:
            models = response.json().get('models', [])
            print(f"✅ Ollama 연결 성공 ({len(models)}개 모델 사용 가능)")
            
            # 권장 모델 확인
            model_names = [model['name'] for model in models]
            if 'llama3.1:8b' not in model_names:
                print("⚠️  권장 모델 llama3.1:8b가 없습니다.")
                print("   다음 명령어로 설치하세요: ollama pull llama3.1:8b")
            if 'codellama:7b' not in model_names:
                print("⚠️  권장 모델 codellama:7b가 없습니다.")
                print("   다음 명령어로 설치하세요: ollama pull codellama:7b")
        else:
            print("⚠️  Ollama API 응답 오류")
    except Exception as e:
        print(f"⚠️  Ollama 연결 실패: {e}")
        print("   Ollama를 설치하고 실행해주세요: https://ollama.ai")
    
    return True

def setup_database():
    """데이터베이스 설정"""
    print("\n🗄️  데이터베이스 설정 중...")
    
    # 마이그레이션 생성
    print("마이그레이션 파일 생성 중...")
    subprocess.run([sys.executable, 'manage.py', 'makemigrations'], check=True)
    
    # 마이그레이션 적용
    print("마이그레이션 적용 중...")
    subprocess.run([sys.executable, 'manage.py', 'migrate'], check=True)
    
    # 슈퍼유저 생성 (선택적)
    if input("관리자 계정을 생성하시겠습니까? (y/N): ").lower() == 'y':
        subprocess.run([sys.executable, 'manage.py', 'createsuperuser'])
    
    print("✅ 데이터베이스 설정 완료")

def collect_static():
    """정적 파일 수집"""
    print("\n📁 정적 파일 수집 중...")
    subprocess.run([sys.executable, 'manage.py', 'collectstatic', '--noinput'], check=True)
    print("✅ 정적 파일 수집 완료")

def start_development_server():
    """개발 서버 시작"""
    print("\n🚀 개발 서버 시작 중...")
    print("서버 주소: http://localhost:8000")
    print("관리자 페이지: http://localhost:8000/admin")
    print("종료하려면 Ctrl+C를 누르세요.")
    
    try:
        subprocess.run([sys.executable, 'manage.py', 'runserver', '0.0.0.0:8000'])
    except KeyboardInterrupt:
        print("\n서버가 종료되었습니다.")

def start_production_server():
    """프로덕션 서버 시작 (Daphne 사용)"""
    print("\n🚀 프로덕션 서버 시작 중...")
    
    try:
        import daphne
    except ImportError:
        print("❌ Daphne가 설치되지 않았습니다.")
        print("다음 명령어로 설치하세요: pip install daphne")
        return
    
    print("서버 주소: http://localhost:8000")
    print("종료하려면 Ctrl+C를 누르세요.")
    
    try:
        subprocess.run([
            'daphne', 
            '-b', '0.0.0.0',
            '-p', '8000',
            'xshell_chatbot.asgi:application'
        ])
    except KeyboardInterrupt:
        print("\n서버가 종료되었습니다.")

def main():
    """메인 함수"""
    print("🤖 XShell AI 챗봇 서버 시작 스크립트")
    print("=" * 50)
    
    # 필요 사항 확인
    if not check_requirements():
        sys.exit(1)
    
    # .env 파일 확인
    if not Path('.env').exists():
        print("\n⚠️  .env 파일이 없습니다.")
        if input(".env.example을 복사하시겠습니까? (y/N): ").lower() == 'y':
            import shutil
            shutil.copy('.env.example', '.env')
            print("✅ .env 파일이 생성되었습니다. 필요에 따라 수정해주세요.")
    
    # 데이터베이스 설정
    if not Path('db.sqlite3').exists() or input("\n데이터베이스를 재설정하시겠습니까? (y/N): ").lower() == 'y':
        setup_database()
    
    # 정적 파일 수집
    if input("\n정적 파일을 수집하시겠습니까? (Y/n): ").lower() != 'n':
        collect_static()
    
    # 서버 시작 방식 선택
    print("\n서버 시작 방식을 선택하세요:")
    print("1. 개발 서버 (Django runserver)")
    print("2. 프로덕션 서버 (Daphne)")
    
    choice = input("선택 (1-2, 기본값: 1): ").strip() or "1"
    
    if choice == "2":
        start_production_server()
    else:
        start_development_server()

if __name__ == "__main__":
    main()
