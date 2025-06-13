#!/usr/bin/env python3
"""
Windows 유틸리티 스크립트
XShell AI 챗봇의 Windows 특화 기능들
"""

import os
import sys
import subprocess
import platform
import winreg
import psutil
from pathlib import Path
from typing import Dict, List, Optional, Tuple

class WindowsSystemInfo:
    """Windows 시스템 정보 수집"""
    
    @staticmethod
    def get_system_info() -> Dict:
        """시스템 정보 수집"""
        info = {
            'os': platform.system(),
            'os_version': platform.version(),
            'architecture': platform.architecture()[0],
            'processor': platform.processor(),
            'hostname': platform.node(),
            'username': os.getenv('USERNAME'),
            'user_domain': os.getenv('USERDOMAIN'),
            'python_version': platform.python_version(),
        }
        
        # 메모리 정보
        memory = psutil.virtual_memory()
        info['memory_total'] = f"{memory.total / (1024**3):.1f} GB"
        info['memory_available'] = f"{memory.available / (1024**3):.1f} GB"
        info['memory_percent'] = f"{memory.percent}%"
        
        # 디스크 정보
        disk = psutil.disk_usage('C:\\')
        info['disk_total'] = f"{disk.total / (1024**3):.1f} GB"
        info['disk_free'] = f"{disk.free / (1024**3):.1f} GB"
        info['disk_percent'] = f"{(disk.used / disk.total) * 100:.1f}%"
        
        return info
    
    @staticmethod
    def get_installed_software() -> List[Dict]:
        """설치된 소프트웨어 목록"""
        software_list = []
        
        try:
            # 레지스트리에서 설치된 프로그램 정보 가져오기
            reg_paths = [
                r"SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
                r"SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
            ]
            
            for reg_path in reg_paths:
                try:
                    reg_key = winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE, reg_path)
                    
                    for i in range(winreg.QueryInfoKey(reg_key)[0]):
                        try:
                            subkey_name = winreg.EnumKey(reg_key, i)
                            subkey = winreg.OpenKey(reg_key, subkey_name)
                            
                            try:
                                name = winreg.QueryValueEx(subkey, "DisplayName")[0]
                                version = ""
                                try:
                                    version = winreg.QueryValueEx(subkey, "DisplayVersion")[0]
                                except:
                                    pass
                                
                                software_list.append({
                                    'name': name,
                                    'version': version
                                })
                            except:
                                pass
                            
                            winreg.CloseKey(subkey)
                        except:
                            continue
                    
                    winreg.CloseKey(reg_key)
                except:
                    continue
                    
        except Exception as e:
            print(f"소프트웨어 목록 가져오기 실패: {e}")
        
        return software_list
    
    @staticmethod
    def check_required_software() -> Dict[str, bool]:
        """필수 소프트웨어 설치 여부 확인"""
        required = {
            'python': False,
            'redis': False,
            'git': False,
            'ollama': False,
            'xshell': False
        }
        
        # Python 확인
        try:
            subprocess.run(['python', '--version'], capture_output=True, check=True)
            required['python'] = True
        except:
            pass
        
        # Redis 확인
        try:
            subprocess.run(['redis-server', '--version'], capture_output=True, check=True)
            required['redis'] = True
        except:
            pass
        
        # Git 확인
        try:
            subprocess.run(['git', '--version'], capture_output=True, check=True)
            required['git'] = True
        except:
            pass
        
        # Ollama 확인
        try:
            subprocess.run(['ollama', '--version'], capture_output=True, check=True)
            required['ollama'] = True
        except:
            pass
        
        # XShell 확인
        xshell_paths = [
            r"C:\Program Files\NetSarang\Xshell 8\Xshell.exe",
            r"C:\Program Files (x86)\NetSarang\Xshell 8\Xshell.exe",
            r"C:\Program Files\NetSarang\Xshell 7\Xshell.exe",
            r"C:\Program Files (x86)\NetSarang\Xshell 7\Xshell.exe"
        ]
        
        for path in xshell_paths:
            if os.path.exists(path):
                required['xshell'] = True
                break
        
        return required


