local M = {}

---Fuzzy-find a directory under `cwd` (workspace if omitted) and open it in nvim-tree.
---@param cwd? string
function M.open(cwd)
  cwd = cwd or vim.uv.cwd() or vim.fn.getcwd()
  local cmd, args
  if vim.fn.executable("fd") == 1 then
    cmd, args = "fd", { "--type", "d", "--color", "never", "-E", ".git" }
  elseif vim.fn.executable("fdfind") == 1 then
    cmd, args = "fdfind", { "--type", "d", "--color", "never", "-E", ".git" }
  else
    cmd, args = "find", { ".", "-type", "d", "-not", "-path", "*/.git/*" }
  end

  Snacks.picker({
    title = "Directories: " .. vim.fn.fnamemodify(cwd, ":t"),
    cwd = cwd,
    format = "file",
    finder = function(_, ctx)
      return require("snacks.picker.source.proc").proc({
        cmd = cmd,
        args = args,
        cwd = cwd,
        transform = function(item)
          item.file = item.text
          item.dir = true
          item.cwd = cwd
        end,
      }, ctx)
    end,
    confirm = function(picker, item)
      picker:close()
      local dir = item and Snacks.picker.util.dir(item)
      if not dir or vim.fn.isdirectory(dir) ~= 1 then
        vim.notify("Invalid directory: " .. tostring(dir or ""), vim.log.levels.ERROR)
        return
      end
      vim.schedule(function()
        local ok, api = pcall(require, "nvim-tree.api")
        if not ok then
          return
        end
        api.tree.find_file({
          buf = dir,
          open = true,
          focus = true,
          update_root = false,
        })
        api.node.open.edit()
      end)
    end,
  })
end

return M
