# 🔧 문제 해결 (트러블슈팅)

> 모든 경우(01~04)에서 생길 수 있는 문제를 **증상별로** 정리했습니다.

[← 전체 목차로 돌아가기](../README.md)

---

## 🔍 먼저 이것부터

**1. 네트워크가 되는지 확인**
```bash
tailscale status               # 원격 기기가 online 인지
tailscale ping 100.x.x.x       # pong 이 오는지
```
- `offline`이거나 ping이 안 되면 → **원격 PC가 꺼졌거나, 잠들었거나, Tailscale이 끊긴 것**입니다. 대부분 현장 확인이 필요합니다.
- ping은 되는데 SSH가 안 되면 → **SSH 서버나 방화벽 문제**입니다. 아래 표를 보세요.

**2. SSH가 어디서 실패하는지 자세히 보기**
```bash
ssh -v 사용자명@100.x.x.x
```

**3. 원격(서버) 쪽 로그 보기** (원격 데스크톱 등으로 들어갈 수 있을 때)
- Ubuntu: `sudo journalctl -u ssh -f` (실시간. 다른 창에서 접속을 시도하면 이유가 찍힘)
- Windows: `이벤트 뷰어` → `응용 프로그램 및 서비스 로그` → `OpenSSH` → `Operational`

---

## 🔌 연결 자체가 안 될 때

