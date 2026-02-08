-- Set options
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = ''
vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.o.wrap = false
vim.g.mapleader = " "
vim.o.cmdheight = 1
vim.o.laststatus = 3
vim.opt.showcmdloc = 'statusline'
vim.o.showmode = false
vim.lsp.set_log_level("ERROR")
vim.g.fzf_layout = { window = {width = 0.8, height = 0.9 } }

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
