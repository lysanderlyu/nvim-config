return {
  {
    "lysanderlyu/treesitter-outline",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-telescope/telescope.nvim",
    },
    config = function()
      -- optional if you want to configure or set keymaps here
      local outline = require("treesitter_outline")
      vim.keymap.set("n", "<leader>so", outline.show_functions_telescope, { desc = "Show Outline" })
    end,
  }
}
