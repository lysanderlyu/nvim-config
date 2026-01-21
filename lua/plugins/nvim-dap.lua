local function run_sudo(cmd)
  -- Open a floating terminal
  local buf = vim.api.nvim_create_buf(false, true)
  local width = math.floor(vim.o.columns * 0.6)
  local height = math.floor(vim.o.lines * 0.3)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
  })

  -- Start terminal in that buffer
  vim.fn.termopen(cmd, {
    on_exit = function(_, exit_code, _)
      if exit_code == 0 then
        print("Command succeeded: " .. cmd)
      else
        print("Command failed: " .. cmd)
      end
      -- Close the floating window
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  })
end

return {
  -- The UI for DAP
  {
    "rcarriga/nvim-dap-ui",
    dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
    config = function()
      local dap, dapui = require("dap"), require("dapui")
      dapui.setup()
      -- Force UI open/close on events
      dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
      dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
      dap.listeners.before.event_exited["dapui_config"] = function() dapui.close() end
    end
  },

  -- The Core Debugger Configuration
  {
    "mfussenegger/nvim-dap",
    lazy = true,
    keys = {
      -- Use <leader> + number to keep your normal number keys working
      { "<leader>5", function() require("dap").continue() end, desc = "Continue" },
      { "<leader>6", function() require("dap").step_into() end, desc = "Step Into" },
      { "<leader>7", function() require("dap").step_over() end, desc = "Step Over" },
      { "<leader>8", function() require("dap").step_out() end, desc = "Step Out" },
      { "<leader>b", function() require("dap").toggle_breakpoint() end, desc = "Toggle Breakpoint" },
      
      -- The "Clean Exit"
      { "<leader>dq", function() 
          require("dap").terminate()
          require("dapui").close()
          run_sudo("sudo pkill -f openocd")
        end, desc = "Stop Debugging" 
      }
    },
    config = function()
      local dap = require("dap")

      -- Helper: Find readelf
      local function readelf_for_arch()
        local candidates = { "readelf", "aarch64-linux-gnu-readelf", "arm-none-eabi-readelf" }
        for _, cmd in ipairs(candidates) do
          if vim.fn.executable(cmd) == 1 then return cmd end
        end
        return nil
      end

      -- Helper: Detect Arch
      local function detect_elf_arch(path)
        local readelf = readelf_for_arch()
        if not readelf then return nil end
        local out = vim.fn.system({ readelf, "-h", path })
        if vim.v.shell_error ~= 0 then return nil end
        local class = out:match("Class:%s+(ELF%d+)")
        local machine = out:match("Machine:%s+([^\n]+)"):lower()
        if class == "ELF32" and machine:match("arm") then return "arm32"
        elseif class == "ELF64" and machine:match("aarch64") then return "aarch64"
        elseif class == "ELF64" and machine:match("x86%-64") then return "x86_64"
        end
        return "unknown"
      end

      local function debug_mcu_elf()
        local dap = require("dap")
      
        local function start_debug(elf_path)
          local file_name = vim.fn.fnamemodify(elf_path, ":t")
      
          -- Resolve GDB
          local sys = vim.loop.os_uname().sysname
          local gdb_path = (sys == "Darwin") and "arm-none-eabi-gdb" or "gdb-multiarch"
      
          -- Ask OpenOCD interface
          vim.ui.input({
            prompt = "OpenOCD interface file:",
            default = "interface/stlink.cfg",
          }, function(interface)
            if not interface or interface == "" then return end
      
            vim.ui.input({
              prompt = "OpenOCD target file:",
              default = "target/stm32f1x.cfg",
            }, function(target)
              if not target or target == "" then return end
      
              -- Launch OpenOCD if needed
              if vim.fn.system("lsof -i :3333") == "" then
                print("Launching OpenOCD...")
                vim.fn.jobstart(
                  string.format("sudo openocd -f %s -f %s", interface, target),
                  { detach = true }
                )
                vim.wait(2000)
              end
      
              -- UI cleanup
              vim.api.nvim_buf_delete(0, { force = true })
      
              -- Adapter
              dap.adapters.gdb = {
                type = "executable",
                command = gdb_path,
                args = { "--interpreter=dap", "--quiet" },
              }
      
              -- Run DAP
              dap.run({
                name = "Hardware: " .. file_name,
                type = "gdb",
                request = "attach",
                target = "localhost:3333",
                program = elf_path,
                cwd = vim.fn.getcwd(),
                stopOnEntry = true,
                setupCommands = {
                  { text = "target remote :3333" },
                  { text = "monitor reset halt" },
                  { text = "set breakpoint pending on" },
                  { text = "load" },
                  { text = "set print pretty on" },
                },
              })
      
              require("dapui").open()
            end)
          end)
        end
      
        -- Determine ELF
        local current_file = vim.fn.expand("%:p")
        if detect_elf_arch(current_file) == "arm32" then
          start_debug(current_file)
        else
          vim.ui.input({
            prompt = "ELF file to debug:",
            default = vim.fn.getcwd() .. "/",
            completion = "file",
          }, function(path)
            if path and detect_elf_arch(path) == "arm32" then
              start_debug(path)
            else
              print("Not a valid ARM ELF")
            end
          end)
        end
      end
      
      vim.keymap.set("n", "<leader>gdb", debug_mcu_elf, {
        desc = "Auto MCU Debug (OpenOCD + GDB)",
      })
    end
  }
}

