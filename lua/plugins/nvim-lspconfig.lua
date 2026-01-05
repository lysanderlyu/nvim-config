return {
  {
    "neovim/nvim-lspconfig",
    lazy = false,
    config = function()
      -- NEW API (Neovim 0.11+)
      vim.lsp.config('clangd', {
        cmd = { "clangd" },       -- clangd binary
        filetypes = { "c", "cpp" },

        -- This function runs when LSP attaches to a buffer
        on_attach = function(client, bufnr)
            -- 'bufnr' is the buffer number
            local opts = { noremap=true, silent=true, buffer=bufnr }

            -- Go to definition
            vim.keymap.set('n', '<leader>lD', vim.lsp.buf.definition, opts)

            -- Show references
            vim.keymap.set('n', '<leader>lr', vim.lsp.buf.references, opts)

            -- -- Go to diagnostic
            -- vim.keymap.set('n', '<leader>ld', vim.lsp.buf.diagnostic, opts)
            vim.keymap.set('n', '<leader>ld', vim.diagnostic.open_float, opts)
            vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
            vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)
            
            vim.keymap.set('n', '<leader>ll', function()
                vim.diagnostic.setloclist({ open = true, severity = { vim.diagnostic.severity.WARN, vim.diagnostic.severity.ERROR } })
            end, { noremap=true, silent=true, buffer=bufnr })

            -- Hover documentation
            vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)

            -- Rename symbol
            vim.keymap.set('n', '<leader>ln', vim.lsp.buf.rename, opts)

            -- Signature help in insert mode
            vim.keymap.set('i', '<C-k>', vim.lsp.buf.signature_help, opts)
        end,
      })
      vim.lsp.enable('clangd')

      vim.lsp.enable('bashls')
      vim.lsp.enable('pyright')
      vim.lsp.enable('lua_ls')
      vim.lsp.enable('jdtls')
    end,
  }
}
