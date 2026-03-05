-- Set options
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = ''
vim.o.wrap = false
vim.g.mapleader = " "
vim.o.cmdheight = 1
vim.o.laststatus = 3
vim.opt.showcmdloc = 'statusline'
vim.o.showmode = false
vim.lsp.set_log_level("ERROR")
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
vim.opt.diffopt:append("horizontal")
vim.opt.diffopt:append("filler")
vim.opt.diffopt:append("closeoff")
vim.opt.diffopt:append("linematch:50")
vim.opt.diffopt:append("iwhite")


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

-- parse gitsendemail file as diff 
vim.api.nvim_create_augroup("gitsendemail_filetype", { clear = true })
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
    pattern = "*.patch",
    command = "set filetype=diff",
    group = "gitsendemail_filetype",
})

-- parse .inc file as bitbake 
vim.api.nvim_create_augroup("bitbake_filetype", { clear = true })
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
    pattern = "*.inc",
    command = "set filetype=bitbake",
    group = "bitbake_filetype",
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

-- For sharing the clipboard between remote
vim.g.clipboard = {
   name = "OSC 52",
   copy = {
      ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
      ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
   },
   paste = {
      ["+"] = require("vim.ui.clipboard.osc52").paste("+"),
      ["*"] = require("vim.ui.clipboard.osc52").paste("*"),
   },
}
