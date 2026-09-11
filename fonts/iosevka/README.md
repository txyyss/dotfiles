# Iosevka Shengyi

这份配置生成两套个人字体，上游版本由 `version.txt` 指定：

| 用途 | 字体家族 | 间距 | 字重 | 样式 |
| --- | --- | --- | --- | --- |
| Emacs | Iosevka Shengyi | normal | Regular 400、SemiBold 600、Bold 700 | 正体、斜体 |
| Ghostty | Iosevka Term Shengyi | term | Regular 400、Medium 500、Bold 700 | 正体、斜体 |

两套字体各生成 6 个 TTF，共 12 个。字宽为 500，斜体角度为 9.4°。
字形继承 Curly（ss20），将 `0` 改为 `long-dotted`，`a` 改为
`double-storey-serifed`。`design` 中的选择适用于所有样式；若以后需要
单独调整斜体，可以增加 `variants.italic`。

## 修改配置

`private-build-plans.toml` 是唯一的构建配置文件。Emacs 的
`IosevkaShengyi` 计划保存共享字形；Ghostty 的 `IosevkaTermShengyi`
继承它的字形、连字、宽度和斜体设置，并单独选择终端间距和字重。

在 [Customizer](https://typeof.net/Iosevka/customizer) 中调整后，将
`IosevkaShengyi` 的配置更新到文件中，保留后面的 Term 计划。
修改共享字形或连字预设时，只需改第一套计划。

当前使用 `ligations.inherits = "dlig"`。Iosevka 会将这个预设用于生成的
字体的默认 `calt` 特性，无须另外打开 `dlig` 才能得到这些连字。
这里采用上游的 Discretionary 预设；不同语言的部分连字规则会互相冲突，
不把所有预设机械叠加。

`noCvSs = true` 省去运行时切换字形的 cv/ss 特性，选定的字形仍然保留。
`exportGlyphNames = false` 沿用 Customizer 的选择。上游版本记录在
`version.txt`，只有主动修改该文件才会更新构建版本。

## 手动构建和下载

配置和 workflow 推送到仓库默认分支后：

1. 打开 GitHub 仓库的 **Actions → Build Iosevka fonts**。
2. 点击 **Run workflow**，选择要构建的分支。
3. 如需长期下载，勾选 **同时发布到 GitHub Release，供长期下载**。
4. 等待构建完成，从该次运行的 **Artifacts** 下载字体包；若勾选了发布，
   也可以从对应的 Release 下载 ZIP。

只有手动触发会运行。推送提交、创建 tag 和 Pull Request 都不会启动构建，
也没有定时任务。一次构建的命令并发数限制为 2，手动构建之间排队运行。
Artifact 保留 14 天；需要长期保存的版本使用 Release。

也可以通过 GitHub CLI 手动启动：

```sh
gh workflow run build-fonts.yml --repo txyyss/dotfiles --ref master
```

手动构建并发布：

```sh
gh workflow run build-fonts.yml --repo txyyss/dotfiles --ref master \
  -f publish_release=true
```

构建会检查字体数量、家族名称、字重、斜体角度、常用符号与 Powerline
分隔符覆盖，并使用 HarfBuzz 验证正体和斜体中的箭头、连字符和括号星号
连字确实通过 `calt` 生效。验证成功后，字体与原始配置、上游许可证、
构建来源及各文件 SHA-256 一起打包。

## 升级 Iosevka

1. 在 [Iosevka Releases](https://github.com/be5invis/Iosevka/releases) 查看新的
   正式版本，将 `version.txt` 中的 `v34.8.1` 改为对应的版本 tag。
2. 提交并推送版本文件，再手动运行 **Build Iosevka fonts**。
3. 下载新字体并检查字形、字重和连字，满意后替换本机安装的旧版本。

通常只需要修改 `version.txt`。`private-build-plans.toml` 中的个人字形
选择可以沿用；若上游更改配置格式或字形选项名称，按该版本的文档和构建
报错调整对应项。workflow 和用于验证字体的 Python 依赖不必随字体版本
一同升级，除非新版本明确提出了新的构建环境要求。

构建结果记录上游版本和 commit。已发布的旧 Release 可以保留，方便比较
或重新安装旧字体。升级版本文件仍然不会自动触发构建。

## 安装与应用

解压字体 ZIP，使用 macOS「字体册」安装两个家族目录中的 TTF 文件。
仓库中的 Emacs 和 Ghostty 配置已使用这两个字体家族，字号均为 18 pt。

Emacs 的主字体、`fixed-pitch`、`org-modern-symbol` 以及拉丁、希腊、
西里尔、符号和私用区 fontset 使用 `Iosevka Shengyi`。`Iosevka Curly Slab`、
`Iosevka Aile` 和中文字体 `LXGW WenKai` 继续用于原有角色。

Ghostty 使用：

```ini
font-family = Iosevka Term Shengyi
font-style = Medium
font-size = 18
```

字体包含连字，还需要应用把相应字符序列交给字体排版。Ghostty 的默认
字体特性会使用 `calt`。Emacs 使用 `ligature.el`，在 `emacs-lisp-mode`、
`coq-mode`、`lean4-mode`、`tuareg-mode` 和 `utop-mode` 中，将连续运算符
交给字体完整排版，支持可变长度的箭头和符号链；带 `- `、`+ ` 或 `* `
前缀的复选框也会包含所需上下文。匹配规则定义在局部 `let*` 中。
实际显示哪些连字由字体决定；新增语言时再扩充模式列表。

## 本地复现

安装 Git、Node.js 24、npm 和 ttfautohint（macOS 可通过 Homebrew 安装）。
在一个独立的工作目录克隆 `version.txt` 中指定的 Iosevka tag，复制本目录
中的 `private-build-plans.toml` 到 Iosevka 源码根目录，然后执行：

```sh
npm ci --no-audit --no-fund
npm run build -- ttf::IosevkaShengyi ttf::IosevkaTermShengyi --jCmd=2
```

字体位于 `dist/IosevkaShengyi/TTF/` 和 `dist/IosevkaTermShengyi/TTF/`。
打包脚本需要 Python 3.11 或更高版本及 `requirements.txt` 中的依赖。

参考：[最初使用的 34.8.1 构建说明](https://github.com/be5invis/Iosevka/blob/v34.8.1/doc/custom-build.md)、
[34.8.1 版本预设](https://github.com/be5invis/Iosevka/blob/v34.8.1/build-plans.toml)。
升级时如需查阅新文档，将链接中的 tag 换成 `version.txt` 对应的版本。
