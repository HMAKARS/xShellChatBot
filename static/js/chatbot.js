/**
 * XShell AI 챗봇 JavaScript
 */

class XShellChatbot {
    constructor() {
        this.currentSessionId = null;
        this.chatSocket = null;
        this.isConnected = false;
        this.messageQueue = [];
        this.settings = this.loadSettings();
        
        this.init();
    }
    
    init() {
        this.setupEventListeners();
        this.setupWebSocket();
        this.loadChatSessions();
        this.createNewSession();
    }
    
    setupEventListeners() {
        // 메시지 전송
        document.getElementById('sendBtn').addEventListener('click', () => this.sendMessage());
        document.getElementById('messageInput').addEventListener('keydown', (e) => {
            if (e.key === 'Enter' && !e.shiftKey) {
                e.preventDefault();
                this.sendMessage();
            }
        });
        
        // 자동 리사이즈
        const messageInput = document.getElementById('messageInput');
        messageInput.addEventListener('input', function() {
            this.style.height = 'auto';
            this.style.height = Math.min(this.scrollHeight, 120) + 'px';
        });
        
        // 새 채팅 버튼
        document.getElementById('newChatBtn').addEventListener('click', () => {
            this.showNewSessionModal();
        });
        
        // 설정 버튼
        document.getElementById('settingsBtn').addEventListener('click', () => {
            this.showSettingsModal();
        });
        
        // 대화 지우기
        document.getElementById('clearChatBtn').addEventListener('click', () => {
            this.clearCurrentChat();
        });
        
        // 모달 이벤트
        document.getElementById('createSessionBtn').addEventListener('click', () => {
            this.createNewSession();
        });
        
        document.getElementById('saveSettingsBtn').addEventListener('click', () => {
            this.saveSettings();
        });
        
        // 세션 선택
        document.addEventListener('click', (e) => {
            if (e.target.closest('.session-item')) {
                const sessionId = e.target.closest('.session-item').dataset.sessionId;
                this.switchToSession(sessionId);
            }
        });
    }
    
    setupWebSocket() {
        if (!this.currentSessionId) return;
        
        const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
        const wsUrl = `${protocol}//${window.location.host}/ws/chat/${this.currentSessionId}/`;
        
        try {
            this.chatSocket = new WebSocket(wsUrl);
            
            this.chatSocket.onopen = (e) => {
                console.log('WebSocket 연결됨');
                this.isConnected = true;
                this.updateConnectionStatus(true);
                this.processMessageQueue();
            };
            
            this.chatSocket.onmessage = (e) => {
                const data = JSON.parse(e.data);
                this.handleWebSocketMessage(data);
            };
            
            this.chatSocket.onclose = (e) => {
                console.log('WebSocket 연결 끊김');
                this.isConnected = false;
                this.updateConnectionStatus(false);
                
                // 재연결 시도
                setTimeout(() => {
                    if (this.currentSessionId) {
                        this.setupWebSocket();
                    }
                }, 3000);
            };
            
            this.chatSocket.onerror = (e) => {
                console.error('WebSocket 오류:', e);
                this.showError('연결 오류가 발생했습니다.');
            };
            
        } catch (error) {
            console.error('WebSocket 생성 실패:', error);
            this.showError('WebSocket 연결을 생성할 수 없습니다.');
        }
    }
    
    handleWebSocketMessage(data) {
        switch (data.type) {
            case 'message':
                this.displayMessage(data.message);
                break;
            case 'typing':
                this.handleTypingIndicator(data);
                break;
            case 'error':
                this.showError(data.error);
                break;
            default:
                console.log('알 수 없는 메시지 타입:', data);
        }
    }
    
