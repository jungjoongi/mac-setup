# Mac 셋업 마무리 가이드 (Claude용)

이 저장소는 새 Mac 개발환경 셋업용이다. 사용자가 `setup.sh`를 실행한 뒤 Claude에게
"남은 셋업 마무리해줘"라고 요청하면 아래 순서대로 처리한다.

원칙:
- 각 단계는 **먼저 상태를 확인**하고, 이미 된 것은 건너뛴다.
- 사용자가 직접 해야 하는 것(GUI 권한 허용, 로그인, 비밀번호 입력)은 정확한 위치와 방법을 안내하고
  사용자가 "했어"라고 하면 다시 확인한다.
- `sudo`가 필요한 명령은 직접 실행하지 말고 `! <명령>` 형태로 사용자에게 실행을 요청한다.
- 대화형 명령(`p10k configure`, `aws configure`, `gh auth login`)은 사용자에게 새 터미널에서 실행하도록 안내한다.
- 끝나면 아래 "최종 점검" 결과를 표로 보고한다.

## 1. setup.sh 결과 점검

다음이 모두 있는지 확인하고, 빠진 게 있으면 `bash setup.sh`를 다시 실행하도록 안내한다
(스크립트는 여러 번 실행해도 안전함).

```bash
brew bundle check --file=Brewfile --verbose
ls -d ~/.oh-my-zsh ~/.oh-my-zsh/custom/themes/powerlevel10k ~/.tmux
ls ~/.oh-my-zsh/custom/plugins   # zsh-autosuggestions zsh-syntax-highlighting zsh-completions fzf-tab you-should-use
ls ~/.zshrc ~/.p10k.zsh ~/.config/karabiner/karabiner.json ~/Library/KeyBindings/DefaultKeyBinding.dict
command -v claude
```

- KakaoTalk(mas)만 실패했다면 App Store 앱에서 로그인한 뒤 `brew bundle --file=Brewfile` 재실행.

## 2. 셸 확인

- 사용자에게 터미널 새 창을 열게 한다. Powerlevel10k 프롬프트가 보여야 한다
  (`~/.p10k.zsh`가 이미 복사되어 있어 마법사는 뜨지 않는 게 정상).
- 아이콘이 깨지면 터미널 폰트를 **D2CodingLigature Nerd Font Mono**로 바꾸도록 안내.
- 다시 설정하고 싶으면 `p10k configure` (새 터미널에서 직접).
- 참고: Claude Code의 `!` 셸에서 `source ~/.zshrc`를 하면 `no matches found: ...(Nm-1)` 오류가 나는데
  `!` 셸의 zsh 옵션 차이 때문이며 실제 터미널에서는 문제없다. 무시해도 된다.

## 3. Karabiner-Elements 권한 (GUI, 사용자 직접)

1. `open -a Karabiner-Elements` 로 실행.
2. 시스템 설정 → 일반 → 로그인 항목 및 확장 프로그램 → 드라이버 확장 프로그램 →
   **Karabiner-DriverKit-VirtualHIDDevice** 켜기.
3. 시스템 설정 → 개인정보 보호 및 보안 → 입력 모니터링 →
   **karabiner_grabber**, **karabiner_observer** 켜기.
4. 확인: Karabiner-Elements → Complex Modifications 탭에 규칙 13개가 켜져 있어야 함
   (Control+숫자 → F1~F12, Command+Shift+Space → 영문 전환 후 Spotlight).
   `~/.config/karabiner/karabiner.json`을 읽어서 규칙 목록을 보여줘도 된다.
5. Control+숫자가 macOS 데스크탑 전환 단축키와 겹치면
   시스템 설정 → 키보드 → 키보드 단축키 → Mission Control 에서 끄도록 안내.

## 4. 기타 앱 첫 실행 / 권한

