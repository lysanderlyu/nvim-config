return {
  {
    "numToStr/Comment.nvim",
    lazy = true,
    keys = { "gcc", "gc", "gb" },  -- lazy-load on these keybindings
    config = function()
      require("Comment").setup({
        padding = true,      -- add a space between comment and code
        sticky = true,       -- maintain comment state across lines
        ignore = "^$",        -- ignore empty lines
        toggler = {
          line = "gcc",      -- toggle line comment
          block = "gbc",     -- toggle block comment
        },
        opleader = {
          line = "gc",       -- operator-pending line comment
          block = "gb",      -- operator-pending block comment
        },
        extra = {
          above = "gcO",     -- add comment above
          below = "gco",     -- add comment below
          eol = "gcA",       -- add comment at end of line
        },
        pre_hook = nil,       -- function to run before commenting (treesitter supported)
        post_hook = nil,      -- function to run after commenting
      })
    end,
  }
}
