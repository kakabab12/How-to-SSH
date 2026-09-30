# 🐧 Ubuntu → 🪟 Windows 원격 접속 가이드

> **내 컴퓨터(노트북, 집 PC)가 Ubuntu**이고, **원격 컴퓨터(연구실 PC)가 Windows**인 경우입니다.
> 이 파일 하나만 위에서부터 순서대로 따라 하면 **SSH**와 **바탕화면 원격 접속**이 모두 설정됩니다.

> 🐣 **컴퓨터가 익숙하지 않다면** 이 문서 대신 **[쉬운 가이드](../easy/01-ubuntu-to-windows.md)** 를 먼저 따라 하세요. 이 문서는 여러 방법을 비교하는 자세한 버전입니다.

[← 전체 목차로 돌아가기](../README.md)

---

## 🖥️ 이 가이드로 할 수 있는 것

| 방법 | 보이는 것 | 연구실 모니터 화면이 그대로 보이나? | 조건 |
|---|---|---|---|
| **SSH** | 터미널(명령어 창)만 | ❌ 화면은 안 보임 | Windows 모든 에디션 |
| **RDP (Remmina)** | 바탕화면 전체 | ✅ 열어 둔 창이 그대로 보임 (대신 연구실 모니터는 **잠금 화면**이 됨) | 원격 Windows가 **Pro / Education / Enterprise** |
| **RustDesk** | 바탕화면 전체 | ✅ **완전히 똑같은 화면** (연구실 모니터에도 내 조작이 그대로 보임) | Windows 모든 에디션 (Home 포함) |

> **표기 규칙**
> - `100.x.x.x` = 원격 Windows의 **Tailscale IP**, `사용자명` = 원격 Windows **계정 이름**
> - 🐧 = **내 Ubuntu** 터미널 (`Ctrl + Alt + T`)
> - 🪟 = **원격 Windows**의 PowerShell (관리자 PowerShell = 시작 버튼 우클릭 → `터미널(관리자)`)

---

## 📚 목차

