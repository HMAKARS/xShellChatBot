# AI 기능 문제 해결 가이드 🔧

XShell 챗봇의 AI 기능에서 발생할 수 있는 문제들과 해결 방법을 정리했습니다.

## 🚨 일반적인 오류들

### 1. 500 Internal Server Error
```
AI 서비스에 연결할 수 없습니다: 500 Server Error: Internal Server Error
```

**원인:** Ollama 서비스 내부 오류 (모델 손상, 메모리 부족, 설정 문제)

**해결 방법:**
```bash
# 1. 자동 해결 (권장)
fix-ollama-500.bat

# 2. 빠른 확인
check-ollama-quick.bat

# 3. 수동 해결
taskkill /f /im ollama.exe
ollama serve
```

### 2. 404 Not Found Error
```
AI 서비스에 연결할 수 없습니다: 404 Client Error: Not Found
```

**원인:** API 엔드포인트가 없음 (구 버전 Ollama)

**해결 방법:**
- ✅ **자동 해결됨** - 최신 코드에서 자동으로 폴백 처리
- 최신 버전 설치: `install-ollama-simple.bat`

### 3. Connection Refused
```
Failed to establish a new connection: [WinError 10061] 연결 거부
```

**원인:** Ollama 서비스가 실행되지 않음

**해결 방법:**
```bash
# 서비스 시작
ollama serve

# 백그라운드 시작
start /min ollama serve

# 자동 시작 설정
install-ollama-simple.bat
```

### 4. Timeout Error
```
Ollama 응답 시간 초과 (30초)
```

**원인:** 모델이 너무 크거나 메모리 부족

**해결 방법:**
```bash
# 1. 더 작은 모델 사용
ollama pull llama3.2:3b    # 2GB
ollama pull llama3.2:1b    # 1GB

# 2. 큰 모델 제거
ollama rm llama3.1:70b     # 40GB 제거

# 3. 메모리 확보
# 다른 프로그램 종료
```

## 🛠️ 단계별 해결 방법

### 1단계: 빠른 진단
```bash
check-ollama-quick.bat
```
- 서비스 상태 확인
- 모델 설치 상태 확인  
- 기본 API 테스트

### 2단계: 자동 수정
```bash
fix-ollama-500.bat
```
- Ollama 완전 재시작
- 모델 재설치
- 메모리 확인
- 단계별 테스트

### 3단계: 상세 진단
```bash
test-ollama.bat
```
- 모든 API 엔드포인트 테스트
- 모델별 동작 확인
- 로그 분석

### 4단계: 완전 재설치
```bash
# 1. Ollama 제거 (제어판)
# 2. 사용자 데이터 삭제
rmdir /s "%USERPROFILE%\.ollama"

# 3. 재설치
install-ollama-simple.bat
```

## 🎯 오류별 빠른 해결

| 오류 | 명령어 | 설명 |
|------|--------|------|
| 500 오류 | `fix-ollama-500.bat` | 자동 진단 및 수정 |
| 연결 거부 | `ollama serve` | 서비스 수동 시작 |
| 모델 없음 | `ollama pull llama3.2:3b` | 기본 모델 설치 |
| 시간 초과 | `ollama pull llama3.2:1b` | 경량 모델 설치 |
| 전체 점검 | `test-ollama.bat` | 종합 진단 |

## 💡 예방 방법

### 1. 시스템 요구사항 확인
```
최소 요구사항:
• RAM: 8GB 이상 (16GB 권장)
• 디스크: 10GB 이상 여유 공간
• CPU: 듀얼코어 이상
```

### 2. 적절한 모델 선택
```bash
# 메모리별 권장 모델
# 8GB RAM  → llama3.2:3b
# 16GB RAM → llama3.1:8b  
# 32GB RAM → llama3.1:70b
```

### 3. 정기적인 유지보수
```bash
# 주 1회 실행 권장
check-ollama-quick.bat

# 월 1회 실행 권장  
test-ollama.bat

# 문제 발생시
fix-ollama-500.bat
```

## 🔍 로그 확인 방법

### Windows 이벤트 로그
```bash
# PowerShell에서
Get-EventLog -LogName Application -Source "Ollama*" -Newest 10
```

### Ollama 로그 파일
```bash
# 로그 파일 위치
echo %TEMP%\ollama.log

# 로그 내용 확인
type "%TEMP%\ollama.log"
```

### Django 로그
```bash
# 프로젝트 로그 확인
type logs\xshell_chatbot.log
```

## 🚀 성능 최적화

### 1. GPU 가속 (선택사항)
```bash
# NVIDIA GPU 확인
nvidia-smi

# CUDA 설치 확인
nvcc --version
```

### 2. 메모리 최적화
```bash
# 환경변수 설정 (PowerShell)
$env:OLLAMA_MAX_LOADED_MODELS = "1"
$env:OLLAMA_FLASH_ATTENTION = "1"
```

### 3. 네트워크 최적화
```bash
# 로컬 전용 설정
$env:OLLAMA_HOST = "127.0.0.1:11434"
```

## 📞 추가 도움

### 공식 리소스
- **Ollama 공식 문서**: https://ollama.com/docs
- **GitHub Issues**: https://github.com/ollama/ollama/issues
- **Discord 커뮤니티**: https://discord.gg/ollama

### 프로젝트 도구
- **빠른 확인**: `check-ollama-quick.bat`
- **자동 수정**: `fix-ollama-500.bat`  
- **상세 진단**: `test-ollama.bat`
- **AI 연결 테스트**: `test-ai.bat`
- **재설치**: `install-ollama-simple.bat`

### 문제 신고시 포함할 정보
1. **오류 메시지** (정확한 전문)
2. **시스템 정보** (Windows 버전, RAM 크기)
3. **Ollama 버전** (`ollama --version`)
4. **설치된 모델** (`ollama list`)
5. **테스트 결과** (`test-ollama.bat` 출력)

---

💡 **팁**: 대부분의 문제는 `fix-ollama-500.bat` 한 번 실행으로 해결됩니다!
