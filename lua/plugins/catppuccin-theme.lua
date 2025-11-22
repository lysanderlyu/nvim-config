return {
  -- Colorschemes
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
      require("catppuccin").setup {
        integrations = {
          nvimtree = false,
          treesitter = true,
          notify = false,
        },
        color_overrides = {
          all = {
            base = "#232423",
--            base = "#181825",
          },
        },
      }
      vim.g.catppuccin_flavour = "mocha"
      vim.cmd.colorscheme("catppuccin")
    end,
  },
}
