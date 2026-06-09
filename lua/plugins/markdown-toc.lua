return {
  {
    "hedyhli/markdown-toc.nvim",
    ft = "markdown",
    cmd = { "Mtoc" },
    keys = {
      { "<leader>mi", ":Mtoc i<CR>", desc = "Insert TOC" },
      { "<leader>mu", ":Mtoc u<CR>", desc = "Update TOC" },
      { "<leader>mr", ":Mtoc r<CR>", desc = "Remove TOC" },
    },
    opts = {
      headings = {
        before_toc = false,
        exclude = {},
        pattern = "^(#+)%s+(.+)$",
      },
      toc_list = {
        markers = '*',
        cycle_markers = false,
        indent_size = 2,
        item_format_string = "${indent}${marker} [${name}](#${link})",
        item_formatter = function(item_info, fmtstr)
          local s = fmtstr:gsub([[${(%w-)}]], function(key)
            return item_info[key] or ('${' .. key .. '}')
          end)
          return s
        end,
        post_processor = function(lines)
          return lines
        end,
        padding_lines = 1,
      },
      fences = {
        enabled = true,
        start_text = "mtoc start",
        end_text = "mtoc end",
      },
      auto_update = {
        enabled = true,
        events = { "BufWritePre" },
        pattern = "*.{md,mdown,mkd,mkdn,markdown,mdwn}",
      },
    },
  },
}
