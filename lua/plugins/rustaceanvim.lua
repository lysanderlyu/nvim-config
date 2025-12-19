return {
  {
    "mrcjkb/rustaceanvim",
    version = "^6",
    ft = "rust",
    config = function()
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "rust",
        callback = function(ev)
          local opts = { buffer = ev.buf, noremap = true, silent = true }

          vim.keymap.set("n", "K", function()
            vim.cmd.RustLsp({ "hover", "actions" })
          end, opts)

          vim.keymap.set("n", "<leader>rd", function()
            vim.cmd.RustLsp("renderDiagnostic")
          end, opts)

          vim.keymap.set("n", "<leader>a", function()
            vim.cmd.RustLsp("codeAction")
          end, opts)
        end,
      })
    end,
  }
}
