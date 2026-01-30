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
            {
              icon = '󰮗 ',
              icon_hl = '@variable',
              desc = 'Find Files',
              group = 'Label',
              key = 'f',
              action = function()
                require('fzf-lua').files({
                  winopts = {
                    width = 0.95,
                    height = 0.95,
                    layout = "horizontal",
                    preview = { 
                      layout = "vertical", 
                      vertical = "right:55%" 
                    },
                  },
                })
              end,
            },
            {
              icon = ' ',
              desc = 'Search content',
              group = 'Label',
              key = 'g',
              action = function()
                require('fzf-lua').live_grep({
                  winopts = {
                    width = 0.95,
                    height = 0.95,
                    layout = "horizontal",
                    preview = { 
                      layout = "vertical", 
                      vertical = "right:55%" 
                    },
                  },
                })
              end,
            },
            {
              icon = ' ',
              icon_hl = '@variable',
              desc = 'New File',
              group = 'Label',
              action = 'ene | startinsert',
              key = 'n',
            },
            {
              icon = ' ',
              desc = 'Config',
              group = 'Number',
              action = 'e ~/.config/nvim',
              key = 'c',
            },
            {
              icon = '󰊄 ',
              desc = 'Update Config',
              group = '@property',
              key = 'u',
              action = function()
                -- 1. Move to the config directory
                local config_path = vim.fn.stdpath("config")
                vim.api.nvim_set_current_dir(config_path)
            
                -- 2. Run git pull (using '!' for shell execution)
                print("Pulling latest config...")
                vim.cmd("!git pull")
            
                -- 3. Run Lazy update
                -- We use vim.schedule to ensure Lazy starts after the git process finishes
                vim.schedule(function()
                  require("lazy").update()
                end)
              end,
            },
          },
          -- project = { enable = true, limit = 8, icon = '󰉋 ', label = 'Projects Folders' },
          project = {
            enable = true,
            limit = 8,
            icon = '󰉋 ',
            label = 'Open Projects Folders',
            -- This is the magic part:
            action = function(path)
              -- 1. Change the current working directory to the project path
              vim.cmd("cd " .. path)
              -- 2. Open the file tree (choose the command for your specific plugin)
              vim.cmd("NvimTreeOpen") 
            end,
          },
          mru = { enable = true, limit = 10, icon = '󱋡 ', label = 'Open Recent Files' },
          footer = { "⚡ Neovim loaded" }
        },
      })
    end,
    dependencies = { {'nvim-tree/nvim-web-devicons'} }
  }
}
