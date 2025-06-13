import os
import subprocess
import time
import json
import logging
import threading
import platform
from typing import Dict, List, Optional, Generator
from django.conf import settings
import paramiko

# Windows 호환성을 위한 조건부 import
try:
    import pexpect
    from pexpect import pxssh
    PEXPECT_AVAILABLE = True
except ImportError:
    # Windows 환경에서는 pexpect 사용 불가
    PEXPECT_AVAILABLE = False
    pexpect = None
    pxssh = None

from chatbot.models import XShellSession, CommandHistory

logger = logging.getLogger('xshell_chatbot')


class WindowsShellService:
    """Windows 기본 Shell 서비스"""
    
    def __init__(self):
        self.is_windows = platform.system().lower() == 'windows'
        self.shell_type = 'powershell'  # 기본값: PowerShell
        
    def execute_command(self, command: str, shell_type: str = None) -> Dict[str, any]:
        """Windows에서 명령어 실행"""
        start_time = time.time()
        
        if not self.is_windows:
            return {
                'success': False,
                'output': 'Windows가 아닌 환경에서는 Windows Shell을 사용할 수 없습니다.',
                'error': 'Not Windows OS',
                'exit_code': -1,
                'execution_time': 0
            }
        
        shell_type = shell_type or self.shell_type
        
        try:
            # 위험한 명령어 체크
            if self.is_dangerous_command(command):
                return {
                    'success': False,
                    'output': f'보안상 위험한 명령어는 실행할 수 없습니다: {command}',
                    'error': 'Dangerous command blocked',
                    'exit_code': -1,
                    'execution_time': 0
                }
            
            # Shell 타입에 따른 명령어 실행
            if shell_type.lower() == 'powershell':
                return self._execute_powershell(command, start_time)
            elif shell_type.lower() in ['cmd', 'command']:
                return self._execute_cmd(command, start_time)
            else:
                return self._execute_cmd(command, start_time)  # 기본값
                
        except Exception as e:
            return {
                'success': False,
                'output': f'명령어 실행 중 오류가 발생했습니다: {str(e)}',
                'error': str(e),
                'exit_code': -1,
                'execution_time': time.time() - start_time
            }
    
    def _execute_powershell(self, command: str, start_time: float) -> Dict[str, any]:
        """PowerShell 명령어 실행"""
        try:
            # PowerShell 명령어 구성
            ps_command = ['powershell', '-Command', command]
            
            result = subprocess.run(
                ps_command,
                capture_output=True,
                text=True,
                timeout=60,  # 60초 타임아웃
                encoding='utf-8',
                errors='replace'
            )
            
            execution_time = time.time() - start_time
            
            return {
                'success': result.returncode == 0,
                'output': result.stdout + (result.stderr if result.returncode != 0 else ''),
                'error': result.stderr if result.returncode != 0 else '',
                'exit_code': result.returncode,
                'execution_time': execution_time,
                'shell_type': 'PowerShell'
            }
            
        except subprocess.TimeoutExpired:
            return {
                'success': False,
                'output': '명령어 실행 시간이 초과되었습니다 (60초)',
                'error': 'Command timeout',
                'exit_code': -1,
                'execution_time': 60,
                'shell_type': 'PowerShell'
            }
    
    def _execute_cmd(self, command: str, start_time: float) -> Dict[str, any]:
        """Command Prompt 명령어 실행"""
        try:
            # CMD 명령어 구성
            cmd_command = ['cmd', '/c', command]
            
            result = subprocess.run(
                cmd_command,
                capture_output=True,
                text=True,
                timeout=60,
                encoding='cp949',  # Windows 기본 인코딩
                errors='replace'
            )
            
            execution_time = time.time() - start_time
            
            return {
                'success': result.returncode == 0,
                'output': result.stdout + (result.stderr if result.returncode != 0 else ''),
                'error': result.stderr if result.returncode != 0 else '',
                'exit_code': result.returncode,
                'execution_time': execution_time,
                'shell_type': 'Command Prompt'
            }
            
        except subprocess.TimeoutExpired:
            return {
                'success': False,
                'output': '명령어 실행 시간이 초과되었습니다 (60초)',
                'error': 'Command timeout',
                'exit_code': -1,
                'execution_time': 60,
                'shell_type': 'Command Prompt'
            }
    
    def execute_command_stream(self, command: str, shell_type: str = None) -> Generator[str, None, None]:
        """스트리밍 방식으로 Windows 명령어 실행"""
        if not self.is_windows:
            yield "Windows가 아닌 환경에서는 Windows Shell을 사용할 수 없습니다."
            return
            
        shell_type = shell_type or self.shell_type
        
        try:
            if self.is_dangerous_command(command):
                yield f"보안상 위험한 명령어는 실행할 수 없습니다: {command}"
                return
            
            # Shell 타입에 따른 명령어 구성
            if shell_type.lower() == 'powershell':
                cmd = ['powershell', '-Command', command]
                encoding = 'utf-8'
            else:
                cmd = ['cmd', '/c', command]
                encoding = 'cp949'
            
            process = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                bufsize=1,
                universal_newlines=True,
                encoding=encoding,
                errors='replace'
            )
            
            # 실시간 출력 스트리밍
            for line in iter(process.stdout.readline, ''):
                yield line.rstrip('\n\r')
            
            process.wait()
            
            if process.returncode != 0:
                yield f"\n명령어가 오류 코드 {process.returncode}로 종료되었습니다."
                
        except Exception as e:
            yield f"Error: {str(e)}"
    
    def is_dangerous_command(self, command: str) -> bool:
        """Windows 위험한 명령어 체크"""
        dangerous_patterns = [
            'format c:',
            'del c:\\',
            'rmdir /s c:',
            'rd /s c:',
            'diskpart',
            'shutdown /r /f',
            'shutdown /s /f',
            'net user administrator',
            'reg delete hklm',
            'bcdedit',
            'attrib -r -s -h c:\\',
            'takeown /f c:\\',
            'icacls c:\\ /grant',
        ]
        
        command_lower = command.lower()
        return any(pattern in command_lower for pattern in dangerous_patterns)


