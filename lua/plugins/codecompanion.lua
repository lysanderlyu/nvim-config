return {
  {
    "olimorris/codecompanion.nvim",
    version = "^18.0.0",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    config = function()
      require("codecompanion").setup({
        strategies = {
          chat = { adapter = "openai_compatible" },
          inline = { adapter = "openai_compatible" },
        },
        adapters = {
          http = {
            openai_compatible = function()
              return require("codecompanion.adapters").extend("openai_compatible", {
                env = {
                  api_key = "LMSTUDIO_API_KEY",
                  url = "http://192.168.1.6:1234",
                },
              })
            end,
          }
        }
      })

      -- Keybindings
      vim.keymap.set({ "n", "v" }, "<leader>cg", "<cmd>CodeCompanionChat Toggle<cr>", { desc = "AI Chat" })
      vim.keymap.set({ "n", "v" }, "<leader>ai", "<cmd>CodeCompanion<cr>", { desc = "AI Inline" })
    end,
  },
}

