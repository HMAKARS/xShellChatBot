/**
 * Sysintec Chatbot JavaScript - 간단한 HTTP 기반
 */

class SysintecChatbot {
    constructor() {
        this.currentSessionId = null;
        this.settings = this.loadSettings();
        this._eventListenersInitialized = false;
        
        this.init();
    }
    
    init() {
        this.setupEventListeners();
        this.loadChatSessions();
        this.createNewSession();
    }
    
    setupEventListeners() {
        if (this._eventListenersInitialized) return;
        this._eventListenersInitialized = true;
        // 메시지 전송
        const sendBtn = document.getElementById('sendBtn');
        if (sendBtn) {
            sendBtn.addEventListener('click', () => this.sendMessage());
        }
        const messageInput = document.getElementById('messageInput');
        if (messageInput) {
            messageInput.addEventListener('keydown', (e) => {
                if (e.key === 'Enter' && !e.shiftKey && !e.isComposing) {
                    e.preventDefault();
                    this.sendMessage();
                }
            });
            // 자동 리사이즈
            messageInput.addEventListener('input', function() {
                this.style.height = 'auto';
                this.style.height = Math.min(this.scrollHeight, 120) + 'px';
            });
        }
        // 파일 업로드 관련
        this.setupFileUploadEvents();
        // 새 채팅 버튼
        const newChatBtn = document.getElementById('newChatBtn');
        if (newChatBtn) {
            newChatBtn.addEventListener('click', () => {
                this.showNewSessionModal();
            });
        }
        // 설정 버튼
        const settingsBtn = document.getElementById('settingsBtn');
        if (settingsBtn) {
            settingsBtn.addEventListener('click', () => {
                this.showSettingsModal();
            });
        }
        // 대화 지우기
        const clearChatBtn = document.getElementById('clearChatBtn');
        if (clearChatBtn) {
            clearChatBtn.addEventListener('click', () => {
                this.clearCurrentChat();
            });
        }
        // 모달 이벤트
        const createSessionBtn = document.getElementById('createSessionBtn');
        if (createSessionBtn) {
            createSessionBtn.addEventListener('click', () => {
                this.createNewSession();
            });
        }
        const saveSettingsBtn = document.getElementById('saveSettingsBtn');
        if (saveSettingsBtn) {
            saveSettingsBtn.addEventListener('click', () => {
                this.saveSettings();
            });
        }
        // 세션 선택
        document.addEventListener('click', (e) => {
            if (e.target.closest('.session-item')) {
                const sessionId = e.target.closest('.session-item').dataset.sessionId;
                this.switchToSession(sessionId);
            }
        });
    }
    
    async sendMessage() {
        const messageInput = document.getElementById('messageInput');
        const message = messageInput.value.trim();
        if (!message) return;

        // 입력창 값을 즉시 비움 (가장 먼저!)
        messageInput.value = '';
        messageInput.style.height = 'auto';

        if (!this.currentSessionId) {
            this.showError('세션이 생성되지 않았습니다.');
            return;
        }
        
        // 전송 버튼 비활성화
        const sendBtn = document.getElementById('sendBtn');
        const originalText = sendBtn.innerHTML;
        sendBtn.disabled = true;
        sendBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i>';
        
        // UI에 사용자 메시지 즉시 표시
        this.displayMessage({
            type: 'user',
            content: message,
            timestamp: new Date().toISOString()
        });
        
        // 타이핑 인디케이터 표시
        this.showTypingIndicator();
 
        try {
            const response = await fetch('/api/message/send/', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRFToken': this.getCSRFToken()
                },
                body: JSON.stringify({
                    session_id: this.currentSessionId,
                    message: message,
                    type: 'user'
                })
            });
            
            const data = await response.json();
            
