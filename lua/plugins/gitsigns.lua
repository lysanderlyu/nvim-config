return {
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup({
        signs = {
          add          = { text = '┃' },
          change       = { text = '┃' },
          delete       = { text = '_' },
          topdelete    = { text = '‾' },
          changedelete = { text = '~' },
          untracked    = { text = '┆' },
        },
        signs_staged = {
          add          = { text = '┃' },
          change       = { text = '┃' },
          delete       = { text = '_' },
          topdelete    = { text = '‾' },
          changedelete = { text = '~' },
          untracked    = { text = '┆' },
        },
        signs_staged_enable = true,
        numhl = true,
        linehl = false,
        _threaded_diff = true,
        watch_gitdir = { 
            enable = true,
            follow_files = true,
            interval = 3000
        },
        current_line_blame = true, -- Toggle with `:Gitsigns toggle_current_line_blame`
        current_line_blame_opts = {
          virt_text = true,
          virt_text_pos = 'eol', -- 'eol' | 'overlay' | 'right_align'
          delay = 500,
          ignore_whitespace = false,
          virt_text_priority = 100,
          use_focus = true,
        },
        current_line_blame_formatter = '<author>, <author_time:%Y-%m-%d %X %A> - <summary>',
        sign_priority = 6,
        update_debounce = 100,
        status_formatter = nil, -- Use default
        max_file_length = 40000, -- Disable if file is longer than this (in lines)
        on_attach = function(bufnr)
          local gs = package.loaded.gitsigns
          local map = function(mode, lhs, rhs)
            vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true })
          end

          -- Stage specific line hunk
          map("n", "<leader>hs", gs.stage_hunk)
          -- Reset hunk
          map("n", "<leader>hr", gs.reset_hunk)
          -- Stage the whole buffer
          map("n", "<leader>hS", gs.stage_buffer)
          -- Undo stage
          map("n", "<leader>hu", gs.undo_stage_hunk)
          -- Preview hunk
          map("n", "<leader>hp", gs.preview_hunk)
          -- Blame line
          map("n", "<leader>hb", gs.blame_line)
        end,
      })
    end,
  },
}