class XShellService:
    """XShell 및 Windows Shell 통합 서비스"""
    
    def __init__(self):
        self.xshell_path = getattr(settings, 'XSHELL_PATH', '')
        self.sessions_path = getattr(settings, 'XSHELL_SESSIONS_PATH', '')
        self.active_connections = {}  # 활성 SSH 연결 저장
        self.is_windows = platform.system().lower() == 'windows'
        self.windows_shell = WindowsShellService() if self.is_windows else None
        
    def execute_command(self, command: str, session_name: str = 'default', shell_type: str = None) -> Dict[str, any]:
        """명령어 실행 - 자동으로 적절한 shell 선택"""
        
        try:
            # Windows 로컬 실행인지 확인
            if session_name == 'default' or session_name == 'local':
                if self.is_windows:
                    # Windows 기본 shell 사용
                    return self.windows_shell.execute_command(command, shell_type)
                else:
                    # Linux/macOS 로컬 실행
                    return self.execute_local_command(command)
            
            # XShell 세션 정보 가져오기
            xshell_session = self.get_xshell_session(session_name)
            
            if not xshell_session:
                # 세션이 없으면 로컬에서 실행
                if self.is_windows:
                    return self.windows_shell.execute_command(command, shell_type)
                else:
                    return self.execute_local_command(command)
            
            # SSH 연결을 통한 원격 실행
            return self.execute_remote_command(command, xshell_session)
            
        except Exception as e:
            logger.error(f"명령어 실행 실패: {e}")
            return {
                'success': False,
                'output': f'오류: {str(e)}',
                'error': str(e),
                'exit_code': -1,
                'execution_time': 0
            }
    
    def execute_local_command(self, command: str) -> Dict[str, any]:
        """로컬 명령어 실행 - OS 자동 감지"""
        
        start_time = time.time()
        
        try:
            # 위험한 명령어 체크
            if self.is_dangerous_command(command):
                return {
                    'success': False,
                    'output': f'보안상 위험한 명령어는 실행할 수 없습니다: {command}',
                    'error': 'Dangerous command blocked',
                    'exit_code': -1,
                    'execution_time': 0
                }
            
            # Windows인 경우 Windows Shell 서비스 사용
            if self.is_windows:
                return self.windows_shell.execute_command(command)
            
            # Linux/macOS 명령어 실행
            result = subprocess.run(
                command,
                shell=True,
                capture_output=True,
                text=True,
                timeout=60  # 60초 타임아웃
            )
            
            execution_time = time.time() - start_time
            
            return {
                'success': result.returncode == 0,
                'output': result.stdout + result.stderr,
                'error': result.stderr if result.returncode != 0 else '',
                'exit_code': result.returncode,
                'execution_time': execution_time,
                'shell_type': 'bash/sh'
            }
            
        except subprocess.TimeoutExpired:
            return {
                'success': False,
                'output': '명령어 실행 시간이 초과되었습니다 (60초)',
                'error': 'Command timeout',
                'exit_code': -1,
                'execution_time': 60
            }
        except Exception as e:
            return {
                'success': False,
                'output': f'명령어 실행 중 오류가 발생했습니다: {str(e)}',
                'error': str(e),
                'exit_code': -1,
                'execution_time': time.time() - start_time
            }
    
    def execute_remote_command(self, command: str, xshell_session: XShellSession) -> Dict[str, any]:
        """원격 SSH 명령어 실행"""
        
        start_time = time.time()
        
        try:
            # SSH 연결 가져오기 또는 생성
            ssh_client = self.get_ssh_connection(xshell_session)
            
            if not ssh_client:
                return {
                    'success': False,
                    'output': f'SSH 연결에 실패했습니다: {xshell_session.host}',
                    'error': 'SSH connection failed',
                    'exit_code': -1,
                    'execution_time': 0
                }
            
            # 명령어 실행
            stdin, stdout, stderr = ssh_client.exec_command(command, timeout=30)
            
            # 결과 읽기
            output_lines = []
            error_lines = []
            
            # stdout 읽기
            for line in stdout:
                output_lines.append(line.rstrip('\n'))
            
            # stderr 읽기
            for line in stderr:
                error_lines.append(line.rstrip('\n'))
            
            exit_code = stdout.channel.recv_exit_status()
            execution_time = time.time() - start_time
            
            output = '\n'.join(output_lines)
            error = '\n'.join(error_lines)
            
            # 히스토리 저장
            self.save_command_history(xshell_session, command, output, exit_code, execution_time)
            
            return {
                'success': exit_code == 0,
                'output': output + ('\n' + error if error else ''),
                'error': error if exit_code != 0 else '',
                'exit_code': exit_code,
                'execution_time': execution_time
            }
            
        except Exception as e:
            logger.error(f"원격 명령어 실행 실패: {e}")
            return {
                'success': False,
                'output': f'원격 명령어 실행 중 오류가 발생했습니다: {str(e)}',
                'error': str(e),
                'exit_code': -1,
                'execution_time': time.time() - start_time
            }
    
    def execute_command_stream(self, command: str, session_name: str = 'default', shell_type: str = None) -> Generator[str, None, None]:
        """스트리밍 방식으로 명령어 실행 (실시간 출력)"""
        
        try:
            # Windows 로컬 실행인지 확인
            if session_name == 'default' or session_name == 'local':
                if self.is_windows:
                    # Windows 기본 shell 사용
                    yield from self.windows_shell.execute_command_stream(command, shell_type)
                    return
                else:
                    # Linux/macOS 로컬 실행
                    yield from self.execute_local_command_stream(command)
                    return
            
            # XShell 세션 정보 가져오기
            xshell_session = self.get_xshell_session(session_name)
            
            if not xshell_session:
                # 세션이 없으면 로컬에서 실행
                if self.is_windows:
                    yield from self.windows_shell.execute_command_stream(command, shell_type)
                else:
                    yield from self.execute_local_command_stream(command)
            else:
                # 원격 스트리밍 실행
                yield from self.execute_remote_command_stream(command, xshell_session)
                
        except Exception as e:
            yield f"Error: {str(e)}"
    
    def execute_local_command_stream(self, command: str) -> Generator[str, None, None]:
        """로컬 명령어 스트리밍 실행 - OS 자동 감지"""
        
        try:
            if self.is_dangerous_command(command):
                yield f"보안상 위험한 명령어는 실행할 수 없습니다: {command}"
                return
            
            # Windows인 경우 Windows Shell 서비스 사용
            if self.is_windows:
                yield from self.windows_shell.execute_command_stream(command)
                return
            
            # Linux/macOS 스트리밍 실행
            process = subprocess.Popen(
                command,
                shell=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                bufsize=1,
                universal_newlines=True
            )
            
            # 실시간 출력 스트리밍
            for line in iter(process.stdout.readline, ''):
                yield line.rstrip('\n')
            
            process.wait()
            
            if process.returncode != 0:
                yield f"\n명령어가 오류 코드 {process.returncode}로 종료되었습니다."
                
        except Exception as e:
            yield f"Error: {str(e)}"
    
    def execute_remote_command_stream(self, command: str, xshell_session: XShellSession) -> Generator[str, None, None]:
        """원격 SSH 명령어 스트리밍 실행"""
        
        try:
            # Windows에서는 pexpect가 없으므로 기본 SSH 클라이언트 사용
            if not PEXPECT_AVAILABLE:
                yield "Windows 환경에서는 실시간 스트리밍이 제한됩니다."
                yield "기본 명령어 실행을 사용합니다..."
                
                # 기본 execute_remote_command 사용
                result = self.execute_remote_command(command, xshell_session)
                
                if result['success']:
                    # 출력을 줄 단위로 나누어 스트리밍 효과 연출
                    lines = result['output'].split('\n')
                    for line in lines:
                        if line.strip():
                            yield line
                        time.sleep(0.1)  # 약간의 지연으로 스트리밍 느낌
                else:
                    yield f"Error: {result['error']}"
                return
            
            # pexpect를 사용한 실시간 SSH 실행 (Linux/macOS에서만)
            ssh_command = f"ssh {xshell_session.username}@{xshell_session.host}"
            
            child = pexpect.spawn(ssh_command)
            child.logfile = None  # 로그 비활성화
            
            # 패스워드 프롬프트 처리 (필요시)
            index = child.expect(['password:', 'Password:', pexpect.TIMEOUT], timeout=10)
            
            if index in [0, 1]:
                # 패스워드 입력 (실제로는 암호화된 패스워드 복호화 필요)
                if xshell_session.password_encrypted:
                    decrypted_password = self.decrypt_password(xshell_session.password_encrypted)
                    child.sendline(decrypted_password)
                    child.expect(['$', '#', '>', pexpect.TIMEOUT], timeout=10)
            
            # 명령어 실행
            child.sendline(command)
            
            # 실시간 출력 읽기
            while True:
                try:
                    index = child.expect(['\n', pexpect.TIMEOUT], timeout=1)
                    if index == 0:
                        output = child.before.decode('utf-8', errors='ignore')
                        if output.strip():
                            yield output.strip()
                    else:
                        break
                except pexpect.EOF:
                    break
            
            child.close()
            
        except Exception as e:
            yield f"Error: {str(e)}"
    
    def get_ssh_connection(self, xshell_session: XShellSession) -> Optional[paramiko.SSHClient]:
        """SSH 연결 가져오기 또는 생성"""
        
        connection_key = f"{xshell_session.host}_{xshell_session.username}"
        
        # 기존 연결 확인
        if connection_key in self.active_connections:
            ssh_client = self.active_connections[connection_key]
            try:
                # 연결 상태 확인
                ssh_client.exec_command('echo test', timeout=5)
                return ssh_client
            except:
                # 연결이 끊어진 경우 제거
                del self.active_connections[connection_key]
        
        # 새로운 연결 생성
        try:
            ssh_client = paramiko.SSHClient()
            ssh_client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
            
            # 인증 방법 결정
            if xshell_session.private_key_path and os.path.exists(xshell_session.private_key_path):
                # 키 기반 인증
                ssh_client.connect(
                    hostname=xshell_session.host,
                    port=xshell_session.port,
                    username=xshell_session.username,
                    key_filename=xshell_session.private_key_path,
                    timeout=10
                )
            elif xshell_session.password_encrypted:
                # 패스워드 인증
                decrypted_password = self.decrypt_password(xshell_session.password_encrypted)
                ssh_client.connect(
                    hostname=xshell_session.host,
                    port=xshell_session.port,
                    username=xshell_session.username,
                    password=decrypted_password,
                    timeout=10
                )
            else:
                logger.error(f"SSH 인증 정보가 없습니다: {xshell_session.name}")
                return None
            
            # 연결 저장
            self.active_connections[connection_key] = ssh_client
            
            # 세션 상태 업데이트
            xshell_session.is_connected = True
            xshell_session.save()
            
            return ssh_client
            
        except Exception as e:
            logger.error(f"SSH 연결 실패: {e}")
            xshell_session.is_connected = False
            xshell_session.save()
            return None
    
    def get_xshell_session(self, session_name: str) -> Optional[XShellSession]:
        """XShell 세션 정보 가져오기"""
        try:
            return XShellSession.objects.get(name=session_name)
        except XShellSession.DoesNotExist:
            return None
    
    def create_xshell_session(self, name: str, host: str, username: str, 
                             password: str = '', private_key_path: str = '', 
                             port: int = 22) -> XShellSession:
        """XShell 세션 생성"""
        
        # 패스워드 암호화 (간단한 예시, 실제로는 더 강력한 암호화 사용)
        encrypted_password = self.encrypt_password(password) if password else ''
        
        session = XShellSession.objects.create(
            name=name,
            host=host,
            port=port,
            username=username,
            password_encrypted=encrypted_password,
            private_key_path=private_key_path
        )
        
        return session
    
    def test_xshell_session(self, session_name: str) -> Dict[str, any]:
        """XShell 세션 연결 테스트"""
        
        xshell_session = self.get_xshell_session(session_name)
        
        if not xshell_session:
            return {
                'success': False,
                'message': f'세션을 찾을 수 없습니다: {session_name}'
            }
        
        ssh_client = self.get_ssh_connection(xshell_session)
        
        if ssh_client:
            try:
                # 간단한 테스트 명령어 실행
                stdin, stdout, stderr = ssh_client.exec_command('whoami', timeout=5)
                result = stdout.read().decode('utf-8').strip()
                
                return {
                    'success': True,
                    'message': f'연결 성공: {result}@{xshell_session.host}'
                }
            except Exception as e:
                return {
                    'success': False,
                    'message': f'연결 테스트 실패: {str(e)}'
                }
        else:
            return {
                'success': False,
                'message': f'SSH 연결 실패: {xshell_session.host}'
            }
    
    def interrupt_command(self, session_name: str):
        """실행 중인 명령어 중단"""
        # 실제 구현에서는 프로세스 ID 추적 및 시그널 전송
        pass
    
    def is_dangerous_command(self, command: str) -> bool:
        """위험한 명령어 체크 - OS별 위험 명령어 포함"""
        
        # Windows 위험한 명령어
        windows_dangerous = [
            'format c:',
            'del c:\\',
            'rmdir /s c:',
            'rd /s c:',
            'diskpart',
            'shutdown /r /f',
            'shutdown /s /f',
            'net user administrator',
            'reg delete hklm',
            'bcdedit',
            'attrib -r -s -h c:\\',
            'takeown /f c:\\',
            'icacls c:\\ /grant',
        ]
        
        # Linux/Unix 위험한 명령어
        unix_dangerous = [
            'rm -rf /',
            'dd if=',
            'mkfs',
            'fdisk',
            'format',
            '> /dev/',
            'chmod 000',
            'chown -R',
            'shutdown',
            'reboot',
            'halt',
            'init 0',
            'init 6',
            'rm -rf *',
            ':(){ :|:& };:',  # Fork bomb
        ]
        
        command_lower = command.lower()
        
        # OS별 위험 명령어 체크
        if self.is_windows:
            dangerous_patterns = windows_dangerous + unix_dangerous
        else:
            dangerous_patterns = unix_dangerous + windows_dangerous
        
        return any(pattern in command_lower for pattern in dangerous_patterns)
    
    def encrypt_password(self, password: str) -> str:
        """패스워드 암호화 (간단한 예시)"""
        # 실제로는 더 강력한 암호화 방법 사용
        import base64
        return base64.b64encode(password.encode()).decode()
    
    def decrypt_password(self, encrypted_password: str) -> str:
        """패스워드 복호화 (간단한 예시)"""
        # 실제로는 더 강력한 복호화 방법 사용
        import base64
        return base64.b64decode(encrypted_password.encode()).decode()
    
    def save_command_history(self, xshell_session: XShellSession, command: str, 
                           result: str, exit_code: int, execution_time: float):
        """명령어 히스토리 저장"""
        try:
            CommandHistory.objects.create(
                xshell_session=xshell_session,
                command=command,
                result=result,
                exit_code=exit_code,
                execution_time=execution_time
            )
        except Exception as e:
            logger.error(f"명령어 히스토리 저장 실패: {e}")
    
    def get_command_history(self, session_name: str, limit: int = 20) -> List[Dict]:
        """명령어 히스토리 조회"""
        try:
            xshell_session = self.get_xshell_session(session_name)
            if not xshell_session:
                return []
            
            history = CommandHistory.objects.filter(
                xshell_session=xshell_session
            ).order_by('-timestamp')[:limit]
            
            return [
                {
                    'command': h.command,
                    'result': h.result[:500],  # 결과는 500자로 제한
                    'exit_code': h.exit_code,
                    'execution_time': h.execution_time,
                    'timestamp': h.timestamp.isoformat()
                }
                for h in history
            ]
        except Exception as e:
            logger.error(f"명령어 히스토리 조회 실패: {e}")
            return []
