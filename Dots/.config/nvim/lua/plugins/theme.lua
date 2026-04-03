return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    opts = {
      transparent_background = true,
      custom_highlights = function(colors)
        return {
          -- Основной номер текущей строки (сделай его ярко-розовым)
          CursorLineNr = { fg = "#ff78c5", style = { "bold" } },

          -- Все остальные номера строк (сделаем их светло-серыми или белыми)
          -- Замени "colors.overlay1" на "#ffffff", если хочешь идеально белый
          LineNr = { fg = colors.overlay2 },

          -- Вертикальная полоса-разделитель (если она мешает, можно убрать)
          WinSeparator = { fg = colors.surface2 },
        }
      end,
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin-mocha",
    },
  },
}