- **OrbStack**: 한 번 실행해서 초기 설정 완료 (`docker` 명령이 여기서 생김). 확인: `docker version`.
- **Raycast**: 실행 후 Command+Space로 쓰려면 Spotlight 단축키를 먼저 끄도록 안내
  (시스템 설정 → 키보드 → 키보드 단축키 → Spotlight). Karabiner의 Command+Shift+Space 규칙은
  Spotlight를 여는데, Raycast로 바꾸길 원하면 karabiner.json의 해당 규칙을 수정한다.
- **BetterDisplay**: 첫 실행 후 메뉴바 아이콘에서 설정. 외부 모니터 HiDPI 등을 쓰려면
  안내에 따라 helper 설치/권한 허용 (사용자 직접).
- **Rectangle / Maccy / Stats**: 첫 실행 시 손쉬운 사용 권한 요청 → 허용.
  Raycast와 단축키가 겹치면 어느 쪽을 쓸지 사용자에게 묻는다.
- **키 반복**: `ApplePressAndHoldEnabled` 설정은 로그아웃/재로그인 후 적용된다.
- **한/영 전환 (Caps Lock)**: Karabiner가 Caps Lock → F19로 바꾸고(simple modification),
  setup.sh가 macOS 단축키 "이전 입력 소스 선택"을 F19로 설정한다.
  - Karabiner가 입력 소스를 직접 바꾸는 방식(`select_input_source`)은 쓰지 않는다. 상단바만 바뀌고
    입력칸에는 반영되지 않는 경우가 있다. macOS 기본 "Caps Lock 키로 ABC 입력 소스 전환"도 끈다.
  - 새 Mac에는 한국어 입력기가 없으므로 사용자에게 시스템 설정 → 키보드 → 입력 소스 → 편집 →
    **+ → 한국어 → 2벌식** 추가를 안내한다.
  - 확인: 시스템 설정 → 키보드 → 키보드 단축키 → 입력 소스 → "이전 입력 소스 선택"이 켜져 있고 F19인지.
    직접 바꿀 때 `defaults write ... -dict-add 60 '{ ... }'`(문자열 문법)을 쓰면 값이 문자열로 저장돼
    인식되지 않는다. setup.sh의 XML 문법(`<integer>`)을 쓴다.
  - 입력 소스 전환 팝업은 setup.sh가 끈다 (`TSMLanguageIndicatorEnabled 0`). 전환 지연을 줄인다. 재로그인 후 적용.

## 5. 계정 / 로그인 (사용자 직접, 대화형)

사용자에게 하나씩 물어보고 필요한 것만 진행한다.

- **git 사용자 정보**: 이름과 이메일을 물어보고 설정한다.
  `git config --global user.name "..."`, `git config --global user.email "..."`,
  권장: `git config --global init.defaultBranch main`,
  delta 사용: `git config --global core.pager delta`, `git config --global interactive.diffFilter "delta --color-only"`.
- **GitHub + SSH 키**: 사용자에게 `! gh auth login` 실행을 요청하고 아래처럼 고르도록 안내한다.
  GitHub.com → 프로토콜 **SSH** → 새 SSH 키 생성 **Yes** → passphrase(선택) → 키 이름 →
  웹 브라우저 로그인. 이러면 `~/.ssh/id_ed25519`가 생성되고 GitHub에 자동 등록된다.
  - 확인: `ssh -T git@github.com` → `Hi <아이디>!` 가 나오면 성공 (처음엔 `yes` 입력).
  - passphrase를 넣었다면 `~/.ssh/config`에 추가 (이미 있으면 건너뜀):
    ```
    Host github.com
      AddKeysToAgent yes
      UseKeychain yes
      IdentityFile ~/.ssh/id_ed25519
    ```
  - 그리고 `ssh-add --apple-use-keychain ~/.ssh/id_ed25519` (사용자 직접, passphrase 입력).
