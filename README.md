# Cloak.nvim

Cloak allows you to overlay *'s over defined patterns in defined files.

It also disabled 'cmp' for the buffer(if it is installed).

## Demo

![Demo](https://user-images.githubusercontent.com/20369598/187440609-4cfce257-a4c2-4036-8ad7-3f3bb583e994.gif)

## Configuration

Here is the default configuration.

'file_pattern' can be a string or table of strings, they should be valid autocommand patterns.
'cloak_pattern' is a lua pattern ran over every line in the buffer, overlaying a * over the match, excluding the first character.

```lua
require('cloak').setup({
  enabled = true,
  patterns = {
    {
      -- Match any file starting with '.env'.
      file_pattern = '.env*',
      -- Match an equals sign and any character after it.
      cloak_pattern = '=.+'
    },
  },
})
```

## Usage

The plugin automatically activates when a file matched by the patterns is opened.

You do have to call the 'setup()' function.

':CloakDisable' and ':CloakEnable' are also available to toggle cloaking.
