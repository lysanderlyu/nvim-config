return {
  {
    "mrcjkb/rustaceanvim",
    version = "^6",
    ft = "rust",
    config = function()
      local opts = { noremap = true, silent = true, buffer = true }

      -- Hover
      vim.keymap.set("n", "K", function()
        vim.cmd.RustLsp({ "hover", "actions" })
      end, opts)

      -- Render diagnostics
      vim.keymap.set("n", "<leader>ld", function()
        vim.cmd.RustLsp("renderDiagnostic")
      end, opts)

      -- Rust Doc on HTML
      vim.keymap.set("n", "<leader>rm", function()
          vim.cmd.RustLsp('openDocs')
      end, opts)

      -- Code action
      vim.keymap.set("n", "<leader>a", function()
        vim.cmd.RustLsp("codeAction")
      end, opts)
    end,
  }
}
