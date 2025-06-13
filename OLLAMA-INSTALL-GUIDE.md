# Ollama 설치 가이드 🤖

XShell AI 챗봇의 AI 기능을 사용하려면 Ollama가 필요합니다. 여러 방법으로 설치할 수 있습니다.

## 🚀 빠른 설치 (추천)

### 방법 1: 자동 설치 스크립트
```bash
# 간단한 설치
install-ollama-simple.bat

# 고급 설치 (여러 방법 시도)
install-ollama.bat
```

### 방법 2: 수동 다운로드
1. https://ollama.com/download 접속
2. "Download for Windows" 클릭
3. `OllamaSetup.exe` 다운로드 및 실행
4. 설치 완료 후 시스템 재시작

## 📦 패키지 매니저로 설치

### Winget (Windows 11/10)
```bash
winget install ollama
```

### Chocolatey
```bash
# Chocolatey 설치 (관리자 권한 PowerShell)
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Ollama 설치
choco install ollama
```

### Scoop
```bash
# Scoop 설치
iwr -useb get.scoop.sh | iex

# Ollama 설치
scoop install ollama
```

## 🔧 설치 확인

### 1. 설치 확인
```bash
ollama --version
```

### 2. 서비스 시작
```bash
# 서비스 시작
ollama serve

# 또는 백그라운드 실행
start /min ollama serve
```

### 3. 서비스 상태 확인
```bash
# 브라우저에서 http://localhost:11434 접속
# 또는 명령어로 확인
curl http://localhost:11434
```

## 🤖 AI 모델 설치

### 추천 모델

#### 경량 모델 (빠름, 적은 메모리)
```bash
# 2GB, 빠른 응답
ollama pull llama3.2:3b

# 1GB, 매우 빠름 (기본적인 대화만)
ollama pull llama3.2:1b
```

#### 고성능 모델 (느림, 높은 품질)
```bash
# 4.7GB, 균형잡힌 성능 (기본 추천)
ollama pull llama3.1:8b

# 26GB, 최고 성능 (고성능 PC만)
ollama pull llama3.1:70b
```

#### 코드 특화 모델
```bash
# 코드 분석 및 생성에 특화
ollama pull codellama:7b
ollama pull codellama:13b
```

### 모델 관리
```bash
# 설치된 모델 확인
ollama list

# 모델 실행 테스트
ollama run llama3.1:8b

# 모델 삭제
ollama rm llama3.1:8b
```

## 🔧 문제 해결

### 설치가 안 되는 경우

#### 1. 관리자 권한으로 실행
- CMD를 "관리자 권한으로 실행"
- PowerShell을 "관리자 권한으로 실행"

#### 2. 바이러스 백신 확인
- Windows Defender 실시간 보호 일시 중지
- 다른 백신 소프트웨어 일시 중지

#### 3. 방화벽 설정
- Windows 방화벽에서 Ollama 허용
- 포트 11434 열기

#### 4. PATH 환경변수 확인
```bash
# 현재 PATH 확인
echo %PATH%

# Ollama 경로 수동 추가 (보통 불필요)
# C:\Users\[사용자명]\AppData\Local\Programs\Ollama
```

### 서비스가 시작되지 않는 경우

#### 1. 포트 충돌 확인
```bash
# 포트 11434 사용 확인
netstat -an | findstr 11434
```

#### 2. 수동 서비스 시작
```bash
# 포그라운드 실행 (로그 확인 가능)
ollama serve

# 백그라운드 실행
start /min "Ollama Service" ollama serve
```

#### 3. 로그 확인
- `%TEMP%\ollama.log` 파일 확인
- 오류 메시지 확인 후 해결

### 모델 다운로드가 실패하는 경우

#### 1. 네트워크 연결 확인
```bash
# 인터넷 연결 테스트
ping 8.8.8.8
```

#### 2. DNS 설정 변경
- Google DNS: 8.8.8.8, 8.8.4.4
- Cloudflare DNS: 1.1.1.1, 1.0.0.1

#### 3. 프록시 설정
```bash
# 프록시 환경에서
set HTTP_PROXY=http://proxy.company.com:8080
set HTTPS_PROXY=http://proxy.company.com:8080
```

#### 4. 수동 재시도
```bash
# 다운로드 재시도
ollama pull llama3.1:8b --verbose
```

## 💡 성능 최적화

### 시스템 요구사항

| 모델 크기 | RAM 필요량 | 디스크 공간 | 추천 CPU |
|-----------|------------|-------------|----------|
| 1B        | 2GB        | 1GB         | 모든 CPU |
| 3B        | 4GB        | 2GB         | 듀얼코어+ |
| 7B        | 8GB        | 4GB         | 쿼드코어+ |
| 8B        | 8GB        | 5GB         | 쿼드코어+ |
| 13B       | 16GB       | 8GB         | 6코어+   |
| 70B       | 40GB       | 40GB        | 고성능 워크스테이션 |

### GPU 가속 (선택사항)
```bash
# NVIDIA GPU가 있는 경우 자동으로 사용됨
# CUDA 설치 필요: https://developer.nvidia.com/cuda-downloads
```

### 메모리 설정
```bash
# 환경변수로 메모리 제한 설정 (선택사항)
set OLLAMA_HOST=127.0.0.1:11434
set OLLAMA_MAX_LOADED_MODELS=1
```

## 🌐 XShell 챗봇과 연동

### 1. 서버 시작 전 Ollama 실행
```bash
# 1. Ollama 서비스 시작
ollama serve

# 2. 챗봇 서버 시작
run-daphne.bat
```

### 2. 자동 시작 설정 (선택사항)
Windows 서비스로 등록하여 부팅시 자동 시작:
```bash
# PowerShell (관리자 권한)
New-Service -Name "Ollama" -BinaryPathName "C:\Users\[사용자명]\AppData\Local\Programs\Ollama\ollama.exe serve" -StartupType Automatic
```

## 📞 추가 도움

### 공식 문서
- 공식 사이트: https://ollama.com
- GitHub: https://github.com/ollama/ollama
- 문서: https://ollama.com/docs

### 커뮤니티
- Discord: https://discord.gg/ollama
- Reddit: r/ollama

### 문제 신고
- XShell 챗봇 관련: 이 프로젝트의 GitHub Issues
- Ollama 관련: https://github.com/ollama/ollama/issues

---

💡 **팁**: 처음 사용자는 `llama3.2:3b` 모델부터 시작하는 것을 추천합니다. 빠르고 가벼우며 대부분의 작업에 충분합니다.
