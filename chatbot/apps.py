from django.apps import AppConfig


class ChatbotConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'chatbot'
    verbose_name = 'XShell 챗봇'

    def ready(self):
        from xshell_integration.services import XShellService
        try:
            xshell_service = XShellService()
            count = xshell_service.sync_xshell_sessions()
            print(f'🔄 서버 시작 시 {count}개 XShell 세션 자동 동기화 완료')
        except Exception as e:
            print(f'XShell 세션 자동 동기화 실패: {e}')
