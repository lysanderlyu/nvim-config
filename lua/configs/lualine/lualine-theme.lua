local M = {}

M.dim_tabs = {
  normal = {
    a = { fg = "#ffffff", bg = "#333333", gui = "bold" },
    b = { fg = "#aaaaaa", bg = "#1e1e1e" },
    c = { fg = "#aaaaaa", bg = "#1e1e1e" },
  },
  insert = { a = { fg = "#ffffff", bg = "#333333", gui = "bold" } },
  visual = { a = { fg = "#ffffff", bg = "#333333", gui = "bold" } },
  replace = { a = { fg = "#ffffff", bg = "#333333", gui = "bold" } },
  tabline = {
    a = { fg = "#ffffff", bg = "#333333" }, -- active tab
    b = { fg = "#aaaaaa", bg = "#1e1e1e" }, -- inactive tabs
    c = { fg = "#aaaaaa", bg = "#1e1e1e" },
  },
  inactive = {
    a = { fg = "#aaaaaa", bg = "#1e1e1e" },
    b = { fg = "#aaaaaa", bg = "#1e1e1e" },
    c = { fg = "#aaaaaa", bg = "#1e1e1e" },
  },
}

return M
