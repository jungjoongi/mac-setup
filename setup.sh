#!/bin/bash
# Mac 개발환경 원클릭 셋업
# 새 Mac(아무것도 설치 안 된 상태)에서 실행:
#   curl -fsSL https://raw.githubusercontent.com/jungjoongi/mac-setup/main/setup.sh | bash
# 집 맥북 (DisplayLink + vdisplay 포함):
#   curl -fsSL https://raw.githubusercontent.com/jungjoongi/mac-setup/main/setup.sh | bash -s -- --home
# 이미 받은 저장소에서 실행:
#   bash setup.sh
#
# 여러 번 실행해도 안전합니다(이미 된 단계는 건너뜀).

set -uo pipefail

# curl | bash 실행 시 스크립트 전체를 먼저 읽도록 함수로 감쌈
main() {
HOME_SETUP=""
for arg in "$@"; do
  case "$arg" in
    --home)    HOME_SETUP=1 ;;
    --no-home) HOME_SETUP=0 ;;
  esac
done
if [[ -z "$HOME_SETUP" ]]; then
  read -r -p "집 맥북 세팅(DisplayLink + vdisplay)도 할까요? [y/N] " ans || ans=""
  [[ "$ans" =~ ^[Yy] ]] && HOME_SETUP=1 || HOME_SETUP=0
fi

REPO="${MAC_SETUP_REPO:-jungjoongi/mac-setup}"
BRANCH="${MAC_SETUP_BRANCH:-main}"
SETUP_DIR="$HOME/.mac-setup"
FAILED=()

step() { printf '\n\033[1;34m==> %s\033[0m\n' "$1"; }
ok()   { printf '\033[32m  ✓ %s\033[0m\n' "$1"; }
warn() { printf '\033[33m  ! %s\033[0m\n' "$1"; FAILED+=("$1"); }

[[ "$(uname)" == "Darwin" ]] || { echo "macOS 전용 스크립트입니다."; exit 1; }
[[ $EUID -ne 0 ]] || { echo "sudo 없이 일반 사용자로 실행하세요."; exit 1; }

# ---------------------------------------------------------------
# 0. 저장소 파일 확보 (curl | bash 로 실행된 경우 git 없이 tarball로 받음)
# ---------------------------------------------------------------
SCRIPT_DIR=""
[[ -f "${BASH_SOURCE[0]:-}" ]] && SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -n "$SCRIPT_DIR" && -f "$SCRIPT_DIR/Brewfile" ]]; then
  SRC="$SCRIPT_DIR"
else
  step "설정 파일 다운로드 ($REPO)"
  rm -rf "$SETUP_DIR" && mkdir -p "$SETUP_DIR"
  curl -fsSL "https://github.com/$REPO/archive/refs/heads/$BRANCH.tar.gz" \
    | tar -xz -C "$SETUP_DIR" --strip-components=1 \
    || { echo "다운로드 실패: 저장소가 public인지, REPO 값이 맞는지 확인하세요."; exit 1; }
  SRC="$SETUP_DIR"
fi
ok "설정 파일 위치: $SRC"

# ---------------------------------------------------------------
# 1. 관리자 비밀번호 (처음 한 번만 입력, 끝날 때까지 유지)
# ---------------------------------------------------------------
step "관리자 권한 확인 (Mac 로그인 비밀번호 입력)"
sudo -v < /dev/tty
while true; do sudo -n true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done 2>/dev/null &

# ---------------------------------------------------------------
# 2. Homebrew (Xcode Command Line Tools 도 함께 설치됨)
# ---------------------------------------------------------------
step "Homebrew + Xcode Command Line Tools"
if ! command -v brew >/dev/null 2>&1 && [[ ! -x /opt/homebrew/bin/brew ]]; then
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"
grep -q 'brew shellenv' "$HOME/.zprofile" 2>/dev/null \
  || echo 'eval "$(/opt/homebrew/bin/brew shellenv zsh)"' >> "$HOME/.zprofile"
command -v brew >/dev/null && ok "Homebrew $(brew --version | head -1)" || { echo "Homebrew 설치 실패"; exit 1; }

