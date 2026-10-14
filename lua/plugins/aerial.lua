return {
  {
    "stevearc/aerial.nvim",
    branch = "nvim-0.11",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
    },
    event = { "BufReadPost", "BufNewFile" },
    keys = {
      { "<leader>ao", "<cmd>AerialToggle<CR>", desc = "Aerial Outline" },
    },
    opts = {
      backends = { "treesitter", "lsp", "markdown", "asciidoc", "man" },
      -- One outline per tab; it follows the current window instead of opening again on split.
      attach_mode = "global",
      layout = {
        min_width = 10,
      },
      open_automatic = function(bufnr)
        return require("aerial.backends").is_supported(bufnr, "treesitter")
      end,
      close_automatic_events = { "unsupported" },
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
