return{
  {
    'mrcjkb/rustaceanvim',
    version = '^6', -- Recommended
    lazy = false, -- This plugin is already lazy

    keys = {
      -- Run the binary
      {
        "<leader>rr",
        function()
          require("rustaceanvim").lsp.run()
        end,
        desc = "Rust: Run",
      },
    },
  }
}
