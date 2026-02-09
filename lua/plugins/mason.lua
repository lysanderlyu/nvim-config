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
        "clangd",      -- clang
        "cmake",      -- cmake
        "pyright",      -- Python
        "bashls",       -- Bash
        "jdtls",        -- Java
        "lua_ls",       -- Lua
        "jsonls",         -- JSON (fixed from "json-lsp")
        "yamlls",      -- yaml
        "html",         -- HTML (fixed from "html-lsp")
        "rust_analyzer", -- Rust (fixed from "rust-analyzer")
        "kotlin_language_server", -- Kotlin (fixed from "kotlin-language-server")
        "arduino_language_server", -- Arduino (fixed from "arduino-language-server")
        "dockerls",     -- Docker (fixed from "docker-language-server")
        "sqlls",     -- Sql
        "systemd_lsp",     -- Systemd
        -- "csharp-language-server", -- csharp
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
        -- Remove cmake-language-server from the list for Linux ARM64
        for i, server in ipairs(ensure_installed) do
          if server == "cmake" then
            table.remove(ensure_installed, i)
            break
          end
        end
        -- Remove systemd_lsp from the list for Linux ARM64
        for i, server in ipairs(ensure_installed) do
          if server == "systemd_lsp" then
            table.remove(ensure_installed, i)
            break
          end
        end
      else
        table.insert(ensure_installed, "clangd")
        table.insert(ensure_installed, "cmake")
        table.insert(ensure_installed, "systemd_lsp")
      end
      return {
        ensure_installed = ensure_installed,
        automatic_installation = true,
      }
    end,
  },
}
