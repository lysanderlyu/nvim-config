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
        refresh = {
              statusline = 1000,
              tabline = 1000,
              winbar = 1000,
              refresh_time = 16, -- ~60fps
              events = {
                'WinEnter',
                'BufEnter',
                'BufWritePost',
                'SessionLoadPost',
                'FileChangedShellPost',
                'VimResized',
                'Filetype',
                'CursorMoved',
                'CursorMovedI',
                'ModeChanged',
              },
        },
        tabline = {
          lualine_a = { { "tabs", mode = 2 } }, -- show tab index + filename
          lualine_x = {},
        },
        sections = {
          lualine_a = {'mode'},
          lualine_b = {'branch', 'diff', 'diagnostics'},
          lualine_c = {'filename'},
          lualine_x = {"os.date('%c')", 'data', 'encoding', 'fileformat', 'filetype'},
          lualine_y = {'progress'},
          lualine_z = {'location'}
        },
        inactive_sections = {
          lualine_a = {},
          lualine_b = {},
          lualine_c = {'filename'},
          lualine_x = {'location'},
          lualine_y = {},
          lualine_z = {}
        },
      }

      -- Always show the tabline
      vim.o.showtabline = 2
    end,
  },
}
