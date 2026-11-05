return {
  {
    "CoreyKaylor/diffbandit.nvim",
    tag = "v0.3.0", -- pin to latest release; bump manually after reading changelog
    module = "diffbandit", -- let require("diffbandit") lazily load it
    cmd = {
      "DiffBandit",
      "DiffBanditBuffers",
      "DiffBanditFolderDiff",
      "DiffBanditGit",
      "DiffBanditGitCurrent",
      "DiffBanditCommitPanel",
      "DiffBanditGitMenu",
      "DiffBanditGitLog",
      "DiffBanditGitCommit",
      "DiffBanditGitCompare",
      "DiffBanditGitCheckout",
      "DiffBanditMerge",
      "DiffBanditLaunch",
    },
    config = function()
      require("diffbandit").setup()
    end,
  },
}
