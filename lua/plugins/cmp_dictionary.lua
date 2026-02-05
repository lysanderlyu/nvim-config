local dict = {
  ["*"] = { "/usr/share/dict/words" },

  ft = {
    plantuml = {
      vim.fn.stdpath("config") .. "/dicts/puml_keywords.txt",
    },
  },
}

return {
  {
    "uga-rosa/cmp-dictionary",
    dependencies = { "hrsh7th/nvim-cmp" },

    config = function()
      local cmp_dict = require("cmp_dictionary")

      -- Check if 'wn' is installed on the system
      local has_wordnet = vim.fn.executable("wn") == 1
      
      cmp_dict.setup({
        -- Use the 'dic' structure we discussed for better filetype support
        paths = dict["*"],
        exact_length = 3,
        first_case_insensitive = true,
        document = {
          -- Automatically enable if 'wn' exists, otherwise disable
          enable = has_wordnet,
          command = { "wn", "${label}", "-over" },
        },
      })

      -- per-buffer dictionary switching
      vim.api.nvim_create_autocmd("BufEnter", {
        callback = function()
          local ft = vim.bo.filetype

          -- deepcopy to avoid modifying original tables
          local paths = vim.deepcopy(dict.ft[ft] or {})

          -- append global dictionary
          vim.list_extend(paths, dict["*"])

          cmp_dict.setup({
            paths = paths,
          })
        end,
      })
    end,
  },
}

