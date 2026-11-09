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

      -- Noice (Neovim 0.11+) draws a real cursor in the cmdline popup.
      -- Default guicursor maps mode `c` to block; prefer an insert-style bar.
      vim.opt.guicursor:append("c:ver25")

      -- Noice's `notify` view prefers Snacks as its backend when available, so
      -- notifications never enter nvim-notify's history and `:Telescope notify`
      -- stays empty. Use Noice's own history instead: it is backend-agnostic and
      -- also contains errors, warnings, and LSP messages.
      vim.keymap.set("n", "<leader>n", "<cmd>Noice telescope<CR>", { desc = "Search Notification History" })
    end,
  }
}
