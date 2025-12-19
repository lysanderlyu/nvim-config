return {
  {
    "mrcjkb/rustaceanvim",
    enabled = true,   -- enable the plugin
    version = "^6",
    lazy = false,     -- load immediately
    ft = "rust",  -- filetype trigger

    config = function()
      -- Buffer-local keymaps
      local bufnr = vim.api.nvim_get_current_buf()
      local opts = { noremap = true, silent = true, buffer = bufnr }

      -- Hover actions
      vim.keymap.set("n", "K", function()
        vim.cmd.RustLsp({ "hover", "actions" })
      end, opts)

      -- Close hover buffer
      vim.keymap.set("n", "q", "<Cmd>close<CR>", opts)

      -- Rust code actions
      vim.keymap.set("n", "<leader>a", function()
        vim.cmd.RustLsp("codeAction")
      end, opts)
    end,
  }
}

