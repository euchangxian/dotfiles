local function paste_template(template_name)
  local template_path = vim.fn.stdpath("config") .. "/templates/" .. template_name
  local file, err = io.open(template_path, "r")
  if file then
    local content = file:read("*all")
    file:close()
    local lines = vim.fn.split(content, "\n")
    vim.api.nvim_put(lines, "l", true, true)
  else
    vim.notify("Failed to load template: " .. template_name .. ". Error: " .. err, vim.log.levels.ERROR)
  end
end

vim.keymap.set("n", "<leader>td", function()
  paste_template("Directions.cpp")
end, { desc = "Paste Directions template" })

vim.keymap.set("n", "<leader>tu", function()
  paste_template("UnionFind.cpp")
end, { desc = "Paste Union Find template" })

vim.keymap.set("n", "<leader>tq", function()
  paste_template("CircularQueue.cpp")
end, { desc = "Paste Circular Queue template" })

vim.keymap.set("n", "<leader>tf", function()
  paste_template("FenwickTree.cpp")
end, { desc = "Paste Fenwick Tree template" })

vim.keymap.set("n", "<leader>ts", function()
  paste_template("SegmentTree.cpp")
end, { desc = "Paste Segment Tree template" })

vim.keymap.set("n", "<leader>tm", function()
  paste_template("MaxFlow.cpp")
end, { desc = "Paste Max Flow template" })
