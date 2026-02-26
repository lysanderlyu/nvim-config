-- plantuml-previewer.lua
return {
  {
    'weirongxu/plantuml-previewer.vim',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'aklt/plantuml-syntax',
      'tyru/open-browser.vim',
    },
    config = function()
      vim.g.plantuml_previewer_open_command = 'echo'
      vim.g.plantuml_previewer_image_format = 'svg'
      vim.g.plantuml_previewer_split = 'right'
      vim.g.plantuml_previewer_auto_refresh = 1
      vim.g.plantuml_previewer_cache_enabled = 1
      
      -- Enable real-time preview
      vim.g.plantuml_previewer_realtime = 1
      
      -- Key mappings
      vim.keymap.set('n', '<leader>ps', ':PlantumlOpen<CR>', { desc = 'PlantUML View' })
      vim.keymap.set('n', '<leader>pu', ':PlantumlStop<CR>', { desc = 'PlantUML Stop' })
    end
  }
}

