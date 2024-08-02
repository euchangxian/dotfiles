-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- Function to insert C++ template
local function insert_cpp_template()
  local file_path = vim.fn.expand("~/.config/nvim/templates/cpp_template.cpp")
  local lines = vim.fn.readfile(file_path)
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
end

-- Create an autocommand for new C++ files
vim.api.nvim_create_autocmd("BufNewFile", {
  pattern = "*.cpp",
  callback = insert_cpp_template,
})
