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

      -- Platform-specific logic
      if jit and jit.os == "Linux" and jit.arch == "arm64" then
        -- Remove unsupported servers on ARM64
        local filtered = {}
        for _, server in ipairs(ensure_installed) do
          if server ~= "clangd" and server ~= "cmake" and server ~= "systemd_lsp" then
            table.insert(filtered, server)
          end
        end
        ensure_installed = filtered
      elseif jit and jit.os == "Linux" and jit.arch == "x86_64" then
        -- -- Optionally handle x86_64 differently if needed (e.g., remove cmake-language-server)
        -- local filtered = {}
        -- for _, server in ipairs(ensure_installed) do
        --   if server ~= "cmake" then
        --     table.insert(filtered, server)
        --   end
        -- end
        -- ensure_installed = filtered
      end

      return {
        ensure_installed = ensure_installed,
        automatic_installation = true,
      }
    end,
  },
}
