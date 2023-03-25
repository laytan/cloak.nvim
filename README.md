# Cloak.nvim

Cloak allows you to overlay *'s (or any other character) over defined patterns in defined files.

It also disables 'cmp' for the buffer(if it is installed).

## Demo

![Demo](https://user-images.githubusercontent.com/20369598/187440609-4cfce257-a4c2-4036-8ad7-3f3bb583e994.gif)

## Configuration

Here is the default configuration.

- `file_pattern` can be a string or table of strings, they should be valid autocommand patterns.
- `cloak_pattern` is a lua pattern ran over every line in the buffer,
overlaying `cloak_character` over the match, excluding the first character.

```lua
require('cloak').setup({
  enabled = true,
  cloak_character = '*',
  -- The applied highlight group (colors) on the cloaking, see `:h highlight`.
  highlight_group = 'Comment',
  -- Applies the length of the replacement characters for all matched
  -- patterns, defaults to the length of the matched pattern.
  cloak_length = nil, -- Provide a number if you want to hide the true length of the value. 
  patterns = {
    {
      -- Match any file starting with '.env'.
      -- This can be a table to match multiple file patterns.
      file_pattern = '.env*',
      -- Match an equals sign and any character after it.
      -- This can also be a table of patterns to cloak,
      -- example: cloak_pattern = { ':.+', '-.+' } for yaml files.
      cloak_pattern = '=.+'
    },
  },
})
```

## Usage

The plugin automatically activates when a file matched by the patterns is opened.

You do have to call the 'setup()' function.

':CloakDisable', ':CloakEnable' and ':CloakToggle' are also available to toggle cloaking.
