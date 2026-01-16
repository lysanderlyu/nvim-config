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
function M.show_functions_telescope()
  local bufnr = vim.api.nvim_get_current_buf()
  local ft = vim.bo[bufnr].filetype

  local lang_map = {
    c = "c", cpp = "cpp", java = "java", python = "python", lua = "lua", bash = "bash",
    sh = "bash", xml = "xml", asm = "asm", S = "asm", s = "asm", cs = "c_sharp", make = "make",
    diff = "diff", bp = "bp", vue = "vue", php = "php", markdown = "markdown", rst = "rst",
    qmljs = "qmljs", rust = "rust"
  }

  local lang = lang_map[ft]
  if not lang then print("Unsupported filetype for function outline: " .. ft) return end

  local lang_tree = vim.treesitter.get_parser(bufnr, lang)
  if not lang_tree then print("No parser found for language: " .. lang) return end

  local syntax_tree = lang_tree:parse()
  local root = syntax_tree[1]:root()

  local queries = {
    rust = [[
    (enum_item
        name: (_) @name)

    (struct_item
        name: (_) @name
        body: (field_declaration_list))

    (struct_item
        name: (_) @name
        body: (ordered_field_declaration_list))

    (macro_definition
      name: (identifier) @name)

    (impl_item
        type: (_) @type
        body: (declaration_list
            (function_item
                name: (identifier) @name)))

    (impl_item
        trait: (_) @name
        type: (_) @type)

    (trait_item
      (visibility_modifier)
      name: (_) @name
      body: (_))

    (function_item
      name: (identifier) @name
      parameters: (parameters)
      return_type: (never_type)
      body: (block))
    ]],
    qmljs = [[
      (ui_object_definition
        type_name: (identifier) @name)
    ]],
    rst = [[
      (section
          (title) @name)
    ]],
    markdown = [[
      (section
        (atx_heading) @name)
    ]],
    markdown_inline = [[
;;               (inline
;;                 (code_span) @name)  ; <-- capture code_span here
    ]],
    php = [[
      (class_declaration
        name: (name) @name)

      (method_declaration
        name: (name) @name)
    ]],
    vue = [[
      (template_element
        (start_tag
          (tag_name) @name))

      (element
       (start_tag
        (tag_name) @name))

      (script_element
       (start_tag
        (tag_name) @name))
    ]],
    bp = [[
      (module
        type: (identifier) @name)
    ]],
    c = [[
      ;; Match typedef
      (type_definition
        type: (_)
        declarator: (type_identifier) @name)

      ;; Match fucntion with attribute modified on the head like:
      (ERROR
      (type_descriptor
        type: (type_identifier) @name))

      ;; Match general function without
      (function_definition
      type: (_)
      declarator: (_
       declarator: (_) @name))

      ;; Macro function
      (preproc_function_def
        name: (identifier) @name)

      ;; Struct definition match 
      (struct_specifier
          name: (type_identifier) @name
          body: (_))
 
      ;; Union definition match 
      (union_specifier
          name: (type_identifier) @name
          body: (_))

      ;; Enum definition match 
      (enum_specifier
          name: (type_identifier) @name
          body: (_))
    ]],
    xml = [[
      (STag
          (Name) @name)
    ]],
    diff = [[
      (block                                                                                                                                                                                         
         (command                                                                                                                                                                                             
            (filename) @name))
    ]],
    make = [[
        (rule
         (targets
            (word) @name))
    ]],
    asm = [[
      (label
        (ident) @name) @label

      (instruction
        kind: (word)
        (ptr
          (reg) @name))
    ]],
    lua = [[
      ;; Named functions
      (function_declaration
        name: (identifier) @name)
    
      ;; Local functions
      (function_declaration
        name: (dot_index_expression
                field: (identifier) @name))
    
      ;; Anonymous functions assigned to a variable
      (assignment_statement
        (variable_list (identifier) @name)
        (expression_list (function_definition)))
    ]],
    cpp = [[
        ;; Match all the regular and constructor/destructor with class qualified_identifier
        (function_definition
          declarator: (function_declarator
            declarator: (_) @name))

        ;; Match the enum on .h header
        (enum_specifier
          name: (type_identifier) @name)

        ;; Match the typdef enum that does not has name only has typedef
        (type_definition
          type: (_
            body: (_))
          declarator: (type_identifier) @name)

        ;; Macro function
        (preproc_function_def
          name: (identifier) @name) @func

        ;; Class definition match 
        (class_specifier
            name: (type_identifier) @name
            body: (_))

        ;; Struct definition match 
        (struct_specifier
            name: (type_identifier) @name
            body: (_))
 
        ;; Union definition match 
        (union_specifier
            name: (type_identifier) @name
            body: (_))
    ]],
    java = [[
      (method_declaration
        name: (identifier) @name)

      (constructor_declaration
        name: (identifier) @name)
    
      (class_declaration
        name: (identifier) @name)
    ]],
    python = [[
      (function_definition
        name: (identifier) @name)
    ]],
    bash = [[
        (function_definition
        name: (word) @name) @func
    ]],
    c_sharp = [[
      (method_declaration
        name: (identifier) @name)
      (constructor_declaration
        name: (identifier) @name)
      (class_declaration
        name: (identifier) @name)
      (enum_declaration
        name: (identifier) @name)
      (struct_declaration
        name: (identifier) @name)
    ]]
  }

  local query_str = queries[lang]
  local query = vim.treesitter.query.parse(lang, query_str)

  local items = {}
  for pattern, match in query:iter_matches(root, bufnr) do
    -- match is a table where keys are capture IDs
    -- We need to map the IDs back to names
    local dict = {}
    for id, nodes in pairs(match) do
      local name = query.captures[id]
      dict[name] = nodes[1] -- Grab the first node for this capture name
    end
  
    if dict.name then
      local name_text = vim.treesitter.get_node_text(dict.name, bufnr)
      local type_text = ""
      
      if dict.type then
        type_text = vim.treesitter.get_node_text(dict.type, bufnr)
      end

      -- Helper to check if a string is not nil and not just whitespace
      local function is_valid(s)
        return s and s:find("%S") ~= nil
      end
  
      local combined = ""
        if is_valid(type_text) and is_valid(name_text) then
          combined = type_text .. ": " .. name_text
        elseif is_valid(type_text) then
          combined = type_text
        elseif is_valid(name_text) then
          combined = name_text
        end

      local start_row, _, _, _ = dict.name:range()
  
      table.insert(items, {
        text = combined,
        filename = vim.api.nvim_buf_get_name(bufnr),
        lnum = start_row + 1
      })
    end
  end

  require("telescope.pickers").new({}, {
    prompt_title = lang:sub(1,1):upper() .. lang:sub(2) .. " Outline",
    finder = require("telescope.finders").new_table({
      results = items,
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry.text,
          ordinal = entry.text,
          filename = entry.filename,
          lnum = entry.lnum,
          col = 1,
        }
      end,
    }),
    sorter = require("telescope.config").values.generic_sorter({}),
    previewer = require("telescope.config").values.grep_previewer({}),

    attach_mappings = function(prompt_bufnr)
      require("telescope.actions").select_default:replace(function()
        local selection = require("telescope.actions.state").get_selected_entry()
        require("telescope.actions").close(prompt_bufnr)
        vim.api.nvim_win_set_cursor(0, {selection.value.lnum, 0})
      end)
      return true
    end,
  }):find()
end

-- Register as command
vim.api.nvim_create_user_command("ShowFunctionsTelescope", M.show_functions_telescope, {})

return M