1. [Tailscale 설치 (두 컴퓨터 모두)](#tailscale)
2. [원격 Windows 설정 (연구실에서 한 번만)](#remote-setup)
3. [SSH로 접속하기](#ssh)
4. [비밀번호 없이 접속하기 (SSH 키)](#key)
5. [짧은 이름으로 접속하기 (ssh config)](#config)
6. [🖥️ 바탕화면 보기 (Remmina / RustDesk)](#desktop)
7. [파일 주고받기](#files)
8. [✅ 설정 완료 점검표](#checklist)
9. [⚠️ 이 경우의 주의사항](#cautions)
10. [🔧 자주 생기는 문제](#troubleshooting)

---

<a id="tailscale"></a>
## 1. Tailscale 설치 (두 컴퓨터 모두)

학교 방화벽 뒤에 있는 연구실 PC에 접속하기 위해 **Tailscale**(무료 VPN)을 씁니다. **두 컴퓨터 모두 같은 계정으로 로그인**해야 합니다.
자세한 설명은 [00-tailscale.md](00-tailscale.md)를 참고하세요.

### 1-1. 🪟 원격 Windows (연구실 PC)

1. https://tailscale.com/download/windows 에서 설치 파일을 받아 실행합니다.
2. 작업 표시줄 오른쪽 아래 Tailscale 아이콘 → **Log in** → 브라우저에서 로그인합니다. (Google, Microsoft, GitHub 계정 중 선택)
3. Tailscale 아이콘 → **Settings(설정)** → ✅ **Run unattended**
   → Windows에 로그인하기 전(재부팅 직후)에도 Tailscale이 연결됩니다.
4. IP를 확인하고 **메모**합니다.
   ```powershell
   tailscale ip -4
   ```

### 1-2. 🐧 내 Ubuntu

```bash
sudo apt install -y curl                           # curl 이 없으면 설치 (새로 설치한 우분투에는 없음)
curl -fsSL https://tailscale.com/install.sh | sh   # 설치
sudo tailscale up                                  # 출력되는 URL을 브라우저로 열어 "같은 계정"으로 로그인
tailscale status                                   # 원격 Windows가 목록에 보이면 OK
```

### 1-3. ⚠️ 원격 Windows의 "키 만료" 끄기

Tailscale은 기본적으로 약 180일마다 재로그인을 요구합니다. 연구실 PC가 어느 날 갑자기 끊기지 않도록 꺼 두세요.

1. https://login.tailscale.com/admin/machines 에 접속합니다.
2. 원격 Windows 줄 오른쪽의 `...` → **Disable key expiry**를 누릅니다.

### 1-4. 연결 테스트

```bash
tailscale ping 100.x.x.x      # "pong from ..." 이 나오면 성공
```

---

<a id="remote-setup"></a>
## 2. 원격 Windows 설정 (연구실에서 한 번만)

> 이 장은 모두 **연구실 Windows PC 앞에서** 합니다.

<a id="win-check"></a>
### 2-1. 먼저 확인할 것

#### ① Windows 에디션
`설정` → `시스템` → `정보` → `Windows 사양` → **에디션**

| 에디션 | SSH | RDP로 바탕화면 보기 | RustDesk로 바탕화면 보기 |
|---|---|---|---|
| Pro / Education / Enterprise | ✅ | ✅ | ✅ |
| **Home** | ✅ | ❌ | ✅ ← Home이면 이것만 가능 |

#### ② 사용자 이름
```powershell
whoami
# 출력 예: desktop-abc123\hong  →  사용자명은 역슬래시 뒤의 "hong"
```

#### ③ Microsoft 계정인지 (이메일로 로그인하는지)
- Microsoft 계정이면 SSH와 RDP 비밀번호는 **PIN이 아니라 Microsoft 계정 비밀번호**입니다.
- `설정` → `계정` → `로그인 옵션` → **"보안 향상을 위해 이 장치의 Microsoft 계정에 대해 Windows Hello 로그인만 허용"** 을 **끕니다.**
- 끈 뒤 **한 번 로그아웃했다가 PIN 말고 비밀번호로 로그인**해 두세요. 이렇게 해야 원격 로그인 문제가 줄어듭니다.

#### ④ 관리자 계정인지
```powershell
net localgroup administrators
```
목록에 내 사용자명이 있으면 **관리자**입니다. 개인 PC는 대부분 관리자입니다. [4장 키 등록](#key)에서 필요합니다.

### 2-2. OpenSSH 서버 설치

**방법 A — 설정 앱**
`설정` → `시스템` → `선택적 기능` → `기능 보기` → **"OpenSSH 서버"** 검색 → 체크 → 설치

**방법 B — 🪟 관리자 PowerShell**
```powershell
Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH*'   # 설치 상태 확인
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0        # 서버 설치
```

### 2-3. SSH 서비스 시작 + 자동 시작 (🪟 관리자 PowerShell)

```powershell
Start-Service sshd
Set-Service -Name sshd -StartupType Automatic
Get-Service sshd        # Status 가 Running 이면 성공
```

### 2-4. 방화벽 확인 (🪟 관리자 PowerShell)

```powershell
Get-NetFirewallRule -Name *OpenSSH-Server* | Select-Object Name, Enabled, Profile
```
아무것도 안 나오면 규칙을 만듭니다.
```powershell
New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' `
  -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
```

### 2-5. (추천) SSH 기본 셸을 PowerShell로 바꾸기 (🪟 관리자 PowerShell)

SSH로 접속했을 때 기본으로 뜨는 `cmd` 대신 PowerShell이 뜨게 합니다.
```powershell
New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell `
  -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -PropertyType String -Force
```

<a id="win-rdp"></a>
### 2-6. 원격 데스크톱(RDP) 켜기 — Pro / Education / Enterprise만

`설정` → `시스템` → `원격 데스크톱` → **켬** → 확인
- "네트워크 수준 인증(NLA) 필요"는 **켠 채로** 둡니다.

또는 🪟 관리자 PowerShell:
```powershell
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name fDenyTSConnections -Value 0
Enable-NetFirewallRule -Group "@FirewallAPI.dll,-28752"   # 원격 데스크톱 방화벽 규칙 켜기
```

<a id="win-rustdesk"></a>
### 2-7. RustDesk 설치 (Home이거나, 연구실 모니터와 완전히 같은 화면을 보고 싶을 때)

1. https://github.com/rustdesk/rustdesk/releases 에서 Windows용 `rustdesk-x.x.x-x86_64.exe`를 받습니다.
2. 실행 → 왼쪽 아래 **설치(Install)** 를 눌러 **정식 설치**합니다. 정식 설치해야 아무도 없을 때도 접속할 수 있습니다.
3. RustDesk 설정(⚙) → **보안(Security)** → **잠금 해제**
   - ✅ **IP 직접 접속 허용 (Enable direct IP access)**
   - ✅ **영구 비밀번호 사용 (Use permanent password)** → 강력한 비밀번호 설정
4. 버전에 따라 메뉴 이름이 조금 다를 수 있습니다.

> RDP(2-6)와 RustDesk(2-7)는 **둘 다 설치해도 됩니다.** 하나가 안 될 때 다른 하나로 들어갈 수 있어서 오히려 안전합니다.

<a id="win-power"></a>
### 2-8. 절전 끄기 & 재부팅 대비

원격 PC가 **잠들면 접속할 수 없습니다.**

- `설정` → `시스템` → `전원 및 배터리` → `화면 및 절전` → **"전원 연결 시 절전 모드로 전환" → 안 함**
- 또는 🪟 관리자 PowerShell:
  ```powershell
  powercfg /change standby-timeout-ac 0
  powercfg /change hibernate-timeout-ac 0
  ```
- `설정` → `Windows 업데이트` → `고급 옵션` → **사용 시간** 설정 (작업 중 자동 재시작 방지)
- (가능하면) BIOS의 `Restore on AC Power Loss` → **Power On** (정전 후 자동으로 켜짐)

> 재부팅돼도 SSH, Tailscale(Run unattended), RDP, RustDesk는 **로그인 전에도** 자동으로 동작합니다.

---

<a id="ssh"></a>
## 3. SSH로 접속하기

🐧 내 Ubuntu 터미널:
```bash
ssh 사용자명@100.x.x.x
```

1. 처음 접속하면 `Are you sure you want to continue connecting (yes/no/[fingerprint])?` → **`yes`**
2. 비밀번호를 입력합니다. **입력해도 화면에 안 보이는 게 정상**입니다. Microsoft 계정이면 **Microsoft 계정 비밀번호**를 입력합니다.
3. 프롬프트가 `PS C:\Users\hong>` (또는 `C:\Users\hong>`)로 바뀌면 성공입니다.
4. 끝내려면 `exit`를 입력합니다.

> 💡 이제부터 입력하는 명령은 **Windows에서 실행**됩니다. `ls`, `cd`, `pwd`, `cat` 정도는 PowerShell에서도 동작하지만 `apt`, `grep` 같은 리눅스 명령은 안 됩니다.

---

<a id="key"></a>
## 4. 비밀번호 없이 접속하기 (SSH 키)

**① 🐧 키 만들기** (이미 `~/.ssh/id_ed25519`가 있으면 건너뛰기)
```bash
ssh-keygen -t ed25519 -C "ubuntu-laptop"      # -C 뒤에는 이 기기를 알아볼 이름
# 저장 위치: Enter / passphrase: Enter 두 번 (또는 원하는 키 비밀번호)
```
- `~/.ssh/id_ed25519` = **개인키** → **절대 남에게 주지 않기**
- `~/.ssh/id_ed25519.pub` = **공개키** → 원격에 등록하는 파일

**② 🐧 공개키를 원격 Windows로 복사**
```bash
scp ~/.ssh/id_ed25519.pub 사용자명@100.x.x.x:key.pub
```

**③ 🐧 원격 Windows에 접속해서 키 등록**
```bash
ssh 사용자명@100.x.x.x
```
접속한 뒤 프롬프트가 `C:\Users\...>`(cmd)라면 먼저 `powershell`을 입력합니다.

🔸 **관리자 계정인 경우 (대부분의 개인 PC)**
> Windows는 관리자 계정의 키를 **`C:\ProgramData\ssh\administrators_authorized_keys`** 에서 읽습니다. 사용자 폴더의 `.ssh`가 아닙니다. **가장 많이 틀리는 부분입니다.**
```powershell
Get-Content $HOME\key.pub | Add-Content -Force C:\ProgramData\ssh\administrators_authorized_keys
icacls.exe C:\ProgramData\ssh\administrators_authorized_keys /inheritance:r /grant "Administrators:F" /grant "SYSTEM:F"
Remove-Item $HOME\key.pub
exit
```
(`icacls` = 파일 권한을 관리자와 SYSTEM만 접근하도록 바꿉니다. 권한이 넓으면 SSH가 이 파일을 무시합니다.)

🔸 **일반(표준) 계정인 경우**
```powershell
New-Item -ItemType Directory -Force $HOME\.ssh | Out-Null
Get-Content $HOME\key.pub | Add-Content -Force $HOME\.ssh\authorized_keys
Remove-Item $HOME\key.pub
exit
```

**④ 🐧 테스트**
```bash
ssh 사용자명@100.x.x.x      # 비밀번호 없이 접속되면 성공!
```

---

<a id="config"></a>
## 5. 짧은 이름으로 접속하기 (ssh config)

```bash
nano ~/.ssh/config
```
아래 내용을 추가합니다.
```
Host win
    HostName 100.x.x.x
    User 사용자명
    IdentityFile ~/.ssh/id_ed25519
    ServerAliveInterval 60
```
`Ctrl + O` → Enter → `Ctrl + X`로 저장한 뒤:
```bash
chmod 600 ~/.ssh/config
ssh win           # 이제 이것만 입력하면 접속
```

> VS Code의 **Remote - SSH** 확장을 쓰면 `win`을 골라서 원격 Windows 파일을 바로 편집할 수 있습니다. → [05-tips.md](05-tips.md)

---

<a id="desktop"></a>
## 6. 🖥️ 바탕화면 보기

### 6-1. 어떤 걸 쓸까?

| | Remmina (RDP) | RustDesk |
|---|---|---|
| 원격 Windows 에디션 | Pro 이상만 | 모두 (Home 포함) |
| 연구실 모니터 | **잠금 화면**이 됨 (내 화면이 노출되지 않음) | **내 조작이 그대로 보임** |
| 열어 둔 창, 프로그램 | ✅ 그대로 보임 | ✅ 그대로 보임 |
| 연구실에서 누가 쓰고 있을 때 | 그 사람이 **쫓겨남** | 마우스를 **같이 쓰게 됨** |
| 화질, 속도 | 매우 좋음 | 좋음 |
| 설치 | 내 Ubuntu에 기본 설치됨 | 양쪽 다 설치 필요 |

> **추천**: Pro 이상이면 **Remmina(RDP)**, Home이면 **RustDesk**

### 6-2. Remmina로 접속 (원격이 Pro 이상)

Remmina는 Ubuntu에 기본으로 들어 있습니다. 없으면 설치합니다.
```bash
sudo apt install -y remmina remmina-plugin-rdp
```

1. 프로그램 목록에서 **Remmina** 실행 → 왼쪽 위 **`+`**
2. 입력:
   | 항목 | 값 |
   |---|---|
   | Name | `연구실 윈도우` (아무거나) |
   | Protocol | **RDP - Remote Desktop Protocol** |
   | Server | `100.x.x.x` |
   | Username | Windows 사용자명 (Microsoft 계정이면 **이메일 전체**) |
   | Password | Windows 비밀번호 (Microsoft 계정이면 MS 계정 비밀번호) |
   | Resolution | **Use client resolution** |
   | Colour depth | 기본값 (화면이 깨지면 `True colour (24 bpp)`) |
3. **Save and Connect** → 인증서 확인 창이 뜨면 **Yes(수락)**

💡 사용 팁
- 도구 모음에서 **전체 화면**, **크기 맞춤(Scaling)** 을 켤 수 있습니다.
- 복사/붙여넣기(텍스트)는 양쪽 사이에서 바로 됩니다.
- **창을 닫으면 = 연결 끊기**: 원격 Windows의 프로그램은 **계속 실행**됩니다. ✅
- **원격에서 시작 → 로그아웃**: 실행 중이던 프로그램이 **모두 종료**됩니다. ⚠️

### 6-3. RustDesk로 접속

1. 🐧 내 Ubuntu에도 RustDesk를 설치합니다. https://github.com/rustdesk/rustdesk/releases 에서 `rustdesk-x.x.x-x86_64.deb`를 받은 뒤:
   ```bash
   cd ~/다운로드              # 영어 환경이면 ~/Downloads
   sudo apt install -y ./rustdesk-*-x86_64.deb
   ```
   (접속**하는** 쪽이므로 Wayland나 Xorg 설정은 신경 쓰지 않아도 됩니다.)
2. RustDesk 실행 → **원격 ID(Remote ID)** 칸에 `100.x.x.x` 입력 → **연결(Connect)**
3. 원격 Windows에 설정한 **영구 비밀번호**를 입력합니다.

---

<a id="files"></a>
## 7. 파일 주고받기

```bash
scp ./report.pdf win:Documents/          # 내 Ubuntu → 원격 Windows (사용자 폴더 기준 경로)
scp win:Documents/result.csv ./          # 원격 Windows → 내 Ubuntu
scp -r ./project win:Documents/          # 폴더 통째로
```

> ⚠️ **원격 Windows 바탕화면이 OneDrive와 동기화되는 경우** 바탕화면 경로는 `C:\Users\사용자명\OneDrive\바탕 화면`입니다.
> 공백과 한글이 있어서 `scp`로는 헷갈리니 `sftp`를 쓰세요.
> ```bash
> sftp win
> sftp> cd "OneDrive/바탕 화면"
> sftp> put report.pdf        # 올리기
> sftp> get result.csv        # 내려받기
> sftp> exit
> ```

**GUI로 하기**: 파일 관리자(Nautilus) → 왼쪽 **다른 위치** → 아래 **서버 연결** 칸에 `sftp://사용자명@100.x.x.x/` → 연결 → 드래그 앤 드롭

---

<a id="checklist"></a>
## 8. ✅ 설정 완료 점검표 (연구실에 있을 때 하기)

- [ ] 원격 Windows: Tailscale 로그인 + **Run unattended** + **키 만료 끄기**
- [ ] 원격 Windows: `sshd` 실행 중 + 자동 시작
- [ ] 원격 Windows: RDP 켬(Pro 이상) 또는 RustDesk 설치 + 영구 비밀번호
- [ ] 원격 Windows: Windows Hello 전용 로그인 끔, 절전 끔
- [ ] 내 Ubuntu에서 `ssh win` → **비밀번호 없이** 접속됨
- [ ] 내 Ubuntu에서 Remmina 또는 RustDesk로 **바탕화면** 보임
- [ ] **원격 Windows 재부팅** → 로그인하지 않은 상태에서 SSH와 바탕화면 접속이 **다시 되는지** 확인
- [ ] 30분 이상 두었다가 접속 테스트 (절전 확인)

---

<a id="cautions"></a>
## 9. ⚠️ 이 경우의 주의사항

> 전체 주의사항은 [07-cautions.md](07-cautions.md)에 있습니다. 아래는 **Ubuntu → Windows**에서 특히 중요한 것만 모았습니다.

### 🔴 연구실에 가야만 복구되는 실수
- 원격에서 **"시스템 종료"를 누르거나 `Stop-Computer`를 실행하지 마세요.** 꺼진 PC는 원격으로 켤 수 없습니다. → 항상 **다시 시작**(`Restart-Computer`)만 쓰세요.
- 원격 Windows의 **Tailscale을 로그아웃하거나 종료하지 마세요.** 내가 타고 들어온 통로가 끊깁니다.
- SSH로 접속한 상태에서 **`Stop-Service sshd`를 실행하지 마세요.** 설정을 바꿨다면 `Restart-Service sshd`를 쓰세요.
- 원격 PC의 **네트워크 설정, 랜 드라이버, 사용자 비밀번호**를 바꾸는 작업은 연구실에 있을 때 하세요.

### 🟠 Windows 특유의 함정
- **관리자 계정의 SSH 키는 `C:\ProgramData\ssh\administrators_authorized_keys`** 에 넣어야 합니다. 사용자 폴더의 `.ssh`에 넣으면 동작하지 않습니다.
- **Microsoft 계정**은 PIN이 아니라 **MS 계정 비밀번호**를 씁니다. 비밀번호를 바꾸면 Remmina에 저장된 비밀번호도 바꿔야 합니다.
- SSH로 접속한 PowerShell은 **관리자 권한**으로 실행됩니다(관리자 계정인 경우). 확인 창 없이 바로 실행되니 삭제나 시스템 변경 명령은 조심하세요.
- **Windows 업데이트 자동 재시작** 때 열어 둔 프로그램과 진행 중인 작업이 모두 날아갑니다. 긴 작업 전에는 업데이트를 **일시 중지**하세요.

### 🟠 바탕화면 원격 접속
- **RDP에서 "로그아웃"하면 프로그램이 모두 꺼집니다.** 나올 때는 **창 닫기(연결 끊기)** 를 하세요.
- RDP로 접속하면 **연구실에서 그 PC를 쓰던 사람은 쫓겨납니다.** 공용 PC라면 미리 알려 주세요.
- **RustDesk는 연구실 모니터에 내 화면이 그대로 보입니다.** 메일, 메신저, 비밀번호 입력 화면이 노출될 수 있으니 연구실 모니터를 꺼 두세요.
- Remmina에서 **비밀번호 저장**은 내 개인 노트북에서만 하세요.

### 🟡 파일
- `scp`는 같은 이름의 파일을 **경고 없이 덮어씁니다.**
- Windows에서 만든 `.sh`, `.py` 파일을 Ubuntu로 가져와서 실행하면 `\r: command not found` 에러가 날 수 있습니다(CRLF 줄바꿈). → `dos2unix 파일.sh`로 바꾸세요.
- OneDrive와 동기화되는 바탕화면이나 문서 폴더에 **큰 데이터를 넣지 마세요.** `C:\data` 같은 별도 폴더를 쓰세요.

### 🟡 긴 작업
- Windows에는 `tmux`가 없습니다. SSH로 긴 작업을 실행하면 **연결이 끊기는 순간 작업도 같이 죽습니다.**
  → 긴 작업은 **RDP나 RustDesk 화면에서 실행**하고 창만 닫고 나오세요. 또는 원격 Windows에 WSL을 설치해서 그 안에서 `tmux`를 쓰세요.

---

<a id="troubleshooting"></a>
## 10. 🔧 자주 생기는 문제

> 🔍 **만능 디버깅**: `ssh -v 사용자명@100.x.x.x` → 어디서 실패하는지 자세히 보여줍니다.
> 전체 목록은 [08-troubleshooting.md](08-troubleshooting.md)에 있습니다.

| 증상 | 해결 |
|---|---|
| `Connection timed out` | `tailscale status`로 원격 PC가 online인지 확인 → 꺼졌거나 절전 상태면 현장에서 확인. Tailscale ping은 되는데 SSH만 안 되면 방화벽 문제: 🪟 관리자 PowerShell에서 `Set-NetFirewallRule -Name OpenSSH-Server-In-TCP -Profile Any` |
| `Connection refused` | 원격 SSH 서버가 꺼져 있음 → `Get-Service sshd` / `Start-Service sshd` |
| `Permission denied (password)` | 사용자명(`whoami`) 확인 / MS 계정이면 MS 비밀번호 / Windows Hello 전용 로그인 끄기 / 원격 PC에서 비밀번호로 한 번 로그인 |
| `Permission denied (publickey)` | 관리자 계정이면 키를 `C:\ProgramData\ssh\administrators_authorized_keys`에 넣고 `icacls` 명령 실행 ([4장](#key)) |
| Remmina: 연결 실패 | 원격이 Home 에디션인지 확인 (Home이면 RustDesk 사용) / RDP 켜져 있는지 확인 ([2-6](#win-rdp)) |
| Remmina: 로그인 실패 | Username을 `MicrosoftAccount\이메일@example.com` 형식으로 입력해 보기 |
| RustDesk: 연결 안 됨 | 원격 RustDesk에서 **IP 직접 접속 허용**이 켜져 있는지, 정식 설치했는지 확인 |
| `REMOTE HOST IDENTIFICATION HAS CHANGED` | 원격 PC를 포맷했다면 `ssh-keygen -R 100.x.x.x`. 이유를 모르면 접속하지 말고 확인부터 하세요 |
| 몇 달 뒤 갑자기 전부 안 됨 | Tailscale 키 만료 → [1-3](#tailscale) |

---

[← 전체 목차로 돌아가기](../README.md) · [다음: Windows → Windows](02-windows-to-windows.md)
