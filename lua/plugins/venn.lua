return {
  {
    "jbyuki/venn.nvim",
    keys = {
      {
        "<leader>dv",
        function()
          -- toggle venn mode
          local venn = require("venn")
          venn.toggle()
        end,
        desc = "Toggle Venn Drawing Mode",
      },
    },
  }
}
