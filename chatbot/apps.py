from django.apps import AppConfig


class ChatbotConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'chatbot'
    verbose_name = 'Sysintec 챗봇'

    def ready(self):
        # XShell 관련 기능 제거됨 - 이제 간단한 웹 챗봇만 사용
        pass