    sendMessage() {
        const messageInput = document.getElementById('messageInput');
        const message = messageInput.value.trim();
        
        if (!message) return;
        
        if (!this.isConnected) {
            this.messageQueue.push({
                type: 'message',
                message: message
            });
            this.showError('연결 중입니다. 잠시 후 다시 시도해주세요.');
            return;
        }
        
        // UI에 즉시 표시
        this.displayMessage({
            type: 'user',
            content: message,
            timestamp: new Date().toISOString()
        });
        
        // WebSocket으로 전송
        this.chatSocket.send(JSON.stringify({
            type: 'message',
            message: message
        }));
        
        // 입력 필드 초기화
        messageInput.value = '';
        messageInput.style.height = 'auto';
        
        // 타이핑 인디케이터 표시
        this.showTypingIndicator('ai');
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
        messageDiv.dataset.messageId = message.id;
        
        const content = this.formatMessageContent(message.content, message.type);
        const timestamp = message.timestamp ? new Date(message.timestamp).toLocaleTimeString() : '';
        
        messageDiv.innerHTML = `
            <div class="message-content">
                ${content}
            </div>
            <div class="message-meta">
                ${timestamp}
                ${this.getMessageActions(message)}
            </div>
        `;
        
        chatMessages.appendChild(messageDiv);
        this.scrollToBottom();
        
        // 타이핑 인디케이터 숨기기
        if (message.type === 'ai') {
            this.hideTypingIndicator();
        }
    }
    
    formatMessageContent(content, type) {
        if (type === 'command' || type === 'result') {
            return `<pre><code>${this.escapeHtml(content)}</code></pre>`;
        }
        
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
    
    getMessageActions(message) {
        let actions = '';
        
        if (message.type === 'ai' && message.metadata) {
            if (message.metadata.type === 'command_ready') {
                actions += `
                    <div class="message-actions">
                        <button class="btn btn-sm btn-success execute-command-btn" 
                                data-command="${this.escapeHtml(message.metadata.command)}">
                            <i class="fas fa-play me-1"></i>실행
                        </button>
                        <button class="btn btn-sm btn-outline-secondary copy-command-btn" 
                                data-command="${this.escapeHtml(message.metadata.command)}">
                            <i class="fas fa-copy me-1"></i>복사
                        </button>
                    </div>
                `;
            }
        }
        
        return actions;
    }
    
    showTypingIndicator(user) {
        const indicator = document.getElementById('typingIndicator');
        indicator.style.display = 'block';
        this.scrollToBottom();
    }
    
    hideTypingIndicator() {
        const indicator = document.getElementById('typingIndicator');
        indicator.style.display = 'none';
    }
    
    handleTypingIndicator(data) {
        if (data.user === 'ai') {
            if (data.is_typing) {
                this.showTypingIndicator('ai');
            } else {
                this.hideTypingIndicator();
            }
        }
    }
    
    createNewSession() {
        const title = document.getElementById('sessionTitle')?.value || '새로운 채팅';
        
        fetch('/api/session/create/', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-CSRFToken': this.getCSRFToken()
            },
            body: JSON.stringify({ title: title })
        })
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                this.currentSessionId = data.session_id;
                this.updateSessionTitle(data.title);
                this.clearMessages();
                this.setupWebSocket();
                this.hideNewSessionModal();
                this.addSessionToList(data);
            } else {
                this.showError(data.error);
            }
        })
        .catch(error => {
            console.error('세션 생성 실패:', error);
            this.showError('세션을 생성할 수 없습니다.');
        });
    }
    
    switchToSession(sessionId) {
        if (this.currentSessionId === sessionId) return;
        
        // 기존 WebSocket 연결 종료
        if (this.chatSocket) {
            this.chatSocket.close();
        }
        
        this.currentSessionId = sessionId;
        this.loadChatHistory(sessionId);
        this.setupWebSocket();
        this.updateActiveSession(sessionId);
    }
    
    loadChatHistory(sessionId) {
        fetch(`/api/session/${sessionId}/`)
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                this.updateSessionTitle(data.session.title);
                this.clearMessages();
                
                data.messages.forEach(message => {
                    this.displayMessage(message);
                });
            } else {
                this.showError(data.error);
            }
        })
        .catch(error => {
            console.error('채팅 히스토리 로드 실패:', error);
            this.showError('채팅 히스토리를 불러올 수 없습니다.');
        });
    }
    
    loadChatSessions() {
        // 이 기능은 서버에서 세션 목록을 가져오는 API가 필요합니다
        // 현재는 페이지 로드시 템플릿에서 렌더링된 세션 목록을 사용합니다
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
                    <h4>XShell AI 챗봇</h4>
                    <p class="text-muted">터미널 명령어 실행, 코드 분석, 시스템 관리 등을 도와드립니다.</p>
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
    
    addSessionToList(sessionData) {
        const sessionList = document.getElementById('chatSessionList');
        const sessionDiv = document.createElement('div');
        sessionDiv.className = 'session-item active';
        sessionDiv.dataset.sessionId = sessionData.session_id;
        sessionDiv.innerHTML = `
            <div class="session-name">${sessionData.title}</div>
            <div class="session-time">방금 전</div>
        `;
        
        // 기존 active 클래스 제거
        document.querySelectorAll('.session-item').forEach(item => {
            item.classList.remove('active');
        });
        
        sessionList.insertBefore(sessionDiv, sessionList.firstChild);
    }
    
    updateConnectionStatus(connected) {
        const statusText = connected ? '연결됨' : '연결 안됨';
        document.getElementById('currentSessionInfo').textContent = 
            `Ollama 기반 오픈소스 AI로 구동됩니다 - ${statusText}`;
    }
    
    processMessageQueue() {
        while (this.messageQueue.length > 0) {
            const message = this.messageQueue.shift();
            this.chatSocket.send(JSON.stringify(message));
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
            aiModel: 'llama3.1:8b',
            temperature: 0.7,
            autoSave: true,
            soundNotifications: false
        };
        
        const saved = localStorage.getItem('xshell_chatbot_settings');
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
            aiModel: document.getElementById('aiModel').value,
            temperature: parseFloat(document.getElementById('temperature').value),
            autoSave: document.getElementById('autoSave').checked,
            soundNotifications: document.getElementById('soundNotifications').checked
        };
        
        localStorage.setItem('xshell_chatbot_settings', JSON.stringify(settings));
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
        document.getElementById('temperature').addEventListener('input', function() {
            document.getElementById('temperatureValue').textContent = this.value;
        });
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
}

