return {
  {
    "bassamsdata/namu.nvim",
    lazy = true,
    config = function()
      require("namu").setup({
        global = {},
  
        namu_symbols = {
          enable = true,
          options = {
            -- configure which symbol kinds to include, keymaps, window style, etc.
            AllowKinds = {
              default = { "Function", "Method", "Class", "Variable" },
              lua = { "Function", "Table", "Module" },
              python = { "Function", "Class", "Method" },
            },
            display = {
              mode = "icon", -- or "raw"
              padding = 2,
            },
            row_position = "top10",
            preview = {
              highlight_on_move = true,
            },
            window = {
              auto_size = true,
              border = "rounded",
              width_ratio = 0.6,
              height_ratio = 0.6,
            },
            multiselect = {
              enabled = true,
              keymaps = {
                toggle = "<Tab>",
                clear_all = "<C-l>",
                select_all = "<C-a>",
              },
            },
            custom_keymaps = {
              yank = { keys = { "<C-y>" } },
              vertical_split = { keys = { "<C-v>" } },
            },
          },
        },
  
        -- You can enable or disable other modules similarly:
        workspace = { enable = true },
        diagnostics = { enable = true },
        call_hierarchy = { enable = true },
        ctags = { enable = false },
      })
  
      -- Keybindings
      vim.keymap.set("n", "<leader>ms", "<cmd>Namu symbols<CR>", { desc = "Namu: Symbols" })
      vim.keymap.set("n", "<leader>mp", "<cmd>Namu workspace<CR>", { desc = "Namu: Workspace" })
    end,
  }
}
