return {
    {
        "simrat39/rust-tools.nvim",
        ft = "rust",
        dependencies = { "neovim/nvim-lspconfig" },
        config = function()
            require("rust-tools").setup({})

            -- Keymaps for rust-tools
            vim.keymap.set("n", "<leader>rr", function()
                require("rust-tools.runnables").runnables()
            end)

            vim.keymap.set("n", "<leader>re", function()
                require("rust-tools.expand_macro").expand_macro()
            end)

            vim.keymap.set("n", "<leader>rd", function()
                require("rust-tools.hover_actions").hover_actions()
            end)

            vim.keymap.set("n", "<leader>ri", function()
                require("rust-tools.inlay_hints").toggle_inlay_hints()
            end)

            -- rustfmt
            vim.keymap.set("n", "<leader>rf", function()
                vim.cmd("RustFmt")
            end)
        end,
    },
}
