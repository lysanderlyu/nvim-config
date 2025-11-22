return {
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup({
        signs = {
          add = { hl = "GitGutterAdd", text = "│", numhl = "GitSignsAddNr" },
          change = { hl = "GitGutterChange", text = "│", numhl = "GitSignsChangeNr" },
          delete = { hl = "GitGutterDelete", text = "_", numhl = "GitSignsDeleteNr" },
          topdelete = { hl = "GitGutterDelete", text = "‾", numhl = "GitSignsDeleteNr" },
          changedelete = { hl = "GitGutterChange", text = "~", numhl = "GitSignsChangeNr" },
        },
        numhl = true,
        linehl = false,
        watch_gitdir = { interval = 1000 },
        update_debounce = 100, -- default 100ms
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

