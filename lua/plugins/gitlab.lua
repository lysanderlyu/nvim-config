return {
  {
    "harrisoncramer/gitlab.nvim",
    branch = "main", -- upstream default is "develop"; main is the stable branch
    tag = "v4.1.2", -- pin to release; bump manually after reading changelog
    event = "VeryLazy",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "dlyongemallo/diffview-plus.nvim",
    },
    config = function()
      require("gitlab").setup({
        -- Auth: GITLAB_TOKEN, or auth_token in a project-root .gitlab.nvim
        -- (the file wins if both are set). Self-hosted: export
        -- GITLAB_URL=https://gitlab.example.com
        connection_settings = {
          remote = "origin",
        },
      })

      -- Leader entry points; the plugin's own review/action maps live on `gl*`
      vim.keymap.set("n", "<leader>gm", function()
        require("gitlab").choose_merge_request()
      end, { desc = "GitLab: choose MR" })
      vim.keymap.set("n", "<leader>gR", function()
        require("gitlab").review()
      end, { desc = "GitLab: review current branch's MR" })
    end,
  },
}
