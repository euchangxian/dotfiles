return {
  "neovim/nvim-lspconfig",
  opts = function()
    local keys = require("lazyvim.plugins.lsp.keymaps").get()

    -- disable a keymap
    keys[#keys + 1] = { "<C-k>", false, mode = "i" }
  end,
}
