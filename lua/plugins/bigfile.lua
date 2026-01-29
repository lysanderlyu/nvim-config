return {
  "LunarVim/bigfile.nvim",
  -- enabled = false,
  event = "BufReadPre",
  opts = {
    filesize = 10, -- size of the file in MiB, the plugin round file sizes to the closest MiB
    features = { -- features to disable
      -- "filetype",
      "illuminate",
      "indent_blankline",
      "lsp",
      "matchparen",
      "syntax",
      "treesitter",
      -- "vimopts",
    },
  },
}
