-- if Neovim 0.9+, use vim.loade speedup module loading
if vim.loader then 
  vim.loader.enable()
end

-- all use dump print
_G.dd = function(...)
  require("util.debug").dump(...)
end
vim.print = _G.dd

-- use plugin
require("config.lazy")
