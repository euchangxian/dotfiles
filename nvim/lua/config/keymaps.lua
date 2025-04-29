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

vim.keymap.set("n", "<leader>tD", function()
  paste_template("Debug.cpp")
end, { desc = "Paste Debugging template" })

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
  paste_template("ModNum.cpp")
end, { desc = "Paste Mod Num template" })

vim.keymap.set("n", "<leader>tM", function()
  paste_template("MaxFlow.cpp")
end, { desc = "Paste Max Flow template" })

vim.keymap.set("n", "<leader>tMM", function()
  paste_template("Matrix.cpp")
end, { desc = "Paste Matrix template" })

vim.keymap.set("n", "<leader>tH", function()
  paste_template("Hungarian.cpp")
end, { desc = "Paste Hungarian Weighted Matching template" })

vim.keymap.set("n", "<leader>tr", function()
  paste_template("RadixSort.cpp")
end, { desc = "Paste Radix/Counting Sort template" })

vim.keymap.set("n", "<leader>ts", function()
  paste_template("SCC.cpp")
end, { desc = "Paste Tarjan SCC template" })

vim.keymap.set("n", "<leader>tS", function()
  paste_template("SuffixArray.cpp")
end, { desc = "Paste Suffix Array template" })

vim.keymap.set("n", "<leader>tB", function()
  paste_template("MCBM.cpp")
end, { desc = "Paste MCBM template" })

vim.keymap.set("n", "<leader>tI", function()
  paste_template("IndependentSet.cpp")
end, { desc = "Paste IndependentSet template" })

vim.keymap.set("n", "<leader>tC", function()
  paste_template("MaxClique.cpp")
end, { desc = "Paste MaxClique template" })
