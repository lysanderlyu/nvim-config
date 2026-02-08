return {
  {
    "norcalli/nvim-colorizer.lua",
    -- Load on specific commands or when opening these file types
    cmd = { "ColorizerAttachToBuffer", "ColorizerToggle" },
    ft = { "lua", "css", "html", "cs", "javascript", "qml", "java", "cpp", "python", "plantuml" }, 
    config = function()
      require("colorizer").setup({
        -- Filetype specific overrides
        "lua",
        "css",
        "html",
        -- Global settings for everything else
        ["*"] = {
          RGB = true,         -- #RGB hex codes
          RRGGBB = true,      -- #RRGGBB hex codes 
          names = true,       -- "Name" codes like Blue Red Green
          RRGGBBAA = true,    -- Alpha support
          rgb_fn = true,      -- CSS rgb() and rgba() functions
          hsl_fn = true,      -- CSS hsl() and hsla() functions
          mode = "background", -- Set the display mode
        },
      })
    end,
  },
}
