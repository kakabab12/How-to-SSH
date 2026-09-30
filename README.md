# 🖥️ How-to-SSH

> 노트북이나 집 컴퓨터에서 **학교 연구실 컴퓨터(또는 다른 PC)에 원격으로 접속**하는 방법을 처음부터 끝까지 정리한 가이드입니다.
> **SSH(터미널 접속)** 와 **원격 데스크톱(바탕화면을 그대로 보면서 조작)** 두 가지를 모두 다룹니다.

- 기준 환경: **Windows 11**, **Ubuntu 22.04 LTS**
- 학교 방화벽이나 공유기 뒤에 있어도 되도록 **Tailscale**(무료 VPN)을 기본으로 사용합니다.

---

<a id="claude-code"></a>
## 🤖 Claude Code로 설정하기 (가장 쉬운 방법)

설정할 컴퓨터에서 **Claude Code**를 열고, 아래 문장을 **그대로 복사해서 붙여넣으세요.**

```
https://github.com/kakabab12/How-to-SSH 저장소를 받아서 AGENTS.md 지침대로 이 컴퓨터의 원격 접속 설정을 처음부터 끝까지 도와줘.
```

Claude가 "이 컴퓨터가 연구실 PC인가요, 노트북인가요?"처럼 물어보면 답하고, 시키는 대로 따라 하면 돼요.

