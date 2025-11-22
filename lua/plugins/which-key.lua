return {
  {
    "folke/which-key.nvim",
    lazy = true,
    config = function()
      require("which-key").setup({
        plugins = {
          marks = true,         -- show marks
          registers = true,     -- show registers
          spelling = {
            enabled = true,     -- enable spelling suggestions
            suggestions = 20,
          },
        },
        icons = {
          breadcrumb = "»",     -- symbol in the command line
          separator = "➜",      -- symbol between key and label
          group = "+",          -- symbol for groups
        },
        popup_mappings = {
          scroll_down = "<c-d>",
          scroll_up = "<c-u>",
        },
        window = {
          border = "rounded",   -- none, single, double, rounded, shadow
          position = "bottom",  -- top, bottom
          margin = { 1, 0, 1, 0 },
          padding = { 1, 1, 1, 1 },
          winblend = 0
        },
        layout = {
          height = { min = 4, max = 25 },
          width = { min = 20, max = 50 },
          spacing = 3,
          align = "left",
        },
        hidden = { "<silent>", "<cmd>", "<Cmd>", "<CR>", "call", "lua", "^:", "^ " },
      })
    end
  }
}
