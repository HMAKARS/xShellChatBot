from django.urls import re_path
from . import consumers

websocket_urlpatterns = [
    re_path(r'ws/chat/(?P<session_id>[^/]+)/$', consumers.ChatConsumer.as_asgi()),
    re_path(r'ws/xshell/(?P<session_name>[^/]+)/$', consumers.XShellConsumer.as_asgi()),
]
