#!/usr/bin/env python
"""
XShell AI 챗봇 초기 설정 스크립트
"""

import os
import sys
import subprocess
import shutil
from pathlib import Path


def run_command(command, description):
    """명령어 실행"""
    print(f"🔧 {description}...")
    try:
        subprocess.run(command, shell=True, check=True)
        print(f"✅ {description} 완료")
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ {description} 실패: {e}")
        return False


def check_python_version():
    """Python 버전 확인"""
    if sys.version_info < (3, 8):
        print("❌ Python 3.8 이상이 필요합니다.")
        return False
    print(f"✅ Python {sys.version} 확인됨")
    return True


def setup_environment():
    """환경 설정"""
    print("🌟 XShell AI 챗봇 초기 설정을 시작합니다.")
    
    # Python 버전 확인
    if not check_python_version():
        return False
    
    # .env 파일 생성
    if not Path('.env').exists():
        if Path('.env.example').exists():
            shutil.copy('.env.example', '.env')
            print("✅ .env 파일이 생성되었습니다.")
        else:
            print("⚠️ .env.example 파일이 없습니다.")
    
    # 가상환경 생성 (존재하지 않는 경우)
    if not Path('.venv').exists():
        if not run_command('python -m venv .venv', '가상환경 생성'):
            return False
    
    # 가상환경 활성화 명령어 안내
    if os.name == 'nt':  # Windows
        activate_cmd = '.venv\\Scripts\\activate'
    else:  # Unix/Linux/MacOS
        activate_cmd = 'source .venv/bin/activate'
    
    print(f"\n📋 다음 명령어로 가상환경을 활성화하세요:")
    print(f"   {activate_cmd}")
    
    # 의존성 설치
    print("\n📦 의존성 설치:")
    print("   pip install -r requirements.txt")
    
    # 데이터베이스 설정
    print("\n🗄️ 데이터베이스 설정:")
    print("   python manage.py makemigrations")
    print("   python manage.py migrate")
    print("   python manage.py createsuperuser")
    
    # 서버 실행
    print("\n🚀 서버 실행:")
    print("   python start_server.py")
    print("   또는")
    print("   python manage.py runserver")
    
    # Docker 사용법
    print("\n🐳 Docker 사용 (선택사항):")
    print("   chmod +x deploy/deploy.sh")
    print("   ./deploy/deploy.sh")
    
    print("\n🎉 설정 완료! 즐거운 개발 되세요!")
    return True


def main():
    """메인 함수"""
    try:
        setup_environment()
    except KeyboardInterrupt:
        print("\n\n❌ 설정이 중단되었습니다.")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ 설정 중 오류 발생: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
