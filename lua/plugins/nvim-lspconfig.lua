local function on_attach_common(client, bufnr)
    local opts = { noremap=true, silent=true, buffer=bufnr }

    -- Go to definition
    -- vim.keymap.set('n', '<leader>ls', vim.lsp.buf.definition, opts)
    vim.keymap.set("n", "<leader>ls", function()
        local params = vim.lsp.util.make_position_params()
        vim.lsp.buf_request(0, "textDocument/definition", params, function(err, result, ctx, _)
            if err or not result or vim.tbl_isempty(result) then
                print("Definition not found")
                return
            end
    
            local def = result[1]
            -- Open in horizontal split
            vim.cmd("vsplit")  -- horizontal split
            vim.lsp.util.jump_to_location(def, "utf-8")
        end)
    end, opts)

    -- Show references
    vim.keymap.set('n', '<leader>lr', vim.lsp.buf.references, opts)

    -- Diagnostics
    vim.keymap.set('n', '<leader>ld', vim.diagnostic.open_float, opts)
    vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
    vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)
    vim.keymap.set('n', '<leader>ll', function()
        vim.diagnostic.setloclist({ open = true, severity = { vim.diagnostic.severity.WARN, vim.diagnostic.severity.ERROR } })
    end, opts)

    -- Hover documentation
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)

    -- Rename symbol
    vim.keymap.set('n', '<leader>ln', vim.lsp.buf.rename, opts)

    -- Signature help in insert mode
    vim.keymap.set('i', '<C-k>', vim.lsp.buf.signature_help, opts)
end

return {
  {
    "neovim/nvim-lspconfig",
    lazy = false,
    config = function()
        local servers = { "clangd", "bashls", "pyright", "lua_ls", "jdtls", "rust_analyzer" }

        for _, server in ipairs(servers) do
            vim.lsp.config(server, {
                on_attach = on_attach_common,
            })
            vim.lsp.enable(server)
        end
    end,
  }
}
