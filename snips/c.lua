local ls = require("luasnip")
-- some shorthands...
local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local c = ls.choice_node
local d = ls.dynamic_node
local r = ls.restore_node
local l = require("luasnip.extras").lambda
local rep = require("luasnip.extras").rep
local p = require("luasnip.extras").partial
local m = require("luasnip.extras").match
local n = require("luasnip.extras").nonempty
local dl = require("luasnip.extras").dynamic_lambda
local fmt = require("luasnip.extras.fmt").fmt
local fmta = require("luasnip.extras.fmt").fmta
local types = require("luasnip.util.types")
local conds = require("luasnip.extras.expand_conditions")


ls.add_snippets("c", {
  s("main", {
    t({
      "#include <stdio.h>",
      "",
      "int main() {",
      "\treturn 0;",
      "}",
    }),
  }),
  s("gtkdoc", {
    t({"/**", " * SECTION: "}), i(1, "section_name"),
    t({"", " * @title: "}), i(2, "Title"),
    t({"", " * @short_description: "}), i(3, "Short description"),
    t({"", " *", " * "}), i(4, "Description..."),
    t({"", " */"})
  }),
  s("fn1", {
    t({"/**", " * SECTION: "}), i(1, "section_name"),
    t({"", " * @title: "}), i(2, "Title"),
    t({"", " * @short_description: "}), i(3, "Short description"),
    
    -- Parameters section (dynamic)
    d(4, function(args)
      -- args[1][1] is the content of insert node 5 (parameter list)
      local params_text = args[1][1]
      if params_text == "" then
        return sn(nil, t(""))
      end
      local nodes = {}
      for param in params_text:gmatch("[^,]+") do
        param = param:gsub("^%s*(.-)%s*$", "%1") -- trim spaces
        table.insert(nodes, t({"", " * @param " .. param .. " "}))
      end
      return sn(nil, nodes)
    end, {5}),  -- depends on insert node 5
    
    t({"", " * @return: "}), i(2, ""),
    t({"", " */"}),
    
    -- Function signature
    t({"", "void "}), i(6, "func_name"), t("("), i(5, "param1"), t({") {", "\t"}), i(0), t({"", "}"}),
  }),
  s("fn2", {
    t({"/**", " * SECTION: "}), i(1, "section_name"),
    t({"", " * @title: "}), i(2, "Title"),
    t({"", " * @short_description: "}), i(3, "Short description"),
    
    -- Parameters section (dynamic)
    d(4, function(args)
      -- args[1][1] is the content of insert node 5 (parameter list)
      local params_text = args[1][1]
      if params_text == "" then
        return sn(nil, t(""))
      end
      local nodes = {}
      for param in params_text:gmatch("[^,]+") do
        param = param:gsub("^%s*(.-)%s*$", "%1") -- trim spaces
        table.insert(nodes, t({"", " * @param " .. param .. " "}))
      end
      return sn(nil, nodes)
    end, {5}),  -- depends on insert node 5
    
    t({"", " * @return: "}), i(2, ""),
    t({"", " */"}),
    
    -- Function signature
    t({"", "void "}), i(6, "func_name"), t("("), i(5, "param1, param2"), t({") {", "\t"}), i(0), t({"", "}"}),
  }),
  s("fn3", {
    t({"/**", " * SECTION: "}), i(1, "section_name"),
    t({"", " * @title: "}), i(2, "Title"),
    t({"", " * @short_description: "}), i(3, "Short description"),
    
    -- Parameters section (dynamic)
    d(4, function(args)
      -- args[1][1] is the content of insert node 5 (parameter list)
      local params_text = args[1][1]
      if params_text == "" then
        return sn(nil, t(""))
      end
      local nodes = {}
      for param in params_text:gmatch("[^,]+") do
        param = param:gsub("^%s*(.-)%s*$", "%1") -- trim spaces
        table.insert(nodes, t({"", " * @param " .. param .. " "}))
      end
      return sn(nil, nodes)
    end, {5}),  -- depends on insert node 5
    
    t({"", " * @return: "}), i(2, ""),
    t({"", " */"}),
    
    -- Function signature
    t({"", "void "}), i(6, "func_name"), t("("), i(5, "param1, param2, param3"), t({") {", "\t"}), i(0), t({"", "}"}),
  }),
})
