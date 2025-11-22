return {
  {
    "luukvbaal/statuscol.nvim",
    event = "BufRead",  -- lazy-load when a buffer is read
    config = function()
      local builtin = require("statuscol.builtin")
      require("statuscol").setup({
        -- Define segments
        relculright = true,
        segments = {
          { text = { builtin.foldfunc },      click = "v:lua.ScFa" },
          { text = { "%s" },                  click = "v:lua.ScSa" },  -- Sign column
          { text = { builtin.lnumfunc },      click = "v:lua.ScLa" },  -- Line numbers
        },
      })
    end
  }
}
