local M = {}

function M.copy_current_file()
  local path = vim.api.nvim_buf_get_name(0)
  if path == "" then
    vim.notify("No file associated with this buffer", vim.log.levels.WARN)
    return
  end

  local name = vim.fn.fnamemodify(path, ":t")

  -- macOS
  if vim.fn.has("mac") == 1 then
    vim.fn.system({
      "osascript",
      "-e",
      string.format([[
        set theFile to POSIX file "%s"
        set the clipboard to theFile
      ]], path)
    })

  -- Windows / WSL
  elseif vim.fn.has("win32") == 1 or vim.fn.has("wsl") == 1 then
    local cmd = string.format(
      'powershell.exe -NoProfile -Command "Set-Clipboard -Path \'%s\'"',
      path
    )
    vim.fn.system(cmd)

  -- Linux
  else
    if vim.fn.executable("wl-copy") == 1 then
      vim.fn.system(
        string.format("printf 'file://%s' | wl-copy -t text/uri-list", path)
      )
    elseif vim.fn.executable("xclip") == 1 then
      vim.fn.system(
        string.format("printf 'file://%s' | xclip -selection clipboard -t text/uri-list", path)
      )
    elseif vim.fn.executable("xsel") == 1 then
      vim.fn.system(
        string.format("printf 'file://%s' | xsel --clipboard --input", path)
      )
    else
      vim.notify("No clipboard tool found (wl-copy/xclip/xsel)", vim.log.levels.ERROR)
      return
    end
  end

  vim.notify("Copied file: " .. name)
end

function M.copy_fs_object_from_nvim_tree()
  local api = require("nvim-tree.api")
  local node = api.tree.get_node_under_cursor()
  if not node or not node.absolute_path then return end

  local path = node.absolute_path
  local name = node.name

  -- macOS
  if vim.fn.has("mac") == 1 then
    vim.fn.system({
      "osascript",
      "-e",
      string.format([[
        set theFile to POSIX file "%s"
        set the clipboard to theFile
      ]], path)
    })

  -- Windows / WSL
  elseif vim.fn.has("win32") == 1 or vim.fn.has("wsl") == 1 then
    local cmd = string.format(
      'powershell.exe -NoProfile -Command "Set-Clipboard -Path \'%s\'"',
      path
    )
    vim.fn.system(cmd)

  -- Linux
  else
    if vim.fn.executable("wl-copy") == 1 then
      vim.fn.system(
        string.format("printf 'file://%s' | wl-copy -t text/uri-list", path)
      )
    elseif vim.fn.executable("xclip") == 1 then
      vim.fn.system(
        string.format("printf 'file://%s' | xclip -selection clipboard -t text/uri-list", path)
      )
    elseif vim.fn.executable("xsel") == 1 then
      vim.fn.system(
        string.format("printf 'file://%s' | xsel --clipboard --input", path)
      )
    else
      vim.notify("No clipboard tool found (wl-copy/xclip/xsel)", vim.log.levels.ERROR)
      return
    end
  end

  vim.notify("Copied filesystem object: " .. name)
end

return M
