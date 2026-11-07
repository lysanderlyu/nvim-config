-- Neovim 0.11 deprecates vim.tbl_islist; keep a silent alias for plugins
-- (old telescope, etc.) that still call it from pickers and layout resolve.
if vim.islist then
  vim.tbl_islist = vim.islist
end

-- Set options
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = ''
vim.o.wrap = false
-- New vertical splits open to the right of the current window. Without this,
-- <C-v> in a picker (or nvim-tree) launched from the tree sidebar splits to
-- the left of the sidebar itself.
vim.opt.splitright = true
vim.g.mapleader = " "
vim.o.cmdheight = 1
vim.o.laststatus = 3
vim.opt.showcmdloc = 'statusline'
vim.o.showmode = false
vim.lsp.log.set_level("ERROR")
vim.g.fzf_layout = { window = {width = 0.8, height = 0.9 } }

-- Dynamic switch tab size
-- Default: 4 spaces
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.expandtab = true

-- Function to detect Linux kernel style
local function detect_kernel_style()
    -- Search upward for Kconfig file
    local kconfig = vim.fn.findfile("Kconfig", ".;")
    if kconfig ~= "" then
        vim.opt_local.tabstop = 8
        vim.opt_local.shiftwidth = 8
        vim.opt_local.softtabstop = 8
        vim.opt_local.expandtab = false
    end
end

-- Autocommand group
local group = vim.api.nvim_create_augroup("KernelStyle", { clear = true })

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
    group = group,
    pattern = { "*.c", "*.h" },
    callback = detect_kernel_style,
})

-- Enable folding
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
-- start opened
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99
vim.opt.foldenable = true

-- For git diff word based
vim.opt.diffopt:append("internal")
vim.opt.diffopt:append("algorithm:patience")
vim.opt.diffopt:append("indent-heuristic")
vim.opt.diffopt:append("linematch:60")
vim.opt.diffopt:append("vertical")
vim.opt.diffopt:append("filler")
vim.opt.diffopt:append("closeoff")
vim.opt.diffopt:append("linematch:50")
vim.opt.diffopt:append("iwhite")

-- gf on diff paths: strip a/ and b/ prefixes (e.g. a/device/... -> device/...)
vim.opt.includeexpr = "substitute(v:fname, '^[ab]/', '', '')"


-- parse .pro file as shell
vim.api.nvim_create_augroup("tshark_filetype", { clear = true })
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
    pattern = "*.tshark",
    command = "set filetype=tshark",
    group = "tshark_filetype",
})

-- parse .pro file as shell
vim.api.nvim_create_augroup("pro_filetype", { clear = true })
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
    pattern = "*.pro",
    command = "set filetype=sh",
    group = "pro_filetype",
})

-- parse .qml file as qmljs 
vim.api.nvim_create_augroup("qml_filetype", { clear = true })
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
    pattern = "*.qml",
    command = "set filetype=qmljs",
    group = "qml_filetype",
})

-- parse .drawio file as xml 
vim.api.nvim_create_augroup("drawio_filetype", { clear = true })
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
    pattern = "*.drawio",
    command = "set filetype=xml",
    group = "drawio_filetype",
})

-- parse .inc file as bitbake 
vim.api.nvim_create_augroup("bitbake_filetype", { clear = true })
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
    pattern = "*.inc",
    command = "set filetype=bitbake",
    group = "bitbake_filetype",
})

-- parse *config*.in and Config.src as kconfig regardless of letter case
-- (Config.in, config.in, FOOconfig.IN, Config.src). configure.in is autoconf,
-- not Kconfig.
vim.filetype.add({
  extension = {
    tshark = "tshark",
    pro = "sh",
    qml = "qmljs",
    drawio = "xml",
    inc = "bitbake",
    uc = "javascript",
  },
  pattern = {
    -- Lua patterns are case-sensitive, so spell out both cases.
    [".*[cC][oO][nN][fF][iI][gG].*%.[iI][nN]"] = function(path)
      -- configure.in is Autoconf, not Kconfig.
      if vim.fs.basename(path):lower() == "configure.in" then
        return "config"
      end
      return "kconfig"
    end,
    -- Config.src is a Kconfig source file in some projects. Patterns without a
    -- slash match the basename and are implicitly anchored, so this hits
    -- Config.src only, not e.g. Fooconfig.src.
    ["[cC][oO][nN][fF][iI][gG]%.[sS][rR][cC]"] = "kconfig",
    -- Kbuild.src is a Kbuild fragment; use the same filetype Neovim gives
    -- the Kbuild file itself.
    ["[kK][bB][uU][iI][lL][dD]%.[sS][rR][cC]"] = "make",
  },
})

-- DownLoad lazy if not exits
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Remote sessions have no OS clipboard of their own, so copy through OSC 52.
-- Paste reads the unnamed register instead: an OSC 52 read is a request the
-- terminal must answer, and most refuse it for security, which blocks Neovim
-- for ~10s on every access to "+ / "*.
local is_ssh = vim.env.SSH_CONNECTION or vim.env.SSH_TTY or vim.env.SSH_CLIENT

-- Also cover local Linux without a display server (TTY / container).
local has_local_clipboard = vim.fn.has("mac") == 1
  or vim.fn.has("win32") == 1
  or vim.env.DISPLAY ~= nil
  or vim.env.WAYLAND_DISPLAY ~= nil

if is_ssh or not has_local_clipboard then
  local osc52 = require("vim.ui.clipboard.osc52")
  local function paste_from_unnamed()
    return vim.fn.getreg('"', 1, true)
  end

  vim.g.clipboard = {
    name = "OSC 52 (remote)",
    copy = {
      ["+"] = osc52.copy("+"),
      ["*"] = osc52.copy("*"),
    },
    paste = {
      ["+"] = paste_from_unnamed,
      ["*"] = paste_from_unnamed,
    },
  }
end
