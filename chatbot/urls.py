from django.urls import path
from . import views

app_name = 'chatbot'

urlpatterns = [
    # 인증 관련
    path('login/', views.login_view, name='login'),
    path('logout/', views.logout_view, name='logout'),
    path('register/', views.register_view, name='register'),
    
    # 메인 페이지
    path('', views.ChatbotHomeView.as_view(), name='home'),
    
    # 채팅 세션 관리
    path('api/session/create/', views.create_chat_session, name='create_session'),
    path('api/session/<str:session_id>/', views.get_chat_history, name='chat_history'),
    path('api/session/<str:session_id>/delete/', views.delete_chat_session, name='delete_session'),
    path('api/sessions/', views.get_chat_sessions, name='chat_sessions'),
    
    # 메시지 처리
    path('api/message/send/', views.send_message, name='send_message'),
    
    # 파일 분석
    path('api/file/analyze/', views.analyze_file, name='analyze_file'),
]
