# 🪟 Windows → 🐧 Ubuntu 원격 접속 가이드

> **내 컴퓨터(노트북, 집 PC)가 Windows**이고, **원격 컴퓨터(연구실 PC)가 Ubuntu**인 경우입니다.
> 연구실 서버(Ubuntu)와 개인 PC(Windows)를 쓰는 **가장 흔한 조합**입니다.
> 이 파일 하나만 위에서부터 순서대로 따라 하면 **SSH**와 **바탕화면 원격 접속**이 모두 설정됩니다.

> 🐣 **컴퓨터가 익숙하지 않다면** 이 문서 대신 **[쉬운 가이드](../easy/04-windows-to-ubuntu.md)** 를 먼저 따라 하세요. 이 문서는 여러 방법을 비교하는 자세한 버전입니다.

[← 전체 목차로 돌아가기](../README.md)

---

## 🖥️ 이 가이드로 할 수 있는 것

| 방법 | 보이는 것 | 연구실 모니터 화면이 그대로 보이나? | 비고 |
|---|---|---|---|
| **SSH** | 터미널(명령어 창)만 | ❌ 화면은 안 보임 | 가장 빠르고 안정적 |
| **RustDesk** ⭐추천 | 바탕화면 전체 | ✅ **완전히 똑같은 화면** | Xorg 전환 + 자동 로그인 필요 |
| **Ubuntu 내장 원격 데스크톱 + mstsc** | 바탕화면 전체 | ✅ **똑같은 화면** | 설치 불필요, 원격 PC가 로그인된 상태여야 함 |
| **xrdp + mstsc** | 바탕화면 전체 | ❌ **별도의 새 화면** (연구실 모니터에 떠 있는 창은 안 보임) | 로그인 안 된 상태에서도 접속 가능 |

> **표기 규칙**
> - `100.x.x.x` = 원격 Ubuntu의 **Tailscale IP**, `사용자명` = 원격 Ubuntu **계정 이름**
> - 💻 = **내 Windows**의 PowerShell (시작 버튼 우클릭 → `터미널`)
> - 🐧 = **원격 Ubuntu**(연구실 PC) 터미널 (`Ctrl + Alt + T`)

---

## 📚 목차

