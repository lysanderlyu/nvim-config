return {
  {
    'akinsho/toggleterm.nvim',
    version = "*",
    config = function()
      require("toggleterm").setup({
        size = 20,
        open_mapping = [[<c-\>]], -- Shortcut to toggle
        hide_numbers = true,
        shade_terminals = true,
        start_in_insert = true,
        insert_mappings = true,
        terminal_mappings = true,
        persist_size = true,
        direction = 'horizontal', -- 'vertical' | 'horizontal' | 'window' | 'float'
        close_on_exit = true,
        shell = vim.o.shell,
      })

      -- Custom Keymaps
      local opts = { noremap = true, silent = true }
      vim.keymap.set('n', '<leader>sC', '<cmd>ToggleTerm direction=horizontal<cr>', { desc = "Terminal Horizontal" })

      function _G.set_terminal_keymaps()
        local opts = {buffer = 0}
        vim.keymap.set('t', '<esc>', [[<C-\><C-n>]], opts)
        vim.keymap.set('t', 'jk', [[<C-\><C-n>]], opts)
        vim.keymap.set('t', '<C-h>', [[<Cmd>wincmd h<CR>]], opts)
        vim.keymap.set('t', '<C-j>', [[<Cmd>wincmd j<CR>]], opts)
        vim.keymap.set('t', '<C-k>', [[<Cmd>wincmd k<CR>]], opts)
        vim.keymap.set('t', '<C-l>', [[<Cmd>wincmd l<CR>]], opts)
      end
      
      -- only apply to toggleterm buffers
      vim.cmd('autocmd! TermOpen term://*toggleterm#* lua set_terminal_keymaps()')
    end
  }
}
