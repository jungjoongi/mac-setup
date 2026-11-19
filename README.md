# mac-setup

새 Mac(아무것도 설치되지 않은 상태)을 한 번에 개발환경으로 만드는 스크립트.

## 설치

터미널(기본 Terminal.app)을 열고:

```bash
curl -fsSL https://raw.githubusercontent.com/__REPO__/main/setup.sh | bash
```

- 처음에 Mac 로그인 비밀번호를 한 번 입력합니다.
- Xcode Command Line Tools, Homebrew부터 자동으로 설치합니다. git이 없어도 됩니다.
- 여러 번 실행해도 안전합니다. 중간에 실패하면 다시 실행하세요.

끝나면 새 터미널에서:

```bash
cd ~/.mac-setup && claude "CLAUDE.md 읽고 남은 셋업 마무리해줘"
```

권한 허용(Karabiner 등), 계정 로그인, git 설정처럼 스크립트로 못 하는 일은
Claude가 [CLAUDE.md](CLAUDE.md)를 보고 안내합니다.

## 구성

| 파일 | 내용 |
|---|---|
| `setup.sh` | 설치 스크립트 |
| `Brewfile` | CLI, 앱, 폰트 목록 |
| `dotfiles/zshrc` | Oh My Zsh + Powerlevel10k + 플러그인 설정 |
| `dotfiles/p10k.zsh` | Powerlevel10k 프롬프트 설정 |
| `dotfiles/DefaultKeyBinding.dict` | 한글 키보드에서 ₩ → ` |
| `karabiner/karabiner.json` | Karabiner-Elements 설정 |
| `CLAUDE.md` | 스크립트 이후 마무리 작업 가이드 (Claude용) |

## zsh 플러그인

git, sudo, extract, aws, docker, fzf, fzf-tab, you-should-use,
zsh-autosuggestions, zsh-syntax-highlighting, zsh-completions