class WindowsServiceManager:
    """Windows 서비스 관리"""
    
    @staticmethod
    def get_service_status(service_name: str) -> Optional[str]:
        """서비스 상태 확인"""
        try:
            result = subprocess.run(
                ['sc', 'query', service_name],
                capture_output=True,
                text=True
            )
            
            if result.returncode == 0:
                output = result.stdout
                if 'RUNNING' in output:
                    return 'running'
                elif 'STOPPED' in output:
                    return 'stopped'
                else:
                    return 'unknown'
            else:
                return None
        except:
            return None
    
    @staticmethod
    def start_service(service_name: str) -> bool:
        """서비스 시작"""
        try:
            result = subprocess.run(
                ['sc', 'start', service_name],
                capture_output=True,
                text=True
            )
            return result.returncode == 0
        except:
            return False
    
    @staticmethod
    def stop_service(service_name: str) -> bool:
        """서비스 중지"""
        try:
            result = subprocess.run(
                ['sc', 'stop', service_name],
                capture_output=True,
                text=True
            )
            return result.returncode == 0
        except:
            return False


class WindowsRegistryManager:
    """Windows 레지스트리 관리"""
    
    @staticmethod
    def get_registry_value(key_path: str, value_name: str, hive=winreg.HKEY_LOCAL_MACHINE) -> Optional[str]:
        """레지스트리 값 읽기"""
        try:
            key = winreg.OpenKey(hive, key_path)
            value, _ = winreg.QueryValueEx(key, value_name)
            winreg.CloseKey(key)
            return value
        except:
            return None
    
    @staticmethod
    def set_registry_value(key_path: str, value_name: str, value: str, hive=winreg.HKEY_LOCAL_MACHINE) -> bool:
        """레지스트리 값 설정"""
        try:
            key = winreg.CreateKey(hive, key_path)
            winreg.SetValueEx(key, value_name, 0, winreg.REG_SZ, value)
            winreg.CloseKey(key)
            return True
        except:
            return False


class WindowsNetworkManager:
    """Windows 네트워크 관리"""
    
    @staticmethod
    def get_network_interfaces() -> List[Dict]:
        """네트워크 인터페이스 정보"""
        interfaces = []
        
        for interface_name, interface_addresses in psutil.net_if_addrs().items():
            interface_info = {
                'name': interface_name,
                'addresses': []
            }
            
            for addr in interface_addresses:
                if addr.family == 2:  # IPv4
                    interface_info['addresses'].append({
                        'type': 'IPv4',
                        'address': addr.address,
                        'netmask': addr.netmask
                    })
                elif addr.family == 23:  # IPv6
                    interface_info['addresses'].append({
                        'type': 'IPv6',
                        'address': addr.address
                    })
            
            if interface_info['addresses']:
                interfaces.append(interface_info)
        
        return interfaces
    
    @staticmethod
    def test_connectivity(host: str = "8.8.8.8") -> bool:
        """인터넷 연결 테스트"""
        try:
            result = subprocess.run(
                ['ping', '-n', '1', host],
                capture_output=True,
                timeout=5
            )
            return result.returncode == 0
        except:
            return False


def main():
    """메인 함수"""
    print("🖥️ Windows 시스템 정보 수집 중...")
    
    # 시스템 정보
    system_info = WindowsSystemInfo.get_system_info()
    print("\n📊 시스템 정보:")
    for key, value in system_info.items():
        print(f"  {key}: {value}")
    
    # 필수 소프트웨어 확인
    print("\n🔍 필수 소프트웨어 확인:")
    required_software = WindowsSystemInfo.check_required_software()
    for software, installed in required_software.items():
        status = "✅ 설치됨" if installed else "❌ 설치 안됨"
        print(f"  {software}: {status}")
    
    # 네트워크 연결 테스트
    print("\n🌐 네트워크 연결 테스트:")
    connectivity = WindowsNetworkManager.test_connectivity()
    print(f"  인터넷 연결: {'✅ 정상' if connectivity else '❌ 연결 실패'}")
    
    # 서비스 상태 확인
    print("\n🔧 서비스 상태:")
    services = ['Redis', 'W3SVC', 'Spooler']
    for service in services:
        status = WindowsServiceManager.get_service_status(service)
        if status:
            print(f"  {service}: {status}")
        else:
            print(f"  {service}: 서비스 없음")
    
    print("\n✅ 시스템 정보 수집 완료")


if __name__ == "__main__":
    if platform.system().lower() != 'windows':
        print("❌ 이 스크립트는 Windows에서만 실행됩니다.")
        sys.exit(1)
    
    main()
