from django.urls import path
from . import views

app_name = 'chatbot'

urlpatterns = [
    # 메인 페이지
    path('', views.ChatbotHomeView.as_view(), name='home'),
    
    # 채팅 세션 관리
    path('api/session/create/', views.create_chat_session, name='create_session'),
    path('api/session/<str:session_id>/', views.get_chat_history, name='chat_history'),
    path('api/session/<str:session_id>/delete/', views.delete_chat_session, name='delete_session'),
    
    # 메시지 처리
    path('api/message/send/', views.send_message, name='send_message'),
    
    # XShell 관련
    path('api/command/execute/', views.execute_command, name='execute_command'),
    path('api/xshell/sessions/', views.get_xshell_sessions, name='xshell_sessions'),
]