# ---------------------------------------------------------------
# 3. 앱 / CLI 설치 (Brewfile)
# ---------------------------------------------------------------
step "Brewfile 패키지 설치 (시간이 걸립니다)"
echo "  App Store에 로그인되어 있지 않으면 KakaoTalk만 실패할 수 있습니다(로그인 후 재실행)."
brew bundle --file="$SRC/Brewfile" && ok "Brewfile 완료" || warn "Brewfile 일부 실패 → 'brew bundle --file=$SRC/Brewfile' 재실행"

# ---------------------------------------------------------------
# 4. Oh My Zsh + 테마 + 플러그인
# ---------------------------------------------------------------
step "Oh My Zsh"
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi
ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
clone() { [[ -d "$2" ]] || git clone -q --depth=1 "$1" "$2" || warn "clone 실패: $1"; }
clone https://github.com/romkatv/powerlevel10k.git                 "$ZSH_CUSTOM/themes/powerlevel10k"
clone https://github.com/zsh-users/zsh-autosuggestions.git         "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
clone https://github.com/zsh-users/zsh-syntax-highlighting.git     "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
clone https://github.com/zsh-users/zsh-completions.git             "$ZSH_CUSTOM/plugins/zsh-completions"
clone https://github.com/Aloxaf/fzf-tab.git                        "$ZSH_CUSTOM/plugins/fzf-tab"
clone https://github.com/MichaelAquilina/zsh-you-should-use.git    "$ZSH_CUSTOM/plugins/you-should-use"
ok "Oh My Zsh / Powerlevel10k / 플러그인"

# ---------------------------------------------------------------
# 5. 설정 파일 (기존 파일은 .bak.날짜 로 백업)
# ---------------------------------------------------------------
step "설정 파일 복사"
TS="$(date +%Y%m%d%H%M%S)"
install_file() { # src dest
  mkdir -p "$(dirname "$2")"
  if [[ -f "$2" ]] && ! cmp -s "$1" "$2"; then cp "$2" "$2.bak.$TS"; fi
  cp "$1" "$2"
}
install_file "$SRC/dotfiles/zshrc"                  "$HOME/.zshrc"
install_file "$SRC/dotfiles/p10k.zsh"               "$HOME/.p10k.zsh"
install_file "$SRC/dotfiles/DefaultKeyBinding.dict" "$HOME/Library/KeyBindings/DefaultKeyBinding.dict"
install_file "$SRC/karabiner/karabiner.json"        "$HOME/.config/karabiner/karabiner.json"
mkdir -p "$HOME/.nvm"
ok "~/.zshrc, ~/.p10k.zsh, ₩→\` 키바인딩, Karabiner 설정"

# ---------------------------------------------------------------
# 6. tmux (Oh My Tmux)
# ---------------------------------------------------------------
step "Oh My Tmux"
if [[ ! -d "$HOME/.tmux" ]]; then
  git clone -q --depth=1 https://github.com/gpakosz/.tmux.git "$HOME/.tmux" || warn "Oh My Tmux clone 실패"
fi
if [[ -f "$HOME/.tmux/.tmux.conf" ]]; then
  ln -sf "$HOME/.tmux/.tmux.conf" "$HOME/.tmux.conf"
  [[ -f "$HOME/.tmux.conf.local" ]] || cp "$HOME/.tmux/.tmux.conf.local" "$HOME/.tmux.conf.local"
  ok "Oh My Tmux"
fi

# ---------------------------------------------------------------
# 7. Claude Code CLI
# ---------------------------------------------------------------
step "Claude Code CLI"
if [[ ! -x "$HOME/.local/bin/claude" ]] && ! command -v claude >/dev/null 2>&1; then
  curl -fsSL https://claude.ai/install.sh | bash || warn "Claude CLI 설치 실패"
fi
[[ -x "$HOME/.local/bin/claude" ]] && ok "claude 설치됨"
export PATH="$HOME/.local/bin:$PATH"

# ---------------------------------------------------------------
# 7-0. Claude Code 도구: Node LTS, Claude HUD, secrets, claude-carousel
# ---------------------------------------------------------------
step "Node.js LTS (nvm)"
export NVM_DIR="$HOME/.nvm"
NODE_BIN=""
if [[ -s "$(brew --prefix)/opt/nvm/nvm.sh" ]]; then
  # shellcheck disable=SC1091
  . "$(brew --prefix)/opt/nvm/nvm.sh"
  nvm install --lts >/dev/null && nvm alias default 'lts/*' >/dev/null && NODE_BIN="$(nvm which default)"
