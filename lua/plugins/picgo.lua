return {
  {
    -- "askfiy/nvim-picgo",
    "lysanderlyu/nvim-picgo",
    config = function()
      require("nvim-picgo").setup()
    end,
    -- For picgo
    vim.keymap.set("n", "<leader>p", ":UploadClipboard<CR>")
  }
}
