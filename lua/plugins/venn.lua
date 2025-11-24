return {
  {
    "jbyuki/venn.nvim",
    config = function()
      -- Global toggle function
      function _G.Toggle_venn()
        if vim.b.venn_enabled == nil then
          vim.b.venn_enabled = true
          vim.cmd([[setlocal ve=all]])

          -- draw lines with HJKL
          vim.keymap.set("n", "J", "<C-v>j:VBox<CR>", { buffer = true })
          vim.keymap.set("n", "K", "<C-v>k:VBox<CR>", { buffer = true })
          vim.keymap.set("n", "L", "<C-v>l:VBox<CR>", { buffer = true })
          vim.keymap.set("n", "H", "<C-v>h:VBox<CR>", { buffer = true })

          -- draw box in visual mode using 'f'
          vim.keymap.set("v", "f", ":VBox<CR>", { buffer = true })

          print("Venn mode enabled")
        else
          -- disable
          vim.cmd([[setlocal ve=]])
          vim.keymap.del("n", "J", { buffer = true })
          vim.keymap.del("n", "K", { buffer = true })
          vim.keymap.del("n", "L", { buffer = true })
          vim.keymap.del("n", "H", { buffer = true })
          vim.keymap.del("v", "f", { buffer = true })

          vim.b.venn_enabled = nil
          print("Venn mode disabled")
        end
      end
    end,

    keys = {
      { "<leader>v", "<cmd>lua Toggle_venn()<CR>", desc = "Toggle Venn Mode" },
    }
  }
}
