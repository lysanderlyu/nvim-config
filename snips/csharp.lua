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

ls.add_snippets("cs", {
 s("fn1", {
    -- Summary
    t({"/// <summary>"}), i(1, "", "Short description"), t({"", "/// </summary>"}),

    -- Dynamic param documentation
    d(2, function(args)
      local params_text = args[1][1]
      if params_text == "" then
        return sn(nil, t(""))
      end

      local nodes = {}
      for param in params_text:gmatch("[^,]+") do
        param = param:gsub("^%s*(.-)%s*$", "%1")     -- trim spaces
        local name_only = param:match("%w+$") or param
        table.insert(nodes, t({"", '/// <param name="' .. name_only .. '"></param>'}))
      end

      return sn(nil, nodes)
    end, {3}, nil, {user_args={}, repeatable=false, update_events="TextChanged,TextChangedI"}), 

    t({"", "/// <returns>"}), i(1, ""), t({"", "/// </returns>"}),
    -- Method signature
    t({"", "public void "}), i(4, "MethodName"), t("("), i(3, "int a1"), t({")", "{", "\t"}), i(0), t({"", "}"}),
  }),
 s("fn2", {
    -- Summary
    t({"/// <summary>"}),t({"", "/// "}), i(1, "", "Short description"), t({"", "/// </summary>"}),

    -- Dynamic parameter comments
    d(2, function(args)
      local params_text = args[1][1]
      if params_text == "" then
        return sn(nil, t(""))
      end

      local nodes = {}
      for param in params_text:gmatch("[^,]+") do
        param = param:gsub("^%s*(.-)%s*$", "%1") -- trim spaces
        local name_only = param:match("%w+$") or param
        table.insert(nodes, t({"", '/// <param name="' .. name_only .. '"></param>'}))
      end
      return sn(nil, nodes)
    end, {3}),  -- depends on node 3 (parameter list)

    t({"", "/// <returns>"}), i(1, ""), t({"", "/// </returns>"}),
    -- Method signature
    t({"", "public void "}), i(4, "MethodName"), t("("), i(3, "int param1, int param2"), t({")", "{", "\t"}), i(0), t({"", "}"}),
  }),
 s("fn3", {
    -- Summary
    t({"/// <summary>"}),t({"", "/// "}), i(1, "", "Short description"), t({"", "/// </summary>"}),

    -- Dynamic parameter comments
    d(2, function(args)
      local params_text = args[1][1]
      if params_text == "" then
        return sn(nil, t(""))
      end

      local nodes = {}
      for param in params_text:gmatch("[^,]+") do
        param = param:gsub("^%s*(.-)%s*$", "%1") -- trim spaces
        local name_only = param:match("%w+$") or param
        table.insert(nodes, t({"", '/// <param name="' .. name_only .. '"></param>'}))
      end
      return sn(nil, nodes)
    end, {3}),  -- depends on node 3 (parameter list)

    t({"", "/// <returns>"}), i(1, ""), t({"", "/// </returns>"}),
    -- Method signature
    t({"", "public void "}), i(4, "MethodName"), t("("), i(3, "int param1, int param2, int param3"), t({")", "{", "\t"}), i(0), t({"", "}"}),
  }),
  s("gtkdoc", {
    t({"/**", " * SECTION: "}), i(1, "section_name"),
    t({"", " * @title: "}), i(2, "Title"),
    t({"", " * @short_description: "}), i(3, "Short description"),
    t({"", " *", " * "}), i(4, "Description..."),
    t({"", " */"})
  }),
})
