# 🖥️ How-to-SSH

> 노트북이나 집 컴퓨터에서 **학교 연구실 컴퓨터(또는 다른 PC)에 원격으로 접속**하는 방법을 처음부터 끝까지 정리한 가이드입니다.
> **SSH(터미널 접속)** 와 **원격 데스크톱(바탕화면을 그대로 보면서 조작)** 두 가지를 모두 다룹니다.

- 기준 환경: **Windows 11**, **Ubuntu 22.04 LTS**
- 학교 방화벽이나 공유기 뒤에 있어도 되도록 **Tailscale**(무료 VPN)을 기본으로 사용합니다.

---

<a id="choose"></a>
## 📌 내 경우 고르기

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

### 경우별 가이드 (이것만 따라 하면 됨)
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

## 🚦 처음이라면 이 순서로

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
