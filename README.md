# dotfiles

这是我的个人 macOS 配置仓库，目前管理 Emacs、Ghostty、Fastfetch、
Zsh 和自定义 Iosevka 字体。程序配置保存在仓库中，再通过符号链接放到
各程序实际读取的位置；字体配置通过 GitHub Actions 手动构建。

这个仓库首先服务于我当前的开发环境，不是通用配置发行版。部分设置依赖
macOS、Homebrew、特定字体和已安装的开发工具；新机器部署前应先阅读下面的
依赖与私有数据说明。

## 仓库结构

```text
dotfiles/
├── .github/workflows/build-fonts.yml
├── emacs/
│   ├── early-init.el
│   ├── init.el
│   └── custom.el
├── fastfetch/
│   ├── config.jsonc
│   └── logos/
├── ghostty/
│   └── config.ghostty
├── fonts/
│   └── iosevka/
│       ├── private-build-plans.toml
│       ├── version.txt
│       ├── package-fonts.py
│       ├── requirements.txt
│       └── README.md
├── zsh/
│   ├── .zprofile
│   └── .zshrc
├── .gitignore
└── README.md
```

## 链接布局

| 程序 | 仓库源 | 实际目标 | 粒度 |
| --- | --- | --- | --- |
| Emacs | `emacs/early-init.el` | `~/.emacs.d/early-init.el` | 文件 |
| Emacs | `emacs/init.el` | `~/.emacs.d/init.el` | 文件 |
| Emacs | `emacs/custom.el` | `~/.emacs.d/custom.el` | 文件 |
| Ghostty | `ghostty/config.ghostty` | `~/Library/Application Support/com.mitchellh.ghostty/config.ghostty` | 文件 |
| Fastfetch | `fastfetch/` | `${XDG_CONFIG_HOME:-$HOME/.config}/fastfetch` | 目录 |
| Zsh | `zsh/.zprofile` | `~/.zprofile` | 文件 |
| Zsh | `zsh/.zshrc` | `~/.zshrc` | 文件 |

这里有几个刻意保留的边界：

- `~/.emacs.d` 本身仍是本机目录，只链接三个配置入口。Emacs 包、缓存、
  历史记录和其他运行时状态不会进入仓库。
- Fastfetch 链接整个目录，因为 `config.jsonc` 和 `logos/` 需要一起使用。
  因此通过 `~/.config/fastfetch` 新建文件，实际会写入仓库。
- Ghostty 只管理 macOS Application Support 中的 `config.ghostty`，不同时
  创建 XDG 配置，以免两份配置互相覆盖。
- Zsh 只链接 `.zprofile` 和 `.zshrc`。不设置 `ZDOTDIR`，也不管理
  `.zshenv`、历史记录、会话和补全缓存。

当前链接使用仓库的绝对路径。仓库被移动、重命名或重新克隆到别处后，需要
重新建立链接。如果仓库位于 Dropbox 等 File Provider 目录中，应确保配置
文件始终保留在本机，否则登录 Shell 启动时可能暂时无法读取它们。

## 环境与依赖

### 基本环境

- macOS
- Git
- Zsh
- 需要使用对应配置时安装 Emacs、Ghostty 和 Fastfetch

### 字体

- Ghostty 使用 `Iosevka Term Curly`。
- Emacs 配置使用 Iosevka Curly 系列和 `LXGW WenKai`。
- Zsh 提示符包含 Powerline 私用区字符，终端字体需要提供对应字形。

自定义的 `Iosevka Shengyi` 和 `Iosevka Term Shengyi` 构建配置位于
[`fonts/iosevka/`](fonts/iosevka/README.md)。两套字体共用 Curly 字形设计，
采用长点零、双层带衬线 a 和 dlig 连字预设。构建只支持手动触发，可下载
Artifact 或选择发布到 Release。安装字体后，再按该目录的说明切换应用。

### 可选的命令行工具

Zsh 配置集成了 Homebrew、opam、Elan、Bison、zsh-syntax-highlighting、
pyenv、direnv、Fastfetch 和 Mole。启动阶段会检查相关命令或目录是否存在，
缺少它们时会跳过相应初始化。