| 증상 | 원인 | 해결 |
|---|---|---|
| `Connection timed out` | 원격 PC가 꺼짐, 절전, Tailscale 끊김 | 1) `tailscale status`로 원격 기기가 online인지 확인 2) `tailscale ping 100.x.x.x` 3) 원격 PC 절전 설정 확인 |
| `Connection timed out` (Tailscale ping은 됨) — 원격 Windows | 방화벽이 22번 포트 차단 | 원격 관리자 PowerShell: `Get-NetFirewallRule -Name *OpenSSH-Server*`로 규칙 확인. `Profile`이 `Private`만이면 `Set-NetFirewallRule -Name OpenSSH-Server-In-TCP -Profile Any` |
| `Connection timed out` (Tailscale ping은 됨) — 원격 Ubuntu | ufw가 22번 포트 차단 | `sudo ufw allow ssh` |
| `Connection refused` | SSH 서버가 안 켜져 있음 | Windows: `Get-Service sshd` → `Start-Service sshd` / Ubuntu: `sudo systemctl enable --now ssh` |
| `ssh: Could not resolve hostname` | 기기 이름(MagicDNS)이나 config 별칭 오타 | IP로 직접 접속해 보기, `~/.ssh/config`의 `Host` 이름 확인 |
| `ssh`: 명령을 찾을 수 없음 (Windows) | OpenSSH 클라이언트 미설치 | `설정` → `시스템` → `선택적 기능` → **OpenSSH 클라이언트** 설치 |
| 몇 달 뒤 갑자기 모든 접속이 안 됨 | Tailscale 키 만료 | 원격 PC에서 Tailscale 다시 로그인 → 관리 콘솔에서 **Disable key expiry** ([00-tailscale.md](00-tailscale.md#key-expiry)) |
| 가만히 두면 연결이 끊김 | 유휴 연결 끊김 | ssh config에 `ServerAliveInterval 60` 추가 ([05-tips.md](05-tips.md#ssh-config)) |
| 매우 느림 | Tailscale이 중계 서버 경유 | `tailscale status`에서 `relay`로 나오면 학교 방화벽 때문. 원격 데스크톱 해상도를 낮추거나 SSH 위주로 작업 |

---

## 🔑 로그인이 안 될 때

| 증상 | 원인 | 해결 |
|---|---|---|
| `Permission denied (password)` — 원격 Windows | 사용자명이나 비밀번호 오류 | 원격에서 `whoami`로 사용자명 재확인 / Microsoft 계정이면 **PIN 아니라 MS 계정 비밀번호** / `로그인 옵션`의 **Windows Hello 전용 로그인** 끄기 / 원격 PC에서 한 번 **비밀번호로** 로그인해 보기 |
| `Permission denied (password)` — 원격 Ubuntu | 사용자명이나 비밀번호 오류 | 원격에서 `whoami` 확인. 대소문자 확인 |
| `Permission denied (publickey)` — 원격 Windows | 관리자 계정인데 키를 `~\.ssh\authorized_keys`에 넣음 / 파일 권한 문제 | 관리자는 **`C:\ProgramData\ssh\administrators_authorized_keys`** 에 넣고 **`icacls`** 로 권한 설정 ([01 가이드 4장](01-ubuntu-to-windows.md#key)) |
| `Permission denied (publickey)` — 원격 Ubuntu | `~/.ssh` 권한이 너무 넓음 | 원격에서 `chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys && chmod go-w ~` |
| `Permission denied (publickey)` — 비밀번호 로그인을 끈 뒤 | 이 기기의 키가 등록 안 됨 | 등록된 다른 기기나 원격 데스크톱으로 들어가서 이 기기의 공개키 추가 |
| 키 등록했는데 계속 비밀번호를 물어봄 | 다른 키 파일을 쓰고 있거나 등록 실패 | ssh config에 `IdentityFile ~/.ssh/id_ed25519` 명시 / `ssh -v`로 어떤 키를 시도하는지 확인 / 원격의 `authorized_keys`에 내 키가 있는지 확인 |
| 키 passphrase를 매번 물어봄 | ssh-agent 미사용 | [06-security.md](06-security.md) 3번의 ssh-agent 설정 |
| `WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!` | 원격 PC를 포맷, 재설치했거나 IP가 다른 기기로 넘어감 | 이유를 알고 있다면 `ssh-keygen -R 100.x.x.x` 후 다시 접속. **이유를 모르면 접속하지 말고 확인부터 하세요.** |
| `Bad owner or permissions on ~/.ssh/config` (Ubuntu) | config 파일 권한 | `chmod 600 ~/.ssh/config` |

---

## 🖥️ 원격 데스크톱 문제

### 원격이 Windows

| 증상 | 원인 | 해결 |
|---|---|---|
| RDP: "원격 컴퓨터에 연결할 수 없습니다" | Home 에디션 / RDP 꺼짐 / 방화벽 | 에디션 확인 → Home이면 RustDesk. `설정 → 시스템 → 원격 데스크톱` 켜기 |
| RDP: "자격 증명이 작동하지 않았습니다" | Microsoft 계정 문제 | 사용자 이름을 `MicrosoftAccount\이메일@example.com` 형식으로 입력 / 원격 PC에서 비밀번호로 한 번 로그인 / Windows Hello 전용 옵션 끄기 |
| RDP: 연결했더니 연구실 사람이 쫓겨남 | RDP는 한 번에 한 명만 사용 | 정상 동작. 공용 PC라면 RustDesk를 쓰거나 미리 알리기 |
| RDP: 작업하던 프로그램이 다 꺼짐 | "로그아웃"으로 나옴 / Windows 업데이트 재시작 | 나올 때는 **창 닫기(연결 끊기)**. 업데이트 사용 시간 설정 |
| Remmina(Ubuntu) → Windows: 화면이 깨짐 | 색상 설정 | 프로필 편집 → Colour depth → `True colour (24 bpp)` |

### 원격이 Ubuntu

| 증상 | 원인 | 해결 |
|---|---|---|
| RustDesk: 검은 화면, 연결 거부 | Wayland 사용 중 | 원격에서 `echo $XDG_SESSION_TYPE` → `wayland`이면 Xorg로 전환 ([03 가이드](03-ubuntu-to-ubuntu.md#xorg)) |
| RustDesk: 재부팅 후 접속 안 됨 | 로그인 화면에 멈춰 있음 | **자동 로그인** 켜기 |
| 내장 원격 데스크톱: 재부팅 후 비밀번호가 바뀜 | 자동 로그인으로 키링이 잠김 | `암호 및 키` 앱에서 로그인 키링 비밀번호를 빈칸으로 ([03 가이드 2-4 B](03-ubuntu-to-ubuntu.md#ubuntu-desktop)) |
| 내장 원격 데스크톱: 접속 안 됨 | 화면 잠김 / 로그아웃 상태 | 자동 화면 잠금 끄기, 로그인 상태 유지 |
| 내장 원격 데스크톱: 연결되자마자 끊김 (Remmina) | 색상 설정 호환 문제 | 프로필 편집 → Colour depth를 다른 값으로 |
| xrdp: 로그인 후 검은 화면, 바로 튕김 | 같은 계정이 원격 PC에 로그인 중 | 원격 PC에서 **로그아웃** 후 다시 접속 |
| 3389 포트 충돌 | 내장 원격 데스크톱과 xrdp를 동시에 켬 | 하나만 켜기 |

### 공통

| 증상 | 해결 |
|---|---|
| RustDesk: "연결할 수 없음" | 원격 RustDesk에서 **IP 직접 접속 허용**이 켜져 있는지 / Windows면 **정식 설치**했는지 / Tailscale ping이 되는지 확인 |
| 화면이 느림, 끊김 | 해상도, 색상 깊이 낮추기 / `tailscale status`에서 `direct` 연결인지 확인 |

---

## 📁 파일 전송 문제

| 증상 | 해결 |
|---|---|
| Windows 경로를 못 찾음 | `scp`의 Windows 경로는 사용자 폴더 기준 **슬래시(/)** 로 적기: `win:Documents/file.txt` |
| 경로에 공백, 한글이 있어서 실패 | `sftp`로 접속해서 `cd "OneDrive/바탕 화면"` 처럼 따옴표 사용, 또는 WinSCP나 VS Code 사용 |
| Windows에서 옮긴 스크립트가 Ubuntu에서 `\r: command not found` | `dos2unix 파일.sh` 또는 VS Code에서 줄바꿈을 `LF`로 변경 |
| 큰 파일 전송이 중간에 끊김 | `rsync -avz --progress --partial`로 다시 실행하면 이어서 전송 (Ubuntu ↔ Ubuntu) |

---

[← 전체 목차로 돌아가기](../README.md)
