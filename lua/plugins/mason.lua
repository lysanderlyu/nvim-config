return {
  --------------------------------------------------------
  -- Mason (Install LSP servers)
  --------------------------------------------------------
  {
    "williamboman/mason.nvim",
    lazy = false, -- load immediately
    config = function()
      require("mason").setup({
        ui = {
          icons = {
            package_installed = "✓",
            package_pending = "➜",
            package_uninstalled = "✗",
          },
        },
      })
    end,
  },

  --------------------------------------------------------
  -- Mason LSP Config
  --------------------------------------------------------
  {
    "williamboman/mason-lspconfig.nvim",
    lazy = false,
    dependencies = { "mason.nvim" },
    opts = {
      ensure_installed = {
        "clangd",       -- C/C++
        "pyright",      -- Python
        "bashls",       -- Bash
        "jdtls",        -- Java
        "lua_ls",       -- Lua
      },
      automatic_installation = true,
    },
  },
}