1. [Tailscale 설치 (두 컴퓨터 모두)](#tailscale)
2. [원격 Ubuntu 설정 (연구실에서 한 번만)](#remote-setup)
3. [SSH로 접속하기](#ssh)
4. [비밀번호 없이 접속하기 (SSH 키)](#key)
5. [짧은 이름으로 접속하기 (ssh config)](#config)
6. [🖥️ 바탕화면 보기](#desktop)
7. [파일 주고받기](#files)
8. [긴 작업 돌리기 (tmux)](#tmux)
9. [✅ 설정 완료 점검표](#checklist)
10. [⚠️ 이 경우의 주의사항](#cautions)
11. [🔧 자주 생기는 문제](#troubleshooting)

---

<a id="tailscale"></a>
## 1. Tailscale 설치 (두 컴퓨터 모두)

학교 방화벽 뒤에 있는 연구실 PC에 접속하기 위해 **Tailscale**(무료 VPN)을 씁니다. **두 컴퓨터 모두 같은 계정으로 로그인**해야 합니다.
자세한 설명은 [00-tailscale.md](00-tailscale.md)를 참고하세요.

### 1-1. 🐧 원격 Ubuntu (연구실 PC)

```bash
sudo apt install -y curl                           # curl 이 없으면 설치 (새로 설치한 우분투에는 없음)
curl -fsSL https://tailscale.com/install.sh | sh   # 설치
sudo tailscale up                                  # 출력되는 URL을 브라우저로 열어 로그인
tailscale ip -4                                    # 100.x.x.x → 메모
```
Ubuntu에서는 Tailscale이 시스템 서비스로 등록되어 **부팅할 때 자동으로 연결**됩니다.

### 1-2. 💻 내 Windows (노트북, 집 PC)

1. https://tailscale.com/download/windows 에서 설치 파일을 받아 실행합니다.
2. 작업 표시줄 오른쪽 아래 Tailscale 아이콘 → **Log in** → 원격 Ubuntu와 **같은 계정**으로 로그인합니다.

### 1-3. ⚠️ 원격 Ubuntu의 "키 만료" 끄기

Tailscale은 기본적으로 약 180일마다 재로그인을 요구합니다. 연구실 PC가 어느 날 갑자기 끊기지 않도록 꺼 두세요.

1. https://login.tailscale.com/admin/machines 에 접속합니다.
2. 원격 Ubuntu 줄 오른쪽의 `...` → **Disable key expiry**를 누릅니다.

### 1-4. 연결 테스트 (💻 내 Windows)

```powershell
tailscale ping 100.x.x.x      # "pong from ..." 이 나오면 성공
```

---

<a id="remote-setup"></a>
## 2. 원격 Ubuntu 설정 (연구실에서 한 번만)

> 이 장은 모두 **연구실 Ubuntu PC 앞에서** 합니다.

### 2-1. SSH 서버 설치

🐧
```bash
sudo apt update
sudo apt install -y openssh-server      # SSH 서버 설치
sudo systemctl enable --now ssh         # 지금 시작 + 부팅 시 자동 시작
systemctl status ssh                    # "active (running)" 이면 성공 (q 로 나가기)
```

### 2-2. 방화벽(ufw) 확인

Ubuntu 데스크톱은 기본적으로 방화벽이 꺼져 있습니다.
```bash
sudo ufw status              # Status: inactive → 아무것도 안 해도 됨
sudo ufw allow ssh           # Status: active 인 경우에만 실행
```

### 2-3. 접속 정보 확인

```bash
whoami           # 사용자명 → 메모
tailscale ip -4  # Tailscale IP → 메모
```

<a id="ubuntu-desktop"></a>
### 2-4. 원격 데스크톱 방법 고르기

| 방법 | 연구실 모니터 화면 그대로? | Windows에서 접속하는 프로그램 | 장점 | 단점 |
|---|---|---|---|---|
| **A. RustDesk** ⭐ | ✅ | RustDesk | 안정적, 재부팅 후에도 접속 가능 | Xorg 전환, 설치 필요 |
| **B. 내장 원격 데스크톱** | ✅ | 원격 데스크톱 연결 (mstsc, 기본 앱) | 양쪽 다 설치 없음 | 로그인된 상태 필요, 잠금 화면에서 불안정, 재부팅 후 비밀번호 문제 |
| **C. xrdp** | ❌ 별도 화면 | 원격 데스크톱 연결 (mstsc, 기본 앱) | 로그인 안 해도 접속 가능 | 실제 화면이 아님, 같은 계정이 로그인 중이면 검은 화면 |

> **"연구실 바탕화면을 그대로" 보고 싶다면 A(RustDesk)** 를 추천합니다.
> ⚠️ **A와 B 중 하나만** 고르세요(A 때문에 Xorg로 바꾸면 B가 잘 안 될 수 있음). **B와 C는 둘 다 3389 포트를 써서 충돌**합니다.

<a id="xorg"></a>
#### 🅰️ 방법 A: RustDesk (실제 화면, 추천)

**① Wayland → Xorg 전환**
Ubuntu 22.04는 기본으로 Wayland를 쓰는데, Wayland에서는 원격 프로그램이 화면을 제대로 캡처하지 못합니다.
```bash
sudo sed -i 's/^#WaylandEnable=false/WaylandEnable=false/' /etc/gdm3/custom.conf
grep WaylandEnable /etc/gdm3/custom.conf     # "WaylandEnable=false" (앞에 # 없음) 확인
sudo reboot
```
재부팅한 뒤 확인합니다.
```bash
echo $XDG_SESSION_TYPE      # x11 이 나오면 성공
```

**② RustDesk 설치**
https://github.com/rustdesk/rustdesk/releases 에서 `rustdesk-x.x.x-x86_64.deb`를 받습니다.
```bash
cd ~/다운로드            # 영어 환경이면 ~/Downloads
sudo apt install -y ./rustdesk-*-x86_64.deb
```

**③ RustDesk 설정**
RustDesk 실행 → 설정(⚙) → **보안(Security)** → **잠금 해제**
- ✅ **IP 직접 접속 허용 (Enable direct IP access)**
- ✅ **영구 비밀번호 사용 (Use permanent password)** → 강력한 비밀번호 설정

(버전에 따라 메뉴 이름이 조금 다를 수 있습니다.)

**④ 자동 로그인 켜기**
`설정` → `사용자` → 오른쪽 위 **잠금 해제** → **자동 로그인** 켜기
→ 재부팅해도 바탕화면까지 자동으로 올라와서 RustDesk로 바로 접속할 수 있습니다.
> ⚠️ 자동 로그인의 보안 위험은 [10장 주의사항](#cautions)을 꼭 읽어 보세요.

#### 🅱️ 방법 B: Ubuntu 내장 원격 데스크톱 (설치 불필요)

1. `설정` → `공유(Sharing)` → 오른쪽 위 **토글 켜기**
2. **원격 데스크톱(Remote Desktop)** 클릭
   - ✅ **원격 데스크톱**
   - ✅ **원격 제어(Remote Control)** (끄면 보기만 가능)
3. **인증(Authentication)** 에서 **사용자 이름과 비밀번호** 설정
   → **Ubuntu 로그인 비밀번호와 별개**입니다. Windows에서 접속할 때 이 값을 씁니다.

> `공유` 메뉴가 없으면 `sudo apt install -y gnome-remote-desktop`으로 설치하세요.

⚠️ 방법 B의 한계
- 원격 PC에 **사용자가 로그인해 있어야** 합니다. 로그인 화면에서는 접속이 안 됩니다.
- **화면이 잠겨 있으면** 접속이 잘 안 됩니다 → [2-5](#ubuntu-power)에서 자동 잠금을 끄세요.
- **자동 로그인을 쓰면 재부팅할 때마다 원격 데스크톱 비밀번호가 바뀌는 문제**가 있습니다. 로그인 키링이 잠겨 있기 때문입니다.
  - 해결: `암호 및 키`(Passwords and Keys, `seahorse`) 앱 → `로그인(Login)` 키링 우클릭 → **비밀번호 변경** → 새 비밀번호를 **빈칸**으로 둡니다.
  - 키링 안의 저장된 비밀번호가 암호화되지 않은 상태가 되므로 **개인 전용 PC에서만** 하세요.

#### 🅲 방법 C: xrdp (별도 세션)

```bash
sudo apt install -y xrdp
sudo systemctl enable --now xrdp
sudo adduser xrdp ssl-cert           # 인증서 접근 권한
sudo ufw allow 3389/tcp              # ufw 가 켜져 있는 경우에만
```
- 접속하면 **새 바탕화면 세션**이 열립니다. 연구실 모니터에 떠 있는 창은 **보이지 않습니다.**
- 원격 PC에서 **같은 계정이 로그인된 상태면 검은 화면**이 뜹니다 → 원격 PC에서 로그아웃해 두세요.

<a id="ubuntu-power"></a>
### 2-5. 절전 & 화면 잠금 끄기

원격 PC가 **잠들면 접속할 수 없습니다.**

**설정 앱**
- `설정` → `전원` → **빈 화면: 안 함**, **자동 절전: 끔**
- `설정` → `개인 정보` → `화면`(또는 `화면 잠금`) → **자동 화면 잠금: 끔**

**터미널** 🐧
```bash
# 절전/최대 절전 완전히 막기
sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target

# 화면 꺼짐 & 자동 잠금 끄기 (sudo 없이, 로그인한 사용자로 실행)
gsettings set org.gnome.desktop.session idle-delay 0
gsettings set org.gnome.desktop.screensaver lock-enabled false
```
> 나중에 절전을 다시 켜려면: `sudo systemctl unmask sleep.target suspend.target hibernate.target hybrid-sleep.target`

- (가능하면) BIOS의 `Restore on AC Power Loss` → **Power On** (정전 후 자동으로 켜짐)
- **모니터는 꺼도 됩니다.** 본체만 켜져 있으면 됩니다.

---

<a id="ssh"></a>
## 3. SSH로 접속하기

Windows 11에는 **SSH 클라이언트가 기본으로 들어 있습니다.** 💻 확인해 보세요.
```powershell
ssh -V          # OpenSSH_for_Windows_... 가 나오면 OK
```
안 나오면: `설정` → `시스템` → `선택적 기능` → `기능 보기` → **OpenSSH 클라이언트** 설치

💻 접속:
```powershell
ssh 사용자명@100.x.x.x
```
1. 처음 접속하면 `Are you sure you want to continue connecting (yes/no/[fingerprint])?` → **`yes`**
2. 원격 Ubuntu 로그인 비밀번호를 입력합니다. **화면에 안 보이는 게 정상**입니다.
3. 프롬프트가 `사용자명@원격호스트이름:~$`으로 바뀌면 성공입니다. 이제부터는 **리눅스 명령어**를 씁니다.
4. 끝내려면 `exit`를 입력합니다.

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

**② 💻 공개키를 원격 Ubuntu에 등록**
Windows에는 `ssh-copy-id`가 없으므로 아래 한 줄로 대신합니다. (비밀번호 한 번 입력)
```powershell
type $env:USERPROFILE\.ssh\id_ed25519.pub | ssh 사용자명@100.x.x.x "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
```

**③ 💻 테스트**
```powershell
ssh 사용자명@100.x.x.x      # 비밀번호 없이 접속되면 성공!
```

> 노트북과 집 PC **각각** ①~③을 해야 합니다. 기기마다 키가 따로 있습니다.

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
Host lab
    HostName 100.x.x.x
    User 사용자명
    IdentityFile ~/.ssh/id_ed25519
    ServerAliveInterval 60
```
```powershell
ssh lab           # 이제 이것만 입력하면 접속
```

> ⭐ **VS Code의 Remote - SSH** 확장을 쓰면 `lab`을 골라서 연구실 Ubuntu의 파일을 내 Windows VS Code에서 바로 편집하고 실행할 수 있습니다. 이 조합에서 가장 편한 작업 방법입니다. → [05-tips.md](05-tips.md)

---

<a id="desktop"></a>
## 6. 🖥️ 바탕화면 보기

원격 Ubuntu에서 [2-4](#ubuntu-desktop)에서 고른 방법에 맞춰 접속합니다.

### 6-1. 원격이 🅰️ RustDesk인 경우

1. 💻 내 Windows에서 RustDesk를 받습니다. (https://github.com/rustdesk/rustdesk/releases → Windows용 `.exe`)
   접속만 할 거라면 **설치하지 않고 실행만 해도 됩니다.**
2. **원격 ID(Remote ID)** 칸에 `100.x.x.x` 입력 → **연결(Connect)**
3. 원격 Ubuntu에 설정한 **영구 비밀번호**를 입력합니다.

→ 연구실 Ubuntu 바탕화면이 **그대로** 보이고, 마우스와 키보드로 조작할 수 있습니다.

### 6-2. 원격이 🅱️ 내장 원격 데스크톱 또는 🅲 xrdp인 경우 → 원격 데스크톱 연결 (mstsc)

1. `Win + R` → `mstsc` 입력 → Enter
2. **컴퓨터**: `100.x.x.x` → **연결**
3. 사용자 이름 / 비밀번호:
   - 🅱️ 내장 원격 데스크톱: 원격 `설정 → 공유 → 원격 데스크톱`에서 **정한 값**
   - 🅲 xrdp: 원격 **Ubuntu 로그인 계정과 비밀번호** (xrdp 로그인 창에서 Session은 `Xorg` 선택)
4. 인증서 경고가 나오면 **"예"**

💡 **옵션 표시** → **디스플레이** 탭에서 해상도를 정하고, **일반** 탭 → **다른 이름으로 저장**하면 다음부터 `.rdp` 파일 더블클릭으로 접속할 수 있습니다.

---

<a id="files"></a>
## 7. 파일 주고받기

💻 내 Windows PowerShell:
```powershell
scp .\data.zip lab:~/                   # 내 Windows → 원격 Ubuntu (홈 폴더)
scp lab:~/results/out.csv .             # 원격 Ubuntu → 내 Windows
scp -r .\project lab:~/                 # 폴더 통째로
```

**GUI로 하기**
- **[WinSCP](https://winscp.net)**: 프로토콜 `SFTP`, 호스트 `100.x.x.x`, 사용자명 입력 → 왼쪽(내 PC)과 오른쪽(원격)을 드래그 앤 드롭
- **VS Code Remote-SSH**: 탐색기에 원격 파일이 보이고, 내 PC 파일을 끌어다 놓으면 업로드됩니다. 원격 파일을 우클릭 → **Download**로 받을 수 있습니다.

---

<a id="tmux"></a>
## 8. 긴 작업 돌리기 (tmux)

SSH로 학습을 돌리다가 **노트북을 덮거나 와이파이가 끊기면 작업도 같이 죽습니다.** `tmux` 안에서 실행하세요.

```bash
ssh lab
sudo apt install -y tmux      # 원격에 한 번만 설치

tmux new -s train             # "train" 세션 만들기
python train.py               # 세션 안에서 실행
# Ctrl + b 누르고 손 뗀 뒤 d  → 빠져나오기 (작업은 계속 실행)

tmux ls                       # 세션 목록
tmux attach -t train          # 다시 들어가기 (노트북 → 집 PC로 바꿔서 접속해도 OK)
```
자세한 사용법, Jupyter 포트 포워딩 등은 [05-tips.md](05-tips.md)를 참고하세요.

---

<a id="checklist"></a>
## 9. ✅ 설정 완료 점검표 (연구실에 있을 때 하기)

- [ ] 원격 Ubuntu: Tailscale 로그인 + **키 만료 끄기**
- [ ] 원격 Ubuntu: `ssh` 서비스 active
- [ ] 원격 Ubuntu: 원격 데스크톱 A / B / C 중 하나 설정
- [ ] 원격 Ubuntu: 절전, 화면 잠금 끔 (+ A라면 자동 로그인)
- [ ] 노트북과 집 PC **각각**에서 `ssh lab` → **비밀번호 없이** 접속됨
- [ ] 노트북과 집 PC에서 **바탕화면** 보임
- [ ] **원격 Ubuntu 재부팅** (`sudo reboot`) → SSH와 바탕화면 접속이 **다시 되는지** 확인
- [ ] 30분 이상 두었다가 접속 테스트 (절전 확인)

---

<a id="cautions"></a>
## 10. ⚠️ 이 경우의 주의사항

> 전체 주의사항은 [07-cautions.md](07-cautions.md)에 있습니다. 아래는 **Windows → Ubuntu**에서 특히 중요한 것만 모았습니다.

### 🔴 연구실에 가야만 복구되는 실수
- 원격에서 **`sudo shutdown now`, `poweroff`를 실행하거나 "전원 끄기"를 누르지 마세요.** 꺼진 PC는 원격으로 켤 수 없습니다. → 항상 `sudo reboot`만 쓰세요.
- 원격에서 **`sudo tailscale down`이나 `tailscale logout`을 실행하지 마세요.** 내가 타고 들어온 통로가 끊깁니다.
- 원격에서 **`sudo systemctl stop ssh`를 실행하지 마세요.** 설정을 바꿨다면 `sudo systemctl restart ssh`를 쓰세요.
- **`sudo ufw enable`은 반드시 `sudo ufw allow ssh`를 먼저 실행한 뒤에** 하세요. 순서가 바뀌면 SSH가 막힙니다.
- **배포판 업그레이드(`do-release-upgrade`, 22.04 → 24.04)** 와 **NVIDIA 드라이버 설치, 변경**은 연구실에 있을 때 하세요. 재부팅 후 화면이나 SSH가 안 올라올 수 있습니다.
- 원격 PC의 **네트워크 설정(netplan, NetworkManager)** 변경도 현장에서만 하세요.

### 🟠 자동 로그인과 화면 잠금 해제 (방법 A, B)
- 자동 로그인을 켜고 화면 잠금을 끄면 **연구실에 들어온 누구나 로그인된 상태 그대로 PC를 쓸 수 있습니다.** (메일, 브라우저 로그인, 코드, 데이터)
- 연구실 출입이 자유롭거나 공용 PC라면 **방법 C(xrdp, 로그인 필요)** 나 SSH 위주로 쓰는 것도 고려하세요.
- 최소한 **모니터 전원은 꺼 두세요.**
- 방법 B 때문에 키링 비밀번호를 빈칸으로 하면 저장된 비밀번호(와이파이 등)가 암호화되지 않은 상태가 됩니다.

### 🟠 화면 노출 (방법 A, B)
- RustDesk와 내장 원격 데스크톱은 **연구실 모니터에 내 조작이 그대로 보입니다.** 개인 메일이나 메신저를 볼 때는 조심하고, 모니터를 꺼 두세요.
- 다른 사람이 쓰고 있는 PC에 접속하면 **그 사람의 마우스를 빼앗게** 됩니다.

### 🟡 Windows ↔ Ubuntu 사이의 차이
- **줄바꿈 문자가 다릅니다.** Windows에서 만든 `.sh`, `.py` 파일을 Ubuntu에서 실행하면 `\r: command not found` 에러가 날 수 있습니다.
  → Ubuntu에서 `sudo apt install -y dos2unix && dos2unix 파일.sh`, 또는 VS Code 오른쪽 아래 `CRLF`를 눌러 `LF`로 바꿔 저장하세요.
- **경로 표기가 다릅니다.** Windows는 `C:\Users\...`(역슬래시), Ubuntu는 `/home/사용자명/...`(슬래시)입니다. 코드에 경로를 직접 적지 말고 `os.path.join`이나 `pathlib`을 쓰세요.
- Ubuntu는 **대소문자를 구분**합니다. `Data.csv`와 `data.csv`는 다른 파일입니다.
- **한글과 공백이 들어간 파일명**은 `scp`에서 문제가 되기 쉽습니다. 가능하면 영어 파일명을 쓰세요.

### 🟡 SSH, 파일
- **긴 작업은 반드시 `tmux` 안에서** 실행하세요. 그냥 실행하면 노트북을 덮는 순간 작업이 죽습니다.
- 공용 GPU 서버라면 학습 전에 `nvidia-smi`로 **다른 사람이 쓰고 있는지** 확인하세요.
- `scp`는 같은 이름의 파일을 **경고 없이 덮어씁니다.**
- `sudo`는 키 인증과 상관없이 **원격 계정 비밀번호**를 물어봅니다.
- 노트북을 잃어버렸다면 원격의 `~/.ssh/authorized_keys`에서 **그 노트북의 키 줄**(끝에 `home-pc` 같은 이름이 붙은 줄)을 지우고, Tailscale 관리 콘솔에서 그 기기를 **Remove** 하세요.

---

<a id="troubleshooting"></a>
## 11. 🔧 자주 생기는 문제

> 🔍 **만능 디버깅**: `ssh -v lab` → 어디서 실패하는지 자세히 보여줍니다. 원격 로그는 `sudo journalctl -u ssh -f`로 봅니다.
> 전체 목록은 [08-troubleshooting.md](08-troubleshooting.md)에 있습니다.

| 증상 | 해결 |
|---|---|
| `ssh` 명령을 찾을 수 없음 | 내 Windows에 **OpenSSH 클라이언트** 설치 ([3장](#ssh)) |
| `Connection timed out` | `tailscale status`로 원격이 online인지 확인 → 꺼졌거나 절전 상태면 현장에서 확인 / 원격 ufw가 켜져 있으면 `sudo ufw allow ssh` |
| `Connection refused` | 원격 SSH 서버가 꺼져 있음 → `sudo systemctl enable --now ssh` |
| `Permission denied (publickey)` | 원격에서 `chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys && chmod go-w ~` |
| 키 등록했는데 계속 비밀번호를 물어봄 | 공개키 등록 명령([4-②](#key))이 성공했는지 확인 → 원격에서 `cat ~/.ssh/authorized_keys`에 내 키가 있는지 확인 |
| `REMOTE HOST IDENTIFICATION HAS CHANGED` | 원격을 재설치했다면 `ssh-keygen -R 100.x.x.x`. 이유를 모르면 접속하지 말고 확인부터 하세요 |
| RustDesk: 검은 화면, 연결 거부 | 원격에서 `echo $XDG_SESSION_TYPE` → `wayland`이면 [Xorg 전환](#xorg) |
| RustDesk: 재부팅 후 접속 안 됨 | 원격 PC가 로그인 화면에 멈춰 있음 → **자동 로그인** 켜기 |
| mstsc → 내장 RDP: 재부팅 후 비밀번호가 바뀜 | 키링 비밀번호를 빈칸으로 ([2-4 B](#ubuntu-desktop)) |
| mstsc → 내장 RDP: 접속 안 됨 | 화면이 잠겼거나 로그아웃 상태 → 자동 잠금 끄기, 로그인 유지 |
| mstsc → xrdp: 로그인 후 검은 화면, 바로 튕김 | 원격 PC에서 같은 계정 **로그아웃** |
| 몇 달 뒤 갑자기 전부 안 됨 | Tailscale 키 만료 → [1-3](#tailscale) |

---

[← 이전: Ubuntu → Ubuntu](03-ubuntu-to-ubuntu.md) · [전체 목차](../README.md)
