# 🚀 XShell AI 챗봇 All-in-One 빠른 시작 가이드

**32GB RAM 고성능 시스템용 완전 자동 설치**

## ⚡ 원클릭 설치

### 1. 설치 파일 다운로드
```bash
# 프로젝트 전체를 다운로드하고 폴더로 이동
cd your-project-folder
```

### 2. All-in-One 설치 실행
```bash
install-all-in-one.bat
```
**⚠️ 반드시 "관리자 권한으로 실행"하세요!**

### 3. 설치 완료 후 자동 실행
- 브라우저가 자동으로 http://localhost:8000 열림
- AI 챗봇 바로 사용 가능

## 📦 설치되는 구성 요소

### **자동 설치 항목**
- ✅ **Python 3.11** (PATH 자동 설정)
- ✅ **Ollama AI 엔진** (최신 버전)
- ✅ **고성능 AI 모델들**:
  - `llama3.1:8b` (4.7GB) - 일반 대화용
  - `codellama:13b` (7GB) - 코드 분석용
  - `llama3.1:70b` (40GB) - 최고 성능 (선택사항)
- ✅ **Django 웹 프레임워크**
- ✅ **모든 Python 패키지**
- ✅ **데이터베이스 설정**
- ✅ **환경 설정 파일** (32GB RAM 최적화)

### **32GB RAM 고성능 최적화**
```bash
기본 AI 모델: llama3.1:8b (고품질)
코드 AI 모델: codellama:13b (전문)
동시 모델 로딩: 2개
컨텍스트 길이: 8192 토큰
병렬 처리: 4 스레드
```

## ⏱️ 설치 시간

| 구성 요소 | 예상 시간 | 디스크 사용량 |
|-----------|-----------|---------------|
| Python 설치 | 2-3분 | 300MB |
| Ollama 설치 | 1-2분 | 200MB |
| AI 모델 다운로드 | 10-20분 | 12GB |
| Python 패키지 | 2-3분 | 500MB |
| **전체** | **15-30분** | **~15GB** |

## 🎯 설치 후 즉시 사용

### **웹 인터페이스**
- **메인 페이지**: http://localhost:8000
- **관리자 페이지**: http://localhost:8000/admin

### **AI 기능 테스트**
1. 웹 페이지에서 채팅창 사용
2. "안녕하세요" 입력해서 AI 응답 확인
3. 코드 질문으로 전문 분석 테스트

### **XShell 통합 기능**
- XShell 세션 자동 감지
- 터미널 명령어 AI 도움
- 실시간 채팅 지원

## 🔧 문제 해결

### **설치 중 오류 발생시**
```bash
# 1. 관리자 권한 확인
우클릭 → "관리자 권한으로 실행"

# 2. 인터넷 연결 확인
ping google.com

# 3. 바이러스 백신 일시 비활성화
Windows Defender 실시간 보호 끄기

# 4. 다시 시도
install-all-in-one.bat
```

### **AI 기능 오류시**
```bash
# AI 연결 테스트
check-ollama-quick.bat

# AI 오류 자동 수정
fix-ollama-500.bat

# 전체 AI 시스템 테스트
test-ai.bat
```

### **서버 시작 오류시**
```bash
# 가상환경 활성화 후 수동 시작
.venv\Scripts\activate
python manage.py runserver

# 또는 배치 파일 사용
start.bat
run-daphne.bat
```

## 💡 사용 팁

### **고성능 활용법**
1. **대화 품질**: `llama3.1:8b`가 기본으로 설정되어 높은 품질
2. **코드 분석**: Python, JavaScript 등 코드 질문시 `codellama:13b` 자동 사용
3. **최고 성능**: `llama3.1:70b` 설치시 더욱 정교한 답변

### **모델 변경 방법**
```bash
# .env 파일 수정
DEFAULT_AI_MODEL=llama3.1:70b  # 최고 성능으로 변경
CODE_AI_MODEL=codellama:13b    # 코드 전용 유지
```

### **성능 모니터링**
```bash
# AI 모델 상태 확인
ollama list

# 메모리 사용량 확인
작업 관리자 → 성능 탭

# 시스템 리소스 모니터링
리소스 모니터 실행
```

## 🎊 설치 성공 확인

설치가 성공적으로 완료되면 다음과 같이 표시됩니다:

```
🎉 설치 완료!
==============

✅ 설치된 구성 요소:
  • Python 3.11 + 가상환경
  • Django 웹 프레임워크
  • Ollama AI 엔진
  • AI 모델: llama3.1:8b, codellama:13b
  • WebSocket 실시간 채팅
  • 데이터베이스 (SQLite)
  • 모든 설정 파일 (32GB RAM 최적화)

🔥 32GB RAM 고성능 설정:
  • 기본 AI 모델: llama3.1:8b (고품질 대화)
  • 코드 AI 모델: codellama:13b (전문 코드 분석)
  • 동시 모델 로딩: 2개
  • 컨텍스트 길이: 8192 토큰
  • 병렬 처리: 4 스레드

🚀 서버 시작 중...
🌐 5초 후 브라우저가 자동으로 열립니다...
```

## 📚 추가 자료

- **상세 가이드**: README.md
- **문제 해결**: TROUBLESHOOTING-AI.md
- **빠른 수정**: AI-QUICK-FIX.md
- **Ollama 가이드**: OLLAMA-INSTALL-GUIDE.md

---

💡 **한 번의 실행으로 모든 것이 자동 설치됩니다!**  
🚀 **32GB RAM의 성능을 최대한 활용하세요!**
