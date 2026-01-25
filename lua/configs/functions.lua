-----------------------------------------------------------
-- Enable diff for exactly two windows
-----------------------------------------------------------
function DiffTwoWindows()
  local wins = vim.api.nvim_tabpage_list_wins(0) -- only current tab
  local normal_wins = {}

  -- filter normal windows (exclude floating / plugin)
  for _, win in ipairs(wins) do
    local cfg = vim.api.nvim_win_get_config(win)
    if cfg.relative == "" then
      table.insert(normal_wins, win)
    end
  end

  if #normal_wins ~= 2 then
    print("Exactly two NORMAL windows must be open in this tab!")
    return
  end

  for _, win in ipairs(normal_wins) do
    vim.api.nvim_win_call(win, function()
      vim.cmd("diffthis")
    end)
  end

  print("Diff mode enabled for this tab ✔")
end

-----------------------------------------------------------
-- Cancel diff mode for all windows
-----------------------------------------------------------
function CancelDiff()
  vim.cmd("diffoff!")
end

-----------------------------------------------------------
-- Keymaps
-----------------------------------------------------------
vim.keymap.set("n", "<leader>;d", DiffTwoWindows, { desc = "Diff the two windows" })
vim.keymap.set("n", "<leader>;D", CancelDiff, { desc = "Cancel diff mode" })

local M = {}

