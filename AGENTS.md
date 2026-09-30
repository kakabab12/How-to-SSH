# AGENTS.md — AI 에이전트(Claude Code 등)용 실행 지침

> 사용자가 이 저장소 링크를 주면서 "설정해줘", "도와줘"라고 하면 **이 문서를 따르세요.**
> 사람이 읽는 설명서는 `easy/`(초보용)와 `guides/`(자세한 버전)에 있습니다.
> 이 문서는 **에이전트가 무엇을 어떤 순서로 하고, 어디까지 직접 실행하고, 어디서 사용자에게 넘기는지**를 정합니다.

---

## 0. 목표

지금 에이전트가 실행 중인 **이 컴퓨터**를 역할에 맞게 설정합니다.

| 역할 | 목표 |
|---|---|
| **연구실 PC (호스트)** | 밖에서 **SSH**와 **RustDesk**(바탕화면 그대로 보기)로 접속받을 수 있게 |
| **노트북 / 집 PC (클라이언트)** | 연구실 PC에 SSH와 RustDesk로 접속할 수 있게 |

두 컴퓨터는 **Tailscale**(같은 계정)로 연결합니다. 연구실 PC 주소는 Tailscale IP(`100.x.x.x`)입니다.

---

## 1. 반드시 지킬 규칙

1. **사용자는 컴퓨터 초보입니다.** 한국어 해요체로, **한 번에 한 단계씩**, 짧게 말하세요. 전문 용어는 [easy/glossary.md](easy/glossary.md)처럼 쉬운 말로 풀어 주세요.
2. **비밀번호와 로그인은 절대 대신 입력하거나 저장하지 마세요.** 구글/Tailscale 로그인, 윈도우/우분투 비밀번호, RustDesk 영구 비밀번호는 **사용자가 직접** 입력합니다. 사용자가 채팅에 비밀번호를 쓰려고 하면 "저한테 알려주지 않아도 돼요"라고 말리세요.
3. **관리자 권한**
   - **Ubuntu**: `sudo -n true`로 확인하세요. 실패하면 에이전트 셸은 sudo 비밀번호를 입력할 수 없습니다. 그때는 sudo 명령을 **코드 블록으로 보여 주고**, 사용자가 **자기 터미널(`Ctrl`+`Alt`+`T`)에 붙여넣게** 하세요. 끝나면 알려 달라고 한 뒤 점검 스크립트로 확인합니다. 붙여넣기는 `Ctrl`+`Shift`+`V`라고 꼭 알려 주세요.
   - **Windows**: 점검 스크립트에서 관리자(elevated) 여부를 확인하세요. 관리자가 아니면 둘 중 하나로 합니다.
     - (a) 관리자 명령을 임시 `.ps1` 파일로 저장하고 아래처럼 실행합니다. 사용자가 **UAC 창에서 "예"** 를 누르게 안내하세요.
       ```powershell
       Start-Process powershell -Verb RunAs -Wait -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File "<임시파일경로>"'
       ```
     - (b) 사용자에게 **`터미널(관리자)`** 를 열고 붙여넣게 합니다.
4. **설치, 다운로드, 약관 동의**(winget의 `--accept-*-agreements` 등) 전에는 **무엇을 어디서 설치하는지** 말하고 사용자 동의를 받으세요.
5. **GUI 작업은 사용자가 합니다.** 설정 앱, RustDesk 설정, 브라우저 로그인, 트레이 아이콘이 여기에 해당합니다. 해당 easy 가이드 단계의 클릭 순서를 그대로 안내하고, 끝나면 점검 스크립트로 확인하세요.
6. **절대 실행하지 마세요.** 원격 접속이 끊겨서 **사용자가 연구실에 직접 가야** 복구됩니다.
   - 시스템 종료: `shutdown`, `poweroff`, `halt`, `Stop-Computer`. 재부팅이 필요하면 **사용자에게** "다시 시작"을 안내하세요.
   - `tailscale down`, `tailscale logout`, 연구실 PC의 Tailscale 종료나 삭제
   - SSH 서버 중지: `systemctl stop ssh`, `Stop-Service sshd`. 설정을 바꿨으면 `restart`만 쓰세요.
   - `ufw allow ssh` 없이 `ufw enable`
   - 네트워크 설정 변경, 사용자 비밀번호 변경, 배포판 업그레이드(`do-release-upgrade`), 그래픽 드라이버 변경
   - 사용자가 요청하지 않은 **비밀번호 로그인 끄기**(sshd_config 수정)
