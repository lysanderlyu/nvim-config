return {
  {
    "folke/noice.nvim",
    lazy = true,
    event = "VeryLazy",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "rcarriga/nvim-notify",
    },
    config = function()
      require("noice").setup({
        cmdline = {
          format = {
            cmdline = { pattern = "^:", icon = "", lang = "vim" },
            search_down = { kind = "search", pattern = "^/", icon = " " },
            search_up = { kind = "search", pattern = "^%?", icon = " " },
          },
          view = "cmdline_popup",
          opts = {
            position = { row = 5, col = "50%" },
            size = { width = 60, height = "auto" },
          },
        },
        messages = {
          view = "notify",
          view_error = "notify",
          view_warn = "notify",
          view_history = "messages", -- Redirects history to Noice's message view
        },
      })

      -- Keymap to show notification history
      -- Option A: Noice built-in (Opens in a split as per your config)
      -- vim.keymap.set("n", "<leader>n", "<cmd>Noice history<CR>", { desc = "Show Notification History" })

      -- Option B: If you use Telescope (highly recommended for searching history)
      vim.keymap.set("n", "<leader>n", "<cmd>Telescope notify<CR>", { desc = "Search Notification History" })
    end,
  }
}
