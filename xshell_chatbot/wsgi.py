"""
WSGI config for xshell_chatbot project.
"""

import os

from django.core.wsgi import get_wsgi_application

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'xshell_chatbot.settings')

application = get_wsgi_application()
