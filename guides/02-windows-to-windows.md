# 🪟 Windows → 🪟 Windows 원격 접속 가이드

> **내 컴퓨터(노트북, 집 PC)가 Windows**이고, **원격 컴퓨터(연구실 PC)도 Windows**인 경우입니다.
> 이 파일 하나만 위에서부터 순서대로 따라 하면 **SSH**와 **바탕화면 원격 접속**이 모두 설정됩니다.

[← 전체 목차로 돌아가기](../README.md)

---

## 🖥️ 이 가이드로 할 수 있는 것

| 방법 | 보이는 것 | 연구실 모니터 화면이 그대로 보이나? | 조건 |
|---|---|---|---|
| **SSH** | 터미널(명령어 창)만 | ❌ 화면은 안 보임 | Windows 모든 에디션 |
| **원격 데스크톱 연결 (mstsc, RDP)** | 바탕화면 전체 | ✅ 열어 둔 창이 그대로 보임 (대신 연구실 모니터는 **잠금 화면**이 됨) | 원격 Windows가 **Pro / Education / Enterprise** |
| **RustDesk** | 바탕화면 전체 | ✅ **완전히 똑같은 화면** (연구실 모니터에도 내 조작이 그대로 보임) | Windows 모든 에디션 (Home 포함) |

> **표기 규칙**
> - `100.x.x.x` = 원격 Windows의 **Tailscale IP**, `사용자명` = 원격 Windows **계정 이름**
> - 💻 = **내 Windows**의 PowerShell (시작 버튼 우클릭 → `터미널`)
> - 🪟 = **원격 Windows**의 PowerShell (관리자 PowerShell = 시작 버튼 우클릭 → `터미널(관리자)`)

---

## 📚 목차

