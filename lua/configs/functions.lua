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
        name: (type_identifier) @name)

    (struct_item
        name: (type_identifier) @name
        body: (field_declaration_list))

    (struct_item
        name: (type_identifier) @name
        body: (ordered_field_declaration_list))

    (impl_item
        trait: (type_identifier)
        type: (type_identifier) @name)

    (macro_definition
      name: (identifier) @name)

    (impl_item
      trait: (generic_type) @name)

    (trait_item
      (visibility_modifier)
      name: (type_identifier) @name
      body: (declaration_list))

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

      (section
        (atx_heading)
        (list
          (list_item
            (list_marker_minus)
            (paragraph
              (inline) @name))))

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
      ;; Match typedef strcut
      (type_definition
        type: (struct_specifier)
        declarator: (type_identifier) @name) @struct_name

      ;; Match fucntion with attribute modified on the head like:
      (ERROR
        (type_descriptor
          type: (type_identifier) @name))

      ;; Match normal function without qualified_identifier
      (function_definition
        declarator: (function_declarator
          declarator: (identifier) @name)) @func
    
      ;; Match pointer function without qualified_identifier
      (function_definition
        declarator: (pointer_declarator
         declarator: (function_declarator
           declarator: (identifier) @name))) @func

      ;; Match pointer function that has two level pointer
      (function_definition
        declarator: (pointer_declarator
          declarator: (pointer_declarator
            declarator: (function_declarator
              declarator: (identifier) @name))))

      ;; Macro function
        (preproc_function_def
          name: (identifier) @name) @func

      ;; Struct definition match 
        (struct_specifier
            name: (type_identifier) @name
            body: (field_declaration_list)) @struct_name
 
      ;; Union definition match 
        (union_specifier
            name: (type_identifier) @name
            body: (field_declaration_list)) @union_name

      ;; Enum definition match 
        (enum_specifier
            name: (type_identifier) @name
            body: (enumerator_list)) @enum_name
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
        name: (identifier) @name) @func
    
      ;; Local functions
      (function_declaration
        name: (dot_index_expression
                field: (identifier) @name)) @func
    
      ;; Anonymous functions assigned to a variable
      (assignment_statement
        (variable_list (identifier) @name)
        (expression_list (function_definition))) @func
    ]],
    cpp = [[
        ;; Match the struct definition on qt like struct QT_EXPORT QMetaObject \ {
        (function_definition
          type: (struct_specifier)
          declarator: (identifier) @name)

        ;; Match the class definition on qt like class QT_EXPORT QBytearray \ {
        (function_definition
          type: (class_specifier)
          declarator: (identifier) @name)

        ;; Match label statement on cpp class like public: private: slot:
        (function_definition
          body: (compound_statement
            (labeled_statement
              label: (statement_identifier) @name)))

        ;; Match the enum on .h header
        (enum_specifier
          name: (type_identifier) @name)

        ;; Match the typdef enum that does not has name only has typedef
      (type_definition
        type: (enum_specifier
          body: (enumerator_list))
        declarator: (type_identifier) @name) @func

        ;; Match the typdef struct that does not has name only has typedef
      (type_definition
        type: (struct_specifier
          body: (field_declaration_list))
        declarator: (type_identifier) @name) @func

        ;; Match regular functions that without class name specific
      (function_definition
        declarator: (function_declarator
          declarator: (field_identifier) @name)) @func

        ;; Match regular functions that with class name specific (include constructor)
      (function_definition
        declarator: (function_declarator
          declarator: (qualified_identifier
            name: (identifier) @name))) @func

        ;; Match reference returned functions that with class name specific
      (function_definition
       declarator: (reference_declarator
         (function_declarator
           declarator: (qualified_identifier
             name: (identifier) @name))) @func
      )

      ;; Match destructor function
     (function_definition
       declarator: (function_declarator
         declarator: (qualified_identifier
           scope: (namespace_identifier)
           name: (destructor_name) @name))) @func

      ;; Match normal function without qualified_identifier
      (function_definition
        declarator: (function_declarator
          declarator: (identifier) @name)) @func
    
      ;; Match pointer function without qualified_identifier and storage_class_specifier
      (function_definition
        declarator: (pointer_declarator
         declarator: (function_declarator
           declarator: (identifier) @name))) @func

      ;; Match reference function without qualified_identifier
      (function_definition
       declarator: (reference_declarator
         (function_declarator
             name: (identifier) @name)) @func
      )

      ;; Match operators (e.g., operator==, operator=)
      (function_definition
        declarator: (function_declarator
          declarator: (operator_name) @name)) @func

      ;; Macro function
        (preproc_function_def
          name: (identifier) @name) @func

      ;; Class definition match 
        (class_specifier
            name: (type_identifier) @name
            body: (field_declaration_list)) @class_name

      ;; Struct definition match 
        (struct_specifier
            name: (type_identifier) @name
            body: (field_declaration_list)) @struct_name
 
      ;; Union definition match 
        (union_specifier
            name: (type_identifier) @name
            body: (field_declaration_list)) @union_name
    ]],
    java = [[
      (method_declaration
        name: (identifier) @name) @func

      (constructor_declaration
        name: (identifier) @name) @func
    
      (class_declaration
        name: (identifier) @name) @func
    ]],
    python = [[
      (function_definition
        name: (identifier) @name) @func
    ]],
    bash = [[
        (function_definition
        name: (word) @name) @func
    ]],
    c_sharp = [[
      (method_declaration
        name: (identifier) @name) @func
      (property_declaration
        name: (identifier) @name) @func
      (constructor_declaration
        name: (identifier) @name) @func
      (class_declaration
        name: (identifier) @name) @func
      (enum_declaration
        name: (identifier) @name) @func
      (struct_declaration
        name: (identifier) @name) @func
    ]]
  }

  local query_str = queries[lang]
  local query = vim.treesitter.query.parse(lang, query_str)

  local items = {}
  for id, node in query:iter_captures(root, bufnr) do
    if query.captures[id] == "name" then
      local name = vim.treesitter.get_node_text(node, bufnr)
      local ok, start_row, _, _ = pcall(node.start, node)
      if ok then
      table.insert(items, {
        text = name,
        filename = vim.api.nvim_buf_get_name(bufnr),
        lnum = start_row + 1
      })
      end
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

-- Line number shows version
--require("telescope.pickers").new({}, {
--  prompt_title = lang:sub(1,1):upper() .. lang:sub(2) .. " Outline",
--  finder = require("telescope.finders").new_table({
--    results = items,
--    entry_maker = function(entry)
--      return {
--        value = entry,
--        display = entry.text,
--        ordinal = entry.text,
--        filename = entry.filename,
--        lnum = entry.lnum,
--        col = 1,
--      }
--    end,
--  }),
--  sorter = require("telescope.config").values.generic_sorter({}),
--  previewer = require("telescope.previewers").new_buffer_previewer({
--    define_preview = function(self, entry, status)
--      local filename = entry.filename
--      if vim.fn.filereadable(filename) == 1 then
--        vim.api.nvim_buf_set_option(self.state.bufnr, "number", true)
--        vim.api.nvim_buf_set_option(self.state.bufnr, "relativenumber", false)
--        vim.api.nvim_buf_set_option(self.state.bufnr, "wrap", false)
--        local start_line = math.max(0, entry.lnum - 10)
--        local end_line = entry.lnum + 20
--        local lines = vim.fn.readfile(filename, start_line + 1, end_line + 1)
--        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
--        vim.api.nvim_buf_set_option(self.state.bufnr, "modifiable", false)
--      else
--        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, {"File not found: " .. filename})
--      end
--    end,
--  }),
--
--  attach_mappings = function(prompt_bufnr)
--    require("telescope.actions").select_default:replace(function()
--      local selection = require("telescope.actions.state").get_selected_entry()
--      require("telescope.actions").close(prompt_bufnr)
--      vim.api.nvim_win_set_cursor(0, {selection.value.lnum, 0})
--    end)
--    return true
--  end,
--}):find()
--end

-- Register as command
vim.api.nvim_create_user_command("ShowFunctionsTelescope", M.show_functions_telescope, {})

return M

