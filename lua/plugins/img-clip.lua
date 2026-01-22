return {
  { 
    -- "HakonHarnes/img-clip.nvim",
    -- event = "VeryLazy",
    -- opts = {
    --   -- Use default config, or override options here
    --   default = {
    --     dir_path = "assets",         -- where to save images
    --     extension = "png",            -- default extension
    --     file_name = "%Y-%m-%d-%H-%M-%S",
    --     use_absolute_path = false,
    --     relative_to_current_file = false,
    --     template = "![$LABEL]($FILE_PATH)",  -- default template for Markdown
    --     embed_image_as_base64 = false,
    --   },
    --   -- filetype-specific settings
    --   filetypes = {
    --     markdown = {
    --       template = "![$LABEL]($FILE_PATH)",
    --     },
    --     tex = {
    --       template = "\\includegraphics{$FILE_PATH}",
    --     },
    --   },
    -- },
    -- keys = {
    --   { "<leader>p", "<cmd>PasteImage<cr>", desc = "Paste image from clipboard" },
    -- },
    -- config = function(_, opts)
    --   require("img-clip").setup(opts)
    -- end,
  }
}
