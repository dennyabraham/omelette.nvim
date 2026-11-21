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

test("the LSP config runs omelette lsp for omelette files", function()
  eq(vim.lsp.config.omelette.cmd, { "omelette", "lsp" })
  eq(vim.lsp.config.omelette.filetypes, { "omelette" })
end)

test("a client attaches and returns semantic tokens", function()
  if vim.fn.executable("omelette") == 0 then error({ skip = "omelette is not on PATH" }) end
  local usage = vim.system({ "omelette" }):wait().stdout or ""
  if not usage:find("lsp") then error({ skip = "the omelette on PATH has no lsp command" }) end
  local path = dir .. "/y.egg"
  vim.fn.writefile({ "let f x = x" }, path)
  vim.cmd("edit " .. path)
  local attached = vim.wait(5000, function()
    return #vim.lsp.get_clients({ bufnr = 0, name = "omelette" }) > 0
  end)
  if not attached then error("no omelette client attached") end
  local client = vim.lsp.get_clients({ bufnr = 0, name = "omelette" })[1]
  local res = client:request_sync("textDocument/semanticTokens/full",
    { textDocument = vim.lsp.util.make_text_document_params(0) }, 5000, 0)
  if not (res and res.result and #res.result.data > 0) then
    error("no semantic tokens: " .. vim.inspect(res))
  end
end)

for _, c in ipairs(vim.lsp.get_clients()) do c:stop(true) end
vim.cmd(failures == 0 and "qall!" or "cquit!")
