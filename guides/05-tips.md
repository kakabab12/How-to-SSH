# 🚀 더 편하게 쓰기

> ssh config, VS Code Remote-SSH, tmux, 포트 포워딩(Jupyter, TensorBoard) 등 **SSH를 편하게 쓰는 방법**입니다.
> 모든 경우(01~04)에 공통으로 쓸 수 있습니다.

[← 전체 목차로 돌아가기](../README.md)

---

## 📚 목차
1. [ssh config로 여러 대 관리하기](#ssh-config)
2. [VS Code Remote-SSH ⭐](#vscode)
3. [tmux — SSH가 끊겨도 작업 유지하기](#tmux)
4. [포트 포워딩 — Jupyter, TensorBoard를 내 브라우저로](#port-forwarding)
5. [GPU 상태 보기](#gpu)
6. [자주 쓰는 원격 관리 명령](#admin)

---

<a id="ssh-config"></a>
## 1. ssh config로 여러 대 관리하기

**파일 위치**
- Ubuntu: `~/.ssh/config` (만든 뒤 `chmod 600 ~/.ssh/config`)
- Windows: `C:\Users\내이름\.ssh\config` (확장자 없음. `config.txt`가 되지 않게 주의)

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

# 모든 호스트 공통 설정 (맨 아래에 두기)
Host *
    ServerAliveInterval 60      # 60초마다 신호를 보내 가만히 있어도 연결이 안 끊기게
    ServerAliveCountMax 3
```

이제 이렇게 짧게 쓸 수 있습니다.
```bash
ssh lab
ssh lab-win
scp file.txt lab:~/
rsync -avz ./data/ lab:~/data/
```

> 💡 `Host *` 같은 공통 설정은 **파일 맨 아래**에 두세요. ssh config는 **먼저 나온 값이 우선**합니다.

---

<a id="vscode"></a>
## 2. VS Code Remote-SSH ⭐ (강력 추천)

원격 컴퓨터의 파일을 **내 컴퓨터의 VS Code에서 바로 편집하고 실행**할 수 있습니다. 코드는 원격에서 돌고, 화면만 내 VS Code에 보입니다.

1. VS Code 확장(Extensions, `Ctrl + Shift + X`)에서 **Remote - SSH** (Microsoft)를 설치합니다.
2. `F1` (또는 `Ctrl + Shift + P`) → **Remote-SSH: Connect to Host...**
3. `~/.ssh/config`에 등록한 `lab` 또는 `lab-win`이 목록에 뜨면 선택합니다.
4. 처음이면 원격 OS(**Linux** / **Windows**)를 선택합니다. 원격에 VS Code 서버가 자동으로 설치됩니다(1~2분).
5. **Open Folder**로 원격 폴더를 엽니다.
6. `` Ctrl + ` `` 로 여는 터미널도 **원격 컴퓨터의 터미널**입니다.

💡 알아두기
- Python, Jupyter 같은 확장은 **원격 쪽에 따로 설치**해야 합니다. 확장 목록의 **"Install in SSH: lab"** 버튼을 누르세요.
- 왼쪽 아래 초록색(파란색) 표시에 `SSH: lab`이 보이면 원격에 연결된 상태입니다.
- 탐색기에 내 PC 파일을 **끌어다 놓으면 업로드**되고, 원격 파일 우클릭 → **Download**로 받을 수 있습니다.
- 원격에서 실행한 웹 서버(예: `localhost:8888`)는 VS Code가 **자동으로 포트 포워딩**해 줍니다. 아래 **포트(PORTS)** 탭에서 확인하세요.
- VS Code 터미널에서 돌린 작업도 **창을 닫으면 종료**됩니다. 긴 작업은 tmux를 쓰세요.

---

<a id="tmux"></a>
## 3. tmux — SSH가 끊겨도 작업 유지하기 (원격이 Ubuntu일 때)

SSH로 딥러닝 학습을 돌리다가 **노트북을 덮거나 와이파이가 끊기면 작업도 같이 죽습니다.**
`tmux` 안에서 실행하면 연결이 끊겨도 원격에서 계속 돌아갑니다.

```bash
sudo apt install -y tmux      # 원격 Ubuntu에 한 번만 설치

tmux new -s train             # "train" 이라는 세션 만들기
python train.py               # 세션 안에서 작업 실행
# Ctrl + b 누르고 손 뗀 뒤 d  → 세션에서 빠져나오기 (작업은 계속 실행됨)

tmux ls                       # 세션 목록
tmux attach -t train          # 다시 들어가기 (다음 날 다른 컴퓨터에서 접속해도 OK)
tmux kill-session -t train    # 세션 완전히 종료
```

| tmux 단축키 (`Ctrl + b` 누르고 손 뗀 뒤) | 기능 |
|---|---|
| `d` | 빠져나오기 (detach) — 작업은 계속 |
| `c` | 새 창 만들기 |
| `n` / `p` | 다음 / 이전 창 |
| `0`~`9` | 해당 번호 창으로 이동 |
| `%` / `"` | 화면 세로 / 가로 분할 |
| 방향키 | 분할된 칸 사이 이동 |
| `[` | 스크롤 모드 (방향키, PgUp으로 위로 보기, `q`로 종료) |

**tmux 없이 간단하게 백그라운드 실행**
```bash
nohup python train.py > train.log 2>&1 &
tail -f train.log             # 로그 실시간 보기 (Ctrl + C = 보기만 종료, 작업은 계속)
```

> 🪟 **원격이 Windows라면** tmux가 없습니다. 긴 작업은 **원격 데스크톱 안에서 실행한 뒤 "창 닫기(연결 끊기)"** 로 나오거나, 원격 Windows에 WSL(Windows용 리눅스)을 설치해서 그 안에서 tmux를 쓰세요.

---

<a id="port-forwarding"></a>
## 4. 포트 포워딩 — Jupyter, TensorBoard를 내 브라우저로

원격에서 돌아가는 웹 화면(Jupyter, TensorBoard 등)을 **내 컴퓨터 브라우저**로 봅니다.

```bash
# 내 컴퓨터에서: 내 8888 포트 → 원격의 8888 포트로 연결하면서 접속
ssh -L 8888:localhost:8888 lab

# (접속된 원격에서) Jupyter 실행
jupyter lab --no-browser --port 8888
```
내 컴퓨터 브라우저에서 `http://localhost:8888`을 엽니다. 토큰이 필요하면 원격 터미널 출력의 `?token=...`을 복사하세요.

**TensorBoard**
```bash
ssh -L 6006:localhost:6006 lab
tensorboard --logdir runs --port 6006     # 원격에서 실행 → 내 브라우저에서 http://localhost:6006
```

**매번 입력하기 귀찮다면** ssh config에 넣어 두세요. `ssh lab`만 해도 자동으로 포워딩됩니다.
```
Host lab
    HostName 100.x.x.x
    User 사용자명
    LocalForward 8888 localhost:8888
    LocalForward 6006 localhost:6006
```

> 💡 **VS Code Remote-SSH**를 쓰면 이 과정을 VS Code가 자동으로 해 줍니다.
> ⚠️ `jupyter lab --ip 0.0.0.0`처럼 모든 주소에 열지 마세요. 같은 네트워크의 다른 사람도 접속할 수 있습니다. 포트 포워딩을 쓰면 `localhost`로만 열어도 됩니다.

---

<a id="gpu"></a>
## 5. GPU 상태 보기 (NVIDIA, 원격 Ubuntu)

```bash
nvidia-smi                 # 한 번 보기 (GPU 사용률, 메모리, 실행 중인 프로세스)
watch -n 1 nvidia-smi      # 1초마다 갱신 (Ctrl + C 로 종료)
```

> 공용 GPU 서버라면 학습을 시작하기 전에 **다른 사람이 쓰고 있는지** 꼭 확인하세요.

---

<a id="admin"></a>
## 6. 자주 쓰는 원격 관리 명령

### 🐧 원격 Ubuntu
```bash
df -h                     # 디스크 남은 용량
free -h                   # 메모리 사용량
htop                      # 실행 중인 프로그램 (없으면 sudo apt install -y htop, q로 종료)
uptime                    # 켜진 지 얼마나 됐는지
sudo reboot               # 재부팅 (⚠️ shutdown 은 절대 금지)
```

### 🪟 원격 Windows (PowerShell)
```powershell
Get-PSDrive C             # C 드라이브 용량
Get-Process | Sort-Object CPU -Descending | Select-Object -First 10   # CPU 많이 쓰는 프로그램
Restart-Computer          # 재부팅 (⚠️ Stop-Computer 는 절대 금지)
```

---

[← 전체 목차로 돌아가기](../README.md)
