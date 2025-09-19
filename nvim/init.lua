require("config.lazy")

vim.keymap.set("n", "<leader>r", vim.lsp.buf.rename, { desc = "LSP: Rename" })

local function is_codeforces_directory()
  local current_dir = vim.fn.getcwd()
  return string.match(current_dir, "CodeForces/?$") -- Main CodeForces directory
    or string.match(current_dir, "CodeForces/[^/]+/?$") -- Any subdirectory under CodeForces
end

local function is_cs3233_kattis_directory()
  local current_dir = vim.fn.getcwd()
  return string.match(current_dir, "CS3233/?$")
    or string.match(current_dir, "CS3233/[^/]+/?$")
    or string.match(current_dir, "CS3233/ProblemSets/?$")
    or string.match(current_dir, "CS3233/ProblemSets/[^/]+/?$")
    or string.match(current_dir, "OpenKattis/?$") -- OpenKattis directory
    or string.match(current_dir, "OpenKattis/[^/]+/?$") -- Any subdirectory under OpenKattis
end

-- Function to insert C++ template
local function insert_cpp_template()
  local template_path

  if is_codeforces_directory() then
    template_path = vim.fn.expand("~/.config/nvim/templates/codeforces_template.cpp")
  elseif is_cs3233_kattis_directory() then
    template_path = vim.fn.expand("~/.config/nvim/templates/kattis_template.cpp")
  else
    template_path = vim.fn.expand("~/.config/nvim/templates/cpp_template.cpp")
  end

  vim.api.nvim_command("0r " .. template_path)
  -- Add any dynamic replacements here
  -- Example:
  -- vim.api.nvim_command('silent! execute "0,%s/%AUTHOR%/Your Name/e"')
  -- vim.api.nvim_command('silent! execute "0,%s/%DESCRIPTION%/Brief description of the file/e"')
  -- local solution_line_number = 11
  -- vim.api.nvim_win_set_cursor(0, { solution_line_number, 0 })
end

-- Create an autocommand for new C++ files
vim.api.nvim_create_autocmd("BufNewFile", {
  pattern = "*.cpp",
  callback = insert_cpp_template,
})