- **AWS**: `aws configure` 또는 `aws-vault add <프로필>` (새 터미널에서 직접). 키는 Claude가 받지 않는다.
- **Node**: setup.sh가 nvm으로 LTS를 설치하고 기본값으로 지정한다. 확인: 새 터미널에서 `node -v`.
- **Claude Code**: `claude` 첫 실행 시 로그인 (이 계정이 carousel의 `default` 프로필).
- Slack, Notion, Obsidian, Bitwarden, KakaoTalk 등은 각 앱에서 로그인.

## 5-1. Claude Code 도구 (HUD, secrets, claude-carousel)

setup.sh가 설치한다: Claude HUD 플러그인(상태 줄), secrets 플러그인(Bitwarden Secrets Manager),
claude-carousel(`cc`, 여러 계정을 번갈아 쓰기). 아래로 확인하고 빠진 것만 처리한다.

1. **secrets**: `secrets doctor`. 처리 방법은 secrets 스킬을 따른다.
   `fail token`이면 사용자 **별도 터미널**에서 `secrets setup token`과 `secrets setup project main --create`.
   (Bitwarden 웹 → Secrets Manager → 머신 계정 → 액세스 토큰 → 이 Mac 이름으로 새로 발급. 다른 기기 토큰을 옮기지 않는다.)
2. **carousel 프로필**: `carousel ls`. 프로필은 `carousel-order` 파일(default 제외)에 있는 이름이고,
   토큰은 Secrets Manager의 `PERSONAL_CAROUSEL_TOKEN_<이름 대문자>`에 있다. 빠진 프로필은 값을 보지 않고 등록한다.
   ```bash
   carousel add dev < /dev/null
   secrets run --map TOK=PERSONAL_CAROUSEL_TOKEN_DEV -- sh -c 'printf "%s\n" "$TOK" | carousel token dev'
   carousel order $(cat carousel-order)
   carousel check        # 토큰이 실제로 동작하는지 (사용량 조금 씀). 실패한 토큰은 사용자에게 알린다.
   ```
   - 계정 이메일 라벨은 넣지 않는다 (사용자 선호: 프로필 이름으로 구분).
   - `default`에 토큰이 없으면 사용자에게 `cc token default`(별도 터미널)를 안내한다.
   - 단축 명령 `cc`는 dotfiles/zshrc에 있다. 셸이 이전 설정이면 `cc`가 C 컴파일러로 실행되니 `exec zsh`.
3. **HUD**: Claude Code에서 `/hud`로 점검. 상태 줄은 nvm Node를 **전체 경로**로 실행해야 한다
   (`hud install`을 그 Node로 실행). Node 버전을 바꾸면 `/hud`를 다시 실행한다.
   - 설정: `~/.claude/plugins/claude-hud/config.json` ← `dotfiles/claude-hud-config.json`
     (에이전트·할 일 줄, effort 표시).
   - 프로필 이름 표시: 설정 폴더마다 `claude-hud.json`에 `display.providerName`=프로필 이름,
     `showProvider`=true. default는 `~/.claude/claude-hud.json`, 나머지는
     `~/.claude-carousel/profiles/<이름>/claude-hud.json`. 새 프로필을 만들면 이 파일도 만든다.

## 5-2. 집 맥북 전용 (사용자가 "집 맥북"이라고 했거나 `~/git/vdisplay`가 있을 때만)