-- local has_telescope, telescope = pcall(require, "telescope")
-- if not has_telescope then
--   vim.notify("telescope.nvim not found", vim.log.levels.ERROR)
--   return M
-- end
-- 
-- local pickers = require("telescope.pickers")
-- local finders = require("telescope.finders")
-- local conf = require("telescope.config").values
-- local actions = require("telescope.actions")
-- local action_state = require("telescope.actions.state")
-- 
-- ---------------------------------------------------------------------
-- -- Icons (Nerd Font recommended)
-- ---------------------------------------------------------------------
-- local ICONS = {
--   function_ = "󰊕",
--   method    = "󰆧",
--   struct    = "󰙅",
--   class     = "󰌗",
--   enum      = "󰕘",
--   macro     = "󰏿",
--   heading   = "󰉫",
--   variable  = "󰀫",
--   module    = "󰏗",
--   label     = "󰌋",
--   default   = "󰈙",
-- }
-- 
-- ---------------------------------------------------------------------
-- -- Filetype → Treesitter language map
-- ---------------------------------------------------------------------
-- local LANG_MAP = {
--   c = "c",
--   cpp = "cpp",
--   java = "java",
--   python = "python",
--   lua = "lua",
--   bash = "bash",
--   sh = "bash",
--   xml = "xml",
--   asm = "asm",
--   s = "asm",
--   S = "asm",
--   cs = "c_sharp",
--   make = "make",
--   diff = "diff",
--   bp = "bp",
--   vue = "vue",
--   php = "php",
--   markdown = "markdown",
--   rst = "rst",
--   qmljs = "qmljs",
--   rust = "rust",
-- }
-- 
-- ---------------------------------------------------------------------
-- -- Treesitter queries (semantic captures)
-- ---------------------------------------------------------------------
-- local QUERIES = {
--   c = [[
--     (function_definition
--       declarator: [
--         (function_declarator declarator: (identifier) @function_)
--         (pointer_declarator declarator:
--           (function_declarator declarator: (identifier) @function_))
--       ])
--     (struct_specifier name: (type_identifier) @struct body:(_))
--     (enum_specifier name: (type_identifier) @enum body:(_))
--     (preproc_function_def name: (identifier) @macro)
--   ]],
-- 
--   cpp = [[
--     (function_definition declarator: (function_declarator declarator: (_) @function_))
--     (class_specifier name: (type_identifier) @class)
--     (struct_specifier name: (type_identifier) @struct)
--     (enum_specifier name: (type_identifier) @enum)
--     (preproc_function_def name: (identifier) @macro)
--   ]],
-- 
--   rust = [[
--     (function_item name: (identifier) @function_)
--     (struct_item name: (type_identifier) @struct)
--     (enum_item name: (type_identifier) @enum)
--     (impl_item body: (declaration_list
--         (function_item name: (identifier) @method)))
--   ]],
-- 
--   lua = [[
--     (function_declaration name: (identifier) @function_)
--     (assignment_statement
--       (variable_list (identifier) @function_)
--       (expression_list (function_definition)))
--   ]],
-- 
--   python = [[
--     (function_definition name: (identifier) @function_)
--     (class_definition name: (identifier) @class)
--   ]],
-- 
--   java = [[
--     (method_declaration name: (identifier) @method)
--     (class_declaration name: (identifier) @class)
--     (constructor_declaration name: (identifier) @method)
--   ]],
-- 
--   bash = [[
--     (function_definition name: (word) @function_)
--   ]],
-- 
--   c_sharp = [[
--     (method_declaration name: (identifier) @method)
--     (constructor_declaration name: (identifier) @method)
--     (class_declaration name: (identifier) @class)
--     (struct_declaration name: (identifier) @struct)
--     (enum_declaration name: (identifier) @enum)
--   ]],
-- 
--   markdown = [[
--     (section (atx_heading) @heading)
--   ]],
-- 
--   rst = [[
--     (section (title) @heading)
--   ]],
-- 
--   qmljs = [[
--     (ui_object_definition type_name: (identifier) @class)
--   ]],
-- }
-- 
-- ---------------------------------------------------------------------
-- -- Main function
-- ---------------------------------------------------------------------
-- function M.show_functions_telescope()
--   local bufnr = vim.api.nvim_get_current_buf()
--   local ft = vim.bo[bufnr].filetype
--   local lang = LANG_MAP[ft]
-- 
--   if not lang then
--     vim.notify("Unsupported filetype: " .. ft, vim.log.levels.WARN)
--     return
--   end
-- 
--   local query_str = QUERIES[lang]
--   if not query_str then
--     vim.notify("No Treesitter query for: " .. lang, vim.log.levels.WARN)
--     return
--   end
-- 
--   local parser = vim.treesitter.get_parser(bufnr, lang)
--   if not parser then
--     vim.notify("No Treesitter parser for: " .. lang, vim.log.levels.WARN)
--     return
--   end
-- 
--   local tree = parser:parse()[1]
--   local root = tree:root()
--   local query = vim.treesitter.query.parse(lang, query_str)
-- 
--   local items = {}
-- 
--   for _, match in query:iter_matches(root, bufnr) do
--     for id, nodes in pairs(match) do
--       local capture = query.captures[id]
--       local node = nodes[1]
-- 
--       if node then
--         local text = vim.treesitter.get_node_text(node, bufnr)
--         local icon = ICONS[capture] or ICONS.default
--         local row = select(1, node:range())
-- 
--         table.insert(items, {
--           text = string.format("%s  %s", icon, text),
--           kind = capture,
--           filename = vim.api.nvim_buf_get_name(bufnr),
--           lnum = row + 1,
--         })
--       end
--     end
--   end
-- 
--   if vim.tbl_isempty(items) then
--     vim.notify("No symbols found", vim.log.levels.INFO)
--     return
--   end
-- 
--   pickers.new({}, {
--     prompt_title = lang:upper() .. " Outline",
--     layout_strategy = "horizontal",
--     layout_config = {
--       width = 0.9,
--       height = 0.95,
--       preview_width = 0.55,
--     },
--     finder = finders.new_table {
--       results = items,
--       entry_maker = function(entry)
--         return {
--           value = entry,
--           display = entry.text,
--           ordinal = entry.kind .. " " .. entry.text,
--           filename = entry.filename,
--           lnum = entry.lnum,
--           col = 1,
--         }
--       end,
--     },
--     sorter = conf.generic_sorter({}),
--     previewer = conf.grep_previewer({}),
--     attach_mappings = function(prompt_bufnr)
--       actions.select_default:replace(function()
--         local selection = action_state.get_selected_entry()
--         actions.close(prompt_bufnr)
--         vim.api.nvim_win_set_cursor(0, { selection.lnum, 0 })
--       end)
--       return true
--     end,
--   }):find()
-- end
-- 
-- ---------------------------------------------------------------------
-- -- User command
-- ---------------------------------------------------------------------
-- vim.api.nvim_create_user_command(
--   "ShowFunctionsTelescope",
--   M.show_functions_telescope,
--   { desc = "Treesitter outline (functions / structs / classes / headings)" }
-- )

return M
