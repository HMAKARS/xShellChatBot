import google.generativeai as genai
import os
from django.conf import settings
import logging

logger = logging.getLogger(__name__)

class GeminiClient:
    def __init__(self):
        """Initialize Gemini API client"""
        try:
            api_key = os.getenv('GEMINI_API_KEY')
            if not api_key:
                raise ValueError("GEMINI_API_KEY not found in environment variables")
            
            genai.configure(api_key=api_key)
            self.model = genai.GenerativeModel('gemini-2.0-flash-001')
            logger.info("Gemini client initialized successfully")
        except Exception as e:
            logger.error(f"Failed to initialize Gemini client: {e}")
            raise

    def generate_response(self, message, context=None):
        """Generate response using Gemini API"""
        try:
            # Build conversation context
            conversation_text = ""
            if context:
                for ctx in context[-5:]:  # Only keep last 5 messages for context
                    conversation_text += f"사용자: {ctx.get('user', '')}\n"
                    conversation_text += f"어시스턴트: {ctx.get('assistant', '')}\n"
            
            conversation_text += f"사용자: {message}\n어시스턴트: "
            
            # Generate response
            response = self.model.generate_content(conversation_text)
            
            if response.text:
                return response.text.strip()
            else:
                return "죄송합니다. 응답을 생성할 수 없습니다."
                
        except Exception as e:
            logger.error(f"Error generating response: {e}")
            return f"오류가 발생했습니다: {str(e)}"

    def handle_chat(self, message, session_context=None):
        """Handle chat message and return response"""
        try:
            response = self.generate_response(message, session_context)
            return {
                'success': True,
                'response': response,
                'error': None
            }
        except Exception as e:
            logger.error(f"Error in handle_chat: {e}")
            return {
                'success': False,
                'response': "죄송합니다. 현재 서비스에 문제가 있습니다.",
                'error': str(e)
            }

# Backward compatibility alias
AIService = GeminiClient
