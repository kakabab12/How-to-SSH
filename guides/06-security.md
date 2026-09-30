# 🔒 보안 설정

> 원격 접속을 **안전하게** 쓰기 위한 설정입니다. 모든 경우(01~04)에 공통입니다.

[← 전체 목차로 돌아가기](../README.md)

---

## 1. 기본 원칙

- ✅ **Tailscale을 쓰면 포트를 인터넷에 열지 않으므로** 기본적으로 안전합니다.
- ❌ 공유기에서 22번(SSH), 3389번(RDP), 21118번(RustDesk) 포트를 인터넷에 여는 **포트포워딩은 하지 마세요.** 몇 분 안에 전 세계에서 무작위 로그인 공격이 들어옵니다.
- 🔑 **개인키(`id_ed25519`, `.pub`가 없는 파일)는 절대 공유하지 마세요.** 원격에 등록하는 건 항상 `.pub`(공개키)입니다.
- 🔑 **깃허브, 노션, 카톡 등에 IP, 사용자명, 비밀번호, 키를 올리지 마세요.**
- 🔒 원격 계정 비밀번호와 RustDesk 영구 비밀번호는 **길고 복잡하게** 설정하세요.
- 🧹 쓰지 않는 기기는 Tailscale 관리 콘솔에서 **Remove** 하세요.

---

<a id="disable-password"></a>
## 2. 키 인증을 설정한 뒤 비밀번호 로그인 끄기 (선택, 권장)

키 인증이 되면 비밀번호 로그인은 꺼도 됩니다. 비밀번호를 알아도 키가 없으면 SSH로 못 들어오게 됩니다.

> ⚠️ **반드시 키 로그인이 되는 것을 먼저 확인하세요.**
> 기존 SSH 창은 **닫지 말고**, **새 터미널**에서 `ssh lab`이 비밀번호 없이 되는지 테스트한 뒤 적용하세요.
> 잘못하면 SSH로 못 들어가게 됩니다. 원격 데스크톱이나 현장에서는 복구할 수 있습니다.
> 여러 기기(노트북, 집 PC)를 쓴다면 **모든 기기의 키를 먼저 등록**한 뒤에 끄세요.

### 🐧 원격이 Ubuntu인 경우

```bash
# 설정 파일 생성 (파일 이름이 01로 시작해야 다른 기본 설정보다 먼저 적용됨)
printf "PasswordAuthentication no\nKbdInteractiveAuthentication no\n" | sudo tee /etc/ssh/sshd_config.d/01-disable-password.conf

sudo sshd -t                     # 설정 문법 검사 (아무 출력 없으면 OK)
sudo systemctl restart ssh
sudo sshd -T | grep -Ei 'passwordauthentication|kbdinteractive'   # 둘 다 "no" 인지 확인
```

되돌리려면:
```bash
sudo rm /etc/ssh/sshd_config.d/01-disable-password.conf
sudo systemctl restart ssh
```

### 🪟 원격이 Windows인 경우 (관리자 PowerShell)

```powershell
notepad C:\ProgramData\ssh\sshd_config
```
1. `#PasswordAuthentication yes` 줄을 찾아 **`PasswordAuthentication no`** 로 바꿉니다. 앞의 `#`도 지웁니다.
2. 파일 맨 아래의 `Match Group administrators` 부분은 **그대로 둡니다.**
3. 저장한 뒤 다음을 실행합니다.
```powershell
Restart-Service sshd
```

---

## 3. SSH 키에 비밀번호(passphrase) 걸기

키를 만들 때 passphrase를 걸면 **노트북을 도난당해도 키를 바로 쓸 수 없습니다.**

```bash
ssh-keygen -p -f ~/.ssh/id_ed25519      # 이미 만든 키에 passphrase 추가/변경
```

매번 입력하기 귀찮다면 **ssh-agent**에 한 번 등록해 두면 됩니다.
- Ubuntu 데스크톱: 처음 접속할 때 한 번 입력하면 로그인 세션 동안 기억합니다.
- Windows (관리자 PowerShell):
  ```powershell
  Get-Service ssh-agent | Set-Service -StartupType Automatic
  Start-Service ssh-agent
  ssh-add $env:USERPROFILE\.ssh\id_ed25519
  ```

---

<a id="lost-device"></a>
## 4. 노트북을 잃어버렸을 때

**즉시** 아래를 하세요.

1. **Tailscale 관리 콘솔**(https://login.tailscale.com/admin/machines) → 잃어버린 기기 `...` → **Remove**
2. **원격 컴퓨터에서 그 기기의 SSH 키 삭제**
   - Ubuntu: `nano ~/.ssh/authorized_keys` → 끝에 `ubuntu-laptop`처럼 **그 기기 이름이 붙은 줄**을 삭제
   - Windows 관리자: 관리자 메모장으로 `C:\ProgramData\ssh\administrators_authorized_keys` 열어서 해당 줄 삭제
   - (키를 만들 때 `-C "기기이름"`을 붙여야 구분할 수 있습니다. 꼭 붙이세요.)
3. **원격 계정 비밀번호**와 **RustDesk 영구 비밀번호** 변경
4. RDP나 RustDesk에 **비밀번호를 저장**해 뒀다면 이것도 바꿔야 합니다.

---

## 5. 공용 PC에서 접속했을 때

PC방, 도서관, 남의 컴퓨터에서 접속했다면 나오기 전에:
- 원격 데스크톱 연결(mstsc): **자격 증명 삭제** (연결 창 → 사용자 이름 옆 **삭제**)
- RustDesk: 저장된 비밀번호, 최근 연결 기록 삭제
- 키를 복사해 썼다면 `.ssh` 폴더의 **개인키 삭제**
- Tailscale을 설치했다면 **로그아웃 + 관리 콘솔에서 Remove**

> 가능하면 **공용 PC에서는 접속하지 않는 것**이 가장 안전합니다.

---

## 6. (Tailscale 없이 공인 IP로 열어야만 한다면)

권장하지 않지만, 꼭 해야 한다면 최소한:
- **키 인증만 허용** (위 2번)
- **fail2ban** 설치 (Ubuntu): 로그인에 반복해서 실패한 IP를 자동으로 차단합니다.
  ```bash
  sudo apt install -y fail2ban
  sudo systemctl enable --now fail2ban
  sudo fail2ban-client status sshd      # 차단 현황
  ```
- RDP(3389)는 **절대 인터넷에 직접 열지 마세요.**
- 학교 네트워크라면 **학교 VPN** 등 공식 방법을 먼저 고려하세요. → [10-without-tailscale.md](10-without-tailscale.md)

---

[← 전체 목차로 돌아가기](../README.md)
