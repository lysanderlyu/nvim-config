return {
  {
    "stevearc/aerial.nvim",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
    },
    keys = {
      { "<leader>ao", "<cmd>AerialToggle<CR>", desc = "Aerial Outline" },
    },
    opts = {
      backends = { "treesitter"},
      lazy_load = true,
      layout = {
        min_width = 30,
      },
      filter_kind = {
        "Class",
        "Constructor",
        "Enum",
        "Function",
        "Interface",
        "Module",
        "Method",
        "Struct",
      },
      -- Markdown-specific config
      markdown = {
        -- show only headings, not lists
        include_headers = true,
        include_lists = false,
      },
    },
  },
}
