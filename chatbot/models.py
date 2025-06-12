from django.db import models
from django.contrib.auth.models import User
from django.utils import timezone


class ChatSession(models.Model):
    """채팅 세션 모델"""
    user = models.ForeignKey(User, on_delete=models.CASCADE, null=True, blank=True)
    session_id = models.CharField(max_length=100, unique=True)
    title = models.CharField(max_length=200, default="새로운 채팅")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    is_active = models.BooleanField(default=True)
    
    class Meta:
        ordering = ['-updated_at']
        verbose_name = '채팅 세션'
        verbose_name_plural = '채팅 세션들'
    
    def __str__(self):
        return f"{self.title} ({self.session_id})"


class ChatMessage(models.Model):
    """채팅 메시지 모델"""
    MESSAGE_TYPES = [
        ('user', '사용자'),
        ('ai', 'AI'),
        ('system', '시스템'),
        ('command', '명령어'),
        ('result', '실행 결과'),
    ]
    
    session = models.ForeignKey(ChatSession, on_delete=models.CASCADE, related_name='messages')
    message_type = models.CharField(max_length=10, choices=MESSAGE_TYPES)
    content = models.TextField()
    timestamp = models.DateTimeField(auto_now_add=True)
    metadata = models.JSONField(default=dict, blank=True)  # 추가 데이터 저장용
    
    class Meta:
        ordering = ['timestamp']
        verbose_name = '채팅 메시지'
        verbose_name_plural = '채팅 메시지들'
    
    def __str__(self):
        return f"{self.get_message_type_display()}: {self.content[:50]}"


class XShellSession(models.Model):
    """XShell 세션 관리 모델"""
    name = models.CharField(max_length=100)
    host = models.CharField(max_length=255)
    port = models.IntegerField(default=22)
    username = models.CharField(max_length=100)
    password_encrypted = models.TextField(blank=True)  # 암호화된 비밀번호
    private_key_path = models.CharField(max_length=500, blank=True)
    session_file_path = models.CharField(max_length=500, blank=True)
    is_connected = models.BooleanField(default=False)
    last_used = models.DateTimeField(auto_now=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-last_used']
        verbose_name = 'XShell 세션'
        verbose_name_plural = 'XShell 세션들'
    
    def __str__(self):
        return f"{self.name} ({self.username}@{self.host})"


class CommandHistory(models.Model):
    """명령어 실행 히스토리"""
    xshell_session = models.ForeignKey(XShellSession, on_delete=models.CASCADE)
    chat_session = models.ForeignKey(ChatSession, on_delete=models.CASCADE, null=True, blank=True)
    command = models.TextField()
    result = models.TextField(blank=True)
    exit_code = models.IntegerField(null=True, blank=True)
    execution_time = models.FloatField(null=True, blank=True)  # 실행 시간 (초)
    timestamp = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-timestamp']
        verbose_name = '명령어 히스토리'
        verbose_name_plural = '명령어 히스토리들'
    
    def __str__(self):
        return f"{self.command[:50]} - {self.timestamp}"


class AIModel(models.Model):
    """AI 모델 설정"""
    name = models.CharField(max_length=100)
    model_id = models.CharField(max_length=200)  # ollama 모델 ID
    description = models.TextField(blank=True)
    is_active = models.BooleanField(default=True)
    model_type = models.CharField(max_length=50, choices=[
        ('general', '일반 대화'),
        ('code', '코드 분석'),
        ('system', '시스템 관리'),
    ])
    parameters = models.JSONField(default=dict, blank=True)  # 모델 파라미터
    
    class Meta:
        verbose_name = 'AI 모델'
        verbose_name_plural = 'AI 모델들'
    
    def __str__(self):
        return f"{self.name} ({self.model_id})"
