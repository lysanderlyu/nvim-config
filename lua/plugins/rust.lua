return{
    {
        "rust-lang/rust.vim",
        ft = "rust",  -- load only for Rust files
        config = function()
            -- Optional key mappings
            vim.keymap.set("n", "<leader>rb", ":!cargo build<CR>", { silent = true })
            vim.keymap.set("n", "<leader>rr", ":!cargo run<CR>", { silent = true })
            vim.keymap.set("n", "<leader>rt", ":!cargo test<CR>", { silent = true })
            vim.keymap.set("n", "<leader>rc", ":!cargo clean<CR>", { silent = true })
            vim.keymap.set("n", "<leader>rf", ":RustFmt<CR>", { silent = true })
        end
    }
}
