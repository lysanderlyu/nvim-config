return {
  {
    "abecodes/tabout.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      require('tabout').setup {
        tabkey = "<Tab>",             -- key to move forward
        backwards_tabkey = "<S-Tab>", -- key to move backward
        act_as_tab = true,            -- shift only when not jumping
        completion = true,            -- integrates with completion plugins
        ignore_beginning = true,      -- don't tab out at beginning of line
        tabouts = {
          { open = "'", close = "'" },
          { open = '"', close = '"' },
          { open = "`", close = "`" },
          { open = "(", close = ")" },
          { open = "[", close = "]" },
          { open = "{", close = "}" },
        },
      }
    end
  }
}
