return {
  "akinsho/toggleterm.nvim",
  version = "*",
  opts = {
    size = function(term)
      if term.direction == "horizontal" then
        return 25
      elseif term.direction == "vertical" then
        return vim.o.columns * 0.4
      else
        return 20
      end
    end,

    open_mapping = [[<c-;>]],
    start_in_insert = true,
    shade_terminals = true,
    shading_factor = 2,
    direction = "horizontal",
  },
}