部分别名和函数只有在实际调用时才需要额外工具：

- `opam-up` 和 `opam-set` 需要 opam。
- `rsbcl` 需要 `rlwrap` 和 SBCL。
- `rgpdf` 需要 `rga`。
- `EDITOR` 当前指向 macOS Emacs.app 中的 `emacsclient`。

Emacs 配置还依赖 `custom.el` 中记录的包和若干外部开发工具。包安装目录不受
本仓库管理；新机器目前仍需单独安装 `package-selected-packages`。该过程尚未
自动化，也不能假定当前配置兼容所有旧版 Emacs。

配置格式可以参考
[Ghostty 官方文档](https://ghostty.org/docs/config)和
[Fastfetch 官方文档](https://github.com/fastfetch-cli/fastfetch/wiki/Configuration)。

## 手动建立链接

目前还没有自动安装脚本。下面的 Zsh 函数只会创建缺失的链接：

- 源文件不存在时拒绝操作；
- 已经正确链接时不做任何修改；
- 普通文件、普通目录、不同链接或断开的链接一律视为冲突；
- 不覆盖、不删除，也不自动移动任何现有内容。

先克隆仓库并进入仓库根目录：

```zsh
git clone https://github.com/txyyss/dotfiles.git
cd dotfiles
dotfiles_root="$(git rev-parse --show-toplevel)"
```

定义安全的单链接操作：

```zsh
link_one() {
    local source_path="$1"
    local target_path="$2"
    local current_target

    if [[ ! -e "$source_path" ]]; then
        print -u2 -r -- "missing source: $source_path"
        return 1
    fi

    if [[ -L "$target_path" ]]; then
        current_target="$(readlink "$target_path")"
        if [[ "$current_target" == "$source_path" ]]; then
            print -r -- "already linked: $target_path"
            return 0
        fi

        print -u2 -r -- "conflicting symlink: $target_path -> $current_target"
        return 1
    fi

    if [[ -e "$target_path" ]]; then
        print -u2 -r -- "existing path: $target_path"
        return 1
    fi

    mkdir -p "$(dirname "$target_path")" || return 1
    ln -s "$source_path" "$target_path"
    print -r -- "linked: $target_path -> $source_path"
}
```

确认所有冲突都已经逐项检查并备份后，再建立链接：

```zsh
link_one "$dotfiles_root/emacs/early-init.el" \
    "$HOME/.emacs.d/early-init.el"
link_one "$dotfiles_root/emacs/init.el" \
    "$HOME/.emacs.d/init.el"
link_one "$dotfiles_root/emacs/custom.el" \
    "$HOME/.emacs.d/custom.el"

link_one "$dotfiles_root/ghostty/config.ghostty" \
    "$HOME/Library/Application Support/com.mitchellh.ghostty/config.ghostty"

fastfetch_config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
link_one "$dotfiles_root/fastfetch" \
    "$fastfetch_config_home/fastfetch"

link_one "$dotfiles_root/zsh/.zprofile" "$HOME/.zprofile"
link_one "$dotfiles_root/zsh/.zshrc" "$HOME/.zshrc"
```

不要使用 `ln -sf` 或 `ln -sfn`。特别是当 Fastfetch 目标已经是普通目录时，
直接执行普通的 `ln -s` 可能在该目录内部再创建一层链接，而不是替换目录。
上面的函数会拒绝这种情况。

手动安装可能只完成部分组件；每个 `link_one` 调用都会独立报告结果。未来的
安装脚本会在写入前一次性检查全部目标，避免出现半安装状态。

## 验证

先检查符号链接：

```zsh
readlink "$HOME/.emacs.d/early-init.el"
readlink "$HOME/.emacs.d/init.el"
readlink "$HOME/.emacs.d/custom.el"
readlink "$HOME/Library/Application Support/com.mitchellh.ghostty/config.ghostty"
readlink "${XDG_CONFIG_HOME:-$HOME/.config}/fastfetch"
readlink "$HOME/.zprofile"
readlink "$HOME/.zshrc"
```

再做配置检查：

```zsh
/bin/zsh -n "$dotfiles_root/zsh/.zprofile"
/bin/zsh -n "$dotfiles_root/zsh/.zshrc"

/Applications/Ghostty.app/Contents/MacOS/ghostty +validate-config
fastfetch --list-config-paths

git status --short
```

最后打开新的登录 Shell、Ghostty 和 Emacs，确认提示符、补全、字体和主题。
Emacs 首次部署可以使用 `--debug-init` 启动，以便定位缺包或外部命令问题。

`custom.el` 受版本管理。通过 Emacs Customize 保存设置时，会沿符号链接直接
修改仓库中的 `emacs/custom.el`，提交前需要检查 `git diff`。

## 备份与回滚

建立链接前，应逐项查看原目标并将需要保留的内容移动到仓库之外的唯一备份
路径。不要自动移动整个 `~/.emacs.d`，只处理三个受管理的 Emacs 配置文件。
迁移备份应保留到新配置经过一段时间验证之后。

回滚时：

1. 关闭或停止使用对应程序。
2. 确认目标仍是符号链接，而且精确指向预期的仓库源。
3. 解除该链接。
4. 确认目标路径已经不存在。
5. 将备份作为普通文件或目录恢复到原位置。

不要直接把备份复制到仍然存在的符号链接路径，否则复制操作可能沿着链接
覆盖仓库文件。Fastfetch 是目录链接，解除时不要给目标路径添加尾部 `/`，
也不要对它使用递归删除命令。

Git 只能恢复仓库里的文件，不能恢复安装前被移动的本机配置。备份不会由
仓库或未来安装脚本自动清理。

## 私有数据边界

假设这个仓库以及完整 Git 历史最终可能公开。适合进入版本管理的内容包括：

- 手写配置、主题、快捷键、别名和不含凭据的函数；
- Fastfetch 配置与有意公开的自定义 logo；
- 无真实凭据的示例模板。

真正的秘密必须留在仓库和同步目录之外：

- 密码、API token、cookie、真实 `.env`、SSH/GPG 私钥；
- `.authinfo`、`.netrc`、npm、PyPI 和云服务凭据；

以下生成文件和本机状态不得加入 Git，并应尽量保留在仓库之外：

- `.zsh_history`、`.zsh_sessions`、`.zcompdump*` 和 `*.zwc`；
- Emacs 的 `elpa/`、`eln-cache/`、`.elc`、history、recentf、bookmarks、
  TRAMP、备份与自动保存文件；
- Ghostty 的日志、崩溃报告和会话状态；
- Fastfetch 的缓存、输出和截图；
- Homebrew、opam、pyenv、Elan 与 direnv 的本机状态。

`.gitignore` 不是秘密管理方案；仓库位于 Dropbox 时，被 Git 忽略的文件仍
可能被云同步。真正的凭据应放在仓库外，并交给 macOS Keychain、密码管理器
或其他加密存储管理。

当前 `.gitignore` 会忽略 Emacs 的 `.elc`；它们可以作为本机编译产物存在，
但不属于可移植配置，也不应强制加入版本管理。

当前配置还没有统一的 `local.el` 或 `local.zsh` 私有覆盖接口。在代码真正
支持可选加载、文件权限和 ignore 规则之前，不应假设这些文件会自动生效。

如果秘密曾经进入 Git 历史，仅删除当前文件并不够：应先撤销或轮换凭据，再
决定是否需要清理历史。

## 后续计划

下一步可以增加安装脚本，但它应遵守以下边界：

- 默认只预览，显式选择组件或 `--all` 后才执行；
- 写入前检查全部源和目标，任一冲突都不产生修改；
- 正确链接视为无需操作，其他现有路径默认拒绝；
- 只有显式 `--backup` 才移动冲突目标，永不删除或合并；
- 不使用 `sudo`，不安装或升级 Homebrew、软件和语言包；
- 不迁移历史、缓存、凭据或其他本机状态；
- 失败时只撤销本次刚创建且仍指向预期源的链接；
- 卸载与回滚必须是单独的显式操作。

Zsh 的性能优化也会单独进行，不与安装脚本或配置迁移混在同一次修改中。