`setup.sh --home`(또는 시작 질문에 y)으로 실행하면 DisplayLink Manager(`Brewfile.home`)와
[vdisplay](https://github.com/jungjoongi/vdisplay)(private)가 설치된다.
vdisplay는 DisplayLink로 연결한 LG FHD 세로 모니터(vendor 7789 / model 23381)를
1440×2560 HiDPI 가상 화면 미러링으로 넓게 쓰는 도구다. 회사 맥북이면 이 단계는 건너뛴다.

1. 설치 확인. 하나라도 없으면 아래 순서로 직접 처리:
   ```bash
   ls -d "/Applications/DisplayLink Manager.app" ~/git/vdisplay ~/.local/bin/vdisplay \
         ~/Library/LaunchAgents/com.user.vdisplay.plist
   ```
   - DisplayLink 없음 → `! brew bundle --file=Brewfile.home` (sudo 필요하므로 사용자 실행)
   - 저장소 없음 → `gh auth status` 확인 후 `git clone git@github.com:jungjoongi/vdisplay.git ~/git/vdisplay`
   - 실행 파일/자동 실행 없음 → `make -C ~/git/vdisplay install`
2. **DisplayLink Manager 권한 (사용자 직접)**: 앱 실행 → 시스템 설정 → 개인정보 보호 및 보안 →
   **화면 및 시스템 오디오 녹음**에서 DisplayLink Manager 허용. 로그인 시 자동 실행도 켜도록 안내.
3. 모니터 회전: 시스템 설정 → 디스플레이 → LG FULL HD → 회전 **270°** (사용자 직접).
4. 동작 확인:
   ```bash
   make -C ~/git/vdisplay status   # state = running
   make -C ~/git/vdisplay logs     # "미러링 적용: ... err=0" 이 있어야 정상
   ~/.local/bin/vdisplay --list    # vendor=7789 모니터가 1440x2560 (px 2880x5120) 이면 정상
   ```
   - "대상 모니터 없음" → DisplayLink Manager 실행/케이블 확인. 연결되면 자동 적용됨.
   - 미러링이 꼬였으면 `make -C ~/git/vdisplay restart`.
   - 해상도 변경: `~/git/vdisplay/scripts/install.sh 1260 2240` (9:16 유지).
5. BetterDisplay에서 LG 모니터 해상도를 바꾸거나 가상 화면을 만들지 말라고 안내 (vdisplay와 충돌).
6. 자세한 사용법/문제 해결은 `~/git/vdisplay/README.md`를 읽고 따른다.

## 6. 알려진 문제

- **awscli 실행 시 `pyexpat ... Symbol not found: _XML_SetAllocTrackerActivationThreshold`**:
  Homebrew Python이 지금 macOS보다 새 버전 기준으로 빌드되어 생기는 문제.
  해결: macOS 최신 버전으로 업데이트(`softwareupdate -l`로 확인). 급하면
  `brew reinstall --build-from-source python@3.15` (버전은 `brew deps awscli`로 확인).
- **SpaceVim**: 프로젝트가 아카이브되어 설치 스크립트가 없어졌다(404). 그래서 제외했다.
  Neovim 설정이 필요하면 LazyVim 등을 사용자에게 제안만 하고 임의로 설치하지 않는다.

## 7. 최종 점검

아래를 실행해 결과를 표로 보고한다.

```bash
sw_vers -productVersion
brew bundle check --file=Brewfile && echo "brew OK"
zsh -ic 'echo $ZSH_THEME; echo $plugins' 2>/dev/null | tail -2
command -v claude gh aws docker node fzf zoxide direnv
aws --version
git config --global user.name; git config --global user.email
gh auth status
secrets doctor
carousel ls; carousel order
```

## 설정을 바꿨을 때 (저장소 갱신)

사용자가 Mac에서 설정을 바꾼 뒤 "셋업 저장소 갱신해줘"라고 하면:

- `brew leaves`, `brew list --cask` 와 Brewfile을 비교해 추가/삭제 항목을 반영
  (`brew bundle dump`는 주석/분류가 사라지므로 직접 편집).
- `~/.zshrc` → `dotfiles/zshrc`, `~/.p10k.zsh` → `dotfiles/p10k.zsh`,
  `~/.claude/plugins/claude-hud/config.json` → `dotfiles/claude-hud-config.json`,
  `carousel order` 결과(default 포함) → `carousel-order`,
  `~/.config/karabiner/karabiner.json` → `karabiner/karabiner.json` 복사.
- 복사 전에 비밀값(토큰, 키, 비밀번호)이 들어가지 않았는지 검사한다. 이 저장소는 public이다.
- 변경 내용을 보여주고 커밋/푸시는 사용자 확인 후에 한다.
