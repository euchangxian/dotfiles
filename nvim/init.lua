-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- Function to detect if we're in a CodeForces directory
local function is_codeforces_directory()
  local current_dir = vim.fn.getcwd()
  return string.match(current_dir, "CodeForces/?$") -- Main CodeForces directory
    or string.match(current_dir, "CodeForces/[^/]+/?$") -- Any subdirectory under CodeForces
end

-- Function to insert C++ template
local function insert_cpp_template()
  local template_path

  if is_codeforces_directory() then
    template_path = vim.fn.expand("~/.config/nvim/templates/codeforces_template.cpp")
  else
    -- Default to a basic template if not in CodeForces directory
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

-- Lspsaga keymaps
vim.keymap.set("n", "gd", "<cmd>Lspsaga goto_definition<CR>")
vim.keymap.set("n", "gR", "<cmd>Lspsaga peek_definition<CR>")
vim.keymap.set("n", "<leader>ca", "<cmd>Lspsaga code_action<CR>")
