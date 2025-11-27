return{
    {
        "rust-lang/rust.vim",
        ft = "rust",  -- load only for Rust files
        config = function()
            -- Optional key mappings
            vim.keymap.set("n", "<leader>rr", ":RustRun<CR>", {silent=true})
            vim.keymap.set("n", "<leader>rb", ":RustBuild<CR>", {silent=true})
            vim.keymap.set("n", "<leader>rt", ":RustTest<CR>", {silent=true})
            vim.keymap.set("n", "<leader>rf", ":RustFmt<CR>", {silent=true})
        end
    }
}
