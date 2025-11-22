-- return {
--   -- LSP Config
--   {
--     'neovim/nvim-lspconfig',
--     config = function()
--       local lspconfig = require('lspconfig')
--     end
--   },
-- }
return {
  {
    -- "neovim/nvim-lspconfig",
    -- lazy = false,  -- <- ensures plugin is loaded before config
    -- config = function()
    --   local capabilities = require("cmp_nvim_lsp").default_capabilities()
    --   local on_attach = function(_, bufnr)
    --     vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = bufnr })
    --     vim.keymap.set("n", "K", vim.lsp.buf.hover, { buffer = bufnr })
    --     vim.keymap.set("n", "gr", vim.lsp.buf.references, { buffer = bufnr })
    --     vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { buffer = bufnr })
    --     vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { buffer = bufnr })
    --     vim.keymap.set("n", "<leader>fm", function()
    --       vim.lsp.buf.format({ async = true })
    --     end, { buffer = bufnr })
    --   end

    --   -- NEW API (Neovim 0.11+)
    --   vim.lsp.config.clangd.setup({ on_attach = on_attach, capabilities = capabilities })
    --   vim.lsp.config.pyright.setup({ on_attach = on_attach, capabilities = capabilities })
    --   vim.lsp.config.bashls.setup({ on_attach = on_attach, capabilities = capabilities })
    --   vim.lsp.config.lua_ls.setup({
    --     on_attach = on_attach,
    --     capabilities = capabilities,
    --     settings = { Lua = { diagnostics = { globals = { "vim" } } } },
    --   })
    --   vim.lsp.config.jdtls.setup({ on_attach = on_attach, capabilities = capabilities })
    -- end,
  }
}