7. **보안 트레이드오프가 있는 설정은 먼저 위험을 한 줄로 설명하고 동의를 받으세요.** 자동 로그인과 화면 잠금 끄기가 여기에 해당합니다. 예: "켜면 연구실에 온 누구나 이 PC를 로그인된 상태로 쓸 수 있어요. 켤까요?" 참고: [guides/07-cautions.md](guides/07-cautions.md#autologin)
8. **재부팅이나 로그아웃 전에는** 진행 상황을 기록하고(§9), 다시 켜진 뒤 할 말을 사용자에게 알려 주세요.
9. **이 저장소에 커밋하거나 푸시하지 마세요.** IP, 사용자명, 비밀번호를 외부로 보내지 마세요.

---

## 2. 시작 절차

### 2-1. 저장소 준비
- git이 있으면:
  ```bash
  git clone https://github.com/kakabab12/How-to-SSH.git   # 이미 있으면: git -C How-to-SSH pull
  ```
  이후 경로는 모두 이 폴더 기준입니다.
- git이 없으면 필요한 파일을 raw URL로 읽으세요: `https://raw.githubusercontent.com/kakabab12/How-to-SSH/main/<경로>`
- 폴더에 **`.progress.md`가 있으면 먼저 읽고 이어서** 진행하세요(§9).

### 2-2. 사용자에게 물어볼 것 (한 번에, 짧게)
1. "지금 이 컴퓨터는 **연구실 PC**(집에서 접속해서 쓸 컴퓨터)인가요, **노트북이나 집 PC**(접속하는 쪽)인가요?"
2. "**상대 컴퓨터**는 윈도우인가요, 우분투인가요?"
3. (연구실 PC라면) "노트북도 지금 옆에 있나요?" → 마지막 접속 테스트에 필요합니다.

이 컴퓨터의 OS는 **직접 감지**하세요. (Linux: `/etc/os-release` / Windows: `$PSVersionTable`, `Get-CimInstance Win32_OperatingSystem`)

### 2-3. 시나리오와 사용자용 가이드

| 연구실 PC | 노트북 / 집 PC | 사용자에게 보여 줄 가이드 |
|---|---|---|
| Windows | Ubuntu | [easy/01-ubuntu-to-windows.md](easy/01-ubuntu-to-windows.md) |
| Windows | Windows | [easy/02-windows-to-windows.md](easy/02-windows-to-windows.md) |
| Ubuntu | Ubuntu | [easy/03-ubuntu-to-ubuntu.md](easy/03-ubuntu-to-ubuntu.md) |
| Ubuntu | Windows | [easy/04-windows-to-ubuntu.md](easy/04-windows-to-ubuntu.md) |

GUI 단계를 안내할 때는 이 가이드의 해당 단계(`#step1`~`#step10`) 문구를 쓰세요.

### 2-4. 점검 스크립트 실행 (아무것도 바꾸지 않는 읽기 전용)
- **Ubuntu**: `bash scripts/check-ubuntu.sh`
- **Windows**: `powershell -NoProfile -ExecutionPolicy Bypass -File scripts\check-windows.ps1`

출력의 뜻: `[OK]` 완료, `[--]` 해야 함, `[??]` 스크립트로 알 수 없으니 사용자에게 확인.
결과를 사용자에게 **쉬운 말로 요약**하고, **남은 작업만** 아래 목록 순서대로 진행하세요.
노트북(클라이언트)에서는 SSH 서버, RustDesk 서비스, 절전 관련 `[--]`는 무시해도 됩니다.

> 표기: 🤖 에이전트가 직접 실행 가능 · 🧑 사용자 터미널에서 실행(sudo 또는 관리자) · 🖱️ 사용자가 GUI나 브라우저에서

---

## 3. 작업 목록 — 연구실 PC가 **Ubuntu**

사용자용 설명: [easy/04](easy/04-windows-to-ubuntu.md) 또는 [easy/03](easy/03-ubuntu-to-ubuntu.md). 두 파일의 단계 번호는 같습니다.

| ID | 작업 | 누가 | 완료 확인 |
|---|---|---|---|
| H-U1 | curl + Tailscale 설치 | 🧑 | `command -v tailscale` |
| H-U2 | Tailscale 로그인 (노트북과 **같은 계정**) | 🧑 + 🖱️ | `tailscale ip -4` → `100.x.x.x` |
| H-U3 | 연구실 PC **키 만료 끄기** | 🖱️ 브라우저 | 사용자에게 "Expiry disabled 보이나요?" |
| H-U4 | SSH 서버 설치, 켜기 | 🧑 | 스크립트 `SSH server active` |
| H-U5 | 절전 끄기 (+ 동의 후 화면 잠금 끄기) | 🧑 + 🤖 | 스크립트 `sleep.target masked`, `screen lock off` |
| H-U6 | 사용자명과 IP를 사용자에게 알려 주고 메모하게 하기 | 🤖 | `whoami`, `tailscale ip -4` |
| H-U7 | Wayland 끄기 (Xorg) | 🧑 | 스크립트 `Wayland disabled` |
| H-U8 | 자동 로그인 (**동의 필요**) | 🖱️ 또는 🧑 | 스크립트 `automatic login enabled` |
| — | **재부팅** (H-U7, H-U8 적용) | 🧑 | 다시 켜진 뒤 스크립트 `session is x11` |
| H-U9 | RustDesk 설치 | 🤖 다운로드 + 🧑 설치 | 스크립트 `rustdesk service active` |
| H-U10 | RustDesk 설정: IP 직접 접근 허용 + 영구 비밀번호 | 🖱️ | 사용자 확인 |
| H-U11 | 최종 테스트 | §6 | |

**H-U1 · Tailscale 설치** (🧑 사용자 터미널)
```bash
sudo apt update && sudo apt install -y curl
curl -fsSL https://tailscale.com/install.sh | sh
```

**H-U2 · 로그인** (🧑 + 🖱️)
```bash
sudo tailscale up
```
→ 출력된 `https://login.tailscale.com/a/...` 주소를 사용자가 브라우저로 열고 **노트북과 같은 구글 계정**으로 로그인 → **Connect**.
(`sudo -n true`가 되면 에이전트가 이 명령을 백그라운드로 실행하고 URL만 전달해도 됩니다.)

**H-U3 · 키 만료 끄기** (🖱️)
https://login.tailscale.com/admin/machines → 연구실 PC 줄의 `...` → **Disable key expiry**

**H-U4 · SSH 서버** (🧑)
```bash
sudo apt install -y openssh-server
sudo systemctl enable --now ssh
```
스크립트에서 ufw가 켜져 있다고 나오면 `sudo ufw allow ssh`도 실행하게 하세요.

**H-U5 · 절전 끄기**
```bash
sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target   # 🧑
```
화면 꺼짐과 잠금 끄기는 🤖 에이전트가 **사용자 세션에서** 실행할 수 있습니다. **동의를 받은 뒤** 실행하세요.
```bash
gsettings set org.gnome.desktop.session idle-delay 0
gsettings set org.gnome.desktop.screensaver lock-enabled false
```

**H-U7 · Wayland 끄기** (🧑)
```bash
sudo sed -i 's/^#WaylandEnable=false/WaylandEnable=false/' /etc/gdm3/custom.conf
grep WaylandEnable /etc/gdm3/custom.conf     # "WaylandEnable=false" (앞에 # 없음) 이어야 함
```
`WaylandEnable` 줄이 아예 없으면 `sudo sed -i '/^\[daemon\]/a WaylandEnable=false' /etc/gdm3/custom.conf`를 실행하게 하세요.

**H-U8 · 자동 로그인** — 먼저 위험을 설명하고 동의를 받으세요.
- 권장 🖱️: 설정 → 사용자 → **잠금 해제** → **자동 로그인** 켜기 ([easy/04 7️⃣](easy/04-windows-to-ubuntu.md#step7))
- 또는 🧑:
  ```bash
  sudo sed -i "s/^#\?[[:space:]]*AutomaticLoginEnable[[:space:]]*=.*/AutomaticLoginEnable=true/; s/^#\?[[:space:]]*AutomaticLogin[[:space:]]*=.*/AutomaticLogin=$USER/" /etc/gdm3/custom.conf
  grep -E 'AutomaticLogin' /etc/gdm3/custom.conf
  ```

**재부팅** — §9 진행 기록을 **먼저** 남기세요. 그다음 사용자에게 이렇게 안내합니다.
> "이제 재부팅할게요. 터미널에 `sudo reboot`를 입력하세요(또는 오른쪽 위 전원 → **다시 시작**). 다시 켜지면 **로그인 없이 바탕화면이 나오는지** 봐 주시고, Claude Code를 다시 열어서 **'How-to-SSH 이어서 해줘'** 라고 말해 주세요."

재부팅 뒤에는 점검 스크립트로 `current session is x11`과 `automatic login enabled`를 확인하세요.

**H-U9 · RustDesk 설치** — 다운로드 전에 동의를 받으세요.
```bash
# 🤖 최신 .deb 주소 찾아서 받기 (x86_64 기준. `uname -m`이 aarch64면 aarch64 파일)
url="$(curl -fsSL https://api.github.com/repos/rustdesk/rustdesk/releases/latest | grep -o 'https://[^"]*/rustdesk-[0-9.]*-x86_64\.deb' | head -n1)"
echo "$url"
curl -fL -o /tmp/rustdesk.deb "$url"
```
```bash
sudo apt install -y /tmp/rustdesk.deb      # 🧑
```

**H-U10 · RustDesk 설정** (🖱️) — [easy/04 8️⃣-④](easy/04-windows-to-ubuntu.md#step8)
RustDesk 실행 → 설정 → **보안** → **보안 설정 잠금 해제** → ✅ **IP 직접 접근 허용** → **영구 비밀번호 설정**.
영구 비밀번호는 사용자가 **직접 정하고, 에이전트에게 알려주지 않게** 하세요.

---

## 4. 작업 목록 — 연구실 PC가 **Windows**

사용자용 설명: [easy/01](easy/01-ubuntu-to-windows.md) 또는 [easy/02](easy/02-windows-to-windows.md). 두 파일의 단계 번호는 같습니다.

| ID | 작업 | 누가 | 완료 확인 |
|---|---|---|---|
| H-W1 | Tailscale 설치 | 🤖(동의 후) 또는 🖱️ | 스크립트 `Tailscale installed` |
| H-W2 | Tailscale 로그인 + **Run unattended** | 🖱️ | 스크립트 `logged in`, `Run unattended is ON` |
| H-W3 | 연구실 PC **키 만료 끄기** | 🖱️ 브라우저 | 사용자 확인 |
| H-W4 | 계정 확인, Windows Hello 전용 로그인 끄기 | 🤖 확인 + 🖱️ | 스크립트 `Windows Hello sign-in only is off` |
| H-W5 | OpenSSH 서버 + 절전 끄기 | 관리자 (§1-3) | 스크립트 `sshd running`, `Sleep: never` |
| H-W6 | 사용자명과 IP를 사용자에게 알려 주고 메모하게 하기 | 🤖 | `$env:USERNAME`, `tailscale ip -4` |
| H-W7 | RustDesk **설치(서비스)** | 🤖(동의 후) 또는 🖱️ | 스크립트 `RustDesk installed as a service` |
| H-W8 | RustDesk 설정: IP 직접 접근 허용 + 영구 비밀번호 | 🖱️ | 사용자 확인 |
| H-W9 | (권장) Windows 업데이트 **사용 시간** 설정 | 🖱️ | — |
| H-W10 | 최종 테스트 | §6 | |

**H-W1 · Tailscale 설치** — 동의를 받은 뒤 실행하세요.
```powershell
winget install -e --id tailscale.tailscale --accept-source-agreements --accept-package-agreements
```
winget이 없거나 실패하면 → 사용자가 `tailscale.com/download`에서 설치 ([easy/01 1️⃣](easy/01-ubuntu-to-windows.md#step1))

**H-W2 · 로그인** (🖱️) — 트레이의 Tailscale 아이콘 → **Log in** (노트북과 같은 계정) → 아이콘 오른쪽 클릭 → Settings/Preferences → ✅ **Run unattended**

**H-W4 · 계정** — 점검 스크립트의 `Account type`과 `Windows Hello sign-in only`를 보세요.
- `MicrosoftAccount`이면 사용자에게 알려 주세요: "원격 접속 비밀번호는 **PIN이 아니라 Microsoft 계정 비밀번호**예요."
- `Windows Hello sign-in only is ON`이면 🖱️ 설정 → 계정 → 로그인 옵션에서 **끄게** 하세요. 그다음 **로그아웃하고 비밀번호로 한 번 로그인**하게 합니다 ([easy/01 4️⃣](easy/01-ubuntu-to-windows.md#step4)). 레지스트리로 직접 바꾸지 마세요(보안 설정입니다). 로그아웃하면 이 세션이 끝나니 §9 기록을 먼저 남기세요.

**H-W5 · OpenSSH 서버 + 절전** (관리자로 실행, §1-3 방법)
```powershell
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Start-Service sshd
Set-Service -Name sshd -StartupType Automatic
if (-not (Get-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -ErrorAction SilentlyContinue)) {
  New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
}
New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -PropertyType String -Force
powercfg /change standby-timeout-ac 0
powercfg /change hibernate-timeout-ac 0
```
- `Add-WindowsCapability`는 몇 분 걸립니다. 실패하면(예: `0x800f0954`, 학교 관리 PC) 🖱️ 설정 → 시스템 → 선택적 기능 → **OpenSSH 서버**로 설치하게 하세요. 그래도 안 되면 전산팀에 문의하라고 안내합니다.
- 노트북에서 Tailscale ping은 되는데 SSH만 시간 초과가 나면, 동의를 받고 관리자로 `Set-NetFirewallRule -Name OpenSSH-Server-In-TCP -Profile Any`를 실행하세요.

**H-W7 · RustDesk** — 동의를 받은 뒤 실행하세요.
```powershell
winget install -e --id RustDesk.RustDesk --accept-source-agreements --accept-package-agreements
```
설치 뒤 점검 스크립트에 서비스가 없다고 나오면 → 사용자가 RustDesk를 열고 왼쪽 아래 **설치(Install)** 를 누르게 하세요. winget이 안 되면 [easy/01 7️⃣](easy/01-ubuntu-to-windows.md#step7)처럼 GitHub에서 `.exe`를 받아 설치합니다.

**H-W8 · RustDesk 설정** (🖱️) — 설정 → **보안** → **잠금 해제** → ✅ **IP 직접 접근 허용** → **영구 비밀번호 설정**. 비밀번호는 사용자가 직접 정하고 에이전트에게 알려주지 않게 하세요.

(선택) 윈도우 **Pro 이상**이고 사용자가 원하면 Windows 원격 데스크톱(RDP)도 켤 수 있습니다: [guides/01 2-6](guides/01-ubuntu-to-windows.md#win-rdp)

---

## 5. 작업 목록 — **노트북 / 집 PC** (클라이언트)

| ID | 작업 | 누가 | 완료 확인 |
|---|---|---|---|
| C1 | Tailscale 설치 + **연구실 PC와 같은 계정**으로 로그인 | Win: 🤖(동의 후)+🖱️ / Ubuntu: 🧑 | `tailscale status`에 연구실 PC가 보임 |
| C2 | 연결 확인 | 🤖 | `tailscale ping <IP>` |
| C3 | SSH 서버 도달 확인 (비밀번호 필요 없음) | 🤖 | 아래 결과 해석 |
| C4 | 실제 SSH 로그인 | 🧑 | 사용자가 `ssh 사용자명@<IP>` → `yes` → 비밀번호 |
| C5 | RustDesk 설치 + 접속 | 🤖(동의 후) + 🖱️ | 사용자가 연구실 화면을 봄 |
| C6 | (선택) SSH 키 + ssh config | 🤖 + 🧑 | `ssh -o BatchMode=yes <별칭> hostname` |

**C1** — Windows: `winget install -e --id tailscale.tailscale ...` (H-W1과 같음) → 🖱️ 트레이에서 로그인. Ubuntu: H-U1 + H-U2와 같은 명령.

**C2**
```bash
tailscale status
tailscale ping <연구실IP>
```

**C3 · SSH 서버 도달 확인** — 비밀번호 없이 확인할 수 있습니다.
```bash
ssh -o BatchMode=yes -o ConnectTimeout=8 -o StrictHostKeyChecking=accept-new <사용자명>@<연구실IP> exit
```
| 결과 | 뜻 |
|---|---|
| `Permission denied (...)` | ✅ **정상.** 서버에 닿았고 비밀번호가 필요하다는 뜻 → C4로 |
| `Connection timed out` | 연구실 PC 꺼짐, 절전, Tailscale 끊김, 방화벽 → [lab-checklist §6](easy/lab-checklist.md#fix-at-lab) |
| `Connection refused` | 연구실 PC의 SSH 서버가 꺼져 있음 (H-U4 / H-W5) |

**C4** — 에이전트는 비밀번호를 대신 입력할 수 없습니다. 사용자에게 **자기 터미널**에서 `ssh <사용자명>@<IP>` → `yes` → 비밀번호(안 보이는 게 정상)를 입력하게 하세요. 연구실 PC가 Windows이고 Microsoft 계정이면 **MS 계정 비밀번호**입니다.

**C5 · RustDesk**
- Windows: 동의를 받은 뒤 `winget install -e --id RustDesk.RustDesk --accept-source-agreements --accept-package-agreements` (또는 GitHub에서 `.exe`)
- Ubuntu: H-U9와 같은 방법 (Xorg 전환은 **필요 없음**)
- 🖱️ 접속: RustDesk → **원격 데스크톱 제어** 칸에 `<연구실IP>` → 연결 → **RustDesk 영구 비밀번호**
- 연구실 PC가 Ubuntu면 **바탕화면**, Windows면 **로그인 화면이나 바탕화면**이 보이면 성공입니다.

**C6 · (선택) 비밀번호 없이 SSH** — 기본 설정이 모두 끝난 뒤에만 제안하세요.
1. 🤖 키 만들기 (이미 `~/.ssh/id_ed25519`가 있으면 건너뛰기). passphrase를 쓸지 먼저 물어보세요.
   - Ubuntu: `ssh-keygen -t ed25519 -C "<기기이름>" -f ~/.ssh/id_ed25519 -N ""`
   - Windows PowerShell 5.1: `ssh-keygen -t ed25519 -C "<기기이름>" -f $env:USERPROFILE\.ssh\id_ed25519 -N '""'` (빈 문자열 인자를 이렇게 넘겨야 합니다)
2. 🧑 공개키 등록 (비밀번호 1회 필요)
   - → 연구실 Ubuntu: [guides/03 4장](guides/03-ubuntu-to-ubuntu.md#key)(`ssh-copy-id`) / [guides/04 4장](guides/04-windows-to-ubuntu.md#key)(Windows 한 줄 명령)
   - → 연구실 Windows: [guides/01 4장](guides/01-ubuntu-to-windows.md#key) / [guides/02 4장](guides/02-windows-to-windows.md#key). **관리자 계정은 `C:\ProgramData\ssh\administrators_authorized_keys` + `icacls`** 입니다.
3. 🤖 ssh config에 별칭을 추가하세요(예: `lab`). 파일이 이미 있으면 **덧붙이기만** 하고 기존 내용은 지우지 마세요.
4. 🤖 확인: `ssh -o BatchMode=yes lab hostname` → 연구실 PC 이름이 나오면 성공입니다.

(선택) VS Code Remote-SSH, tmux: [guides/05-tips.md](guides/05-tips.md)

---

## 6. 최종 테스트 (연구실을 떠나기 전에 반드시)

1. §9 기록을 남긴 뒤, 사용자에게 **연구실 PC "다시 시작"** 을 안내하세요. (**시스템 종료 아님!** 연구실 PC에서 돌던 이 세션은 끊깁니다)
2. 3분 뒤 **노트북에서** C3(SSH 도달)와 C5(RustDesk 접속)를 다시 확인합니다.
   - 연구실 PC가 Ubuntu → 로그인 없이 **바탕화면**이 보여야 합니다.
   - 연구실 PC가 Windows → **로그인 화면**이 보이면 정상입니다. RustDesk 창 안에서 로그인하면 됩니다.
3. 노트북을 **휴대폰 핫스팟**에 연결하고 RustDesk를 다시 확인합니다. (학교 밖에서도 된다는 확인)
4. 사용자에게 알려 줄 것:
   - 연구실 PC에 **"전원을 끄지 말아 주세요"** 메모 붙이기, 모니터만 끄기
   - 매일 떠날 때 할 일: [easy/lab-checklist.md §3](easy/lab-checklist.md#leaving)
   - 연구실에서 건드리면 안 되는 설정: [easy/lab-checklist.md §4](easy/lab-checklist.md#at-lab)

---

## 7. 완료 후 사용자에게 줄 요약 (이 형식으로)

```
✅ 설정 완료!
📍 연구실 PC 주소: 100.x.x.x
👤 사용자명: ______
🖥️ 화면 보기: RustDesk 실행 → 100.x.x.x 입력 → 연결 → RustDesk 비밀번호
⌨️ 명령어: 터미널 → ssh 사용자명@100.x.x.x
🚪 연구실 떠날 때: 전원 끄지 말고 모니터만 끄기 (우분투는 로그아웃도 하지 않기)
🚫 원격으로 쓸 때 "시스템 종료" 절대 금지 → "다시 시작"만
```
비밀번호는 요약에 넣지 마세요.

---

## 8. 문제가 생기면

1. 점검 스크립트를 다시 실행하고 `[--]` 항목부터 해결하세요.
2. 증상별 해결: [guides/08-troubleshooting.md](guides/08-troubleshooting.md)
3. 연구실에서 확인하는 순서: [easy/lab-checklist.md §6](easy/lab-checklist.md#fix-at-lab)
4. 주의사항 전체: [guides/07-cautions.md](guides/07-cautions.md)

---

## 9. 진행 기록 & 이어하기

- 저장소 폴더에 **`.progress.md`** 를 만들고(`.gitignore`에 포함됨), 단계가 끝날 때마다 한 줄씩 적으세요.
  예: `2026-10-01 | 연구실 PC(Ubuntu) ← 노트북(Windows) | 완료: H-U1~H-U8 | 다음: 재부팅 후 x11 확인 → H-U9`
- **비밀번호는 절대 적지 마세요.** IP와 사용자명은 적어도 됩니다(로컬 파일이고 커밋하지 않음).
- **재부팅이나 로그아웃 전에는 반드시 기록하세요.** 그리고 사용자에게 이렇게 말하세요.
  > "다시 켜지면 Claude Code를 열고 **'How-to-SSH 이어서 해줘'** 라고 말해 주세요." (CLI라면 저장소 폴더에서 `claude --continue`)
- 이어서 할 때는 `.progress.md`를 읽고, **점검 스크립트로 실제 상태를 다시 확인한 뒤** 다음 단계부터 진행하세요.
- 연구실 PC 설정이 끝나면 사용자에게 알려 주세요: "이제 **노트북에서도** Claude Code에 같은 링크를 주면 노트북 설정을 도와드릴게요."
