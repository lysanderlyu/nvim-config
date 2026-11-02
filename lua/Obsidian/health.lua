-- checkhealth may look up "Obsidian" (UserCommand) instead of "obsidian" (lua module).
if package.loaded["obsidian.health"] == nil then
  local ok, lazy = pcall(require, "lazy")
  if ok and lazy then
    pcall(lazy.load, { plugins = { "obsidian.nvim" } })
  end
end

return require("obsidian.health")