fi
[[ -x "$NODE_BIN" ]] && ok "node $("$NODE_BIN" -v)" || warn "Node LTS 설치 실패 (HUD에 필요)"

step "Claude Code 플러그인 (claude-hud, secrets)"
if command -v claude >/dev/null 2>&1; then
  claude plugin marketplace add jarrodwatts/claude-hud >/dev/null 2>&1 || true
  claude plugin install claude-hud@claude-hud >/dev/null 2>&1 || warn "claude-hud 플러그인 설치 실패"
  claude plugin marketplace add jungjoongi/awesome-plugins >/dev/null 2>&1 || true
  claude plugin install secrets@awesome-plugins >/dev/null 2>&1 || warn "secrets 플러그인 설치 실패"
  ok "플러그인 설치"
else
  warn "claude 명령이 없어 플러그인을 건너뜀"
fi

# HUD: 설정 복사 + 상태 줄 연결 (nvm Node는 PATH에 없으므로 전체 경로로 연결)
HUD_MJS="$(ls -d "$HOME"/.claude/plugins/cache/claude-hud/claude-hud/*/hud.mjs 2>/dev/null | sort -V | tail -1)"
install_file "$SRC/dotfiles/claude-hud-config.json" "$HOME/.claude/plugins/claude-hud/config.json"
if [[ -n "$HUD_MJS" && -x "$NODE_BIN" ]]; then
  "$NODE_BIN" "$HUD_MJS" install >/dev/null && ok "Claude HUD 상태 줄 연결" || warn "HUD 연결 실패 → Claude Code에서 /hud"
fi

# secrets (Bitwarden Secrets Manager): shim, bws, 상태 폴더
SECRETS_SRC="$(ls -d "$HOME"/.claude/plugins/cache/awesome-plugins/secrets/*/skills/secrets/scripts/secrets 2>/dev/null | sort -V | tail -1)"
if [[ -n "$SECRETS_SRC" ]]; then
  "$SECRETS_SRC" setup shim >/dev/null 2>&1 || true
  command -v bws >/dev/null 2>&1 || "$SECRETS_SRC" setup bws || warn "bws 설치 실패"
  "$SECRETS_SRC" doctor --fix >/dev/null 2>&1 || true
  if ! secrets doctor 2>/dev/null | grep -q '^ok   auth'; then
    echo
    echo "  Bitwarden Secrets Manager 액세스 토큰을 지금 등록할 수 있습니다."
    echo "  (웹 → Secrets Manager → 머신 계정 → 액세스 토큰 → 이 Mac 이름으로 새 토큰 발급·복사)"
    read -r -p "  지금 등록할까요? [y/N] " ans || ans=""
    if [[ "$ans" =~ ^[Yy] ]]; then
      secrets setup token && secrets setup project main --create >/dev/null || warn "secrets 토큰 등록 실패"
    fi
  fi
  secrets doctor 2>/dev/null | grep -q '^ok   auth' && ok "secrets 준비됨" || warn "secrets 토큰 미등록 → 나중에 'secrets setup token'"
fi

step "claude-carousel (cc)"
if [[ ! -x "$HOME/.local/bin/carousel" ]]; then
  # 단축 명령(cc)은 dotfiles/zshrc 에 이미 있으므로 등록하지 않음
  curl -fsSL https://raw.githubusercontent.com/jungjoongi/claude-carousel/main/install.sh \
    | CAROUSEL_NO_PROMPT=1 bash >/dev/null || warn "carousel 설치 실패"
fi
if command -v carousel >/dev/null 2>&1 && secrets doctor 2>/dev/null | grep -q '^ok   auth'; then
  # carousel-order 의 프로필마다 Secrets Manager의 PERSONAL_CAROUSEL_TOKEN_<이름> 을 등록 (값은 화면에 나오지 않음)
  keys="$(secrets list --prefix PERSONAL_CAROUSEL_TOKEN_ 2>/dev/null | awk 'NR>1 {print $1}')"
  for p in $(cat "$SRC/carousel-order"); do
    [[ "$p" == default ]] && continue
    key="PERSONAL_CAROUSEL_TOKEN_$(printf '%s' "$p" | tr '[:lower:]' '[:upper:]')"
    grep -qx "$key" <<<"$keys" || { warn "Secrets Manager에 $key 없음 → 프로필 $p 건너뜀"; continue; }
    [[ -d "$HOME/.claude-carousel/profiles/$p" ]] || carousel add "$p" < /dev/null >/dev/null 2>&1
    secrets run --map TOK="$key" -- sh -c 'printf "%s\n" "$TOK" | carousel token "$1" >/dev/null 2>&1' _ "$p" \
      && ok "carousel 프로필 $p" || warn "carousel 프로필 $p 토큰 등록 실패"
  done
  order=""
  for p in $(cat "$SRC/carousel-order"); do
    [[ "$p" == default || -d "$HOME/.claude-carousel/profiles/$p" ]] && order="$order $p"
  done
  # shellcheck disable=SC2086
  [[ -n "$order" ]] && carousel order $order >/dev/null && ok "순서:$order"
