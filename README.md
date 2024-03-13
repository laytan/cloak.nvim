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
- `replace` is a pattern with which to replace the matched `cloak_pattern`
  (see [https://www.lua.org/manual/5.1/manual.html#pdf-string.gsub]).
  If the replaced text is not long enough the rest gets filled up with the cloak_character.
  This is useful to only hide certain keys but still show the name.

```lua
require('cloak').setup({
  enabled = true,
  cloak_character = '*',
  -- The applied highlight group (colors) on the cloaking, see `:h highlight`.
  highlight_group = 'Comment',
  -- Applies the length of the replacement characters for all matched
  -- patterns, defaults to the length of the matched pattern.
  cloak_length = nil, -- Provide a number if you want to hide the true length of the value.
  -- Whether it should try every pattern to find the best fit or stop after the first.
  try_all_patterns = true,
  -- Set to true to cloak Telescope preview buffers. (Required feature not in 0.1.x)
  cloak_telescope = true,
  patterns = {
    {
      -- Match any file starting with '.env'.
      -- This can be a table to match multiple file patterns.
      file_pattern = '.env*',
      -- Match an equals sign and any character after it.
      -- This can also be a table of patterns to cloak,
      -- example: cloak_pattern = { ':.+', '-.+' } for yaml files.
      cloak_pattern = '=.+',
      -- A function, table or string to generate the replacement.
      -- The actual replacement will contain the 'cloak_character'
      -- where it doesn't cover the original text.
      -- If left empty the legacy behavior of keeping the first character is retained.
      replace = nil,
    },
  },
})
```

The `cloak_pattern` can also be a table of `inner_pattern`s:
```lua
patterns = {
  file_pattern = '.env*',
  cloak_pattern = {
    '(a=).+',
    { '(b=).+' },
    { '(c=).+', replace = '[inner] %1' }
    -- The outer `replace` could also be specified here instead
  },
  replace = '[outer] %1',
}
```
This would result in a cloaking of text like this:
```env
[outer] a=**
b***********
[inner] c=**
```
The original file was:
```env
a=1234567890
b=1234567890
c=1234567890
```

## Usage

The plugin automatically activates when a file matched by the patterns is opened.

You do have to call the `setup()` function.

`:CloakDisable`, `:CloakEnable` and `:CloakToggle` are also available to change cloaking state.
