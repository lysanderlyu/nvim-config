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
    opts = function()
      local ensure_installed = {
        "pyright",      -- Python
        "bashls",       -- Bash
        "jdtls",        -- Java
        "lua_ls",       -- Lua
      }

      -- Check if we're on Linux ARM64
      if jit and jit.os == "Linux" and jit.arch == "arm64" then
        -- Remove clangd from the list for Linux ARM64
        for i, server in ipairs(ensure_installed) do
          if server == "clangd" then
            table.remove(ensure_installed, i)
            break
          end
        end
      else
        -- Add clangd for other platforms
        table.insert(ensure_installed, "clangd")
      end

      return {
        ensure_installed = ensure_installed,
        automatic_installation = true,
      }
    end,
  },
}