fi
# HUD에 프로필 이름 표시 (설정 폴더마다 claude-hud.json)
hud_label() { printf '{\n  "display": {\n    "showProvider": true,\n    "providerName": "%s"\n  }\n}\n' "$1" > "$2"; }
hud_label default "$HOME/.claude/claude-hud.json"
for d in "$HOME"/.claude-carousel/profiles/*/; do
  [[ -d "$d" ]] && hud_label "$(basename "$d")" "$d/claude-hud.json"
done
ok "HUD 프로필 이름 표시"

# ---------------------------------------------------------------
# 7-1. 집 맥북 전용 (--home): DisplayLink + vdisplay
# ---------------------------------------------------------------
if [[ "$HOME_SETUP" == 1 ]]; then
  step "집 맥북: DisplayLink"
  brew bundle --file="$SRC/Brewfile.home" && ok "DisplayLink Manager" || warn "Brewfile.home 실패"

  step "집 맥북: vdisplay (private 저장소 → GitHub 로그인 필요)"
  if ! gh auth status >/dev/null 2>&1; then
    echo "  GitHub 로그인을 시작합니다. SSH 키가 없으면 새로 만들어 등록합니다."
    gh auth login --hostname github.com --git-protocol ssh --web || warn "gh 로그인 실패"
  fi
  mkdir -p "$HOME/git"
  if [[ ! -d "$HOME/git/vdisplay" ]]; then
    GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=accept-new" git clone -q git@github.com:jungjoongi/vdisplay.git "$HOME/git/vdisplay" \
      || warn "vdisplay clone 실패 (gh 로그인 / SSH 키 확인)"
  fi
  if [[ -d "$HOME/git/vdisplay" ]]; then
    make -C "$HOME/git/vdisplay" install && ok "vdisplay 설치 + 로그인 시 자동 실행 등록" \
      || warn "vdisplay 빌드/설치 실패"
  fi
fi

# ---------------------------------------------------------------
# 8. git / macOS 설정
# ---------------------------------------------------------------
step "git-lfs, macOS 설정"
git lfs install >/dev/null 2>&1 || true
defaults write -g ApplePressAndHoldEnabled -bool false   # 키 길게 누르면 반복 입력
defaults write kCFPreferencesAnyApplication TSMLanguageIndicatorEnabled 0   # 입력 소스 전환 팝업 끄기 (한/영 전환 지연 방지)
# 한/영 전환: Karabiner가 Caps Lock → F19 탭(누르는 즉시 down+up), macOS "이전 입력 소스 선택" = F19 (숫자 타입으로 저장해야 인식됨)
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 60 '<dict><key>enabled</key><true/><key>value</key><dict><key>parameters</key><array><integer>65535</integer><integer>80</integer><integer>8388608</integer></array><key>type</key><string>standard</string></dict></dict>'
/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u 2>/dev/null || true
ok "키 반복, 입력 소스 팝업 끄기, Caps Lock(F19) 한/영 전환 (재로그인 후 적용)"

# ---------------------------------------------------------------
# 끝
# ---------------------------------------------------------------
step "완료"
if [[ ${#FAILED[@]} -gt 0 ]]; then
  printf '\033[33m실패/확인 필요:\033[0m\n'; printf '  - %s\n' "${FAILED[@]}"
fi
cat <<EOF

남은 작업(권한 허용, 로그인 등)은 스크립트로 할 수 없습니다.
새 터미널을 열고 아래를 실행하세요:

  cd $SRC && claude "CLAUDE.md 읽고 남은 셋업 마무리해줘$([[ "$HOME_SETUP" == 1 ]] && echo ' (집 맥북)')"

EOF
}

main "$@" < /dev/tty
