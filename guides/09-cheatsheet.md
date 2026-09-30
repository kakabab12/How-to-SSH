# 📋 명령어 치트시트

> 자주 쓰는 명령어를 한 장에 모았습니다.
> `lab` = ssh config에 등록한 별칭, `100.x.x.x` = 원격 컴퓨터의 Tailscale IP

[← 전체 목차로 돌아가기](../README.md)

---

## SSH (내 컴퓨터에서)

| 목적 | 명령 |
|---|---|
| 접속 | `ssh 사용자명@100.x.x.x` 또는 `ssh lab` |
| 접속 끝내기 | `exit` (Ubuntu는 `Ctrl + D`도 가능) |
| 키 만들기 | `ssh-keygen -t ed25519 -C "기기이름"` |
| 키 등록 (Ubuntu → Ubuntu) | `ssh-copy-id 사용자명@100.x.x.x` |
| 키 등록 (Windows → Ubuntu) | `type $env:USERPROFILE\.ssh\id_ed25519.pub \| ssh 사용자명@100.x.x.x "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"` |
| 키 등록 (→ Windows) | [01 가이드 4장](01-ubuntu-to-windows.md#key) / [02 가이드 4장](02-windows-to-windows.md#key) 참고 |
| 파일 보내기 | `scp 파일 lab:경로/` |
| 파일 받기 | `scp lab:경로/파일 .` |
| 폴더 보내기 | `scp -r 폴더 lab:경로/` |
| 폴더 동기화 (Ubuntu) | `rsync -avz --progress 폴더/ lab:폴더/` |
| 대화형 파일 전송 | `sftp lab` → `put`, `get`, `cd`, `ls`, `exit` |
| 포트 포워딩 | `ssh -L 8888:localhost:8888 lab` |
| GUI 창 하나 띄우기 (→ Ubuntu) | `ssh -X lab` → `gedit &` |
| 디버그 | `ssh -v lab` |
| 호스트 키 초기화 | `ssh-keygen -R 100.x.x.x` |

## Tailscale

| 목적 | 명령 |
|---|---|
| 내 IP | `tailscale ip -4` |
| 기기 목록 / 상태 | `tailscale status` |
| 연결 테스트 | `tailscale ping 100.x.x.x` |
| 로그인 (Ubuntu) | `sudo tailscale up` |
| ⚠️ 원격에서 절대 금지 | `sudo tailscale down`, `tailscale logout` |

## 바탕화면 원격 접속

| 내 PC → 원격 | 프로그램 | 접속 주소 |
|---|---|---|
| Windows → Windows (Pro 이상) | `Win + R` → `mstsc` | `100.x.x.x` |
| Ubuntu → Windows (Pro 이상) | Remmina (RDP) | `100.x.x.x` |
| Windows → Ubuntu (내장, xrdp) | `mstsc` | `100.x.x.x` |
| Ubuntu → Ubuntu (내장, xrdp) | Remmina (RDP) | `100.x.x.x` |
| 모든 경우 | RustDesk | 원격 ID 칸에 `100.x.x.x` |

## 원격 Windows 관리 (관리자 PowerShell)

| 목적 | 명령 |
|---|---|
| SSH 서버 상태 | `Get-Service sshd` |
| SSH 서버 재시작 | `Restart-Service sshd` |
| 사용자명 | `whoami` |
| 관리자인지 확인 | `net localgroup administrators` |
| SSH 방화벽 규칙 확인 | `Get-NetFirewallRule -Name *OpenSSH-Server*` |
| 절전 끄기 | `powercfg /change standby-timeout-ac 0` |
| 재부팅 | `Restart-Computer` |
| ⚠️ 절대 금지 | `Stop-Computer`, `Stop-Service sshd` |

## 원격 Ubuntu 관리

| 목적 | 명령 |
|---|---|
| SSH 서버 상태 | `systemctl status ssh` |
| SSH 서버 재시작 | `sudo systemctl restart ssh` |
| SSH 로그 실시간 | `sudo journalctl -u ssh -f` |
| 화면 방식 확인 (x11 / wayland) | `echo $XDG_SESSION_TYPE` |
| 방화벽 상태 | `sudo ufw status` |
| 디스크 / 메모리 | `df -h` / `free -h` |
| GPU 확인 | `watch -n 1 nvidia-smi` |
| 재부팅 | `sudo reboot` |
| ⚠️ 절대 금지 | `sudo shutdown now`, `poweroff`, `sudo systemctl stop ssh` |

## tmux (원격 Ubuntu)

| 목적 | 명령 / 키 |
|---|---|
| 새 세션 | `tmux new -s 이름` |
| 빠져나오기 (작업 유지) | `Ctrl + b` → `d` |
| 세션 목록 | `tmux ls` |
| 다시 들어가기 | `tmux attach -t 이름` |
| 세션 종료 | `tmux kill-session -t 이름` |
| 스크롤 | `Ctrl + b` → `[` (끝낼 때 `q`) |

---

[← 전체 목차로 돌아가기](../README.md)