1. [Tailscale 설치 (두 컴퓨터 모두)](#tailscale)
2. [원격 Windows 설정 (연구실에서 한 번만)](#remote-setup)
3. [SSH로 접속하기](#ssh)
4. [비밀번호 없이 접속하기 (SSH 키)](#key)
5. [짧은 이름으로 접속하기 (ssh config)](#config)
6. [🖥️ 바탕화면 보기 (원격 데스크톱 연결 / RustDesk)](#desktop)
7. [파일 주고받기](#files)
8. [✅ 설정 완료 점검표](#checklist)
9. [⚠️ 이 경우의 주의사항](#cautions)
10. [🔧 자주 생기는 문제](#troubleshooting)

---

<a id="tailscale"></a>
## 1. Tailscale 설치 (두 컴퓨터 모두)

학교 방화벽 뒤에 있는 연구실 PC에 접속하기 위해 **Tailscale**(무료 VPN)을 씁니다. **두 컴퓨터 모두 같은 계정으로 로그인**해야 합니다.
자세한 설명은 [00-tailscale.md](00-tailscale.md)를 참고하세요.

### 1-1. 두 컴퓨터 모두 (원격 Windows, 내 Windows)

1. https://tailscale.com/download/windows 에서 설치 파일을 받아 실행합니다.
2. 작업 표시줄 오른쪽 아래 Tailscale 아이콘 → **Log in** → 브라우저에서 **같은 계정**으로 로그인합니다.

### 1-2. 🪟 원격 Windows에서만 추가로

1. Tailscale 아이콘 → **Settings(설정)** → ✅ **Run unattended**
   → Windows에 로그인하기 전(재부팅 직후)에도 Tailscale이 연결됩니다.
2. IP를 확인하고 **메모**합니다.
   ```powershell
   tailscale ip -4
   ```

### 1-3. ⚠️ 원격 Windows의 "키 만료" 끄기

Tailscale은 기본적으로 약 180일마다 재로그인을 요구합니다. 연구실 PC가 어느 날 갑자기 끊기지 않도록 꺼 두세요.

1. https://login.tailscale.com/admin/machines 에 접속합니다.
2. 원격 Windows 줄 오른쪽의 `...` → **Disable key expiry**를 누릅니다.

### 1-4. 연결 테스트 (💻 내 Windows)

```powershell
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

| 에디션 | SSH | 원격 데스크톱 연결(RDP)로 바탕화면 보기 | RustDesk로 바탕화면 보기 |
|---|---|---|---|
| Pro / Education / Enterprise | ✅ | ✅ | ✅ |
| **Home** | ✅ | ❌ | ✅ ← Home이면 이것만 가능 |

> 내 Windows(접속하는 쪽)는 **Home이어도** RDP로 접속할 수 있습니다. **원격(접속받는 쪽)** 에디션만 중요합니다.

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

Windows 11에는 **SSH 클라이언트가 기본으로 들어 있습니다.** 💻 내 Windows에서 확인해 보세요.
```powershell
ssh -V          # OpenSSH_for_Windows_... 가 나오면 OK
```
안 나오면: `설정` → `시스템` → `선택적 기능` → `기능 보기` → **OpenSSH 클라이언트** 설치

💻 접속:
```powershell
ssh 사용자명@100.x.x.x
```

1. 처음 접속하면 `Are you sure you want to continue connecting (yes/no/[fingerprint])?` → **`yes`**
2. 비밀번호를 입력합니다. **입력해도 화면에 안 보이는 게 정상**입니다. Microsoft 계정이면 **Microsoft 계정 비밀번호**를 입력합니다.
3. 프롬프트가 `PS C:\Users\hong>` (또는 `C:\Users\hong>`)로 바뀌면 성공입니다.
4. 끝내려면 `exit`를 입력합니다.

> 💡 내 PC와 원격 PC가 둘 다 Windows라서 **지금 어느 쪽 창인지 헷갈리기 쉽습니다.** 프롬프트의 사용자명과 경로를 확인하는 습관을 들이세요.

---

<a id="key"></a>
## 4. 비밀번호 없이 접속하기 (SSH 키)

**① 💻 키 만들기** (이미 `C:\Users\내이름\.ssh\id_ed25519`가 있으면 건너뛰기)
```powershell
ssh-keygen -t ed25519 -C "home-pc"      # -C 뒤에는 이 기기를 알아볼 이름
# 저장 위치: Enter / passphrase: Enter 두 번 (또는 원하는 키 비밀번호)
```
- `id_ed25519` = **개인키** → **절대 남에게 주지 않기**
- `id_ed25519.pub` = **공개키** → 원격에 등록하는 파일

**② 💻 공개키를 원격 Windows로 복사**
```powershell
scp $env:USERPROFILE\.ssh\id_ed25519.pub 사용자명@100.x.x.x:key.pub
```

**③ 💻 원격 Windows에 접속해서 키 등록**
```powershell
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

🔸 **일반(표준) 계정인 경우**
```powershell
New-Item -ItemType Directory -Force $HOME\.ssh | Out-Null
Get-Content $HOME\key.pub | Add-Content -Force $HOME\.ssh\authorized_keys
Remove-Item $HOME\key.pub
exit
```

**④ 💻 테스트**
```powershell
ssh 사용자명@100.x.x.x      # 비밀번호 없이 접속되면 성공!
```

---

<a id="config"></a>
## 5. 짧은 이름으로 접속하기 (ssh config)

💻 내 Windows:
```powershell
# config 파일이 없으면 만들기 (이미 있으면 그대로 둠)
if (!(Test-Path $env:USERPROFILE\.ssh\config)) { New-Item -ItemType File $env:USERPROFILE\.ssh\config }
notepad $env:USERPROFILE\.ssh\config
```
> 메모장으로 새 파일을 저장하면 `config.txt`로 저장될 수 있어서 **파일을 먼저 만들고** 엽니다.

아래 내용을 넣고 저장합니다.
```
Host win
    HostName 100.x.x.x
    User 사용자명
    IdentityFile ~/.ssh/id_ed25519
    ServerAliveInterval 60
```
```powershell
ssh win           # 이제 이것만 입력하면 접속
```

> VS Code의 **Remote - SSH** 확장을 쓰면 `win`을 골라서 원격 파일을 바로 편집할 수 있습니다. → [05-tips.md](05-tips.md)

---

<a id="desktop"></a>
## 6. 🖥️ 바탕화면 보기

### 6-1. 어떤 걸 쓸까?

| | 원격 데스크톱 연결 (RDP) | RustDesk |
|---|---|---|
| 원격 Windows 에디션 | Pro 이상만 | 모두 (Home 포함) |
| 연구실 모니터 | **잠금 화면**이 됨 (내 화면이 노출되지 않음) | **내 조작이 그대로 보임** |
| 열어 둔 창, 프로그램 | ✅ 그대로 보임 | ✅ 그대로 보임 |
| 연구실에서 누가 쓰고 있을 때 | 그 사람이 **쫓겨남** | 마우스를 **같이 쓰게 됨** |
| 화질, 속도 | 매우 좋음 | 좋음 |
| 설치 | Windows 기본 앱 (설치 필요 없음) | 양쪽 다 설치 필요 |

> **추천**: 원격이 Pro 이상이면 **원격 데스크톱 연결**, Home이면 **RustDesk**

### 6-2. 원격 데스크톱 연결 (mstsc) — 원격이 Pro 이상

1. `Win + R` → `mstsc` 입력 → Enter (또는 시작 → **"원격 데스크톱 연결"** 검색)
2. **컴퓨터**: `100.x.x.x`
3. **옵션 표시**를 누릅니다.
   - **일반** 탭: 사용자 이름 입력 (Microsoft 계정이면 **이메일 전체**), ✅ **자격 증명을 저장할 수 있음**
   - **디스플레이** 탭: 해상도(전체 화면 추천). 모니터가 여러 대면 ✅ **"내 모든 모니터를 원격 세션에 사용"**
   - **로컬 리소스** 탭: ✅ 클립보드, **자세히** → ✅ 드라이브 (내 PC 드라이브를 원격에서 열 수 있어서 파일 옮기기가 편함)
   - **일반** 탭 → **다른 이름으로 저장** → 바탕화면에 `.rdp` 파일로 저장 → 다음부터는 **더블클릭만** 하면 됩니다.
4. **연결** → 비밀번호 입력 → 인증서 경고가 나오면 **"예"**

💡 사용 팁
| 하고 싶은 것 | 방법 |
|---|---|
| 전체 화면 ↔ 창 모드 | `Ctrl + Alt + Break`, 또는 화면 위쪽 연결 표시줄 사용 |
| 복사/붙여넣기 | 평소처럼 `Ctrl + C` / `Ctrl + V` (텍스트, 파일 모두) |
| 파일 옮기기 | 파일 복사 → 원격에 붙여넣기, 또는 원격 파일 탐색기 `내 PC`에 보이는 내 드라이브 사용 |
| **연결만 끊기** | 창 닫기(X) → 원격의 **프로그램은 계속 실행됨** ✅ |
| 로그아웃 | 원격에서 시작 → 로그아웃 → 실행 중이던 **프로그램이 모두 종료됨** ⚠️ |

> 오래 걸리는 작업을 돌려 놓고 나올 때는 반드시 **창 닫기(연결 끊기)** 로 나오세요.

### 6-3. RustDesk로 접속

1. 💻 내 Windows에도 RustDesk를 받습니다. (https://github.com/rustdesk/rustdesk/releases → Windows용 `.exe`)
   접속만 할 거라면 **설치하지 않고 실행만 해도 됩니다.**
2. **원격 ID(Remote ID)** 칸에 `100.x.x.x` 입력 → **연결(Connect)**
3. 원격 Windows에 설정한 **영구 비밀번호**를 입력합니다.

---

<a id="files"></a>
## 7. 파일 주고받기

💻 내 Windows PowerShell:
```powershell
scp .\report.pdf win:Documents/          # 내 PC → 원격 (원격 사용자 폴더 기준 경로)
scp win:Documents/result.csv .           # 원격 → 내 PC
scp -r .\project win:Documents/          # 폴더 통째로
```

- **원격 데스크톱 연결 중이라면** 그냥 **복사 → 붙여넣기**로도 파일이 옮겨집니다.
- 원격 바탕화면이 OneDrive와 동기화되면 경로가 `OneDrive/바탕 화면`입니다. 공백이 있으니 따옴표로 감싸세요.
  ```powershell
  scp .\report.pdf "win:OneDrive/바탕 화면/"
  ```
- GUI 프로그램이 편하다면 **[WinSCP](https://winscp.net)** 를 쓰세요. 프로토콜 `SFTP`, 호스트 `100.x.x.x`로 접속합니다.

---

<a id="checklist"></a>
## 8. ✅ 설정 완료 점검표 (연구실에 있을 때 하기)

- [ ] 원격 Windows: Tailscale 로그인 + **Run unattended** + **키 만료 끄기**
- [ ] 원격 Windows: `sshd` 실행 중 + 자동 시작
- [ ] 원격 Windows: RDP 켬(Pro 이상) 또는 RustDesk 설치 + 영구 비밀번호
- [ ] 원격 Windows: Windows Hello 전용 로그인 끔, 절전 끔
- [ ] 내 Windows에서 `ssh win` → **비밀번호 없이** 접속됨
- [ ] 내 Windows에서 원격 데스크톱 연결 또는 RustDesk로 **바탕화면** 보임
- [ ] **원격 Windows 재부팅** → 로그인하지 않은 상태에서 SSH와 바탕화면 접속이 **다시 되는지** 확인
- [ ] 30분 이상 두었다가 접속 테스트 (절전 확인)

---

<a id="cautions"></a>
## 9. ⚠️ 이 경우의 주의사항

> 전체 주의사항은 [07-cautions.md](07-cautions.md)에 있습니다. 아래는 **Windows → Windows**에서 특히 중요한 것만 모았습니다.

### 🔴 연구실에 가야만 복구되는 실수
- 원격 화면에서 **시작 → 전원 → "시스템 종료"를 누르지 마세요.** 꺼진 PC는 원격으로 켤 수 없습니다. → 항상 **다시 시작**만 쓰세요.
  - 두 컴퓨터가 모두 Windows라서 **내 PC를 끄려다 원격 PC를 끄는 실수가 특히 흔합니다.** 원격 데스크톱 창이 전체 화면일 때 조심하세요.
- 원격 Windows의 **Tailscale을 로그아웃하거나 종료하지 마세요.** 내가 타고 들어온 통로가 끊깁니다.
- SSH로 접속한 상태에서 **`Stop-Service sshd`를 실행하지 마세요.** 설정을 바꿨다면 `Restart-Service sshd`를 쓰세요.
- 원격 PC의 **네트워크 설정, 랜 드라이버, 사용자 비밀번호**를 바꾸는 작업은 연구실에 있을 때 하세요.

### 🟠 Windows 특유의 함정
- **관리자 계정의 SSH 키는 `C:\ProgramData\ssh\administrators_authorized_keys`** 에 넣어야 합니다. 사용자 폴더의 `.ssh`에 넣으면 동작하지 않습니다.
- **Microsoft 계정**은 PIN이 아니라 **MS 계정 비밀번호**를 씁니다. 비밀번호를 바꾸면 저장된 RDP 자격 증명도 다시 입력해야 합니다.
- SSH로 접속한 PowerShell은 **관리자 권한**으로 실행됩니다(관리자 계정인 경우). 확인 창 없이 바로 실행되니 삭제나 시스템 변경 명령은 조심하세요.
- **Windows 업데이트 자동 재시작** 때 열어 둔 프로그램과 진행 중인 작업이 모두 날아갑니다. 긴 작업 전에는 업데이트를 **일시 중지**하세요.

### 🟠 바탕화면 원격 접속
- **RDP에서 "로그아웃"하면 프로그램이 모두 꺼집니다.** 나올 때는 **창 닫기(연결 끊기)** 를 하세요.
- RDP로 접속하면 **연구실에서 그 PC를 쓰던 사람은 쫓겨납니다.** 공용 PC라면 미리 알려 주세요.
- **RustDesk는 연구실 모니터에 내 화면이 그대로 보입니다.** 메일, 메신저, 비밀번호 입력 화면이 노출될 수 있으니 연구실 모니터를 꺼 두세요.
- RDP **"자격 증명 저장"** 과 RustDesk 비밀번호 저장은 **내 개인 PC에서만** 하세요. PC방이나 공용 PC에서 접속했다면 나오기 전에 지우세요.
- RDP에서 **내 드라이브 공유**를 켜면 원격 PC에서 내 PC 파일에 접근할 수 있습니다. 원격 PC가 공용이면 꺼 두세요.

### 🟡 긴 작업
- Windows에는 `tmux`가 없습니다. SSH로 긴 작업을 실행하면 **연결이 끊기는 순간 작업도 같이 죽습니다.**
  → 긴 작업은 **원격 데스크톱 화면에서 실행**하고 창만 닫고 나오세요.

### 🟡 파일
- `scp`와 RDP 복사/붙여넣기는 같은 이름의 파일을 **덮어쓸 수 있습니다.** 확인하고 옮기세요.
- OneDrive와 동기화되는 바탕화면이나 문서 폴더에 **큰 데이터를 넣지 마세요.** `C:\data` 같은 별도 폴더를 쓰세요.

---

<a id="troubleshooting"></a>
## 10. 🔧 자주 생기는 문제

> 🔍 **만능 디버깅**: `ssh -v 사용자명@100.x.x.x` → 어디서 실패하는지 자세히 보여줍니다.
> 전체 목록은 [08-troubleshooting.md](08-troubleshooting.md)에 있습니다.

| 증상 | 해결 |
|---|---|
| `ssh` 명령을 찾을 수 없음 | 내 Windows에 **OpenSSH 클라이언트** 설치 ([3장](#ssh)) |
| `Connection timed out` | `tailscale status`로 원격 PC가 online인지 확인 → 꺼졌거나 절전 상태면 현장에서 확인. Tailscale ping은 되는데 SSH만 안 되면 방화벽 문제: 🪟 관리자 PowerShell에서 `Set-NetFirewallRule -Name OpenSSH-Server-In-TCP -Profile Any` |
| `Connection refused` | 원격 SSH 서버가 꺼져 있음 → `Get-Service sshd` / `Start-Service sshd` |
| `Permission denied (password)` | 사용자명(`whoami`) 확인 / MS 계정이면 MS 비밀번호 / Windows Hello 전용 로그인 끄기 / 원격 PC에서 비밀번호로 한 번 로그인 |
| `Permission denied (publickey)` | 관리자 계정이면 키를 `C:\ProgramData\ssh\administrators_authorized_keys`에 넣고 `icacls` 명령 실행 ([4장](#key)) |
| RDP: "원격 컴퓨터에 연결할 수 없습니다" | 원격이 Home 에디션인지 확인 (Home이면 RustDesk) / RDP 켜져 있는지 확인 ([2-6](#win-rdp)) |
| RDP: "자격 증명이 작동하지 않았습니다" | 사용자 이름을 `MicrosoftAccount\이메일@example.com` 형식으로 입력해 보기 / 원격 PC에서 비밀번호로 한 번 로그인 |
| RustDesk: 연결 안 됨 | 원격 RustDesk에서 **IP 직접 접속 허용**이 켜져 있는지, 정식 설치했는지 확인 |
| 몇 달 뒤 갑자기 전부 안 됨 | Tailscale 키 만료 → [1-3](#tailscale) |

---

[← 이전: Ubuntu → Windows](01-ubuntu-to-windows.md) · [전체 목차](../README.md) · [다음: Ubuntu → Ubuntu →](03-ubuntu-to-ubuntu.md)
