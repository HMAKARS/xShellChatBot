from django.core.management.base import BaseCommand
from chatbot.models import XShellSession
from xshell_integration.services import XShellService
import getpass


class Command(BaseCommand):
    help = 'XShell 세션 관리'

    def add_arguments(self, parser):
        parser.add_argument(
            '--list',
            action='store_true',
            help='세션 목록 조회',
        )
        parser.add_argument(
            '--add',
            action='store_true',
            help='새 세션 추가',
        )
        parser.add_argument(
            '--test',
            type=str,
            help='세션 연결 테스트',
        )
        parser.add_argument(
            '--delete',
            type=str,
            help='세션 삭제',
        )
        parser.add_argument(
            '--sync',
            action='store_true',
            help='세션 폴더에서 .xsh 파일을 자동 동기화',
        )

    def handle(self, *args, **options):
        if options['list']:
            self.list_sessions()
        elif options['add']:
            self.add_session()
        elif options['test']:
            self.test_session(options['test'])
        elif options['delete']:
            self.delete_session(options['delete'])
        elif options['sync']:
            self.sync_sessions()
        else:
            self.stdout.write(self.style.WARNING('사용법: --list, --add, --test <name>, --delete <name>, --sync'))

    def list_sessions(self):
        """세션 목록 조회"""
        self.stdout.write(self.style.SUCCESS('📋 XShell 세션 목록:'))
        
        sessions = XShellSession.objects.all()
        
        if not sessions:
            self.stdout.write("등록된 세션이 없습니다.")
            return
        
        for session in sessions:
            status = "🟢 연결됨" if session.is_connected else "🔴 연결 안됨"
            self.stdout.write(
                f"  • {session.name} ({session.username}@{session.host}:{session.port}) - {status}"
            )
            self.stdout.write(f"    마지막 사용: {session.last_used}")

    def add_session(self):
        """새 세션 추가"""
        self.stdout.write(self.style.SUCCESS('➕ 새 XShell 세션 추가'))
        
        try:
            name = input("세션 이름: ")
            host = input("호스트 주소: ")
            username = input("사용자명: ")
            port = input("포트 (기본값: 22): ") or "22"
            
            auth_method = input("인증 방법 (1: 비밀번호, 2: 키 파일): ")
            
            password = ""
            private_key_path = ""
            
            if auth_method == "1":
                password = getpass.getpass("비밀번호: ")
            elif auth_method == "2":
                private_key_path = input("키 파일 경로: ")
            else:
                self.stdout.write(self.style.ERROR("잘못된 인증 방법입니다."))
                return
            
            # 세션 생성
            xshell_service = XShellService()
            session = xshell_service.create_xshell_session(
                name=name,
                host=host,
                username=username,
                password=password,
                private_key_path=private_key_path,
                port=int(port)
            )
            
            self.stdout.write(self.style.SUCCESS(f"✅ 세션 '{name}' 생성 완료"))
            
            # 연결 테스트
            if input("연결 테스트를 하시겠습니까? (y/N): ").lower() == 'y':
                self.test_session(name)
                
        except KeyboardInterrupt:
            self.stdout.write("\n작업이 취소되었습니다.")
        except Exception as e:
            self.stdout.write(self.style.ERROR(f"❌ 세션 생성 실패: {e}"))

    def test_session(self, session_name):
        """세션 연결 테스트"""
        self.stdout.write(f"🔍 세션 '{session_name}' 연결 테스트 중...")
        
        try:
            session = XShellSession.objects.get(name=session_name)
        except XShellSession.DoesNotExist:
            self.stdout.write(self.style.ERROR(f"❌ 세션 '{session_name}'을(를) 찾을 수 없습니다."))
            return
        
        xshell_service = XShellService()
        result = xshell_service.test_xshell_session(session_name)
        
        if result['success']:
            self.stdout.write(self.style.SUCCESS(f"✅ {result['message']}"))
        else:
            self.stdout.write(self.style.ERROR(f"❌ {result['message']}"))

    def delete_session(self, session_name):
        """세션 삭제"""
        try:
            session = XShellSession.objects.get(name=session_name)
        except XShellSession.DoesNotExist:
            self.stdout.write(self.style.ERROR(f"❌ 세션 '{session_name}'을(를) 찾을 수 없습니다."))
            return
        
        confirm = input(f"세션 '{session_name}'을(를) 정말 삭제하시겠습니까? (y/N): ")
        
        if confirm.lower() == 'y':
            session.delete()
            self.stdout.write(self.style.SUCCESS(f"✅ 세션 '{session_name}' 삭제 완료"))
        else:
            self.stdout.write("삭제가 취소되었습니다.")

    def sync_sessions(self):
        xshell_service = XShellService()
        count = xshell_service.sync_xshell_sessions()
        self.stdout.write(self.style.SUCCESS(f'🔄 {count}개 세션 동기화 완료'))
