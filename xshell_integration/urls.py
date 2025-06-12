from django.urls import path
from . import views

app_name = 'xshell_integration'

urlpatterns = [
    # 명령어 실행
    path('execute/', views.execute_command, name='execute_command'),
    path('execute/stream/', views.execute_command_stream, name='execute_command_stream'),
    
    # 세션 관리
    path('sessions/', views.list_sessions, name='list_sessions'),
    path('sessions/create/', views.create_session, name='create_session'),
    path('sessions/<str:session_name>/test/', views.test_session, name='test_session'),
    path('sessions/<str:session_name>/delete/', views.delete_session, name='delete_session'),
    
    # 명령어 히스토리
    path('history/<str:session_name>/', views.get_command_history, name='command_history'),
    
    # 시스템 정보
    path('health/', views.health_check, name='health_check'),
]
