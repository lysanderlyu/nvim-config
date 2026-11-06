return {
  {
    -- "askfiy/nvim-picgo",
    "lysanderlyu/nvim-picgo",
    -- The plugin echoes "Missing picgo-core dependencies" during setup, so
    -- skip it where the CLI is absent and only load it on first use.
    enabled = vim.fn.executable("picgo") == 1,
    keys = {
      { "<leader>pi", "<cmd>UploadClipboard<cr>", desc = "Upload clipboard image via picgo" },
    },
    config = function()
      require("nvim-picgo").setup()
    end,
  },
}
