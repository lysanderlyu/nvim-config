-- gitlab.nvim builds and runs its own Go server. On machines without a
-- supported Go toolchain it is unusable and setup() prints a "Plugin
-- unhealthy" warning, so skip loading it there entirely.
local function has_supported_go()
  if vim.fn.executable("go") == 0 then
    return false
  end
  local ok, result = pcall(vim.system, { "go", "version" }, { text = true })
  if not ok then
    return false
  end
  local version = vim.version.parse(result:wait().stdout or "", { strict = false })
  return version ~= nil and vim.version.ge(version, "1.25.1")
end

return {
  {
    "harrisoncramer/gitlab.nvim",
    branch = "main", -- upstream default is "develop"; main is the stable branch
    tag = "v4.1.2", -- pin to release; bump manually after reading changelog
    enabled = has_supported_go(),
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
