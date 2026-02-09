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
        "clangd",                   -- clang
        "cmake",                    -- cmake
        "pyright",                  -- Python
        "bashls",                   -- Bash
        "jdtls",                    -- Java
        "lua_ls",                   -- Lua
        "jsonls",                   -- JSON
        "yamlls",                   -- yaml
        "html",                     -- HTML
        "rust_analyzer",            -- Rust
        "kotlin_language_server",   -- Kotlin
        "arduino_language_server",  -- Arduino
        "dockerls",                 -- Docker
        "sqlls",                    -- Sql
        "systemd_lsp",              -- Systemd
        -- "csharp-language-server", -- csharp (commented out)
      }

      --------------------------------------------------
      -- Platform filter (ARM)
      --------------------------------------------------
      if jit and jit.os == "Linux" and jit.arch == "arm64" then
        local arm_safe = {}
        local allowed = {
          clangd=false,
          cmake=false,
          bashls=true,
          lua_ls=true,
          pyright=true,
          systemd_ls=true,
        }

        for _, s in ipairs(ensure_installed) do
          if allowed[s] then
            table.insert(arm_safe, s)
          end
        end

        ensure_installed = arm_safe
      end

      --------------------------------------------------
      -- npm check (only remove node-based servers)
      --------------------------------------------------
      if vim.fn.executable("npm") ~= 1 then
        local node_servers = {
          "clangd",
          "cmake",
          "bashls",
          "pyright",
          "html",
          "jsonls",
          "yamlls",
          "dockerls",
          "sqlls",
        }

        local filtered = {}
        for _, s in ipairs(ensure_installed) do
          local remove = false
          for _, ns in ipairs(node_servers) do
            if s == ns then remove = true end
          end
          if not remove then
            table.insert(filtered, s)
          end
        end

        ensure_installed = filtered
      end

      return {
        ensure_installed = ensure_installed,
        automatic_installation = true,
      }
    end,
  },
}
