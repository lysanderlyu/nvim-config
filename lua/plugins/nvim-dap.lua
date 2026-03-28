return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "theHamsta/nvim-dap-virtual-text",
      "nvim-neotest/nvim-nio",
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")

      -- 1. Virtual Text Setup
      require("nvim-dap-virtual-text").setup({
        commented = true, -- Prefix virtual text with a comment string
      })

      -- 2. DAP UI Setup (Custom Layout for Registers)
      dapui.setup({
        layouts = {
          {
            elements = {
              { id = "scopes", size = 0.50 }, -- Increased size for registers/variables
              { id = "breakpoints", size = 0.15 },
              { id = "stacks", size = 0.20 },
              { id = "watches", size = 0.15 },
            },
            position = "left",
            size = 45, -- Width of the sidebar in columns
          },
          {
            elements = {
              { id = "repl", size = 0.6 },
              { id = "console", size = 0.4 },
            },
            position = "bottom",
            size = 10, -- Height of the bottom tray
          },
        },
      })

      -- 3. Adapter: ARM Embedded GDB
      dap.adapters.gdb = {
        type = "executable",
        command = "arm-none-eabi-gdb",
        args = { "--interpreter=dap" }
      }

      -- 4. Configuration: Manual Attach Workflow
      -- Shared Configuration for both C and Assembly
      local attach_config = {
      {
          name = "Attach to ARM GDB Server",
          type = "gdb",
          request = "attach",
          target = function()
            local port = vim.fn.input('GDB Server Port: ', '3333')
            return "localhost:" .. port
          end,
          program = function()
            -- We store this in a variable so we can use it for the 'file' command
            local path = vim.fn.input('Path to .elf: ', vim.fn.getcwd() .. '/', 'file')
            return path
          end,
          cwd = '${workspaceFolder}',
          stopOnEntry = true,
          setup_commands = {
            -- 1. Load the symbols from the ELF file into GDB
            { text = "file " .. vim.fn.getcwd() .. "/build/your_project.elf", description = "load symbols" },
            -- 2. Optional: Flash the board (only if your server supports it)
            { text = "load", description = "flash target" }, 
            -- 3. Reset the hardware and halt at the reset vector
            { text = "monitor reset halt", description = "Reset and halt the MCU", ignore_failures = true },
            { text = "set breakpoint pending on", ignore_failures = true },
          },
        },
      }
      dap.configurations.c = attach_config
      dap.configurations.asm = attach_config

      -- 5. Automation: Open/Close UI
      dap.listeners.before.attach.dapui_config = function() dapui.open() end
      dap.listeners.before.launch.dapui_config = function() dapui.open() end
      dap.listeners.after.event_terminated.dapui_config = function() dapui.close() end
      dap.listeners.after.event_exited.dapui_config = function() dapui.close() end

      -- 6. Keybindings
      vim.keymap.set('n', '<Leader>5', function() dap.continue() end, { desc = "Debug: Start/Continue" })
      vim.keymap.set('n', '<F10>', function() dap.step_over() end, { desc = "Debug: Step Over" })
      vim.keymap.set('n', '<F11>', function() dap.step_into() end, { desc = "Debug: Step Into" })
      vim.keymap.set('n', '<F12>', function() dap.step_out() end, { desc = "Debug: Step Out" })
      vim.keymap.set('n', '<Leader>b', function() dap.toggle_breakpoint() end, { desc = "Debug: Toggle Breakpoint" })
      vim.keymap.set('n', '<Leader>dr', function() dap.repl.open() end, { desc = "Debug: Open REPL" })
      vim.keymap.set('n', '<Leader>du', function() dapui.toggle() end, { desc = "Debug: Toggle UI" })
      vim.keymap.set('n', '<Leader>dc', function() require("dap").terminate() require("dapui").close() end, { desc = "Debug: Stop/Terminate Session" })
    end,
  },
}