| 알아두세요 | |
|---|---|
| 🏫 → 💻 **순서** | **연구실 PC에서 먼저** 하고, 끝나면 **노트북에서도** 같은 문장을 붙여넣어요. |
| 🔑 **비밀번호** | 구글 로그인과 비밀번호는 **직접** 입력해요. Claude에게 알려주지 않아도 돼요. |
| 🛡️ **관리자 권한** | Claude가 **터미널에 붙여넣을 명령**을 주거나, **"예"를 눌러야 하는 창**을 띄워요. |
| 🔄 **재부팅한 뒤** | Claude Code를 다시 열고 **"How-to-SSH 이어서 해줘"** 라고 말하면 이어서 진행해요. |
| 🧰 **준비물** | 설정할 컴퓨터에 Claude Code가 설치되어 있어야 해요. → [claude.com/claude-code](https://claude.com/claude-code) |

> 🤖 **AI 에이전트에게**: 작업을 시작하기 전에 [AGENTS.md](AGENTS.md)를 읽으세요.
> (raw: `https://raw.githubusercontent.com/kakabab12/How-to-SSH/main/AGENTS.md`)
> 상태 점검: `bash scripts/check-ubuntu.sh` / `powershell -NoProfile -ExecutionPolicy Bypass -File scripts\check-windows.ps1`

---

<a id="easy"></a>
## 🐣 직접 따라 하고 싶다면 → 쉬운 가이드

> 터미널이 뭔지 몰라도 괜찮아요. **클릭 순서와 복사해서 붙여넣을 명령어**만 따라 하면 돼요.
> 선택지 없이 **한 가지 방법(Tailscale + SSH + RustDesk)** 만 알려 드려요. 끝나면 **연구실 바탕화면을 그대로** 볼 수 있어요.

**① 먼저 읽기 (5분)** 👉 **[시작하기 전에](easy/00-before-you-start.md)** — 터미널 여는 법, 붙여넣기 방법, 비밀번호가 안 보여도 정상인 이유

**② 내 경우 고르기** ("A → B" = **A(내 노트북, 집 PC)** 로 **B(연구실 PC)** 에 접속)

| 내 노트북 / 집 PC | 연구실 PC | 🐣 쉬운 가이드 (약 40분) |
|---|---|---|
| 🐧 우분투 | 🪟 윈도우 | 👉 **[우분투 → 윈도우](easy/01-ubuntu-to-windows.md)** |
| 🪟 윈도우 | 🪟 윈도우 | 👉 **[윈도우 → 윈도우](easy/02-windows-to-windows.md)** |
| 🐧 우분투 | 🐧 우분투 | 👉 **[우분투 → 우분투](easy/03-ubuntu-to-ubuntu.md)** |
| 🪟 윈도우 | 🐧 우분투 | 👉 **[윈도우 → 우분투](easy/04-windows-to-ubuntu.md)** |

**③ 모르는 단어가 나오면** 👉 **[📖 용어 사전](easy/glossary.md)**

---

<a id="choose"></a>
## 📘 자세한 가이드 (여러 방법 비교, 고급 설정)

쉬운 가이드를 끝냈거나, 여러 방법을 비교하고 직접 고르고 싶다면 이쪽을 보세요.
"A → B"는 **A(내 컴퓨터)에서 B(원격 컴퓨터, 예: 연구실 PC)로 접속한다**는 뜻입니다.
**각 가이드는 그 파일 하나만 보고 처음부터 끝까지 따라 할 수 있게** 원격 컴퓨터 설정까지 모두 들어 있습니다.

| 내 컴퓨터 (접속하는 쪽) | 원격 컴퓨터 (접속당하는 쪽) | 가이드 |
|---|---|---|
| 🐧 Ubuntu | 🪟 Windows | 👉 **[01. Ubuntu → Windows](guides/01-ubuntu-to-windows.md)** |
| 🪟 Windows | 🪟 Windows | 👉 **[02. Windows → Windows](guides/02-windows-to-windows.md)** |
| 🐧 Ubuntu | 🐧 Ubuntu | 👉 **[03. Ubuntu → Ubuntu](guides/03-ubuntu-to-ubuntu.md)** |
| 🪟 Windows | 🐧 Ubuntu | 👉 **[04. Windows → Ubuntu](guides/04-windows-to-ubuntu.md)** |

> 💡 노트북과 집 PC가 서로 다른 OS라면 **각각 해당하는 가이드**를 보면 됩니다. 원격 컴퓨터 설정은 한 번만 하면 되고, 두 가이드에 같은 내용이 들어 있습니다.

---

## 🖥️ 바탕화면이 보이나요?

**SSH는 터미널(명령어 창)만 보입니다.** 바탕화면을 보려면 원격 데스크톱 방법을 써야 합니다.

| 경우 | 방법 | 바탕화면 | 연구실 모니터 화면이 **그대로** 보이나? |
|---|---|---|---|
| **모든 경우** | SSH | ❌ 터미널만 | ❌ |
| Ubuntu → Windows | Remmina (RDP) | ✅ | ✅ 열어 둔 창 그대로 (연구실 모니터는 잠금 화면이 됨) · 원격이 Pro 이상 |
| | RustDesk | ✅ | ✅ **완전히 똑같은 화면** · Home도 가능 |
| Windows → Windows | 원격 데스크톱 연결 (mstsc) | ✅ | ✅ 열어 둔 창 그대로 (연구실 모니터는 잠금 화면이 됨) · 원격이 Pro 이상 |
| | RustDesk | ✅ | ✅ **완전히 똑같은 화면** · Home도 가능 |
| Ubuntu → Ubuntu | RustDesk ⭐ | ✅ | ✅ **완전히 똑같은 화면** |
| | Ubuntu 내장 원격 데스크톱 | ✅ | ✅ 똑같은 화면 (원격이 로그인된 상태여야 함) |
| | xrdp | ✅ | ❌ **별도의 새 화면** |
| | `ssh -X` | 창 하나만 | ❌ |
| Windows → Ubuntu | RustDesk ⭐ | ✅ | ✅ **완전히 똑같은 화면** |
| | Ubuntu 내장 원격 데스크톱 + mstsc | ✅ | ✅ 똑같은 화면 (원격이 로그인된 상태여야 함) |
| | xrdp + mstsc | ✅ | ❌ **별도의 새 화면** |

> ✅ **추천: SSH와 원격 데스크톱을 둘 다 설정하세요.** 평소에는 SSH(+VS Code)로 작업하고, 화면이 필요할 때 원격 데스크톱을 씁니다. 하나가 먹통이 되면 다른 하나로 들어가서 복구할 수 있습니다.

---

## 📂 문서 목록

### 🐣 쉬운 가이드 (`easy/`)
| 파일 | 내용 |
|---|---|
| [00-before-you-start.md](easy/00-before-you-start.md) | 시작하기 전에: 터미널, 복사/붙여넣기, 메모 카드 |
| [01-ubuntu-to-windows.md](easy/01-ubuntu-to-windows.md) | 🐧 우분투 → 🪟 윈도우 |
| [02-windows-to-windows.md](easy/02-windows-to-windows.md) | 🪟 윈도우 → 🪟 윈도우 |
| [03-ubuntu-to-ubuntu.md](easy/03-ubuntu-to-ubuntu.md) | 🐧 우분투 → 🐧 우분투 |
| [04-windows-to-ubuntu.md](easy/04-windows-to-ubuntu.md) | 🪟 윈도우 → 🐧 우분투 |
| [glossary.md](easy/glossary.md) | 📖 용어 사전 |
| [lab-checklist.md](easy/lab-checklist.md) | 🏫 연구실 체크리스트 (첫날 할 일, 매일 떠날 때, 접속 안 될 때 확인 순서) |

### 🤖 AI 에이전트용
| 파일 | 내용 |
|---|---|
| [AGENTS.md](AGENTS.md) | Claude Code 등 AI 에이전트가 따르는 설정 절차 |
| [CLAUDE.md](CLAUDE.md) | Claude Code가 저장소를 열면 자동으로 읽는 파일 (AGENTS.md를 불러옴) |
| [scripts/check-ubuntu.sh](scripts/check-ubuntu.sh) | 우분투 상태 점검 (읽기 전용, 아무것도 바꾸지 않음) |
| [scripts/check-windows.ps1](scripts/check-windows.ps1) | 윈도우 상태 점검 (읽기 전용, 아무것도 바꾸지 않음) |

### 📘 자세한 경우별 가이드 (`guides/`)
| 파일 | 내용 |
|---|---|
| [01-ubuntu-to-windows.md](guides/01-ubuntu-to-windows.md) | 🐧 Ubuntu → 🪟 Windows |
| [02-windows-to-windows.md](guides/02-windows-to-windows.md) | 🪟 Windows → 🪟 Windows |
| [03-ubuntu-to-ubuntu.md](guides/03-ubuntu-to-ubuntu.md) | 🐧 Ubuntu → 🐧 Ubuntu |
| [04-windows-to-ubuntu.md](guides/04-windows-to-ubuntu.md) | 🪟 Windows → 🐧 Ubuntu |

### 공통 참고 문서
| 파일 | 내용 |
|---|---|
| [00-tailscale.md](guides/00-tailscale.md) | 🌐 Tailscale 자세한 설명 (왜 쓰는지, 설치, 키 만료, MagicDNS) |
| [05-tips.md](guides/05-tips.md) | 🚀 ssh config, **VS Code Remote-SSH**, tmux, Jupyter 포트 포워딩 |
| [06-security.md](guides/06-security.md) | 🔒 비밀번호 로그인 끄기, 노트북 분실 시 대처, 공용 PC 주의 |
| [07-cautions.md](guides/07-cautions.md) | ⚠️ **주의사항 총정리** — 꼭 읽어 주세요 |
| [08-troubleshooting.md](guides/08-troubleshooting.md) | 🔧 증상별 문제 해결 |
| [09-cheatsheet.md](guides/09-cheatsheet.md) | 📋 명령어 치트시트 |
| [10-without-tailscale.md](guides/10-without-tailscale.md) | 🧭 Tailscale 없이 접속하기 (같은 네트워크, 학교 VPN, 포트포워딩) |

---

## 🚦 자세한 가이드를 볼 때는 이 순서로

> 컴퓨터가 익숙하지 않다면 이 순서 대신 **[🐣 쉬운 가이드](#easy)** 를 따라 하세요.

1. 아래 **[개념](#concepts)** 을 읽습니다. (3분)
2. [내 경우 고르기](#choose) 표에서 **내 가이드**를 열고 위에서부터 따라 합니다.
   - 1장 Tailscale → 2장 원격 컴퓨터 설정(**연구실에서**) → 3~5장 SSH → 6장 바탕화면
3. 가이드 끝의 **✅ 점검표**를 연구실에 있을 때 확인합니다. 특히 **재부팅 테스트**가 중요합니다.
4. **[⚠️ 주의사항 총정리](guides/07-cautions.md)** 를 꼭 읽습니다.
   원격에서 **"시스템 종료"를 누르면 연구실에 직접 가야** 합니다.
5. 익숙해지면 **[VS Code Remote-SSH와 tmux](guides/05-tips.md)** 로 작업 환경을 편하게 만듭니다.

---

<a id="concepts"></a>
## 📖 먼저 알아야 할 개념

### SSH vs 원격 데스크톱

| | SSH | 원격 데스크톱 |
|---|---|---|
| 보이는 것 | **터미널(명령어 창)만** | **바탕화면 전체** |
| 속도 | 매우 빠르고, 느린 인터넷에서도 잘 됨 | 화면을 전송하므로 인터넷 속도 영향이 큼 |
| 주 용도 | 코딩, 딥러닝 학습 돌리기, 파일 전송, 서버 관리 | GUI 프로그램 사용, 화면 확인 |
| 대표 도구 | `ssh`, VS Code Remote-SSH | Windows 원격 데스크톱(RDP), Remmina, RustDesk |

### 용어

- **원격 컴퓨터(호스트, 서버)**: 접속**당하는** 컴퓨터입니다. 예를 들면 연구실 PC이고, **항상 켜져 있어야** 합니다.
- **내 컴퓨터(클라이언트)**: 접속**하는** 컴퓨터입니다. 예를 들면 노트북이나 집 PC입니다.
- **사설 IP**: 공유기나 학교 방화벽 뒤에서 쓰는 `192.168.x.x`, `10.x.x.x` 같은 주소입니다. **같은 네트워크 안에서만** 접속할 수 있습니다.
- **RDP**: Windows의 원격 데스크톱 방식(Remote Desktop Protocol)입니다. Remmina, mstsc가 이 방식으로 접속합니다.
- **RustDesk**: Windows와 Ubuntu 모두에서 쓸 수 있는 무료 원격 데스크톱 프로그램입니다. 연구실 모니터 화면을 **그대로** 보여 줍니다.

### 왜 Tailscale을 쓰나요?

학교 네트워크는 보통 외부에서 들어오는 접속을 막고 포트포워딩도 마음대로 할 수 없습니다.
**Tailscale**은 내 기기들끼리 암호화된 가상 네트워크를 만들어서, 각 기기에 **`100.x.x.x` 고정 IP**를 줍니다.
포트를 열 필요가 없고, 인터넷에 포트를 노출하지 않아서 안전합니다. → [자세히](guides/00-tailscale.md)

```
 [노트북] ─┐
           ├──(Tailscale 암호화 터널)──> [연구실 PC 100.x.x.x]
 [집 PC] ──┘
```

> ⚠️ **학교 규정 확인**: 일부 학교나 연구실은 외부 원격 접속이나 VPN 프로그램 설치를 제한합니다. 설치 전에 전산팀이나 교수님께 확인하세요.

### ✍️ 문서 공통 표기 규칙

| 표기 | 의미 | 예시 |
|---|---|---|
| `100.x.x.x` | 원격 컴퓨터의 **Tailscale IP** | `100.101.102.103` |
| `사용자명` | **원격 컴퓨터**의 로그인 계정 이름 | `hong` |
| `lab`, `win` | `~/.ssh/config`에 등록한 별칭 | `ssh lab` |
| `# ...` | 명령어 설명(주석). 입력하지 않아도 됩니다. | |

> 문서에 나오는 IP, 사용자명은 모두 **예시(가짜) 값**입니다. 실제 값을 이 저장소나 인터넷에 올리지 마세요.

---

## 📝 요약 — 가장 추천하는 조합

| 상황 | 추천 |
|---|---|
| 코딩, 학습 돌리기 | **Tailscale + SSH 키 인증 + VS Code Remote-SSH + tmux** |
| 원격 Windows 화면 보기 | **RDP**(Pro 이상, `mstsc`나 Remmina) 또는 **RustDesk** |
| 원격 Ubuntu 화면 그대로 보기 | **RustDesk**(Xorg + 자동 로그인) |
| 파일 옮기기 | 작은 파일은 `scp`, 큰 폴더는 `rsync`, GUI는 WinSCP나 Nautilus `sftp://` |

⭐ 도움이 되었다면 Star를 눌러 주세요!
