-- plantuml-previewer.lua
return {
  {
    'lysanderlyu/plantuml-previewer.vim',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'aklt/plantuml-syntax',
      'tyru/open-browser.vim',
    },
    config = function()
      -- Key mappings
      vim.keymap.set('n', '<leader>ps', ':PlantumlSave<CR>', { desc = 'PlantUML Save' })
      vim.keymap.set('n', '<leader>pt', ':PlantumlToggle<CR>', { desc = 'PlantUML Toggle' })
    end
  }
}

