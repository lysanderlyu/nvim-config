return {
  {
    "mfussenegger/nvim-dap",
    lazy = true,
    keys = {
      { "<F5>", function() require("dap").continue() end, desc = "Start/Continue Debugging" },
      { "<F10>", function() require("dap").step_over() end, desc = "Step Over" },
      { "<F11>", function() require("dap").step_into() end, desc = "Step Into" },
      { "<F12>", function() require("dap").step_out() end, desc = "Step Out" },
    },
    config = function()
      local dap = require("dap")
      -- Example: Python adapter
      dap.adapters.python = {
        type = "executable",
        command = "python",
        args = { "-m", "debugpy.adapter" },
      }
      dap.configurations.python = {
        {
          type = "python",
          request = "launch",
          name = "Launch file",
          program = "${file}",
          pythonPath = function()
            return "python"
          end,
        },
      }
    end,
  }
}
