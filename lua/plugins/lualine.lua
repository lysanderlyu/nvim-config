-- For bufferline (tab and status line)
return{
  {
    "nvim-lualine/lualine.nvim",
    config = function()
      local theme = require("configs.lualine.lualine-theme").dim_tabs  -- load theme from luatheme.lua

      require("lualine").setup {
        options = {
          theme = theme,
        },
        tabline = {
          lualine_a = { { "tabs", mode = 2 } }, -- show tab index + filename
        },
      }

      -- Always show the tabline
      vim.o.showtabline = 2
    end,
  },
}
