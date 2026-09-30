# 🌐 Tailscale 설치 & 설정 (공통 준비)

> 모든 가이드에서 공통으로 쓰는 **Tailscale** 설명입니다.
> 각 가이드(01~04)의 1장에 필요한 부분이 요약되어 있으니, 더 자세한 내용이 궁금할 때 보세요.

[← 전체 목차로 돌아가기](../README.md)

---

## 1. 왜 Tailscale을 쓰나요?

학교나 집의 컴퓨터는 대부분 **공유기나 학교 방화벽 뒤**에 있어서 `192.168.x.x`, `10.x.x.x` 같은 **사설 IP**를 씁니다.
사설 IP는 **같은 네트워크 안에서만** 접속할 수 있습니다. 집에서 연구실 PC의 사설 IP로는 접속할 수 없고, 학교 네트워크는 포트포워딩도 마음대로 할 수 없습니다.

**Tailscale**은 이 문제를 이렇게 해결합니다.

- 내 기기들끼리 암호화된 가상 네트워크(VPN, WireGuard 기반)를 만듭니다.
- 각 기기에 **`100.x.x.x` 형태의 고정 IP**를 줍니다. 기기가 어느 와이파이에 있든 이 IP는 바뀌지 않습니다.
- 기기끼리 이 IP로 직접 통신하므로 **포트를 열거나 공유기를 설정할 필요가 없습니다.**
- 인터넷에 포트를 노출하지 않아서 **보안상으로도 안전**합니다.
- 개인 용도라면 무료 플랜으로 충분합니다.

```
 [노트북] ─┐
           ├──(Tailscale 암호화 터널)──> [연구실 PC 100.x.x.x]
 [집 PC] ──┘
```

> ⚠️ 일부 학교나 연구실은 VPN 프로그램 설치를 제한합니다. 설치 전에 전산팀이나 교수님께 확인하세요.

---

## 2. 계정 만들기

1. https://tailscale.com 에 접속해서 **Get started**를 누릅니다.
2. Google, Microsoft, GitHub 계정 중 하나로 로그인합니다.
3. 앞으로 **모든 기기에서 이 계정 하나로** 로그인합니다. 다른 계정으로 로그인한 기기끼리는 서로 보이지 않습니다.

---

## 3. 🪟 Windows에 설치

1. https://tailscale.com/download/windows 에서 설치 파일을 받아 실행합니다.
2. 작업 표시줄 오른쪽 아래(트레이)의 Tailscale 아이콘 → **Log in** → 브라우저에서 로그인합니다.
3. 내 IP를 확인합니다.
   ```powershell
   tailscale ip -4
   ```
4. **(원격 컴퓨터로 쓸 Windows만)** 트레이 아이콘 → **Settings(설정)** → ✅ **Run unattended**
   → Windows에 로그인하지 않은 상태(재부팅 직후)에도 Tailscale이 연결됩니다.

---

## 4. 🐧 Ubuntu에 설치

```bash
sudo apt install -y curl                           # curl 이 없으면 설치 (새로 설치한 우분투에는 없음)
curl -fsSL https://tailscale.com/install.sh | sh   # 설치
sudo tailscale up                                  # 로그인 (출력되는 URL을 브라우저로 열어서 로그인)
tailscale ip -4                                    # 내 Tailscale IP 확인 (100.x.x.x)
tailscale status                                   # 연결된 기기 목록 확인
```

Ubuntu에서는 Tailscale이 시스템 서비스로 등록되어 **부팅할 때 자동으로 연결**됩니다.

> 브라우저가 없는 서버라면 `sudo tailscale up`이 출력한 URL을 **다른 컴퓨터의 브라우저**에서 열어도 됩니다.

---

<a id="key-expiry"></a>
## 5. ⚠️ 원격 컴퓨터는 "키 만료" 끄기 (중요)

Tailscale은 보안을 위해 **일정 기간(기본 180일)마다 기기에 재로그인을 요구**합니다.
연구실 PC가 몇 달 뒤 갑자기 접속이 안 되는 일을 막으려면 **원격 컴퓨터**의 키 만료를 꺼 두세요.

1. https://login.tailscale.com/admin/machines 에 접속합니다.
2. 원격 컴퓨터 줄 오른쪽의 `...` → **Disable key expiry**를 누릅니다.

> 노트북 같은 **내 컴퓨터**는 키 만료를 켜 두는 편이 안전합니다. 잃어버렸을 때 저절로 접속 권한이 끊기기 때문입니다.

---

## 6. IP 대신 기기 이름으로 접속하기 (MagicDNS)

Tailscale의 **MagicDNS**가 켜져 있으면 IP 대신 **기기 이름**으로 접속할 수 있습니다. 새 계정에는 기본으로 켜져 있습니다.

```bash
ssh 사용자명@lab-pc      # 100.x.x.x 대신 기기 이름 사용
```

- 기기 이름은 관리 콘솔(Machines)에서 확인하거나 바꿀 수 있습니다. (`...` → **Edit machine name**)
- 안 되면 관리 콘솔 → **DNS** 탭에서 MagicDNS를 켜세요.

---

## 7. 연결 테스트 & 상태 보기

```bash
tailscale status               # 내 계정의 모든 기기와 online/offline 상태
tailscale ping 100.x.x.x       # "pong from ..." 이 나오면 네트워크 준비 완료
```

`tailscale status`에서 연결 방식도 확인할 수 있습니다.
- `direct` → 기기끼리 **직접** 연결 (빠름)
- `relay "..."` → 학교 방화벽 등 때문에 Tailscale **중계 서버를 거침** (느림, 하지만 동작은 함)

---

## 8. 관리 팁

| 하고 싶은 것 | 방법 |
|---|---|
| 기기 목록 보기 | https://login.tailscale.com/admin/machines |
| 안 쓰는 기기, 잃어버린 기기 제거 | 관리 콘솔 → 기기 `...` → **Remove** |
| 동료에게 연구실 PC 하나만 공유 | 관리 콘솔 → 기기 `...` → **Share** (계정을 공유하지 말고 이 기능을 쓰세요) |
| 원격 PC 재로그인이 필요할 때 | Ubuntu: `sudo tailscale up` / Windows: 트레이 아이콘 → Log in |

> ⚠️ **원격 PC에서 `sudo tailscale down`, `tailscale logout`을 실행하거나 트레이에서 Exit를 누르지 마세요.** 내가 타고 들어온 통로가 끊겨서 연구실에 가야 합니다.

---

[← 전체 목차로 돌아가기](../README.md)
