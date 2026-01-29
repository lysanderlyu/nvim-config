return {
  {
    'nvimdev/dashboard-nvim',
    event = 'VimEnter',
    config = function()
      require('dashboard').setup({
        theme = 'hyper',
        config = {
          week_header = {
            enable = true, -- Shows a cool weekly ASCII header
          },
          shortcut = {
            { desc = '󰊄 Update', group = '@property', action = 'Lazy update', key = 'u' },
            {
              icon = ' ',
              icon_hl = '@variable',
              desc = 'Files',
              group = 'Label',
              action = 'FzfLua files', -- Integrated with your Fzf-lua
              key = 'f',
            },
            {
              icon = ' ',
              desc = 'Apps',
              group = 'DiagnosticHint',
              action = 'Telescope app',
              key = 'a',
            },
            {
              icon = ' ',
              desc = 'Config',
              group = 'Number',
              action = 'edit ~/.config/nvim/init.lua',
              key = 'c',
            },
          },
          project = { enable = true, limit = 8, icon = '󰉋 ', label = 'Projects' },
          mru = { enable = true, limit = 10, icon = '󱋡 ', label = 'Recent Files' },
          footer = { "⚡ Neovim loaded" }
        },
      })
    end,
    dependencies = { {'nvim-tree/nvim-web-devicons'} }
  }
}
