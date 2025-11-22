return {
  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.6",
    dependencies = {
      "nvim-lua/plenary.nvim",
      -- "nvim-telescope/telescope-fzf-native.nvim",
    },
    config = function()
      local telescope = require("telescope")
      telescope.setup()
      -- telescope.load_extension("fzf")

      local opts = { noremap = true, silent = true }

      -- Function Outline with Treesitter
      vim.keymap.set("n", "<leader>cf", ":ShowFunctionsTelescope<CR>", opts)

      -- Function to grep the content that is in the clipboard
      vim.keymap.set("n", "<leader>gh", function()
        local yank = vim.fn.getreg('+')
        if yank == "" then
          print("No yanked text")
          return
        end
        vim.cmd("Rg " .. yank)
      end, opts)

      vim.keymap.set("n", "<leader>fg", function()
        local yank = vim.fn.getreg('"')
        if yank == "" then
          print("No yanked text")
          return
        end
        vim.cmd("Rg " .. yank)
      end, opts)
    end,
  },
}
