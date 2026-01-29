return {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",

    opts = {
      preset = "classic",
      delay = 800,
      plugins = {
        marks = true,
        registers = true,
        spelling = {
          enabled = true,
          suggestions = 20,
        },
      },

      win = {
        border = "rounded",
        padding = { 1, 1, 1, 1 },
      },

      layout = {
        spacing = 3,
        align = "left",
      },
    },

    config = function(_, opts)
      vim.g.mapleader = " "
      vim.g.maplocalleader = " "

      local wk = require("which-key")
      wk.setup(opts)

      wk.add({
        { "<leader>?", "<cmd>WhichKey<cr>", desc = "Show all keymaps" },
      })
    end,
  },
}
