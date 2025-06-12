from django.urls import path
from . import views

app_name = 'ai_backend'

urlpatterns = [
    path('generate/', views.generate_response, name='generate_response'),
    path('intent/', views.analyze_intent, name='analyze_intent'),
    path('models/', views.get_models, name='get_models'),
    path('health/', views.health_check, name='health_check'),
]