            if (data.success) {
                // AI 응답 표시 (현재 시간으로 timestamp 업데이트)
                this.displayMessage({
                    type: 'ai',
                    content: data.ai_message.content,
                    timestamp: new Date().toISOString(), // 응답 받은 시점의 시간으로 변경
                    metadata: data.ai_message.metadata
                });
            } else {
                this.showError(data.error || '메시지 전송에 실패했습니다.');
            }
            
        } catch (error) {
            console.error('메시지 전송 실패:', error);
            // 401 오류인 경우 로그인 페이지로 리다이렉트
            if (error.status === 401) {
                window.location.href = '/login/';
                return;
            }
            this.showError('네트워크 오류가 발생했습니다.');
        } finally {
            // 타이핑 인디케이터 숨기기
            this.hideTypingIndicator();
            
            // 전송 버튼 복원
            sendBtn.disabled = false;
            sendBtn.innerHTML = originalText;
        }
    }
    
    displayMessage(message) {
        const chatMessages = document.getElementById('chatMessages');
        const welcomeMessage = chatMessages.querySelector('.welcome-message');
        
        // 첫 메시지인 경우 환영 메시지 숨기기
        if (welcomeMessage) {
            welcomeMessage.style.display = 'none';
        }
        
        const messageDiv = document.createElement('div');
        messageDiv.className = `message ${message.type}`;
        
        // 파일 업로드 메시지인 경우 특별한 스타일 적용
        if (message.type === 'system' && message.metadata?.file_name) {
            messageDiv.classList.add('file-upload');
        }
        
        const content = this.formatMessageContent(message.content, message.type);
        const timestamp = message.timestamp ? new Date(message.timestamp).toLocaleTimeString() : '';
        
        let metadataHTML = '';
        if (message.metadata?.analyzed_file) {
            metadataHTML = `<div class="message-meta-badge"><i class="fas fa-file-alt me-1"></i>파일 분석: ${message.metadata.analyzed_file}</div>`;
        }
        
        messageDiv.innerHTML = `
            <div class="message-content">
                ${content}
                ${metadataHTML}
            </div>
            <div class="message-meta">
                ${timestamp}
            </div>
        `;
        
        chatMessages.appendChild(messageDiv);
        this.scrollToBottom();
    }
    
    formatMessageContent(content, type) {
        // 마크다운 간단 처리
        let formatted = this.escapeHtml(content);
        
        // 코드 블록
        formatted = formatted.replace(/```([\s\S]*?)```/g, '<pre><code>$1</code></pre>');
        
        // 인라인 코드
        formatted = formatted.replace(/`([^`]+)`/g, '<code>$1</code>');
        
        // 굵은 글씨
        formatted = formatted.replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>');
        
        // 기울임
        formatted = formatted.replace(/\*(.*?)\*/g, '<em>$1</em>');
        
        // 줄바꿈
        formatted = formatted.replace(/\n/g, '<br>');
        
        return formatted;
    }
    
    showTypingIndicator() {
        const indicator = document.getElementById('typingIndicator');
        if (indicator) {
            indicator.style.display = 'block';
            this.scrollToBottom();
        }
    }
    
    hideTypingIndicator() {
        const indicator = document.getElementById('typingIndicator');
        if (indicator) {
            indicator.style.display = 'none';
        }
    }
    
    async createNewSession() {
        const title = document.getElementById('sessionTitle')?.value || '새로운 채팅';
        
        try {
            const response = await fetch('/api/session/create/', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRFToken': this.getCSRFToken()
                },
                body: JSON.stringify({ title: title })
            });
            
            // 401 오류 체크
            if (response.status === 401) {
                window.location.href = '/login/';
                return;
            }
            
            const data = await response.json();
            
            if (data.success) {
                this.currentSessionId = data.session_id;
                this.updateSessionTitle(data.title);
                this.clearMessages();
                this.hideNewSessionModal();
                this.addSessionToList(data);
                this.showWelcomeMessage();
            } else {
                this.showError(data.error || '세션 생성에 실패했습니다.');
            }
        } catch (error) {
            console.error('세션 생성 실패:', error);
            this.showError('세션을 생성할 수 없습니다.');
        }
    }
    
    async switchToSession(sessionId) {
        if (this.currentSessionId === sessionId) return;
        
        this.currentSessionId = sessionId;
        await this.loadChatHistory(sessionId);
        this.updateActiveSession(sessionId);
    }
    
    async loadChatHistory(sessionId) {
        try {
            const response = await fetch(`/api/session/${sessionId}/`);
            
            // 401 오류 체크
            if (response.status === 401) {
                window.location.href = '/login/';
                return;
            }
            
            const data = await response.json();
            
            if (data.success) {
                this.updateSessionTitle(data.session.title);
                this.clearMessages();
                
                data.messages.forEach(message => {
                    this.displayMessage(message);
                });
                
                if (data.messages.length === 0) {
                    this.showWelcomeMessage();
                }
            } else {
                this.showError(data.error || '채팅 히스토리를 불러올 수 없습니다.');
            }
        } catch (error) {
            console.error('채팅 히스토리 로드 실패:', error);
            this.showError('채팅 히스토리를 불러올 수 없습니다.');
        }
    }
    
    async loadChatSessions() {
        try {
            const response = await fetch('/api/sessions/');
            
            // 401 오류 체크
            if (response.status === 401) {
                window.location.href = '/login/';
                return;
            }
            
            const data = await response.json();
            
            if (data.success) {
                const sessionList = document.getElementById('chatSessionList');
                sessionList.innerHTML = '';
                
                if (data.sessions.length === 0) {
                    sessionList.innerHTML = '<div class="text-muted small">채팅 세션이 없습니다</div>';
                } else {
                    data.sessions.forEach(session => {
                        this.addSessionToList(session, false);
                    });
                }
            }
        } catch (error) {
            console.error('세션 목록 로드 실패:', error);
        }
    }
    
    clearCurrentChat() {
        if (confirm('현재 대화를 모두 삭제하시겠습니까?')) {
            this.clearMessages();
            this.showWelcomeMessage();
        }
    }
    
    clearMessages() {
        const chatMessages = document.getElementById('chatMessages');
        chatMessages.innerHTML = '';
    }
    
    showWelcomeMessage() {
        const chatMessages = document.getElementById('chatMessages');
        chatMessages.innerHTML = `
            <div class="welcome-message">
                <div class="text-center p-4">
                    <i class="fas fa-robot fa-3x text-primary mb-3"></i>
                    <h4>Sysintec Chatbot</h4>
                    <p class="text-muted">AI 기반 대화형 어시스턴트로 다양한 업무를 도와드립니다.</p>
                    <div class="row mt-4">
                        <div class="col-md-4">
                            <div class="feature-card p-3 border rounded">
                                <i class="fas fa-comments text-primary mb-2"></i>
                                <h6>스마트 대화</h6>
                                <small class="text-muted">자연스러운 대화로 질문에 답변</small>
                            </div>
                        </div>
                        <div class="col-md-4">
                            <div class="feature-card p-3 border rounded">
                                <i class="fas fa-code text-success mb-2"></i>
                                <h6>코드 분석</h6>
                                <small class="text-muted">프로그래밍 질문과 코드 리뷰</small>
                            </div>
                        </div>
                        <div class="col-md-4">
                            <div class="feature-card p-3 border rounded">
                                <i class="fas fa-lightbulb text-warning mb-2"></i>
                                <h6>문제 해결</h6>
                                <small class="text-muted">다양한 주제의 질문과 해결책 제시</small>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        `;
    }
    
    updateSessionTitle(title) {
        document.getElementById('currentSessionTitle').textContent = title;
    }
    
    updateActiveSession(sessionId) {
        document.querySelectorAll('.session-item').forEach(item => {
            item.classList.remove('active');
        });
        
        const activeSession = document.querySelector(`[data-session-id="${sessionId}"]`);
        if (activeSession) {
            activeSession.classList.add('active');
        }
    }
    
    addSessionToList(sessionData, isNew = true) {
        const sessionList = document.getElementById('chatSessionList');
        
        // "채팅 세션이 없습니다" 메시지 제거
        const emptyMessage = sessionList.querySelector('.text-muted');
        if (emptyMessage) {
            emptyMessage.remove();
        }
        
        const sessionDiv = document.createElement('div');
        sessionDiv.className = 'session-item';
        sessionDiv.dataset.sessionId = sessionData.session_id;
        
        if (isNew) {
            sessionDiv.classList.add('active');
        }
        
        const timeText = isNew ? '방금 전' : new Date(sessionData.updated_at).toLocaleDateString();
        
        sessionDiv.innerHTML = `
            <div class="session-name">${sessionData.title}</div>
            <div class="session-time">${timeText}</div>
        `;
        
        if (isNew) {
            // 기존 active 클래스 제거
            document.querySelectorAll('.session-item').forEach(item => {
                item.classList.remove('active');
            });
            
            sessionList.insertBefore(sessionDiv, sessionList.firstChild);
        } else {
            sessionList.appendChild(sessionDiv);
        }
    }
    
    showNewSessionModal() {
        const modal = new bootstrap.Modal(document.getElementById('newSessionModal'));
        modal.show();
    }
    
    hideNewSessionModal() {
        const modal = bootstrap.Modal.getInstance(document.getElementById('newSessionModal'));
        if (modal) modal.hide();
    }
    
    showSettingsModal() {
        this.loadSettings();
        const modal = new bootstrap.Modal(document.getElementById('settingsModal'));
        modal.show();
    }
    
    loadSettings() {
        const defaultSettings = {
            aiModel: 'gemini-2.0-flash-exp',
            temperature: 0.7,
            autoSave: true,
            soundNotifications: false
        };
        
        const saved = localStorage.getItem('sysintec_chatbot_settings');
        const settings = saved ? JSON.parse(saved) : defaultSettings;
        
        // UI 업데이트
        if (document.getElementById('aiModel')) {
            document.getElementById('aiModel').value = settings.aiModel;
            document.getElementById('temperature').value = settings.temperature;
            document.getElementById('temperatureValue').textContent = settings.temperature;
            document.getElementById('autoSave').checked = settings.autoSave;
            document.getElementById('soundNotifications').checked = settings.soundNotifications;
        }
        
        return settings;
    }
    
    saveSettings() {
        const settings = {
            aiModel: document.getElementById('aiModel')?.value || 'gemini-2.0-flash-exp',
            temperature: parseFloat(document.getElementById('temperature')?.value || 0.7),
            autoSave: document.getElementById('autoSave')?.checked || true,
            soundNotifications: document.getElementById('soundNotifications')?.checked || false
        };
        
        localStorage.setItem('sysintec_chatbot_settings', JSON.stringify(settings));
        this.settings = settings;
        
        // 설정 적용
        this.applySettings();
        
        // 모달 닫기
        const modal = bootstrap.Modal.getInstance(document.getElementById('settingsModal'));
        if (modal) modal.hide();
        
        this.showSuccess('설정이 저장되었습니다.');
    }
    
    applySettings() {
        // Temperature 값 표시 업데이트
        const temperatureInput = document.getElementById('temperature');
        if (temperatureInput) {
            temperatureInput.addEventListener('input', function() {
                document.getElementById('temperatureValue').textContent = this.value;
            });
        }
    }
    
    scrollToBottom() {
        const chatMessages = document.getElementById('chatMessages');
        chatMessages.scrollTop = chatMessages.scrollHeight;
    }
    
    showError(message) {
        this.showToast(message, 'error');
    }
    
    showSuccess(message) {
        this.showToast(message, 'success');
    }
    
    showToast(message, type = 'info') {
        // Bootstrap Toast 사용
        const toastContainer = document.querySelector('.toast-container') || this.createToastContainer();
        
        const toastId = 'toast_' + Date.now();
        const bgClass = type === 'error' ? 'bg-danger' : type === 'success' ? 'bg-success' : 'bg-primary';
        
        const toastHTML = `
            <div id="${toastId}" class="toast ${bgClass} text-white" role="alert" aria-live="assertive" aria-atomic="true">
                <div class="toast-body">
                    ${message}
                </div>
            </div>
        `;
        
        toastContainer.insertAdjacentHTML('beforeend', toastHTML);
        
        const toastElement = document.getElementById(toastId);
        const toast = new bootstrap.Toast(toastElement, { delay: 3000 });
        toast.show();
        
        // 토스트가 숨겨진 후 DOM에서 제거
        toastElement.addEventListener('hidden.bs.toast', () => {
            toastElement.remove();
        });
    }
    
    createToastContainer() {
        const container = document.createElement('div');
        container.className = 'toast-container position-fixed top-0 end-0 p-3';
        container.style.zIndex = '1080';
        document.body.appendChild(container);
        return container;
    }
    
    getCSRFToken() {
        return document.querySelector('[name=csrfmiddlewaretoken]')?.value || '';
    }
    
    escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }
    
    // 파일 업로드 관련 메서드들
    setupFileUploadEvents() {
        this.selectedFile = null;
        
        // 파일 업로드 토글 버튼
        document.getElementById('fileUploadToggle').addEventListener('click', () => {
            this.toggleFileUpload();
        });
        
        // 파일 선택 input
        document.getElementById('fileInput').addEventListener('change', (e) => {
            this.handleFileSelect(e.target.files[0]);
        });
        
        // 드래그 앤 드롭
        const dropZone = document.getElementById('fileDropZone');
        
        dropZone.addEventListener('click', () => {
            document.getElementById('fileInput').click();
        });
        
        dropZone.addEventListener('dragover', (e) => {
            e.preventDefault();
            dropZone.classList.add('dragover');
        });
        
        dropZone.addEventListener('dragleave', (e) => {
            e.preventDefault();
            dropZone.classList.remove('dragover');
        });
        
        dropZone.addEventListener('drop', (e) => {
            e.preventDefault();
            dropZone.classList.remove('dragover');
            
            const files = e.dataTransfer.files;
            if (files.length > 0) {
                this.handleFileSelect(files[0]);
            }
        });
        
        // 파일 업로드 버튼
        document.getElementById('uploadFileBtn').addEventListener('click', () => {
            this.uploadFile();
        });
        
        // 파일 업로드 취소
        document.getElementById('cancelFileUpload').addEventListener('click', () => {
            this.cancelFileUpload();
        });
    }
    
    toggleFileUpload() {
        const fileUploadArea = document.getElementById('fileUploadArea');
        const isVisible = fileUploadArea.style.display !== 'none';
        
        if (isVisible) {
            fileUploadArea.style.display = 'none';
            this.clearFileSelection();
        } else {
            fileUploadArea.style.display = 'block';
        }
    }
    
    handleFileSelect(file) {
        if (!file) return;
        
        // 파일 크기 체크 (10MB)
        const maxSize = 10 * 1024 * 1024;
        if (file.size > maxSize) {
            this.showError('파일 크기가 너무 큽니다. 최대 10MB까지 지원됩니다.');
            return;
        }
        
        // 지원되는 파일 형식 체크
        const supportedTypes = ['.pdf', '.docx', '.txt', '.hwp', '.doc'];
        const fileExt = '.' + file.name.split('.').pop().toLowerCase();
        
        if (!supportedTypes.includes(fileExt)) {
            this.showError(`지원되지 않는 파일 형식입니다. 지원 형식: ${supportedTypes.join(', ')}`);
            return;
        }
        
        this.selectedFile = file;
        this.displaySelectedFile(file);
        
        // 업로드 버튼 활성화
        document.getElementById('uploadFileBtn').disabled = false;
    }
    
    displaySelectedFile(file) {
        const dropZone = document.getElementById('fileDropZone');
        const fileSizeText = this.formatFileSize(file.size);
        const fileExt = file.name.split('.').pop().toUpperCase();
        
        dropZone.innerHTML = `
            <div class="file-selected">
                <div class="file-info">
                    <div class="file-details">
                        <div class="file-icon">${fileExt}</div>
                        <div>
                            <div class="file-name">${file.name}</div>
                            <div class="file-size">${fileSizeText}</div>
                        </div>
                    </div>
                    <div class="remove-file" onclick="chatbot.clearFileSelection()">
                        <i class="fas fa-times"></i>
                    </div>
                </div>
            </div>
        `;
        
        dropZone.classList.remove('error');
    }
    
    clearFileSelection() {
        this.selectedFile = null;
        
        const dropZone = document.getElementById('fileDropZone');
        dropZone.innerHTML = `
            <div class="text-center">
                <i class="fas fa-cloud-upload-alt fa-2x text-muted mb-2"></i>
                <p class="mb-1">파일을 드래그하여 놓거나 클릭하여 선택하세요</p>
                <small class="text-muted">지원 형식: PDF, DOCX, TXT (최대 10MB)</small>
                <input type="file" id="fileInput" accept=".pdf,.docx,.txt,.hwp,.doc" style="display: none;">
            </div>
        `;
        
        // 다시 이벤트 리스너 연결
        document.getElementById('fileInput').addEventListener('change', (e) => {
            this.handleFileSelect(e.target.files[0]);
        });
        
        // 업로드 버튼 비활성화
        document.getElementById('uploadFileBtn').disabled = true;
    }
    
    async uploadFile() {
        if (!this.selectedFile) {
            this.showError('선택된 파일이 없습니다.');
            return;
        }
        
        if (!this.currentSessionId) {
            this.showError('세션이 생성되지 않았습니다.');
            return;
        }
        
        const question = document.getElementById('fileQuestion').value.trim() || '이 파일의 내용을 분석해주세요.';
        
        // 업로드 버튼 비활성화 및 로딩 표시
        const uploadBtn = document.getElementById('uploadFileBtn');
        const originalText = uploadBtn.innerHTML;
        uploadBtn.disabled = true;
        uploadBtn.innerHTML = '<i class="fas fa-spinner fa-spin me-1"></i>분석 중...';
        
        try {
            const formData = new FormData();
            formData.append('file', this.selectedFile);
            formData.append('session_id', this.currentSessionId);
            formData.append('question', question);
            
            const response = await fetch('/api/file/analyze/', {
                method: 'POST',
                headers: {
                    'X-CSRFToken': this.getCSRFToken()
                },
                body: formData
            });
            
            const data = await response.json();
            
            if (data.success) {
                // 파일 업로드 영역 숨기기
                this.cancelFileUpload();
                
                // 시스템 메시지 (파일 정보)
                this.displayMessage({
                    type: 'system',
                    content: data.file_message.content,
                    timestamp: data.file_message.timestamp,
                    metadata: data.file_message.metadata
                });
                
                // 사용자 질문
                this.displayMessage({
                    type: 'user',
                    content: data.user_message.content,
                    timestamp: data.user_message.timestamp
                });
                
                // AI 분석 결과
                this.displayMessage({
                    type: 'ai',
                    content: data.ai_message.content,
                    timestamp: new Date().toISOString(), // 응답 받은 시점의 시간으로 변경
                    metadata: data.ai_message.metadata
                });
                
                this.showSuccess('파일이 성공적으로 분석되었습니다.');
            } else {
                this.showError(data.error || '파일 분석에 실패했습니다.');
            }
        } catch (error) {
            console.error('파일 업로드 실패:', error);
            // 401 오류인 경우 로그인 페이지로 리다이렉트
            if (error.status === 401) {
                window.location.href = '/login/';
                return;
            }
            this.showError('파일 업로드 중 오류가 발생했습니다.');
        } finally {
            // 버튼 복원
            uploadBtn.disabled = false;
            uploadBtn.innerHTML = originalText;
        }
    }
    
    cancelFileUpload() {
        document.getElementById('fileUploadArea').style.display = 'none';
        this.clearFileSelection();
        document.getElementById('fileQuestion').value = '';
    }
    
    formatFileSize(bytes) {
        if (bytes === 0) return '0 Bytes';
        
        const k = 1024;
        const sizes = ['Bytes', 'KB', 'MB', 'GB'];
        const i = Math.floor(Math.log(bytes) / Math.log(k));
        
        return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
    }
}

// 페이지 로드시 챗봇 초기화
let chatbot;
document.addEventListener('DOMContentLoaded', function() {
    chatbot = new SysintecChatbot();
});
