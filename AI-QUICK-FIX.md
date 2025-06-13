# AI 오류 빠른 해결 🚀

XShell 챗봇에서 AI 기능 오류가 발생했나요? 이 가이드로 빠르게 해결하세요!

## 🔥 즉시 해결 (30초)

### 500 Internal Server Error?
```bash
fix-ollama-500.bat
```
**모든 500 오류를 자동으로 진단하고 수정합니다.**

### 연결 오류?
```bash
check-ollama-quick.bat
```
**Ollama 서비스 상태를 빠르게 확인하고 시작합니다.**

### AI 기능이 전혀 안 됨?
```bash
install-ollama-simple.bat
```
**Ollama와 AI 모델을 처음부터 설치합니다.**

## 🎯 오류별 원클릭 해결

| 오류 증상 | 해결 명령어 | 소요 시간 |
|-----------|-------------|-----------|
| 🔴 "500 Server Error" | `fix-ollama-500.bat` | 30초-2분 |
| 🟡 "연결 거부" | `ollama serve` | 10초 |
| 🟠 "404 Not Found" | 자동 처리됨 | 즉시 |
| 🔵 "시간 초과" | `ollama pull llama3.2:1b` | 5분 |
| ⚫ "AI 없음" | `install-ollama-simple.bat` | 10분 |

## 💡 상황별 해결

### 😰 "갑자기 AI가 안 돼요!"
```bash
# 1단계: 빠른 재시작
taskkill /f /im ollama.exe
ollama serve

# 2단계: 여전히 안 되면
fix-ollama-500.bat
```

### 🤔 "처음 설치인데 AI가 안 돼요!"
```bash
# 원스톱 설치
install-ollama-simple.bat
```

### 😵 "너무 느려요!"
```bash
# 더 작은 모델 사용
ollama pull llama3.2:1b    # 1GB (빠름)
ollama rm llama3.1:8b      # 기존 큰 모델 제거
```

### 🤯 "아무것도 안 돼요!"
```bash
# 완전 재설정
1. 시스템 재시작
2. install-ollama-simple.bat 실행
3. run-daphne.bat 실행
```

## ⚡ 초고속 체크리스트

**AI 오류 발생시 순서대로 확인:**

□ `check-ollama-quick.bat` 실행 (10초)  
□ `fix-ollama-500.bat` 실행 (1분)  
□ 시스템 재시작 (2분)  
□ `install-ollama-simple.bat` 실행 (10분)  

**4단계 중 하나에서 반드시 해결됩니다!**

## 🏆 성공 확인

AI가 정상 작동하면 다음과 같이 표시됩니다:

```
✅ Ollama 서비스 실행 중
✅ 모델 사용 가능: llama3.2:3b  
✅ API 정상 작동
🎉 모든 기능이 정상입니다!
```

## 📱 즉시 실행

1. **cmd 창 열기** (Windows키 + R → cmd)
2. **프로젝트 폴더로 이동** (`cd C:\your\project\path`)
3. **해당 명령어 실행**

---

💫 **99% 케이스에서 `fix-ollama-500.bat` 한 번이면 해결됩니다!**