// 명령어 실행 관련 함수들
function executeCommand(command, sessionName = 'default') {
    if (!command) return;
    
    fetch('/api/command/execute/', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'X-CSRFToken': chatbot.getCSRFToken()
        },
        body: JSON.stringify({
            command: command,
            session_name: sessionName,
            chat_session_id: chatbot.currentSessionId
        })
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            chatbot.displayMessage({
                type: 'result',
                content: data.result.output,
                timestamp: new Date().toISOString(),
                metadata: {
                    exit_code: data.result.exit_code,
                    execution_time: data.result.execution_time
                }
            });
        } else {
            chatbot.showError(data.error);
        }
    })
    .catch(error => {
        console.error('명령어 실행 실패:', error);
        chatbot.showError('명령어를 실행할 수 없습니다.');
    });
}

function copyToClipboard(text) {
    navigator.clipboard.writeText(text).then(() => {
        chatbot.showSuccess('클립보드에 복사되었습니다.');
    }).catch(err => {
        console.error('복사 실패:', err);
        chatbot.showError('복사에 실패했습니다.');
    });
}

// 이벤트 위임을 사용한 동적 버튼 처리
document.addEventListener('click', function(e) {
    if (e.target.closest('.execute-command-btn')) {
        const command = e.target.closest('.execute-command-btn').dataset.command;
        executeCommand(command);
    }
    
    if (e.target.closest('.copy-command-btn')) {
        const command = e.target.closest('.copy-command-btn').dataset.command;
        copyToClipboard(command);
    }
});

// 페이지 로드시 챗봇 초기화
let chatbot;
document.addEventListener('DOMContentLoaded', function() {
    chatbot = new XShellChatbot();
});

// 페이지 언로드시 WebSocket 연결 정리
window.addEventListener('beforeunload', function() {
    if (chatbot && chatbot.chatSocket) {
        chatbot.chatSocket.close();
    }
});
