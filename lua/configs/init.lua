require("configs.options")

-- Set leader key
vim.g.mapleader = " "

-- Install lazy.nvim automatically
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

-- Auto-load plugin specs from lua/plugins/*.lua
local plugin_specs = {}
for _, file in ipairs(vim.fn.globpath(vim.fn.stdpath("config") .. "/lua/plugins", "*.lua", false, true)) do
  local name = vim.fn.fnamemodify(file, ":t:r")
  local spec = require("plugins." .. name)
  vim.list_extend(plugin_specs, spec) -- merge all plugin tables
end

-- Setup Lazy.nvim with all plugins
require("lazy").setup(plugin_specs)

-- Load other configs after plugins
require("configs.functions")
require("configs.completion")
require("configs.keymaps")
require("configs.autocommands")

local luasnip = require("luasnip")
require("luasnip.loaders.from_lua").load({ paths = vim.fn.stdpath("config") .. "/snips" })
require("luasnip.loaders.from_lua").lazy_load({ paths = vim.fn.stdpath("config") .. "/syntax" })

-- Set the file  that ends with .rules as udev filetype
vim.filetype.add({
  extension = {
    rules = function(path, bufnr)
      -- Use 'udevrules' (the standard name for udev syntax)
      -- We check for '/udev/' anywhere in the path to be safe
      if path:match("/udev/") then
        return "udevrules"
      end

      -- like hog filetype, force it to udevrules anyway:
      return "udevrules" 
    end,
  },
})
