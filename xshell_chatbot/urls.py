"""
URL configuration for xshell_chatbot project.
"""
from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', include('chatbot.urls')),
    path('api/xshell/', include('xshell_integration.urls')),
    path('api/ai/', include('ai_backend.urls')),
]

# Static and Media files serving in development
if settings.DEBUG:
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
