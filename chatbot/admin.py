from django.contrib import admin
from django.utils.html import format_html
from django.urls import reverse
from django.utils.safestring import mark_safe
from .models import ChatSession, ChatMessage, XShellSession, CommandHistory, AIModel


@admin.register(ChatSession)
class ChatSessionAdmin(admin.ModelAdmin):
    list_display = ['session_id', 'title', 'user', 'message_count', 'is_active', 'created_at', 'updated_at']
    list_filter = ['is_active', 'created_at', 'user']
    search_fields = ['session_id', 'title', 'user__username']
    readonly_fields = ['session_id', 'created_at', 'updated_at', 'message_count']
    date_hierarchy = 'created_at'
    
    def message_count(self, obj):
        return obj.messages.count()
    message_count.short_description = '메시지 수'
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('user').prefetch_related('messages')


@admin.register(ChatMessage)
class ChatMessageAdmin(admin.ModelAdmin):
    list_display = ['session_link', 'message_type', 'content_preview', 'timestamp']
    list_filter = ['message_type', 'timestamp', 'session__user']
    search_fields = ['content', 'session__title', 'session__session_id']
    readonly_fields = ['timestamp', 'content_preview', 'metadata_display']
    date_hierarchy = 'timestamp'
    raw_id_fields = ['session']
    
    def session_link(self, obj):
        url = reverse('admin:chatbot_chatsession_change', args=[obj.session.pk])
        return format_html('<a href="{}">{}</a>', url, obj.session.title)
    session_link.short_description = '세션'
    
    def content_preview(self, obj):
        return obj.content[:100] + '...' if len(obj.content) > 100 else obj.content
    content_preview.short_description = '내용 미리보기'
    
    def metadata_display(self, obj):
        if obj.metadata:
            return format_html('<pre>{}</pre>', str(obj.metadata))
        return '-'
    metadata_display.short_description = '메타데이터'
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('session')


@admin.register(XShellSession)
class XShellSessionAdmin(admin.ModelAdmin):
    list_display = ['name', 'host', 'username', 'port', 'connection_status', 'last_used', 'created_at']
    list_filter = ['is_connected', 'last_used', 'created_at']
    search_fields = ['name', 'host', 'username']
    readonly_fields = ['last_used', 'created_at', 'connection_status', 'command_count']
    
    fieldsets = (
        ('기본 정보', {
            'fields': ('name', 'host', 'port', 'username')
        }),
        ('인증 정보', {
            'fields': ('password_encrypted', 'private_key_path'),
            'classes': ('collapse',),
            'description': '보안상 비밀번호는 암호화되어 저장됩니다.'
        }),
        ('연결 상태', {
            'fields': ('is_connected', 'connection_status', 'last_used', 'created_at'),
            'classes': ('collapse',)
        }),
        ('통계', {
            'fields': ('command_count',),
            'classes': ('collapse',)
        })
    )
    
    def connection_status(self, obj):
        if obj.is_connected:
            return format_html(
                '<span style="color: green;">🟢 연결됨</span>'
            )
        else:
            return format_html(
                '<span style="color: red;">🔴 연결 안됨</span>'
            )
    connection_status.short_description = '연결 상태'
    
    def command_count(self, obj):
        return obj.commandhistory_set.count()
    command_count.short_description = '실행된 명령어 수'
    
    actions = ['test_connection', 'disconnect_sessions']
    
    def test_connection(self, request, queryset):
        from xshell_integration.services import XShellService
        
        xshell_service = XShellService()
        success_count = 0
        
        for session in queryset:
            result = xshell_service.test_xshell_session(session.name)
            if result['success']:
                success_count += 1
        
        self.message_user(
            request,
            f'{success_count}/{queryset.count()}개 세션 연결 성공'
        )
    test_connection.short_description = '선택된 세션 연결 테스트'
    
    def disconnect_sessions(self, request, queryset):
        updated = queryset.update(is_connected=False)
        self.message_user(request, f'{updated}개 세션 연결 해제됨')
    disconnect_sessions.short_description = '선택된 세션 연결 해제'


@admin.register(CommandHistory)
class CommandHistoryAdmin(admin.ModelAdmin):
    list_display = ['command_preview', 'xshell_session', 'exit_code_display', 'execution_time', 'timestamp']
    list_filter = ['exit_code', 'timestamp', 'xshell_session']
    search_fields = ['command', 'result', 'xshell_session__name']
    readonly_fields = ['timestamp', 'result_preview', 'execution_time_display']
    date_hierarchy = 'timestamp'
    raw_id_fields = ['xshell_session', 'chat_session']
    
    def command_preview(self, obj):
        return obj.command[:50] + '...' if len(obj.command) > 50 else obj.command
    command_preview.short_description = '명령어'
    
    def result_preview(self, obj):
        if obj.result:
            return format_html('<pre style="max-height: 200px; overflow-y: auto;">{}</pre>', 
                             obj.result[:1000] + '...' if len(obj.result) > 1000 else obj.result)
        return '-'
    result_preview.short_description = '실행 결과'
    
    def exit_code_display(self, obj):
        if obj.exit_code == 0:
            return format_html('<span style="color: green;">✅ 성공 (0)</span>')
        elif obj.exit_code is None:
            return format_html('<span style="color: gray;">⏳ 실행중</span>')
        else:
            return format_html('<span style="color: red;">❌ 실패 ({})</span>', obj.exit_code)
    exit_code_display.short_description = '실행 결과'
    
    def execution_time_display(self, obj):
        if obj.execution_time:
            return f'{obj.execution_time:.2f}초'
        return '-'
    execution_time_display.short_description = '실행 시간'
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('xshell_session', 'chat_session')


@admin.register(AIModel)
class AIModelAdmin(admin.ModelAdmin):
    list_display = ['name', 'model_id', 'model_type', 'is_active', 'usage_count']
    list_filter = ['model_type', 'is_active']
    search_fields = ['name', 'model_id', 'description']
    readonly_fields = ['usage_count']
    
    fieldsets = (
        ('기본 정보', {
            'fields': ('name', 'model_id', 'description', 'model_type', 'is_active')
        }),
        ('매개변수', {
            'fields': ('parameters',),
            'classes': ('collapse',),
            'description': 'JSON 형식으로 모델 매개변수를 설정합니다.'
        }),
        ('통계', {
            'fields': ('usage_count',),
            'classes': ('collapse',)
        })
    )
    
    def usage_count(self, obj):
        # 실제로는 사용 통계를 추적하는 별도 모델이 필요
        return "구현 예정"
    usage_count.short_description = '사용 횟수'
    
    actions = ['activate_models', 'deactivate_models']
    
    def activate_models(self, request, queryset):
        updated = queryset.update(is_active=True)
        self.message_user(request, f'{updated}개 모델이 활성화되었습니다.')
    activate_models.short_description = '선택된 모델 활성화'
    
    def deactivate_models(self, request, queryset):
        updated = queryset.update(is_active=False)
        self.message_user(request, f'{updated}개 모델이 비활성화되었습니다.')
    deactivate_models.short_description = '선택된 모델 비활성화'


# Admin 사이트 커스터마이징
admin.site.site_header = "XShell AI 챗봇 관리"
admin.site.site_title = "XShell AI 챗봇"
admin.site.index_title = "관리 대시보드"
