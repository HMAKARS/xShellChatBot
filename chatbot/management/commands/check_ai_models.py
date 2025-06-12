from django.core.management.base import BaseCommand
from django.conf import settings
import requests
import json


class Command(BaseCommand):
    help = 'Ollama AI 모델 상태 확인'

    def add_arguments(self, parser):
        parser.add_argument(
            '--install',
            action='store_true',
            help='권장 모델 자동 설치',
        )
        parser.add_argument(
            '--model',
            type=str,
            help='특정 모델 설치',
        )

    def handle(self, *args, **options):
        self.stdout.write(self.style.SUCCESS('🤖 AI 모델 상태 확인 중...'))
        
        # Ollama 연결 확인
        try:
            response = requests.get(f"{settings.OLLAMA_BASE_URL}/api/tags", timeout=10)
            response.raise_for_status()
            data = response.json()
        except Exception as e:
            self.stdout.write(self.style.ERROR(f"❌ Ollama 연결 실패: {e}"))
            self.stdout.write("Ollama가 실행 중인지 확인하세요: http://localhost:11434")
            return

        models = data.get('models', [])
        self.stdout.write(f"✅ Ollama 연결 성공 ({len(models)}개 모델 사용 가능)")
        
        # 설치된 모델 목록
        if models:
            self.stdout.write("\n📋 설치된 모델:")
            for model in models:
                name = model['name']
                size = model.get('size', 0)
                size_gb = size / (1024**3) if size else 0
                modified = model.get('modified', 'Unknown')
                
                self.stdout.write(f"  • {name} ({size_gb:.1f}GB) - {modified}")
        
        # 권장 모델 확인
        recommended_models = [
            settings.DEFAULT_AI_MODEL,
            settings.CODE_AI_MODEL
        ]
        
        installed_models = [model['name'] for model in models]
        missing_models = [model for model in recommended_models if model not in installed_models]
        
        if missing_models:
            self.stdout.write(f"\n⚠️  누락된 권장 모델: {', '.join(missing_models)}")
            
            if options['install']:
                self.install_models(missing_models)
            else:
                self.stdout.write("--install 옵션으로 자동 설치할 수 있습니다.")
        else:
            self.stdout.write("\n✅ 모든 권장 모델이 설치되어 있습니다.")
        
        # 특정 모델 설치
        if options['model']:
            self.install_models([options['model']])

    def install_models(self, models):
        """모델 설치"""
        import subprocess
        
        for model in models:
            self.stdout.write(f"\n📥 {model} 설치 중...")
            try:
                # ollama pull 명령어 실행
                result = subprocess.run(
                    ['ollama', 'pull', model],
                    capture_output=True,
                    text=True,
                    timeout=300  # 5분 타임아웃
                )
                
                if result.returncode == 0:
                    self.stdout.write(self.style.SUCCESS(f"✅ {model} 설치 완료"))
                else:
                    self.stdout.write(self.style.ERROR(f"❌ {model} 설치 실패: {result.stderr}"))
                    
            except subprocess.TimeoutExpired:
                self.stdout.write(self.style.ERROR(f"❌ {model} 설치 시간 초과"))
            except FileNotFoundError:
                self.stdout.write(self.style.ERROR("❌ ollama 명령어를 찾을 수 없습니다."))
                self.stdout.write("Ollama를 설치하세요: https://ollama.ai")
                break
            except Exception as e:
                self.stdout.write(self.style.ERROR(f"❌ {model} 설치 중 오류: {e}"))
