# 🖥️ How-to-SSH

> 노트북이나 집 컴퓨터에서 **학교 연구실 컴퓨터(또는 다른 PC)에 원격으로 접속**하는 방법을 처음부터 끝까지 정리한 가이드입니다.
> **SSH(터미널 접속)** 와 **원격 데스크톱(바탕화면을 그대로 보면서 조작)** 두 가지를 모두 다룹니다.

- 기준 환경: **Windows 11**, **Ubuntu 22.04 LTS**
- 학교 방화벽이나 공유기 뒤에 있어도 되도록 **Tailscale**(무료 VPN)을 기본으로 사용합니다.

---

## 📌 어떤 경우를 다루나요?

"A → B"는 **A(내 컴퓨터)에서 B(원격 컴퓨터)로 접속한다**는 뜻입니다.

| 내 컴퓨터 (접속하는 쪽) | 원격 컴퓨터 (접속당하는 쪽) | 바로가기 |
|---|---|---|
| 🐧 Ubuntu | 🪟 Windows | [4. Ubuntu → Windows](#ubuntu-to-windows) |
| 🪟 Windows | 🪟 Windows | [5. Windows → Windows](#windows-to-windows) |
| 🐧 Ubuntu | 🐧 Ubuntu | [6. Ubuntu → Ubuntu](#ubuntu-to-ubuntu) |
| 🪟 Windows | 🐧 Ubuntu | [7. Windows → Ubuntu (보너스)](#windows-to-ubuntu) |

> 💡 **처음이라면 이 순서로 따라 하세요**
> 1. [0. 개념](#concepts)을 읽고
> 2. [1. Tailscale 설치](#tailscale)를 모든 컴퓨터에 하고
> 3. 원격 컴퓨터 OS에 맞게 [2. Windows 원격 준비](#windows-host) 또는 [3. Ubuntu 원격 준비](#ubuntu-host)를 하고
> 4. 내 경우에 맞는 4~7장을 따라 하면 됩니다.
> 5. **마지막으로 [⚠️ 10. 주의사항 총정리](#cautions)를 꼭 읽어 주세요.** 특히 원격에서 "시스템 종료"를 누르면 연구실에 직접 가야 합니다.

---

## 📚 목차

- [0. 먼저 알아야 할 개념](#concepts)
- [1. 공통 준비: Tailscale 설치](#tailscale)
- [2. 원격 컴퓨터 준비 — Windows](#windows-host)
- [3. 원격 컴퓨터 준비 — Ubuntu](#ubuntu-host)
- [4. Ubuntu → Windows](#ubuntu-to-windows)
- [5. Windows → Windows](#windows-to-windows)
- [6. Ubuntu → Ubuntu](#ubuntu-to-ubuntu)
- [7. Windows → Ubuntu (보너스)](#windows-to-ubuntu)
- [8. 더 편하게 쓰기 (ssh config, VS Code, tmux, 포트포워딩)](#tips)
- [9. 보안 설정](#security)
- [10. ⚠️ 주의사항 총정리](#cautions)
- [11. 문제 해결 (트러블슈팅)](#troubleshooting)
- [12. 명령어 치트시트](#cheatsheet)
- [부록. Tailscale 없이 접속하기](#without-tailscale)

---

### ✍️ 이 문서의 표기 규칙

| 표기 | 의미 | 예시 |
|---|---|---|
| `100.x.x.x` | 원격 컴퓨터의 **Tailscale IP** | `100.101.102.103` |
| `사용자명` | **원격 컴퓨터**의 로그인 계정 이름 | `hong` |
| `lab`, `win` | `~/.ssh/config`에 등록한 별칭 ([8-1](#ssh-config) 참고) | `ssh lab` |
| `# ...` | 명령어 설명(주석). 입력하지 않아도 됩니다. | |

- 🐧 표시는 **Ubuntu 터미널**(`Ctrl + Alt + T`)에서 실행합니다.
- 🪟 표시는 **Windows PowerShell**(시작 버튼 우클릭 → `터미널`)에서 실행합니다.
- **관리자 PowerShell**은 시작 버튼 우클릭 → `터미널(관리자)`로 엽니다.

---

<a id="concepts"></a>
## 0. 먼저 알아야 할 개념

### 0-1. SSH vs 원격 데스크톱

| | SSH | 원격 데스크톱 |
|---|---|---|
| 보이는 것 | **터미널(명령어 창)만** | **바탕화면 전체** |
| 속도 | 매우 빠르고, 느린 인터넷에서도 잘 됨 | 화면을 전송하므로 인터넷 속도 영향이 큼 |
| 주 용도 | 코딩, 딥러닝 학습 돌리기, 파일 전송, 서버 관리 | GUI 프로그램 사용, 화면 확인 |
| 대표 도구 | `ssh`, VS Code Remote-SSH | Windows 원격 데스크톱(RDP), Remmina, RustDesk |

> ✅ **추천: 둘 다 설정해 두세요.** 평소에는 SSH(+VS Code)로 작업하고, 화면이 필요할 때만 원격 데스크톱을 씁니다.
> SSH를 켜 두면 원격 데스크톱이 먹통이 됐을 때 SSH로 들어가서 재부팅하는 등 **복구 수단**도 됩니다.

### 0-2. 용어

- **원격 컴퓨터(호스트, 서버)**: 접속**당하는** 컴퓨터입니다. 예를 들면 연구실 PC이고, **항상 켜져 있어야** 합니다.
- **내 컴퓨터(클라이언트)**: 접속**하는** 컴퓨터입니다. 예를 들면 노트북이나 집 PC입니다.
- **사설 IP / 공인 IP**
  - 학교나 집의 컴퓨터는 대부분 공유기 또는 학교 방화벽 뒤에 있어서 `192.168.x.x`, `10.x.x.x`, `172.16~31.x.x` 같은 **사설 IP**를 씁니다.
  - 사설 IP는 **같은 네트워크 안에서만** 접속할 수 있습니다. 집에서 학교 사설 IP로는 바로 접속할 수 없습니다.

### 0-3. 왜 Tailscale을 쓰나요?

학교 네트워크는 보통 외부에서 들어오는 접속을 막고, 포트포워딩도 마음대로 할 수 없습니다.
**Tailscale**은 이 문제를 이렇게 해결합니다.

- 내 기기들끼리 암호화된 가상 네트워크(VPN, WireGuard 기반)를 만듭니다.
- 각 기기에 **`100.x.x.x` 형태의 고정 IP**를 줍니다.
- 기기끼리 이 IP로 직접 통신하므로 **포트를 열거나 공유기를 설정할 필요가 없습니다.**
- 인터넷에 포트를 노출하지 않으므로 **보안상으로도 안전**합니다.
- 개인 용도라면 무료 플랜으로 충분합니다.

```
 [노트북] ─┐
           ├──(Tailscale 암호화 터널)──> [연구실 PC 100.x.x.x]
 [집 PC] ──┘
```

> ⚠️ **학교 규정 확인**: 일부 학교나 연구실은 외부 원격 접속이나 VPN 프로그램 설치를 제한합니다. 설치 전에 전산팀이나 교수님께 확인하세요.

---

<a id="tailscale"></a>
## 1. 공통 준비: Tailscale 설치

> **모든 기기**(원격 컴퓨터, 노트북, 집 PC)에 설치하고, **모두 같은 계정으로 로그인**합니다.

### 1-1. 계정 만들기

1. https://tailscale.com 에 접속해서 **Get started**를 누릅니다.
2. Google, Microsoft, GitHub 계정 중 하나로 로그인합니다.
3. 앞으로 모든 기기에서 **이 계정 하나**로 로그인합니다.

### 1-2. 🪟 Windows에 설치

1. https://tailscale.com/download/windows 에서 설치 파일을 받아 실행합니다.
2. 설치가 끝나면 작업 표시줄 오른쪽 아래(트레이)의 Tailscale 아이콘 → **Log in** → 브라우저에서 로그인합니다.
3. 내 IP 확인:
   ```powershell
   tailscale ip -4
   ```
4. **(원격 컴퓨터로 쓸 Windows만)** 트레이 아이콘 → **Settings(설정)** → **Run unattended** 체크
   → Windows에 로그인하지 않은 상태(재부팅 직후)에도 Tailscale이 연결됩니다.

### 1-3. 🐧 Ubuntu에 설치

```bash
curl -fsSL https://tailscale.com/install.sh | sh   # 설치
sudo tailscale up                                  # 로그인 (출력되는 URL을 브라우저로 열어서 로그인)
tailscale ip -4                                    # 내 Tailscale IP 확인 (100.x.x.x)
tailscale status                                   # 연결된 기기 목록 확인
```

Ubuntu에서는 Tailscale이 시스템 서비스로 등록되어 **부팅할 때 자동으로 연결**됩니다.

### 1-4. ⚠️ 원격 컴퓨터는 "키 만료" 끄기 (중요)

Tailscale은 기본적으로 **일정 기간(기본 180일)마다 기기에 재로그인을 요구**합니다.
연구실 PC가 어느 날 갑자기 접속이 안 되는 일을 막으려면 원격 컴퓨터의 키 만료를 꺼 두세요.

1. https://login.tailscale.com/admin/machines 에 접속합니다.
2. 원격 컴퓨터 줄 오른쪽의 `...` → **Disable key expiry**를 누릅니다.

### 1-5. IP 대신 기기 이름으로 접속하기 (MagicDNS)

Tailscale의 **MagicDNS**가 켜져 있으면 IP 대신 기기 이름으로 접속할 수 있습니다. 새 계정에는 기본으로 켜져 있습니다.

```bash
ssh 사용자명@lab-pc      # 100.x.x.x 대신 기기 이름 사용
```

- 기기 이름은 관리 콘솔(Machines)에서 확인하거나 바꿀 수 있습니다.
- 안 되면 관리 콘솔 → **DNS** 탭에서 MagicDNS를 켜세요.
- 이 문서는 헷갈리지 않도록 계속 `100.x.x.x`로 표기합니다.

### 1-6. 연결 테스트

내 컴퓨터에서 원격 컴퓨터로 핑을 보내 봅니다.

```bash
tailscale ping 100.x.x.x
```

`pong from ...`이 나오면 네트워크는 준비가 끝난 것입니다.

---

<a id="windows-host"></a>
## 2. 원격 컴퓨터 준비 — Windows

> **원격 컴퓨터가 Windows인 경우**([4장](#ubuntu-to-windows), [5장](#windows-to-windows)) 원격 Windows PC 앞에서 **한 번만** 해 두면 됩니다.

### 2-0. 먼저 확인할 것

#### ① Windows 에디션
`설정` → `시스템` → `정보` → `Windows 사양` → **에디션**

| 에디션 | SSH | Windows 원격 데스크톱(RDP)으로 **접속받기** |
|---|---|---|
| Pro / Education / Enterprise | ✅ | ✅ |
| **Home** | ✅ | ❌ → [RustDesk](#windows-rustdesk)를 사용하세요 |

> Home 에디션도 다른 PC에 RDP로 **접속하는 것**은 됩니다. **접속받는 것**만 안 됩니다.

#### ② 사용자 이름 확인
```powershell
whoami
# 출력 예: desktop-abc123\hong  →  SSH 사용자명은 역슬래시 뒤의 "hong"
```

#### ③ Microsoft 계정인지 확인
- Windows에 **이메일 주소로 로그인**한다면 Microsoft 계정입니다.
- 이 경우 SSH와 RDP 비밀번호는 **PIN이 아니라 Microsoft 계정 비밀번호**입니다.
- ⚠️ `설정` → `계정` → `로그인 옵션` → **"보안 향상을 위해 이 장치의 Microsoft 계정에 대해 Windows Hello 로그인만 허용"** 을 **끄세요.**
  이 옵션이 켜져 있으면 비밀번호로 원격 로그인이 안 될 수 있습니다.
- 끈 뒤에는 **한 번 로그아웃했다가 PIN 말고 비밀번호로 로그인**해 두세요. 이렇게 해야 원격 로그인에서 문제가 덜 생깁니다.

#### ④ 관리자 계정인지 확인
```powershell
net localgroup administrators
```
목록에 내 사용자명이 있으면 **관리자 계정**입니다. 개인 PC는 대부분 관리자입니다. 이 정보는 [SSH 키 등록](#ubuntu-to-windows-key) 때 필요합니다.

### 2-1. OpenSSH 서버 설치

**방법 A — 설정 앱(GUI)**
`설정` → `시스템` → `선택적 기능` → `기능 보기`(선택적 기능 추가) → **"OpenSSH 서버"** 검색 → 체크 → 설치

**방법 B — 관리자 PowerShell**
```powershell
# 설치 상태 확인 (State : Installed / NotPresent)
Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH*'

# OpenSSH 서버 설치
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
```

### 2-2. SSH 서비스 시작 + 부팅 시 자동 시작 (관리자 PowerShell)

```powershell
Start-Service sshd
Set-Service -Name sshd -StartupType Automatic
Get-Service sshd        # Status 가 Running 이면 성공
```

### 2-3. 방화벽 확인 (관리자 PowerShell)

설치할 때 방화벽 규칙이 자동으로 만들어집니다. 확인만 해 보세요.

```powershell
Get-NetFirewallRule -Name *OpenSSH-Server* | Select-Object Name, Enabled, Profile
```

아무것도 안 나오면 직접 만듭니다.

```powershell
New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' `
  -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
```

### 2-4. (선택) SSH 기본 셸을 PowerShell로 바꾸기

Windows SSH에 접속하면 기본으로 `cmd`(명령 프롬프트)가 뜹니다. PowerShell이 더 편하므로 바꾸는 것을 추천합니다.

```powershell
New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell `
  -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -PropertyType String -Force
```

### 2-5. 원격 데스크톱(RDP) 켜기 — Pro / Education / Enterprise

**방법 A — 설정 앱**
`설정` → `시스템` → `원격 데스크톱` → **켬** → 확인
- "연결에 네트워크 수준 인증(NLA) 필요"는 **켠 채로** 두세요. 보안에 좋습니다.

**방법 B — 관리자 PowerShell**
```powershell
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name fDenyTSConnections -Value 0
Enable-NetFirewallRule -Group "@FirewallAPI.dll,-28752"   # "원격 데스크톱" 방화벽 규칙 켜기 (언어 무관)
```

> 📝 **RDP 동작 방식 알아두기**
> - RDP로 접속하면 **원격 PC의 실제 모니터는 잠금 화면**이 됩니다.
> - 하지만 **같은 로그인 세션**을 이어받기 때문에, 원격 PC에 열어 둔 창과 프로그램이 **그대로 보입니다.**
> - 원격 PC 앞에서 누가 로그인하면 원격 연결은 끊깁니다. Windows는 한 번에 한 사람만 쓸 수 있습니다.
> - 모니터 화면을 잠그지 않고 **실제 화면을 같이 보고 싶다면** RustDesk를 쓰세요.

<a id="windows-rustdesk"></a>
### 2-6. RustDesk 설치 (Home 에디션이거나, 실제 화면을 그대로 공유하고 싶을 때)

1. https://github.com/rustdesk/rustdesk/releases 에서 최신 버전의 Windows용 `rustdesk-x.x.x-x86_64.exe`를 받습니다.
2. 실행 → 왼쪽 아래의 **설치(Install)** 를 눌러 **정식 설치**합니다.
   정식 설치해야 서비스로 실행되어 **아무도 없어도(무인) 접속**할 수 있습니다.
3. RustDesk 설정(⚙) → **보안(Security)** → **잠금 해제(Unlock security settings)**
   - **IP 직접 접속 허용 (Enable direct IP access)** 켜기 (기본 포트 21118)
   - **영구 비밀번호 사용 (Use permanent password)** → 강력한 비밀번호 설정
4. Tailscale로 직접 IP 접속을 하므로 RustDesk 공용 서버를 거치지 않습니다. 그래서 빠르고 안전합니다.

> 버전에 따라 메뉴 이름이 조금 다를 수 있습니다.

### 2-7. 절전 끄기 & 자동 재시작 대비

원격 컴퓨터가 **잠들면 접속할 수 없습니다.**

**설정 앱**: `설정` → `시스템` → `전원 및 배터리` → `화면 및 절전` → **"전원 연결 시 절전 모드로 전환" → 안 함**

**관리자 PowerShell**:
```powershell
powercfg /change standby-timeout-ac 0      # 절전 안 함
powercfg /change hibernate-timeout-ac 0    # 최대 절전 안 함
```

추가로 확인할 것:
- **Windows 업데이트 자동 재시작**: `설정` → `Windows 업데이트` → `고급 옵션` → **사용 시간**을 설정해 두세요.
  재부팅돼도 SSH(`sshd`), Tailscale(Run unattended), RDP, RustDesk 서비스는 **로그인 전에도** 동작합니다.
- **정전 대비**: BIOS 설정에서 `Restore on AC Power Loss`(또는 `AC Power Recovery`)를 **Power On**으로 바꿔 두면, 전원이 돌아왔을 때 PC가 자동으로 켜집니다.

### ✅ Windows 원격 컴퓨터 체크리스트

- [ ] Tailscale 설치, 로그인, **Run unattended** 체크, **키 만료 끄기**
- [ ] OpenSSH 서버 설치, `sshd` 서비스 실행 중 + 자동 시작
- [ ] (Pro 이상) 원격 데스크톱 켬 / (Home) RustDesk 설치 + 영구 비밀번호
- [ ] Windows Hello 전용 로그인 옵션 끔
- [ ] 절전 모드 끔
- [ ] Tailscale IP(`tailscale ip -4`)와 사용자명(`whoami`) 메모

---

<a id="ubuntu-host"></a>
## 3. 원격 컴퓨터 준비 — Ubuntu

> **원격 컴퓨터가 Ubuntu인 경우**([6장](#ubuntu-to-ubuntu), [7장](#windows-to-ubuntu)) 원격 Ubuntu PC 앞에서 **한 번만** 해 두면 됩니다.

### 3-1. SSH 서버 설치

```bash
sudo apt update
sudo apt install -y openssh-server      # SSH 서버 설치
sudo systemctl enable --now ssh         # 지금 시작 + 부팅 시 자동 시작
systemctl status ssh                    # "active (running)" 이면 성공 (q 로 나가기)
```

### 3-2. 방화벽(ufw) 확인

Ubuntu 데스크톱은 기본적으로 방화벽이 꺼져 있습니다. 켜져 있다면 SSH를 허용합니다.

```bash
sudo ufw status              # Status: inactive 이면 아무것도 안 해도 됨
sudo ufw allow ssh           # Status: active 인 경우에만 실행
```

### 3-3. 접속 정보 확인

```bash
whoami           # 사용자명
tailscale ip -4  # Tailscale IP (100.x.x.x)
hostname -I      # 같은 네트워크 안에서 쓰는 내부 IP (참고용)
```

### 3-4. 원격 데스크톱 방법 고르기

Ubuntu에는 방법이 세 가지 있습니다. **A와 B 중 하나를 고르는 것을 추천**합니다.

| 방법 | 실제 모니터 화면 그대로? | 장점 | 단점 |
|---|---|---|---|
| **A. RustDesk** (추천) | ✅ | 안정적, 무인 접속, Windows와 Ubuntu 모두에서 같은 방식 | Xorg로 전환 필요, 설치 필요 |
| **B. Ubuntu 내장 원격 데스크톱(RDP)** | ✅ | 설치 없음, Windows 기본 앱으로 접속 | 로그인된 상태 필요, 잠금 화면에서 불안정 |
| **C. xrdp** | ❌ (별도 가상 세션) | 로그인 안 해도 접속 가능 | 실제 화면이 아님, 같은 계정이 로그인 중이면 충돌 |

> ⚠️ **B와 C는 둘 다 3389 포트를 쓰므로 동시에 켜지 마세요.**

#### 🅰️ 방법 A: RustDesk (실제 화면, 추천)

**① 화면 방식을 Wayland에서 Xorg로 전환**
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
- **IP 직접 접속 허용 (Enable direct IP access)** 켜기
- **영구 비밀번호 사용 (Use permanent password)** → 강력한 비밀번호 설정

**④ 자동 로그인 켜기**
`설정` → `사용자` → 오른쪽 위 **잠금 해제** → **자동 로그인** 켜기
→ 재부팅해도 바탕화면까지 자동으로 올라와서 RustDesk로 바로 접속할 수 있습니다.

#### 🅱️ 방법 B: Ubuntu 내장 원격 데스크톱 (설치 불필요)

1. `설정` → `공유(Sharing)` → 오른쪽 위 **토글 켜기**
2. **원격 데스크톱(Remote Desktop)** 클릭
   - **원격 데스크톱** 켜기
   - **원격 제어(Remote Control)** 켜기 (끄면 보기만 가능)
3. **인증(Authentication)** 에서 **사용자 이름과 비밀번호**를 설정합니다.
   이 값은 **Ubuntu 로그인 비밀번호와 별개**이고, 원격 접속할 때 이 값을 씁니다.

> `공유` 메뉴가 없으면 `sudo apt install -y gnome-remote-desktop`으로 설치하세요.

⚠️ 방법 B의 주의사항
- 원격 PC에 **사용자가 로그인해 있는 상태**여야 합니다. 로그인 화면에서는 접속할 수 없습니다.
- **화면이 잠겨 있으면** 접속이 잘 안 됩니다 → [3-5](#ubuntu-power)에서 자동 화면 잠금을 끄세요.
- **자동 로그인을 쓰면 재부팅할 때마다 원격 데스크톱 비밀번호가 바뀌는 문제**가 있습니다. 로그인 키링이 잠겨 있기 때문입니다.
  - 해결: `암호 및 키`(Passwords and Keys, `seahorse`) 앱 → `로그인(Login)` 키링 우클릭 → **비밀번호 변경** → 새 비밀번호를 **빈칸**으로 둡니다.
  - (키링 안의 저장된 비밀번호가 암호화되지 않은 상태가 되므로, 개인 전용 PC에서만 하세요.)
- 방법 A 때문에 Xorg로 전환했다면 방법 B가 잘 안 될 수 있으니 **A와 B 중 하나만** 쓰세요.

#### 🅲 방법 C: xrdp (별도 세션)

```bash
sudo apt install -y xrdp
sudo systemctl enable --now xrdp
sudo adduser xrdp ssl-cert           # 인증서 접근 권한
sudo ufw allow 3389/tcp              # ufw 가 켜져 있는 경우에만
```

- 접속하면 **새 바탕화면 세션**이 열립니다. 연구실 모니터에 떠 있는 창은 보이지 않습니다.
- 원격 PC에서 **같은 계정이 로그인된 상태면 검은 화면**이 뜹니다 → 원격 PC에서 로그아웃해 두세요.

<a id="ubuntu-power"></a>
### 3-5. 절전 & 화면 잠금 끄기

**설정 앱**
- `설정` → `전원` → **빈 화면: 안 함**, **자동 절전: 끔**
- `설정` → `개인 정보` → `화면`(또는 `화면 잠금`) → **자동 화면 잠금: 끔**

**터미널**
```bash
# 절전/최대 절전 완전히 막기
sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target

# 화면 꺼짐 & 자동 잠금 끄기 (현재 사용자 기준, sudo 없이 실행)
gsettings set org.gnome.desktop.session idle-delay 0
gsettings set org.gnome.desktop.screensaver lock-enabled false
```

> 나중에 절전을 다시 켜려면: `sudo systemctl unmask sleep.target suspend.target hibernate.target hybrid-sleep.target`

- **정전 대비**: BIOS에서 `Restore on AC Power Loss` → **Power On**으로 설정하세요.
- **모니터는 꺼도 됩니다.** 본체만 켜져 있으면 됩니다.

### ✅ Ubuntu 원격 컴퓨터 체크리스트

- [ ] Tailscale 설치, 로그인, **키 만료 끄기**
- [ ] `openssh-server` 설치, `ssh` 서비스 active
- [ ] 원격 데스크톱: A(RustDesk + Xorg + 자동 로그인) / B(내장 RDP) / C(xrdp) 중 선택
- [ ] 절전, 화면 잠금 끔
- [ ] Tailscale IP(`tailscale ip -4`)와 사용자명(`whoami`) 메모

---

<a id="ubuntu-to-windows"></a>
## 4. 🐧 Ubuntu → 🪟 Windows

> **준비물**: 원격 Windows에서 [2장](#windows-host) 완료, 두 컴퓨터 모두 [Tailscale](#tailscale) 로그인

### 4-1. SSH로 접속하기

🐧 Ubuntu 터미널:
```bash
ssh 사용자명@100.x.x.x
```

1. 처음 접속하면 아래 메시지가 나옵니다. `yes`를 입력합니다.
   ```
   Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
   ```
2. 비밀번호를 입력합니다. **입력해도 화면에 아무것도 안 보이는 게 정상**입니다.
   Microsoft 계정이면 **Microsoft 계정 비밀번호**를 입력합니다.
3. 아래처럼 프롬프트가 바뀌면 성공입니다.
   ```
   PS C:\Users\hong>          # 기본 셸을 PowerShell로 바꾼 경우
   C:\Users\hong>             # 기본(cmd)인 경우
   ```
4. 접속을 끝내려면 `exit`를 입력합니다.

> 💡 이제부터 입력하는 명령은 **Windows에서 실행**됩니다. `ls`, `cd`, `pwd`, `cat` 정도는 PowerShell에서도 동작하지만, `apt`, `grep` 같은 리눅스 명령은 안 됩니다.

<a id="ubuntu-to-windows-key"></a>
### 4-2. 비밀번호 없이 접속하기 (SSH 키 인증)

매번 비밀번호를 입력하지 않도록 **키 인증**을 설정합니다. 비밀번호보다 훨씬 안전하기도 합니다.

**① 🐧 Ubuntu에서 키 만들기** (이미 `~/.ssh/id_ed25519`가 있으면 건너뛰세요)
```bash
ssh-keygen -t ed25519 -C "ubuntu-laptop"
# 저장 위치: 그냥 Enter
# passphrase(키 비밀번호): 그냥 Enter 두 번 (없이) 또는 원하는 비밀번호
```
- `~/.ssh/id_ed25519`는 **개인키**입니다. **절대 남에게 주지 마세요.**
- `~/.ssh/id_ed25519.pub`는 **공개키**입니다. 이 파일을 원격 컴퓨터에 등록합니다.

**② 🐧 공개키를 Windows로 복사**
```bash
scp ~/.ssh/id_ed25519.pub 사용자명@100.x.x.x:key.pub
```
(비밀번호 입력. 원격 Windows의 `C:\Users\사용자명\key.pub`로 복사됩니다.)

**③ Windows에 접속해서 키 등록**
```bash
ssh 사용자명@100.x.x.x
```

접속한 뒤, 기본 셸이 `cmd`(`C:\Users\...>`)라면 먼저 `powershell`을 입력해서 PowerShell로 바꿉니다.

**🔸 관리자 계정인 경우 (대부분의 개인 PC)**
Windows는 관리자 계정의 키를 **사용자 폴더가 아니라 `C:\ProgramData\ssh\administrators_authorized_keys`에서 읽습니다.** 이 부분을 가장 많이 틀립니다.
```powershell
Get-Content $HOME\key.pub | Add-Content -Force C:\ProgramData\ssh\administrators_authorized_keys
icacls.exe C:\ProgramData\ssh\administrators_authorized_keys /inheritance:r /grant "Administrators:F" /grant "SYSTEM:F"
Remove-Item $HOME\key.pub
exit
```
> `icacls` 명령으로 파일 권한을 "관리자와 SYSTEM만" 접근하도록 바꿉니다. 권한이 넓으면 SSH가 이 파일을 무시합니다.

**🔸 일반(표준) 계정인 경우**
```powershell
New-Item -ItemType Directory -Force $HOME\.ssh | Out-Null
Get-Content $HOME\key.pub | Add-Content -Force $HOME\.ssh\authorized_keys
Remove-Item $HOME\key.pub
exit
```

**④ 🐧 테스트**
```bash
ssh 사용자명@100.x.x.x      # 비밀번호 없이 바로 접속되면 성공!
```

### 4-3. 짧은 이름으로 접속하기 (ssh config)

🐧 `~/.ssh/config` 파일을 만들거나 엽니다.
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

`Ctrl + O` → Enter → `Ctrl + X`로 저장하고 나간 뒤, 권한을 설정합니다.
```bash
chmod 600 ~/.ssh/config
ssh win          # 이제 이것만 입력하면 접속!
```

### 4-4. 바탕화면 보기 — Remmina로 RDP 접속 (Windows Pro 이상)

Remmina는 Ubuntu에 기본으로 설치된 원격 데스크톱 프로그램입니다. 없다면 설치합니다.
```bash
sudo apt install -y remmina remmina-plugin-rdp
```

1. 프로그램 목록에서 **Remmina**를 실행합니다.
2. 왼쪽 위 **`+`** (새 연결 프로필)를 누릅니다.
3. 입력합니다.
   | 항목 | 값 |
   |---|---|
   | Name | `연구실 윈도우` (아무거나) |
   | Protocol | **RDP - Remote Desktop Protocol** |
   | Server | `100.x.x.x` |
   | Username | Windows 사용자명 (Microsoft 계정이면 **이메일 전체**) |
   | Password | Windows 비밀번호 (Microsoft 계정 비밀번호) |
   | Resolution | **Use client resolution** (내 화면 크기에 맞춤) |
   | Colour depth | 기본값. 화면이 깨지면 `True colour (24 bpp)` |
4. **Save and Connect**를 누릅니다.
5. 인증서 확인 창이 뜨면 **Yes(수락)** 를 누릅니다.

💡 Remmina 팁
- 왼쪽(또는 위) 도구 모음에서 **전체 화면**, **화면 크기 맞춤(Scaling)** 을 켤 수 있습니다.
- 도구 모음 → **공유 폴더** 설정으로 Ubuntu 폴더를 Windows에서 열 수 있습니다.
- 창을 닫으면 **연결만 끊기고** Windows에서 실행 중인 프로그램은 계속 돌아갑니다.

### 4-5. 바탕화면 보기 — RustDesk (Windows Home이거나 실제 화면 공유)

1. 🐧 Ubuntu에도 RustDesk를 설치합니다. ([3-4 A의 ②](#ubuntu-host)와 같은 `.deb` 설치 방법)
   - 접속하는 쪽이므로 **Ubuntu를 Xorg로 바꿀 필요는 없습니다.**
2. RustDesk를 실행하고 **"원격 ID(Remote ID)"** 입력칸에 `100.x.x.x`를 입력 → **연결(Connect)**
3. Windows에 설정한 **영구 비밀번호**를 입력합니다.

### 4-6. 파일 주고받기

```bash
# Ubuntu → Windows (Windows의 사용자 폴더 기준 경로)
scp ./report.pdf win:Documents/

# Windows → Ubuntu
scp win:Documents/result.csv ./

# 폴더 통째로
scp -r ./project win:Documents/
```

> ⚠️ **Windows 바탕화면이 OneDrive와 동기화되는 경우** 바탕화면 실제 경로는 `C:\Users\사용자명\OneDrive\바탕 화면`입니다.
> 경로에 공백이 있어서 `scp`가 헷갈리므로 `sftp`를 쓰는 게 편합니다.
> ```bash
> sftp win
> sftp> cd "OneDrive/바탕 화면"
> sftp> put report.pdf        # 올리기
> sftp> get result.csv        # 내려받기
> sftp> exit
> ```

GUI가 편하다면: Ubuntu 파일 관리자(Nautilus) → 왼쪽 **다른 위치(Other Locations)** → 아래 **서버 연결** 칸에 `sftp://사용자명@100.x.x.x/` 입력 → 연결

---

<a id="windows-to-windows"></a>
## 5. 🪟 Windows → 🪟 Windows

> **준비물**: 원격 Windows에서 [2장](#windows-host) 완료, 두 컴퓨터 모두 [Tailscale](#tailscale) 로그인

Windows 11에는 **SSH 클라이언트가 기본으로 들어 있습니다.** 확인해 보세요.
```powershell
ssh -V          # OpenSSH_for_Windows_... 가 나오면 OK
```
안 나오면: `설정` → `시스템` → `선택적 기능` → `기능 보기` → **OpenSSH 클라이언트** 설치

### 5-1. SSH로 접속하기

🪟 내 PC의 PowerShell:
```powershell
ssh 사용자명@100.x.x.x
```
- 처음 접속하면 `yes`를 입력합니다.
- 비밀번호는 화면에 안 보이는 게 정상입니다. Microsoft 계정이면 Microsoft 계정 비밀번호를 입력합니다.
- 접속을 끝내려면 `exit`를 입력합니다.

### 5-2. 비밀번호 없이 접속하기 (SSH 키 인증)

**① 🪟 내 PC에서 키 만들기**
```powershell
ssh-keygen -t ed25519 -C "home-pc"
# Enter 3번 → C:\Users\내이름\.ssh\id_ed25519 (개인키), id_ed25519.pub (공개키) 생성
```

**② 🪟 공개키를 원격 Windows로 복사**
```powershell
scp $env:USERPROFILE\.ssh\id_ed25519.pub 사용자명@100.x.x.x:key.pub
```

**③ 원격 Windows에 접속해서 키 등록**
```powershell
ssh 사용자명@100.x.x.x
```
(기본 셸이 `cmd`면 접속 후 `powershell` 입력)

🔸 **관리자 계정인 경우 (대부분)**
```powershell
Get-Content $HOME\key.pub | Add-Content -Force C:\ProgramData\ssh\administrators_authorized_keys
icacls.exe C:\ProgramData\ssh\administrators_authorized_keys /inheritance:r /grant "Administrators:F" /grant "SYSTEM:F"
Remove-Item $HOME\key.pub
exit
```

🔸 **일반 계정인 경우**
```powershell
New-Item -ItemType Directory -Force $HOME\.ssh | Out-Null
Get-Content $HOME\key.pub | Add-Content -Force $HOME\.ssh\authorized_keys
Remove-Item $HOME\key.pub
exit
```

**④ 테스트**
```powershell
ssh 사용자명@100.x.x.x      # 비밀번호 없이 접속되면 성공
```

### 5-3. 짧은 이름으로 접속하기 (ssh config)

🪟 내 PC PowerShell:
```powershell
# config 파일이 없으면 만들기 (있으면 그대로 둠)
if (!(Test-Path $env:USERPROFILE\.ssh\config)) { New-Item -ItemType File $env:USERPROFILE\.ssh\config }
notepad $env:USERPROFILE\.ssh\config
```
> 메모장으로 새 파일을 저장하면 `config.txt`로 저장될 수 있어서, 위처럼 **파일을 먼저 만들고** 여는 것입니다.

아래 내용을 넣고 저장합니다.
```
Host win
    HostName 100.x.x.x
    User 사용자명
    IdentityFile ~/.ssh/id_ed25519
    ServerAliveInterval 60
```

```powershell
ssh win
```

### 5-4. 바탕화면 보기 — 원격 데스크톱 연결 (mstsc)

> 원격 PC가 **Pro / Education / Enterprise**여야 합니다. Home이면 [5-5 RustDesk](#w2w-rustdesk)를 쓰세요.

1. `Win + R` → `mstsc` 입력 → Enter (또는 시작 → **"원격 데스크톱 연결"** 검색)
2. **컴퓨터**: `100.x.x.x`
3. **옵션 표시**를 누릅니다.
   - **일반** 탭: 사용자 이름 입력(Microsoft 계정이면 이메일), ✅ **자격 증명을 저장할 수 있음**
   - **디스플레이** 탭: 해상도(전체 화면 추천), 여러 모니터를 쓰면 **"내 모든 모니터를 원격 세션에 사용"**
   - **로컬 리소스** 탭: ✅ 클립보드, **자세히** → ✅ 드라이브 (내 PC 드라이브를 원격에서 열 수 있어서 파일 복사에 편함)
   - **일반** 탭 → **다른 이름으로 저장** → 바탕화면에 `.rdp` 파일로 저장하면 다음부터는 더블클릭만 하면 됩니다.
4. **연결** → 비밀번호 입력 → 인증서 경고가 나오면 **"예"**

💡 사용 팁
| 하고 싶은 것 | 방법 |
|---|---|
| 전체 화면 ↔ 창 모드 | `Ctrl + Alt + Break` (또는 위쪽 연결 표시줄 사용) |
| 복사/붙여넣기 | 평소처럼 `Ctrl + C` / `Ctrl + V` (클립보드 공유 켰을 때) |
| 파일 옮기기 | 파일 복사/붙여넣기, 또는 원격 PC 파일 탐색기에서 `내 PC` → 리디렉션된 내 드라이브 |
| **연결만 끊기** | 창 닫기(X) → 원격 PC에서 **프로그램은 계속 실행됨** ✅ |
| 로그아웃 | 원격 PC에서 시작 → 로그아웃 → **실행 중이던 프로그램이 모두 종료됨** ⚠️ |

> 오래 걸리는 작업을 돌려 놓고 나갈 때는 반드시 **"창 닫기(연결 끊기)"** 를 하세요.

<a id="w2w-rustdesk"></a>
### 5-5. 바탕화면 보기 — RustDesk (Home 에디션이거나 실제 화면 공유)

1. 🪟 내 PC에도 RustDesk를 설치합니다. 접속만 할 거라면 설치하지 않고 실행만 해도 됩니다.
2. **원격 ID** 칸에 `100.x.x.x` 입력 → **연결**
3. 원격 PC의 **영구 비밀번호**를 입력합니다.

RDP와 달리 **원격 PC의 모니터 화면이 잠기지 않고** 같은 화면이 양쪽에 보입니다.

### 5-6. 파일 주고받기

```powershell
scp .\report.pdf win:Documents/          # 내 PC → 원격
scp win:Documents/result.csv .           # 원격 → 내 PC
scp -r .\project win:Documents/          # 폴더 통째로
```
- RDP를 쓰는 중이라면 그냥 **복사 → 붙여넣기**로도 파일이 옮겨집니다.
- GUI 프로그램이 편하다면 [WinSCP](https://winscp.net)(SFTP)도 좋습니다.

---

<a id="ubuntu-to-ubuntu"></a>
## 6. 🐧 Ubuntu → 🐧 Ubuntu

> **준비물**: 원격 Ubuntu에서 [3장](#ubuntu-host) 완료, 두 컴퓨터 모두 [Tailscale](#tailscale) 로그인

### 6-1. SSH로 접속하기

```bash
ssh 사용자명@100.x.x.x
```
- 처음 접속하면 `yes`를 입력하고, 원격 Ubuntu 로그인 비밀번호를 입력합니다.
- 프롬프트가 `사용자명@원격호스트이름:~$`으로 바뀌면 성공입니다.
- 끝내려면 `exit` 또는 `Ctrl + D`를 누릅니다.

### 6-2. 비밀번호 없이 접속하기 (SSH 키 인증)

Ubuntu끼리는 `ssh-copy-id` 한 줄이면 끝입니다.

```bash
ssh-keygen -t ed25519 -C "my-laptop"      # 키 만들기 (이미 있으면 생략)
ssh-copy-id 사용자명@100.x.x.x             # 공개키를 원격에 등록 (비밀번호 한 번 입력)
ssh 사용자명@100.x.x.x                     # 비밀번호 없이 접속되면 성공
```

### 6-3. 짧은 이름으로 접속하기 (ssh config)

```bash
nano ~/.ssh/config
```
```
Host lab
    HostName 100.x.x.x
    User 사용자명
    IdentityFile ~/.ssh/id_ed25519
    ServerAliveInterval 60
```
```bash
chmod 600 ~/.ssh/config
ssh lab
```

### 6-4. 바탕화면 보기

원격 Ubuntu에서 [3-4](#ubuntu-host)에서 고른 방법에 따라 접속합니다.

#### 원격이 🅰️ RustDesk인 경우
1. 내 Ubuntu에도 RustDesk `.deb`를 설치합니다. 접속하는 쪽은 Xorg로 바꿀 필요가 없습니다.
2. **원격 ID** 칸에 `100.x.x.x` 입력 → 연결 → 영구 비밀번호 입력

#### 원격이 🅱️ 내장 원격 데스크톱 또는 🅲 xrdp인 경우 → Remmina
1. **Remmina** 실행 → **`+`**
2. Protocol: **RDP**, Server: `100.x.x.x`
3. Username / Password
   - 🅱️ 내장 원격 데스크톱: 원격 PC의 `설정 → 공유 → 원격 데스크톱`에서 **정한 사용자 이름/비밀번호**
   - 🅲 xrdp: 원격 Ubuntu **로그인 계정과 비밀번호**
4. **Save and Connect** → 인증서 수락

> 연결되자마자 끊기면 프로필 편집 → **Colour depth**를 다른 값으로 바꿔 보세요.

#### 창 하나만 띄우기 — X11 포워딩 (가벼운 방법)
바탕화면 전체가 아니라 **프로그램 창 하나만** 내 화면에 띄울 수 있습니다.
```bash
ssh -X lab
gedit &           # 원격의 텍스트 편집기가 내 화면에 뜸
nautilus &        # 원격의 파일 관리자
```
> 인터넷이 느리면 많이 버벅입니다. 같은 네트워크 안이나 가벼운 프로그램에 적합합니다.

### 6-5. 파일 주고받기

```bash
# scp: 간단한 복사
scp ./data.zip lab:~/                   # 내 PC → 원격
scp lab:~/results/out.csv ./            # 원격 → 내 PC
scp -r ./project lab:~/                 # 폴더

# rsync: 큰 폴더 / 이어받기 / 변경분만 동기화 (추천)
rsync -avz --progress ./dataset/ lab:~/dataset/
rsync -avz --progress lab:~/results/ ./results/
```
> `rsync`는 끊겨도 다시 실행하면 **이어서 전송**하고, 바뀐 파일만 보냅니다. 데이터셋처럼 큰 파일에 좋습니다.

**GUI로 하기**: 파일 관리자(Nautilus) → **다른 위치** → **서버 연결** 칸에 `sftp://lab/` 또는 `sftp://사용자명@100.x.x.x/` 입력
→ 원격 폴더가 내 파일 관리자에 나타나서 드래그 앤 드롭으로 복사할 수 있습니다.

---

<a id="windows-to-ubuntu"></a>
## 7. 🪟 Windows → 🐧 Ubuntu (보너스)

> **준비물**: 원격 Ubuntu에서 [3장](#ubuntu-host) 완료, 두 컴퓨터 모두 [Tailscale](#tailscale) 로그인
> 노트북이나 집 PC가 Windows이고 연구실이 Ubuntu인 **가장 흔한 조합**입니다.

### 7-1. SSH로 접속하기
🪟 PowerShell:
```powershell
ssh 사용자명@100.x.x.x
```

### 7-2. 키 인증
```powershell
ssh-keygen -t ed25519 -C "home-pc"     # 이미 있으면 생략

# Windows에는 ssh-copy-id 가 없으므로 아래 한 줄로 대신합니다
type $env:USERPROFILE\.ssh\id_ed25519.pub | ssh 사용자명@100.x.x.x "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"

ssh 사용자명@100.x.x.x                  # 비밀번호 없이 접속되면 성공
```

### 7-3. ssh config
[5-3](#windows-to-windows)과 같은 방법으로 `C:\Users\내이름\.ssh\config`에 추가합니다.
```
Host lab
    HostName 100.x.x.x
    User 사용자명
    IdentityFile ~/.ssh/id_ed25519
    ServerAliveInterval 60
```

### 7-4. 바탕화면 보기
| 원격 Ubuntu 설정 | Windows에서 접속하는 방법 |
|---|---|
| 🅰️ RustDesk | RustDesk 실행 → 원격 ID에 `100.x.x.x` → 영구 비밀번호 |
| 🅱️ 내장 원격 데스크톱 | `mstsc` → `100.x.x.x` → **공유 설정에서 정한** 사용자 이름/비밀번호 |
| 🅲 xrdp | `mstsc` → `100.x.x.x` → Ubuntu 로그인 계정/비밀번호 (세션: Xorg) |

### 7-5. 파일 주고받기
```powershell
scp .\data.zip lab:~/
scp lab:~/results/out.csv .
scp -r .\project lab:~/
```
GUI로 하려면 **WinSCP**에서 프로토콜 `SFTP`, 호스트 `100.x.x.x`로 접속하면 됩니다.

---

<a id="tips"></a>
## 8. 더 편하게 쓰기

<a id="ssh-config"></a>
### 8-1. ssh config로 여러 대 관리하기

`~/.ssh/config` (Windows: `C:\Users\내이름\.ssh\config`)
```
# 연구실 Ubuntu
Host lab
    HostName 100.101.102.103
    User hong
    IdentityFile ~/.ssh/id_ed25519

# 연구실 Windows
Host lab-win
    HostName 100.101.102.104
    User hong
    IdentityFile ~/.ssh/id_ed25519

# 모든 호스트 공통 설정
Host *
    ServerAliveInterval 60      # 60초마다 신호를 보내서 가만히 있어도 연결이 안 끊기게
    ServerAliveCountMax 3
```
이제 `ssh lab`, `ssh lab-win`, `scp file lab:~/`처럼 짧게 쓸 수 있습니다.

### 8-2. VS Code Remote-SSH (강력 추천 ⭐)

원격 컴퓨터의 파일을 **내 컴퓨터의 VS Code에서 바로 편집하고 실행**할 수 있습니다.

1. VS Code 확장(Extensions)에서 **Remote - SSH** (Microsoft)를 설치합니다.
2. `F1` (또는 `Ctrl + Shift + P`) → **Remote-SSH: Connect to Host...**
3. `~/.ssh/config`에 등록한 `lab` 또는 `lab-win`이 목록에 뜨면 선택합니다.
4. 처음이면 원격 OS(Linux / Windows)를 선택합니다. 원격에 VS Code 서버가 자동으로 설치됩니다.
5. **Open Folder**로 원격 폴더를 엽니다.
6. `` Ctrl + ` `` 로 여는 터미널도 **원격 컴퓨터의 터미널**입니다.

> Python 같은 확장은 **원격 쪽에 따로 설치**해야 합니다. 확장 목록의 "Install in SSH: lab" 버튼을 누르세요.

### 8-3. tmux — SSH가 끊겨도 작업 유지하기 (Ubuntu 원격)

SSH로 딥러닝 학습을 돌리다가 **노트북을 덮거나 와이파이가 끊기면 작업도 같이 죽습니다.**
`tmux` 안에서 실행하면 연결이 끊겨도 계속 돌아갑니다.

```bash
sudo apt install -y tmux      # 원격 Ubuntu에 설치

tmux new -s train             # "train" 이라는 세션 만들기
python train.py               # 세션 안에서 작업 실행
# Ctrl + b 누르고 손 뗀 뒤 d  → 세션에서 빠져나오기 (작업은 계속 실행됨)

tmux ls                       # 세션 목록
tmux attach -t train          # 다시 들어가기 (다음 날 다른 컴퓨터에서 접속해도 OK)
```

| tmux 단축키 (`Ctrl + b` 누른 뒤) | 기능 |
|---|---|
| `d` | 빠져나오기 (detach) |
| `c` | 새 창 |
| `n` / `p` | 다음 / 이전 창 |
| `%` / `"` | 화면 세로 / 가로 분할 |
| `[` | 스크롤 모드 (`q`로 종료) |

간단히 로그만 남기고 백그라운드로 돌리려면 이렇게 합니다.
```bash
nohup python train.py > train.log 2>&1 &
tail -f train.log             # 로그 실시간 보기 (Ctrl + C 로 보기 종료, 작업은 계속)
```

> 🪟 **원격이 Windows라면** tmux가 없습니다. 오래 걸리는 작업은 **RDP 안에서 실행한 뒤 "창 닫기(연결 끊기)"** 를 하거나, WSL(Windows용 리눅스)에서 tmux를 쓰세요.

### 8-4. 포트 포워딩 — Jupyter, TensorBoard를 내 브라우저로

```bash
# 내 컴퓨터에서: 내 8888 포트 → 원격의 8888 포트로 연결
ssh -L 8888:localhost:8888 lab

# (접속된 원격에서) Jupyter 실행
jupyter lab --no-browser --port 8888
```
내 컴퓨터 브라우저에서 `http://localhost:8888`을 엽니다. 토큰은 원격 터미널 출력에서 복사합니다.

TensorBoard도 같은 방식입니다.
```bash
ssh -L 6006:localhost:6006 lab
tensorboard --logdir runs --port 6006     # 원격에서 실행 → 내 브라우저에서 http://localhost:6006
```

ssh config에 넣어 두면 `ssh lab`만 해도 자동으로 포워딩됩니다.
```
Host lab
    ...
    LocalForward 8888 localhost:8888
    LocalForward 6006 localhost:6006
```

### 8-5. GPU 상태 보기 (NVIDIA)

```bash
nvidia-smi                 # 한 번 보기
watch -n 1 nvidia-smi      # 1초마다 갱신 (Ctrl + C 로 종료)
```

---

<a id="security"></a>
## 9. 보안 설정

### 9-1. 기본 원칙
- ✅ **Tailscale을 쓰면 포트를 인터넷에 열지 않으므로** 기본적으로 안전합니다.
- ❌ 공유기에서 22번(SSH), 3389번(RDP) 포트를 인터넷에 여는 **포트포워딩은 하지 마세요.** 전 세계에서 무작위 로그인 공격이 들어옵니다.
- 🔑 **개인키(`id_ed25519`)는 절대 공유하지 마세요.** 원격에 등록하는 건 항상 `.pub`(공개키)입니다.
- 🔒 원격 계정 비밀번호와 RustDesk 영구 비밀번호는 **길고 복잡하게** 설정하세요.
- 🧹 쓰지 않는 기기는 Tailscale 관리 콘솔에서 **Remove** 하세요. 노트북을 잃어버렸을 때도 바로 제거하세요.

### 9-2. 키 인증을 설정한 뒤 비밀번호 로그인 끄기 (선택, 권장)

> ⚠️ **반드시 키 로그인이 되는 것을 먼저 확인하세요.** 기존 SSH 창은 닫지 말고, **새 터미널**에서 테스트하세요.
> 잘못하면 원격에 SSH로 못 들어가게 됩니다. 그래도 원격 데스크톱이나 현장에서는 복구할 수 있습니다.

**🐧 원격이 Ubuntu인 경우**
```bash
# 설정 파일 생성 (00~49 사이 숫자로 시작해야 다른 기본 설정보다 우선 적용됨)
printf "PasswordAuthentication no\nKbdInteractiveAuthentication no\n" | sudo tee /etc/ssh/sshd_config.d/01-disable-password.conf

sudo sshd -t                     # 설정 문법 검사 (아무 출력 없으면 OK)
sudo systemctl restart ssh
sudo sshd -T | grep -Ei 'passwordauthentication|kbdinteractive'   # 둘 다 "no" 인지 확인
```

**🪟 원격이 Windows인 경우** (관리자 PowerShell)
```powershell
notepad C:\ProgramData\ssh\sshd_config
```
- `#PasswordAuthentication yes` 줄을 찾아 **`PasswordAuthentication no`** 로 바꿉니다. 앞의 `#`도 지웁니다.
- 파일 맨 아래 `Match Group administrators` 부분은 **그대로 둡니다.**
- 저장한 뒤 다음을 실행합니다.
```powershell
Restart-Service sshd
```

### 9-3. (Tailscale 없이 공인 IP로 열어야만 한다면)
- 키 인증만 허용 (9-2)
- `fail2ban` 설치 (Ubuntu): `sudo apt install -y fail2ban` → 로그인을 반복해서 실패한 IP를 자동으로 차단합니다.
- 가능하면 학교 VPN 등 더 안전한 방법을 먼저 고려하세요.

---

<a id="cautions"></a>
## 10. ⚠️ 주의사항 총정리

> 문서 곳곳에 나온 주의사항과 **실제로 자주 겪는 사고**를 한곳에 모았습니다. 설정 전에 한 번, 설정 후에 한 번 읽어 보세요.
> 🔴 = 사고가 나면 **현장(연구실)에 가야만 복구**할 수 있는 것, 🟠 = 보안이나 데이터 문제, 🟡 = 알아두면 좋은 것

### 10-1. 🔴 원격에서 "스스로 문을 잠그는" 실수 (가장 중요)

원격으로 접속한 상태에서 아래 행동을 하면 **접속이 끊기고 다시 들어갈 방법이 없어집니다.** 연구실에 직접 가야 합니다.

| 하면 안 되는 행동 | 이유 | 대신 이렇게 |
|---|---|---|
| **시스템 종료(Shut down)** 누르기 / `sudo shutdown now` / `Stop-Computer` | 꺼진 PC는 원격으로 켤 수 없음 | 반드시 **다시 시작(재부팅)** 만 사용: `sudo reboot` / `Restart-Computer` |
| 원격에서 **Tailscale 로그아웃, 끄기** (`sudo tailscale down`, 트레이에서 Exit) | 내가 타고 들어온 통로를 끊는 것 | 원격 PC의 Tailscale은 절대 건드리지 않기 |
| 원격에서 **SSH 서버 중지** (`systemctl stop ssh`, `Stop-Service sshd`) | 현재 SSH 연결이 끊김 | 설정을 바꿨다면 `restart`만 사용 |
| Ubuntu에서 `sudo ufw enable`을 **SSH 허용 없이** 실행 | 방화벽이 22번 포트를 막음 | **먼저** `sudo ufw allow ssh`, **그다음** `sudo ufw enable` |
| **비밀번호 로그인 끄기**를 키 로그인 테스트 없이 적용 | 키가 안 되면 아무도 못 들어감 | 새 터미널에서 키 로그인을 확인한 뒤 적용 ([9-2](#security)) |
| 원격 PC의 **네트워크 설정 변경** (IP 수동 설정, 와이파이 변경, 랜 드라이버 업데이트) | 인터넷이 끊기면 Tailscale도 끊김 | 현장에 있을 때만 하기 |
| 원격 PC의 **사용자 비밀번호 변경** 후 확인 없이 로그아웃 | 새 비밀번호가 원격 로그인에 반영이 안 되는 경우가 있음 (특히 Microsoft 계정) | 바꾼 직후 **새 창에서 접속 테스트** |
| Ubuntu **배포판 업그레이드** (`do-release-upgrade`, 22.04 → 24.04) | 중간에 끊기거나 그래픽, SSH 설정이 바뀌어 부팅 후 접속 불가 가능 | 현장에서만 하기 |
| **그래픽 드라이버(NVIDIA) 설치, 변경** | 재부팅 후 화면(원격 데스크톱)이 안 뜰 수 있음 | SSH는 보통 살아 있으므로 SSH로 복구. 가능하면 현장에서 |

> 💡 **안전장치 두 가지**
> 1. **SSH와 원격 데스크톱을 둘 다 켜 두세요.** 하나가 죽어도 다른 하나로 복구할 수 있습니다.
> 2. **설치가 끝나면 연구실에 있을 때 꼭 한 번 "재부팅 테스트"를 하세요.** 재부팅 후 노트북에서 SSH와 원격 데스크톱이 모두 접속되는지 확인해야 나중에 당황하지 않습니다.

### 10-2. 🔴 원격 컴퓨터가 꺼지거나 잠드는 경우

- **절전 모드**: 한 번 잠들면 원격으로 깨울 수 없습니다 → [2-7](#windows-host), [3-5](#ubuntu-power)에서 반드시 꺼 두세요.
- **Windows 업데이트 자동 재시작**: 재부팅 자체는 괜찮지만(서비스는 자동 실행), **RDP 세션의 열린 프로그램과 진행 중인 작업이 모두 날아갑니다.** 사용 시간을 설정하고, 긴 작업 전에는 업데이트를 일시 중지하세요.
- **정전, 누전 차단기**: BIOS의 `Restore on AC Power Loss → Power On` 설정이 없으면 전원이 돌아와도 꺼진 채로 있습니다.
- **Ubuntu 자동 업데이트**: 커널이 업데이트되면 재부팅 전까지 일부 기능(NVIDIA 드라이버 등)이 이상하게 동작할 수 있습니다. 업데이트 후에는 **여유 있을 때** `sudo reboot` 하세요.
- **누군가 연구실에서 PC를 끔**: 연구실 사람들에게 "원격으로 쓰는 PC이니 끄지 말아 달라"고 알려 두거나 메모를 붙여 두세요.

### 10-3. 🟠 자동 로그인과 잠금 해제의 보안 위험

원격 데스크톱을 편하게 쓰려고 **자동 로그인**을 켜고 **화면 잠금**을 끄면,
**연구실에 들어온 누구나 그 PC를 로그인된 상태 그대로 쓸 수 있습니다.** (내 메일, 브라우저 로그인, 코드, 데이터 모두)

- 연구실 출입이 통제되는지, 공용 PC인지 먼저 생각하세요.
- 위험하다고 판단되면: 자동 로그인과 잠금 해제를 쓰지 말고 **SSH + xrdp(로그인 필요)** 또는 **Windows RDP(로그인 필요)** 위주로 쓰세요.
- 최소한 **모니터 전원을 꺼 두면** 지나가는 사람이 화면을 보는 것은 막을 수 있습니다.
- Ubuntu 내장 원격 데스크톱 때문에 **키링 비밀번호를 빈칸으로** 하면, 키링에 저장된 비밀번호(와이파이, 일부 앱 로그인 정보)가 암호화되지 않은 상태가 됩니다. 개인 전용 PC에서만 하세요.

### 10-4. 🟠 원격 화면이 연구실에서 그대로 보임 (RustDesk, Ubuntu 내장 RDP)

- RustDesk와 Ubuntu 내장 원격 데스크톱은 **실제 모니터 화면을 공유**합니다.
  → 내가 집에서 조작하는 것(메일, 메신저, 개인 파일, 비밀번호 입력 화면)이 **연구실 모니터에 그대로 보입니다.**
- 연구실에 다른 사람이 있다면 **모니터를 꺼 두세요.**
  (RustDesk의 "프라이버시 모드"는 원격 화면을 가려 주지만 **Windows에서만** 지원되고, 환경에 따라 동작하지 않을 수 있습니다.)
- 반대로 **다른 사람이 쓰고 있는 PC**에 RustDesk로 들어가면 그 사람의 마우스를 빼앗게 됩니다. 공용 PC라면 접속 전에 먼저 알려 주세요.
- Windows RDP로 접속하면 연구실 모니터는 **잠금 화면**이 되므로 화면 노출은 없지만, **연구실에서 그 PC를 쓰던 사람은 쫓겨납니다.**

### 10-5. 🟠 계정, 키, 비밀번호

- 🔑 **개인키(`id_ed25519`, `.pub` 없는 파일)는 절대 복사해서 남에게 주거나, 깃허브에 올리거나, 카톡으로 보내지 마세요.** 원격에 등록하는 건 항상 **`.pub` 공개키**입니다.
- 🔑 이 저장소를 포함해 **깃허브에 IP, 사용자명, 비밀번호, 키를 올리지 마세요.** README 예시의 값은 모두 가짜입니다.
- 💻 **노트북을 잃어버렸다면 즉시**
  1. Tailscale 관리 콘솔에서 그 노트북을 **Remove**
  2. 원격 컴퓨터의 `authorized_keys`(Windows 관리자는 `administrators_authorized_keys`)에서 **그 노트북의 키 줄을 삭제**. 키 끝의 `-C` 주석(`ubuntu-laptop` 등)으로 어떤 키인지 구분할 수 있으니, 키를 만들 때 기기 이름을 꼭 적어 두세요.
  3. 원격 계정 비밀번호와 RustDesk 영구 비밀번호 변경
- 🔒 키를 만들 때 **passphrase(키 비밀번호)** 를 걸어 두면, 노트북을 도난당해도 키를 바로 쓰기 어렵습니다. (대신 접속할 때마다 입력해야 합니다.)
- 🧑‍🤝‍🧑 **Tailscale 계정을 다른 사람과 공유하지 마세요.** 같은 계정의 모든 기기가 서로 접속할 수 있게 됩니다. 연구실 동료와 PC를 같이 쓰려면 Tailscale의 기기 공유(Share) 기능을 쓰세요.
- 🏢 **남의 PC나 공용 PC에서** 접속했다면 저장된 RDP 자격 증명, RustDesk 비밀번호 저장, `~/.ssh` 안의 키를 **반드시 지우고** 나오세요.
- Windows RDP에서 **"자격 증명 저장"** 을 켜면 내 PC에 비밀번호가 저장됩니다. 내 개인 PC에서만 켜세요.

### 10-6. 🟠 학교 규정과 연구실 매너

- 외부 원격 접속, VPN 프로그램(Tailscale, RustDesk) 설치를 **금지하는 학교나 연구실이 있습니다.** 전산팀이나 교수님께 먼저 확인하세요.
- **연구 데이터와 개인정보**(설문, 의료, 기업 과제 데이터 등)는 외부 PC로 복사하는 것 자체가 **보안 서약이나 규정 위반**일 수 있습니다. `scp`로 내려받기 전에 확인하세요.
- 연구실 **공용 GPU 서버**라면 학습을 돌리기 전에 `nvidia-smi`로 다른 사람이 쓰고 있는지 확인하세요. 남의 프로세스를 `kill` 하면 안 됩니다.
- 학교 네트워크로 **수십~수백 GB를 전송**하면 트래픽 제한이나 차단에 걸릴 수 있습니다. 큰 데이터는 나눠서, 가능하면 밤에 옮기세요.

### 10-7. 🟡 SSH 작업할 때

- **지금 어느 컴퓨터에 접속해 있는지 항상 확인**하세요. 원격인 줄 알고 내 PC에서 `rm -rf`, 반대로 내 PC인 줄 알고 원격에서 `sudo reboot` 하는 실수가 흔합니다. 프롬프트의 `사용자명@호스트이름`을 보세요.
- **긴 작업은 반드시 `tmux` 안에서** 실행하세요 ([8-3](#tips)). 그냥 실행하면 와이파이가 끊기거나 노트북을 덮는 순간 **작업이 같이 죽습니다.**
- 원격이 Windows면 tmux가 없으므로, 긴 작업은 RDP에서 실행하고 **"로그아웃"이 아니라 "창 닫기(연결 끊기)"** 로 나오세요. 로그아웃하면 프로그램이 모두 종료됩니다.
- **`sudo` 비밀번호**는 원격 Ubuntu 계정의 비밀번호입니다. 키 인증으로 로그인해도 `sudo`는 비밀번호를 물어봅니다.
- 원격 Windows에 SSH로 접속한 셸은 **관리자 권한으로 실행**됩니다(관리자 계정인 경우). 시스템 파일을 지우거나 바꿀 때 경고창 없이 바로 실행되니 조심하세요.

### 10-8. 🟡 파일 전송할 때

- **`scp`와 `rsync`는 같은 이름의 파일을 경고 없이 덮어씁니다.** 중요한 파일은 받는 쪽 이름을 바꾸거나 백업을 먼저 해 두세요.
- `rsync`에서 **폴더 끝의 `/` 유무**에 따라 결과가 달라집니다.
  - `rsync -av data/ lab:~/data/` → `data` **안의 내용**을 `~/data/`에 복사
  - `rsync -av data lab:~/data/` → `~/data/data/`가 생김
- `rsync --delete` 옵션은 **받는 쪽에만 있는 파일을 삭제**합니다. 방향을 헷갈리면 원본이 지워질 수 있으니 처음엔 `--dry-run`으로 미리 확인하세요.
- **Windows에서 만든 `.sh`, `.py` 파일을 Ubuntu에서 실행하면** `\r: command not found` 같은 에러가 날 수 있습니다(줄바꿈 CRLF 문제).
  → Ubuntu에서 `sudo apt install -y dos2unix && dos2unix 파일.sh`, 또는 VS Code 오른쪽 아래 `CRLF`를 눌러 `LF`로 바꿔서 저장하세요.
- **한글이나 공백이 들어간 파일명과 경로**는 `scp`에서 문제를 일으키기 쉽습니다. 가능하면 영어 파일명을 쓰고, 공백이 있으면 따옴표로 감싸세요.
- **OneDrive 동기화 폴더(바탕화면, 문서)에 큰 데이터셋을 넣지 마세요.** OneDrive 용량이 가득 차거나 동기화 때문에 PC가 느려집니다. `C:\data` 같은 별도 폴더를 쓰세요.

### 10-9. 🟡 원격 데스크톱 설정 관련

- Ubuntu의 **내장 원격 데스크톱(B)과 xrdp(C)는 둘 다 3389 포트**를 써서 충돌합니다. 하나만 켜세요.
- RustDesk 때문에 **Xorg로 바꾸면** 내장 원격 데스크톱(B), 화면 배율, 일부 터치패드 제스처 등이 달라질 수 있습니다. A와 B 중 하나만 고르세요.
- xrdp는 **같은 계정이 연구실 PC에 로그인되어 있으면 검은 화면**이 뜹니다. xrdp를 쓸 거면 연구실 PC에서는 로그아웃해 두세요.
- 인터넷이 느린 곳(카페, 모바일 핫스팟)에서는 원격 데스크톱이 많이 끊깁니다. 해상도를 낮추거나 **SSH + VS Code**로 작업하세요.
- 학교나 회사 네트워크가 Tailscale의 직접 연결을 막으면 **중계 서버(relay)** 를 거쳐 느려집니다. `tailscale status`에서 `relay "..."`로 표시되면 이 경우입니다.

### ✅ 설정 완료 후 최종 점검표 (연구실에 있을 때 하기)

- [ ] 노트북에서 **SSH 접속** 성공 (키 인증, 비밀번호 없이)
- [ ] 노트북에서 **원격 데스크톱** 접속 성공
- [ ] 연구실 PC **재부팅** → 노트북에서 SSH, 원격 데스크톱 **둘 다 다시 접속되는지** 확인
- [ ] 절전 모드 꺼짐 확인 (30분 이상 방치 후 접속 테스트)
- [ ] Tailscale **키 만료 끄기** 완료
- [ ] BIOS 정전 후 자동 켜짐 설정 (가능하다면)
- [ ] 연구실 사람들에게 "이 PC 끄지 말아 주세요" 공유
- [ ] 개인키를 어디에도 올리지 않았는지 확인

---

<a id="troubleshooting"></a>
## 11. 문제 해결 (트러블슈팅)

> 🔍 **만능 디버깅**: `ssh -v 사용자명@100.x.x.x` → 어디서 실패하는지 자세히 보여줍니다.

### 🔌 연결 자체가 안 될 때

| 증상 | 원인 | 해결 |
|---|---|---|
| `Connection timed out` | 원격 PC가 꺼짐, 절전, Tailscale 끊김 | 1) `tailscale status`로 원격 기기가 online인지 확인 2) `tailscale ping 100.x.x.x` 3) 원격 PC 절전 설정 확인 ([2-7](#windows-host), [3-5](#ubuntu-power)) |
| `Connection timed out` (Tailscale ping은 됨) | 원격 방화벽이 22번 포트 차단 | Windows: [2-3](#windows-host) 방화벽 규칙 확인. `Profile`이 `Private`만이면 관리자 PowerShell에서 `Set-NetFirewallRule -Name OpenSSH-Server-In-TCP -Profile Any`<br>Ubuntu: `sudo ufw allow ssh` |
| `Connection refused` | SSH 서버가 안 켜져 있음 | Windows: `Get-Service sshd` → `Start-Service sshd`<br>Ubuntu: `sudo systemctl status ssh` → `sudo systemctl enable --now ssh` |
| 갑자기 모든 접속이 안 됨 (몇 달 뒤) | Tailscale 키 만료 | 원격 PC에서 Tailscale 다시 로그인 → [1-4](#tailscale) **Disable key expiry** |
| 가만히 두면 연결이 끊김 | 유휴 연결 끊김 | ssh config에 `ServerAliveInterval 60` 추가 ([8-1](#ssh-config)) |

### 🔑 로그인이 안 될 때

| 증상 | 원인 | 해결 |
|---|---|---|
| `Permission denied (password)` — Windows | 사용자명이나 비밀번호 오류 | `whoami`로 사용자명 재확인 / Microsoft 계정이면 **PIN 아니라 MS 계정 비밀번호** / Windows Hello 전용 로그인 옵션 끄기 / 원격 PC에서 한 번 **비밀번호로** 로그인해 보기 ([2-0](#windows-host)) |
| `Permission denied (publickey)` — Windows | 관리자 계정인데 키를 `~\.ssh\authorized_keys`에 넣음 / 파일 권한 문제 | 관리자는 **`C:\ProgramData\ssh\administrators_authorized_keys`** 에 넣고 **`icacls` 명령**으로 권한 설정 ([4-2](#ubuntu-to-windows-key)) |
| `Permission denied (publickey)` — Ubuntu | `~/.ssh` 권한이 너무 넓음 | 원격에서 `chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys && chmod go-w ~` |
| 키 등록했는데 계속 비밀번호를 물어봄 | 다른 키 파일을 쓰고 있음 | ssh config에 `IdentityFile ~/.ssh/id_ed25519` 명시, `ssh -v`로 어떤 키를 시도하는지 확인 |
| `WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!` | 원격 PC를 포맷, 재설치했거나 IP가 다른 기기로 바뀜 | 이유를 알고 있다면 `ssh-keygen -R 100.x.x.x` 후 다시 접속. **이유를 모르면 접속하지 말고 확인부터 하세요.** |

**서버 쪽 로그 보기**
- Ubuntu: `sudo journalctl -u ssh -f` (실시간 로그, 다른 창에서 접속 시도)
- Windows: `이벤트 뷰어` → `응용 프로그램 및 서비스 로그` → `OpenSSH` → `Operational`

### 🖥️ 원격 데스크톱 문제

| 증상 | 원인 | 해결 |
|---|---|---|
| Windows RDP: "원격 컴퓨터에 연결할 수 없습니다" | Home 에디션 / RDP 꺼짐 / 방화벽 | 에디션 확인 → Home이면 RustDesk. RDP 켜기와 방화벽은 [2-5](#windows-host) |
| Windows RDP: 자격 증명이 작동하지 않음 | Microsoft 계정 문제 | 사용자 이름을 `MicrosoftAccount\이메일@example.com` 형식으로 입력 / 원격 PC에서 비밀번호로 한 번 로그인 / Windows Hello 전용 옵션 끄기 |
| Ubuntu RustDesk: 검은 화면, 연결 거부 | Wayland 사용 중 | 원격에서 `echo $XDG_SESSION_TYPE` → `wayland`이면 [3-4 A의 ①](#ubuntu-host)로 Xorg 전환 |
| Ubuntu RustDesk: 재부팅 후 접속 안 됨 | 로그인 화면에 멈춰 있음 | **자동 로그인** 켜기 |
| Ubuntu 내장 RDP: 재부팅 후 비밀번호가 바뀜 | 자동 로그인으로 키링이 잠김 | [3-4 B](#ubuntu-host)의 키링 빈 비밀번호 설정 |
| Ubuntu 내장 RDP: 접속 안 됨 | 화면 잠김 / 로그아웃 상태 | 자동 화면 잠금 끄기, 로그인 상태 유지 |
| xrdp: 로그인 후 검은 화면, 바로 튕김 | 같은 계정이 원격 PC에 로그인 중 | 원격 PC에서 **로그아웃** 후 다시 접속 |
| 화면이 느림, 끊김 | 네트워크 속도 | 해상도와 색상 깊이 낮추기, `tailscale status`에서 `direct` 연결인지 확인 (`relay`면 더 느림) |

### 📁 파일 전송 문제

| 증상 | 해결 |
|---|---|
| Windows 경로를 못 찾음 | `scp`의 Windows 경로는 사용자 폴더 기준 **슬래시(/)** 로 적기: `win:Documents/file.txt` |
| 경로에 공백, 한글이 있어서 실패 | `sftp`로 접속해서 `cd "OneDrive/바탕 화면"` 처럼 따옴표 사용, 또는 WinSCP나 VS Code 사용 |

---

<a id="cheatsheet"></a>
## 12. 명령어 치트시트

### 공통 (SSH 클라이언트)
| 목적 | 명령 |
|---|---|
| 접속 | `ssh 사용자명@100.x.x.x` 또는 `ssh lab` |
| 키 생성 | `ssh-keygen -t ed25519` |
| 키 등록 (→ Ubuntu, Ubuntu에서) | `ssh-copy-id 사용자명@100.x.x.x` |
| 파일 보내기 | `scp 파일 lab:경로/` |
| 파일 받기 | `scp lab:경로/파일 .` |
| 폴더 동기화 (Ubuntu) | `rsync -avz --progress 폴더/ lab:폴더/` |
| 포트 포워딩 | `ssh -L 8888:localhost:8888 lab` |
| 디버그 | `ssh -v lab` |
| 호스트 키 초기화 | `ssh-keygen -R 100.x.x.x` |

### Tailscale
| 목적 | 명령 |
|---|---|
| 내 IP | `tailscale ip -4` |
| 기기 목록 / 상태 | `tailscale status` |
| 연결 테스트 | `tailscale ping 100.x.x.x` |
| 로그인 (Ubuntu) | `sudo tailscale up` |

### 원격 Windows 관리 (관리자 PowerShell)
| 목적 | 명령 |
|---|---|
| SSH 서버 상태 | `Get-Service sshd` |
| SSH 서버 재시작 | `Restart-Service sshd` |
| 사용자명 | `whoami` |
| 재부팅 | `Restart-Computer` |
| 절전 끄기 | `powercfg /change standby-timeout-ac 0` |

### 원격 Ubuntu 관리
| 목적 | 명령 |
|---|---|
| SSH 서버 상태 | `systemctl status ssh` |
| SSH 서버 재시작 | `sudo systemctl restart ssh` |
| 재부팅 | `sudo reboot` |
| tmux 새 세션 / 재접속 | `tmux new -s 이름` / `tmux attach -t 이름` |
| GPU 확인 | `watch -n 1 nvidia-smi` |
| 화면 방식 확인 | `echo $XDG_SESSION_TYPE` |

---

<a id="without-tailscale"></a>
## 부록. Tailscale 없이 접속하기

### A. 같은 네트워크 안에 있을 때 (같은 연구실, 같은 공유기)
Tailscale 없이 **내부 IP**로 바로 접속할 수 있습니다.
- 원격 IP 확인: Ubuntu `hostname -I`, Windows `ipconfig` (IPv4 주소)
- 접속: `ssh 사용자명@192.168.x.x`
- 이 문서의 모든 내용에서 `100.x.x.x` 대신 내부 IP를 쓰면 됩니다.

### B. 학교 VPN을 쓸 수 있을 때
1. 집이나 노트북에서 **학교 VPN에 연결**합니다.
2. 연구실 PC의 **학교 내부 IP**로 접속합니다. 학교 네트워크에서 IP가 바뀔 수 있으니 전산팀에 고정 IP를 문의하세요.
3. 학교가 공식 지원하는 방법이라 규정상 가장 안전합니다.

### C. 공인 IP + 포트포워딩 (비추천)
- 연구실 PC가 공인 IP를 직접 받거나, 공유기 관리자 권한이 있을 때만 가능합니다.
- 반드시 **키 인증만 허용**([9-2](#security))하고 `fail2ban`을 쓰세요.
- 학교 네트워크에서는 대부분 막혀 있고, 규정 위반일 수 있습니다.

---

## 📝 요약 — 가장 추천하는 조합

| 상황 | 추천 |
|---|---|
| 코딩, 학습 돌리기 | **Tailscale + SSH 키 인증 + VS Code Remote-SSH + tmux** |
| 원격 Windows 화면 보기 | **RDP**(Pro 이상, `mstsc`나 Remmina) 또는 **RustDesk** |
| 원격 Ubuntu 화면 그대로 보기 | **RustDesk**(Xorg + 자동 로그인) |
| 파일 옮기기 | 작은 파일은 `scp`, 큰 폴더는 `rsync`, GUI는 WinSCP나 Nautilus `sftp://` |

⭐ 도움이 되었다면 Star를 눌러 주세요!
