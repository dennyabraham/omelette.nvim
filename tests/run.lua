-- Run from the repository root: nvim --clean --headless -l tests/run.lua
vim.opt.rtp:prepend(vim.fn.getcwd())
-- Neovim turned file type detection on before this script ran, so source ftdetect/
-- the way a plugin manager does for a plugin added to runtimepath.
vim.cmd("filetype plugin on")
vim.cmd("runtime! ftdetect/*.lua plugin/*.lua")

local failures = 0
local function test(name, fn)
  local ok, err = pcall(fn)
  if ok then
    print("ok   " .. name)
  elseif type(err) == "table" and err.skip then
    print("skip " .. name .. ": " .. err.skip)
  else
    failures = failures + 1
    print("FAIL " .. name .. ": " .. tostring(err))
  end
end

local function eq(a, b)
  if not vim.deep_equal(a, b) then
    error("expected " .. vim.inspect(b) .. ", got " .. vim.inspect(a), 2)
  end
end

local dir = vim.fn.tempname()
vim.fn.mkdir(dir, "p")

test("an .egg file gets the omelette file type and buffer options", function()
  vim.cmd("edit " .. dir .. "/x.egg")
  eq(vim.bo.filetype, "omelette")
  eq(vim.bo.commentstring, "-- %s")
  eq(vim.bo.shiftwidth, 2)
  eq(vim.bo.expandtab, true)
  eq(vim.bo.autoindent, true)
end)

-- The syntax group at line:col of the current buffer.
local function group_at(line, col)
  return vim.fn.synIDattr(vim.fn.synID(line, col, 1), "name")
end

test("the syntax file colors an .egg file without the server", function()
  local path = dir .. "/s.egg"
  vim.fn.writefile({
    'let f x = x + 1 -- a comment',
    'type T = | A | B',
    'let s = "a \\" b" .. lua "print(1)"',
    'let t = true',
  }, path)
  vim.cmd("syntax on")
  vim.cmd("edit " .. path)
  eq(vim.b.current_syntax, "omelette")
  eq(group_at(1, 1), "omeletteKeyword")       -- let
  eq(group_at(1, 15), "omeletteNumber")       -- 1
  eq(group_at(1, 20), "omeletteComment")
  eq(group_at(2, 1), "omeletteKeyword")       -- type
  eq(group_at(2, 12), "omeletteConstructor")  -- A
  eq(group_at(3, 9), "omeletteString")
  eq(group_at(3, 14), "omeletteString")       -- after the escaped quote
  eq(group_at(3, 16), "omeletteString")       -- the closing quote
  eq(group_at(3, 17), "")                     -- the space after it
  eq(group_at(3, 21), "omeletteKeyword")      -- lua
  eq(group_at(4, 9), "omeletteBoolean")       -- true
end)

test("the LSP config runs omelette lsp for omelette files", function()
  eq(vim.lsp.config.omelette.cmd, { "omelette", "lsp" })
  eq(vim.lsp.config.omelette.filetypes, { "omelette" })
end)

-- Opens lines as a new .egg file and returns the omelette client attached to it.
local function attach(name, lines)
  if vim.fn.executable("omelette") == 0 then error({ skip = "omelette is not on PATH" }) end
  local usage = vim.system({ "omelette" }):wait().stdout or ""
  if not usage:find("lsp") then error({ skip = "the omelette on PATH has no lsp command" }) end
  local path = dir .. "/" .. name
  vim.fn.writefile(lines, path)
  vim.cmd("edit " .. path)
  local attached = vim.wait(5000, function()
    local c = vim.lsp.get_clients({ bufnr = 0, name = "omelette" })[1]
    return c and c.initialized
  end)
  if not attached then error("no omelette client attached") end
  return vim.lsp.get_clients({ bufnr = 0, name = "omelette" })[1]
end

test("a client attaches and returns semantic tokens", function()
  local client = attach("y.egg", { "let f x = x" })
  local res = client:request_sync("textDocument/semanticTokens/full",
    { textDocument = vim.lsp.util.make_text_document_params(0) }, 5000, 0)
  if not (res and res.result and #res.result.data > 0) then
    error("no semantic tokens: " .. vim.inspect(res))
  end
end)

test("hover, go to definition and the outline answer", function()
  local client = attach("n.egg", { "let n : number = 1", "let m = n" })
  if not client.server_capabilities.hoverProvider then
    error({ skip = "the omelette on PATH is older than 0.3.0" })
  end
  local function ask(method, line, character)
    local params = { textDocument = vim.lsp.util.make_text_document_params(0) }
    if line then params.position = { line = line, character = character } end
    local res = client:request_sync(method, params, 5000, 0)
    if not (res and res.result) then error(method .. ": " .. vim.inspect(res)) end
    return res.result
  end
  local hover = ask("textDocument/hover", 1, 8)
  if not hover.contents.value:find("n : number", 1, true) then error("hover: " .. vim.inspect(hover)) end
  eq(ask("textDocument/definition", 1, 8).range.start, { line = 0, character = 4 })
  local names = {}
  for i, s in ipairs(ask("textDocument/documentSymbol")) do names[i] = s.name end
  eq(names, { "n", "m" })
end)

for _, c in ipairs(vim.lsp.get_clients()) do c:stop(true) end
vim.cmd(failures == 0 and "qall!" or "cquit!")
