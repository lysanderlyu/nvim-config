# Neovim 配置说明

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;这是一个个人的 Neovim 配置，包含了常用插件、LSP 支持、Telescope/Fzf 文件查找、Git 操作、调试工具、快捷键和自定义命令，适合日常开发使用。  


---

## 一、安装 Neovim

1. macOS:

```bash
mkdir ~/bin/
cd ~/bin
wget https://github.com/neovim/neovim/releases/download/v0.11.5/nvim-macos-arm64.tar.gz
tar -vxf nvim-macos-arm64.tar.gz
ln -s nvim-macos-arm64/bin/nvim ./
```

2. Linux (Debian/Ubuntu):
    Linux 下一般不建议直接用APT安装NVIM，因为APT库的NVIM都是旧的版本，可能大部分插件都已经不支持了, 下面是直接下载Neovim官方编译好的版本方法

```bash
cd ~
mkdir bin #在家目录下创建bin目录，常用的Linux发行版会检测这目录是否存在，并会自动将其加入到PATH变量中
wget https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
tar vxf nvim-linux-x86_64.tar.gz
ln -s nvim-linux-x86_64/bin/nvim ./
```

3. Windows:

- 推荐使用 [Neovim 官方发布版](https://github.com/neovim/neovim/releases)

---

## 二、使用方法

1. 克隆本配置：

```bash
git clone https://github.com/lysanderlyu/nvim-config ~/.config/nvim
cd ~/.config/nvim
git checkout for-ssh-client     # 这个适用于远程SSH客户端使用, 主要是适配远程拷贝到本地系统剪切板功能
git checkout master             # 这个适合本地系统使用
```

2. 打开 Neovim：

```bash
nvim
```

3. Lazy.nvim 会自动安装插件  
4. 使用上述快捷键快速操作  
5. 本配置的说明没有覆盖vi/vim的基础按键的用法说明，如果在此配置文件找不到对应的说明，可以参考vi/vim 使用手册 [vi/vim 原生快捷键手册](https://vim.rtorr.com/) 
6. 如果想要查看当前可用的所有快捷键，只需按下Esc进入Normal模式，然后 空格+sk即可查看所有可用快捷键
![查看可用快捷键](http://106.55.165.251:9000/images/2026/01/118849ffeb2ba8084be46f63b51fa86a.png)
---

## 三、配置目录结构

```
~/.config/nvim
├── init.lua           # 主配置文件
├── lazy-lock.json     # Lazy.nvim 锁定文件
├── lua
│   ├── configs        # 各插件及 LSP 配置
│   └── plugins        # 插件列表
├── snips              # 代码片段
└── syntax             # 自定义语法文件
```

---

## 四、插件管理

- 使用 [Lazy.nvim](https://github.com/folke/lazy.nvim) 管理插件
- 常用插件：
  - `telescope.nvim` / `fzf-lua`：文件查找、模糊搜索
  - `nvim-lspconfig`：LSP 配置
  - `toggleterm.nvim`：终端管理
  - `nvim-dap`：调试工具
  - `statuscol.nvim`：状态栏和行号
  - `which-key.nvim`：快捷键提示
  - `soil.nvim`：快速格式化

---

## 五、快捷键说明
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Neovim支持用户自定义快捷键，但这些快捷都是基础快捷键之外的快捷键，比如j，k，l，h这些快捷键依然是原生的Neovim快捷键这里不会覆盖。
> 需要注意的是，以下的快捷键是我自定义的快捷键，如果快捷键含有`<leader>`字眼，说明这个快捷键是空格开头的，需要先按空格再按后面的才会生效

### 1. 文本操作（搜索查询复制粘贴）

| 快捷键 | 功能 |
|--------|------|
| `<leader>;a` | 全选文本 |
| `vl` | 选中当前行（去掉首尾空格） |
| `N;y` | 复制 N 行到系统剪贴板 |
| `N;d` | 删除 N 行并复制到系统剪贴板 |
| `';` | Visual模式下复制到系统剪贴板 |
| `;'` | 粘贴系统剪贴板内容 |
| `<leader>sb` | 打开当前文件搜索框 |
| `<leader>sB` | 打开所有已打开的文件搜索框 |
| `<leader>sg` | 打开文本全局搜索框 |
| `<leader>ss` | 将当前`"`寄存器的文本进行全局搜索 |
| `<leader>sS` | 将当前`+`寄存器（也就是系统剪切板）的文本进行全局搜索 |
| `<leader>tl` | 使用谷歌翻译当前行 |
| `T` | 使用谷歌翻译当前字 |
| `<leader>n<leader>tr` | 使用谷歌翻译n行 |

### 2. Tab 操作
Neovim 支持多开TAB，就像VScode多开文件一样

| 快捷键 | 功能 |
|--------|------|
| `<leader>tt` | 新建 tab |
| `<leader>tq` | 关闭 tab |
| `<leader>;0` | 跳转到最后一个 tab |
| `;N` | 跳转到第N个tab |
| `<leader>lt` | 下一个 tab |
| `<leader>ht` | 上一个 tab |

### 3. 文件操作

| 快捷键 | 功能 |
|--------|------|
| `<leader>;w` | 保存 |
| `<leader>;q` | 关闭 |
| `<leader>cr` | 重命名当前文件 |
| `<leader>bd` | 关闭当前Buffer |
| `<leader>br` | 重新打开当前Buffer |
| `<leader>bR` | 重新打开所有Buffer |
| `<leader>;W` | 保存并关闭 |
| `<leader>;Q` | 强制关闭 |
| `<leader>;bo` | 关闭当前Buffer以外的所有Buffer |
| `<leader>;l` | 执行 `./build.sh` |
| `<leader>;r` | 删除文件中的 `\r` 字符 |
| `<leader>;d` | 如果当前窗口打开了两个文件，执行这个快捷键就会比较这两个文件 |
| `<leader>;D` | 如果当前窗口打开了两个文件，执行这个快捷键就会取消比较这两个文件 |
| `<leader>mt` | 使用Typora打开此markdown文件 |
| `<leader>mc` | 使用playwright渲染此markdown文件到PNG文件并打开 |
| `<leader>so` | 打开大纲/函数/结构体/类/标题查询跳转窗口 |
| `<leader>ao` | 打开函数/结构体/类/标题浏览窗口 |
| `]f` | 定位到上一个函数 |
| `[f` | 定位到下一个函数 |

### 4. Telescope / Fzf 文件搜索

| 快捷键 | 功能 |
|--------|------|
| `<leader>sh` | 搜索帮助标签 |
| `<leader>/` | 当前缓冲区模糊查找 |
| `<leader>km` | 查看所有快捷键 |
| `<leader>cm` | 查看所有命令 |
| `<leader>ff` | 全局文件搜索 |
| `<leader>fb` | 查看已打开的Buffer |

### 5. Git 快捷键

| 快捷键 | 功能 |
|--------|------|
| `<leader>gs` | 打开 Git status, 可git add 和checkout 和reset |
| `<leader>go` | Git 状态总览窗口 |
| `<leader>gb` | Git 分支切换窗口 |
| `<leader>gS` | Git stash 当前文件 |
| `<leader>gSa` | Git stash 所有 |
| `<leader>gSp` | Git stash pop 恢复最近一次暂存 |
| `<leader>gcm` | Git commit 弹出提交窗口|
| `<leader>gp` | Git pull 拉取当前分支最新提交|
| `<leader>gP` | Git push 推送当前分支到Origin仓库 |
| `<leader>gl` | Git log 列表浏览模式查看Git log |
| `<leader>gL` | Git log 这个模式进入看详情Git log |
| `<leader>gbl` | Git blame 在文件侧边显示当前文件的Git blame信息 |
| `<leader>ga` | Git add Git添加当前文件 |
| `<leader>gA` | Git add Git添加所有修改 |
| `<leader>gco` | Git checkout Git恢复当前文件 |
| `<leader>gd` | Git diff split Git diff 当前文件，与最近一次提交进行比较 |
| `<leader>gD` | 弹出窗口，选择当前文件与特定提交点进行差异比较 |
| `<leader>gra` | 执行 Git reset --mixed |
| `<leader>grs` | 执行 Git reset --soft HEAD~1 |
| `<leader>grd` | 执行 Git reset --hard HEAD~1 |

以下是在按下<leader>gs 打开Git Status的交互界面时的快捷键

| 快捷键 | 功能 |
| -------------- | --------------- |
| `s` | Stage当前光标下的文件 |
| `u` | Unstage当前光标下的文件 |
| `U` | Unstage所有文件 |
| `X` | checkout光标下的文件 |
| `=` | 粗略显示当前光标下文件的变更内容 |
| `dv` | 新建两个横向窗口显示当前光标下文件的详细差异 |
| `ds` | 新建两个竖向窗口显示当前光标下文件的详细差异 |
| `cc` | 提交当前Stage区内容 |
| `cw` | 修改上一次提交的提交提示信息 |
| `ca` | 修改上一次提交的提交提示信息并可追加遗漏的更改至该提交上 |


### 6. LSP
#### 6.1 环境准备
要使用LSP功能，要准备好以下环境：

| 程序                 | 目的              |
| :------------------- | ----------------- |
| clangd               | C/CPP 语法服务端  |
| pyright              | python 语法服务端 |
| bash-language-server | Bash 语法服务端   |
| lua-language-server  | Lua 语法服务端    |



Linux可以通过以下命令进行安装

```bash

# LSP Server 安装
sudo apt install clangd bash-language-server lua-language-server npm rust-analyzer
npm install pyright

# 1. For clangd
# 由于clangd不是绝对的智能，对于一些头文件的查找路径识别不是很准确，但是 clangd会通过读取一个文件
# “compilation_commands.json” 来重新识别头文件路径， compilation_commands.json 可以通过编译
# CMakefileList.txt (cmake 所使用) 或者 Makefile (make 所使用) 时自动生成，对于 cmake 和 make 有
# 不同的生成方式，各对应两种不同的使用方法
# 1.1 对于 cmkae项目(CMakefileList.txt), 添加CMAKE_EXPORT_COMPILE_COMMANDS=ON 变量即可
cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON ........
# 1.2 对于 make项目(Makefile), 需要一些额外工具才能配合make 去生成 被clangd使用的 compilation_commands.json
# 1.2.1 使用 Build EAR (bear), (通过追踪system calls，来记录实际编译的命令)
sudo apt install bear
bear -- make
# 1.2.2 使用python的compiledb (不会追踪system calls，更兼容多平台)
pip install --user compiledb
python3 -m compiledb -n make

```

| 快捷键 | 功能 |
|--------|------|
| `<leader>ld` | 显示当前光标下的诊断信息 |
| `[d` | 下一个诊断信息 |
| `]d` | 上一个诊断信息 |
| `<leader>ll` | 已列表显示所以的ERROR和WARN |
| `<leader>li` | 显示Implementation |
| `<leader>la` | 显示当前符号的可用操作 |
| `<leader>lD` | 查找定义 |
| `<leader>lS` | 自定义输入查找符号定义 |
| `<leader>lr` | 查找引用 |
| `<leader>ln` | 重命名 |
| `K` | 悬浮窗口显示光标下变量或函数信息 |

### 7. 调试 (nvim-dap)

| 快捷键 | 功能 |
|--------|------|
| `<F5>` | 开始 / 继续 |
| `<F10>` | 单步跳过 |
| `<F11>` | 单步进入 |
| `<F12>` | 单步跳出 |
| `<leader>b` | 切换断点 |
| `<leader>B` | 设置条件断点 |
| `<leader>dr` | 打开 REPL |
| `<leader>dl` | 运行上一次调试 |

### 8. 文件Exploer侧边栏

| 快捷键 | 功能 |
|--------|------|
| `<leader>db` | 打开主页 |
| `<leader>e` | 打开文件管理器 |
| `<leader>ge` | 打开Git变更文件浏览器侧边栏 |
| 以下快捷键是在文件浏览侧边栏中才能使用的快捷键 | |
| `C-k` | 显示光标下文件的基本信息 |
| `c` | 复制当前光标下的文件 |
| `p` | 粘贴当前光标下的文件，尽量将光标移动到你想粘贴到的位置再按 |
| `x` | 剪切当前文件 |
| `d` | 删除当前文件 |
| `y` | 复制当前文件名 |
| `Y` | 复制当前文件相对路径 |
| `gy` | 复制当前文件绝对路径 |

### 9. 其他功能

| 快捷键 | 功能 |
|--------|------|
| `<leader>dt` | 查看 DTB 文件的 DTS 展开 |
| `<leader>ds` | 使用本地编译器将ELF文件展开查看Symbol |
| `<leader>da` | 使用本地编译器将ELF文件展开查看Assemble |
| `<leader>di` | 编译 D2 图并打开 |
| `<leader>ac`, `<leader>ae`, `<leader>a{` | 对齐 N 行注释、等号、花括号 |
| `<leader>cn` | 复制当前文件绝对路径 |
| `<leader>sC` | 打开系统终端 |
| `<leader>si` | 编译当前的Plantuml文件并打开生成的SVG |
| `<leader>cp` | 编译当前的Plantuml文件到PNG图片 |
| `<leader>v` | 进入ASCII画图模式 |

> 以下快捷键是进入venn画图模式时所使用

| 快捷键   | 功能    |
|--------------- | --------------- |
| J   | 竖线往下   |
| K   | 竖线往上   |
| L   | 竖线往右   |
| H   | 竖线往左   |


以下是venn模式下画图例子:

```plain
┌───────────────────────┐
│   ┌──────────────┐    │
│   │              │    │
│   │   venn test  │    │
│   │              │    │
│   └──────────────┘    │
└───────────────────────┘

```

## 六、自定义命令

- `:D2`：编译当前 D2 文件为 PNG 并打开
- `:Soil`：将当前的plantuml图编译并打开
- Git / DTB / 对齐命令均绑定快捷键

---

## 七、代码片段

这个是用来配合补全功能来使用的片段快捷插入功能

放在 `snips/` 目录中，支持不同语言：

- `snippets/c.json`：vs-code 样式的代码片段  
- `all.lua`：通用片段  
- `c.lua`：C 语言片段  
    当你打开的是C语言文件，并输入`fn1` 或者 `fn2` 然后回车，就会自动插入预定好的片段：
    ```c
    /**
     * SECTION: section_name
     * @title: Title
     * @short_description: Short description
     * @param param1 
     * @return: 
     */
    void func_name(param1) {
    }
    ```
- `csharp.lua`：C# 片段  
    适用于csharp源码使用的预定义片段
- `java.lua`：Java 片段  
    与同上类似

---

## 八、自定义语法

- 放在 `syntax/` 目录，例如 `tshark.vim` 这个是我用来高亮一些NVIM不支持高亮的特殊文件类型

---

## 九、备注


- 本配置适合 macOS / Linux / Windows  
- 推荐配合 `git`, `rg`, `bat`, `fzf` 等工具  
- 可以根据自己的习惯修改 `lua/plugins/` 或 `lua/configs/` 中的配置
- `Keymaps.lua`文件中并不是包含所有的快捷键映射，独立的插件文件比如`lua/plugins/fzf-lua.lua`插件文件也有自己的快捷键映射，但不是放在`keymaps.lua`文件中

