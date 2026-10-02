# code-helper.nvim

Small conversion helpers for Neovim: base64 (standard and URL-safe), URL
percent-encoding, and a URL-safe JWT secret generator. No picker, no completion
backend, no dependencies beyond the coreutils binaries `base64`, `head` and
`tr`.

## Commands

| Command            | Range | What it does                                                          |
| ------------------ | ----- | --------------------------------------------------------------------- |
| `:ConBase64Encode` | yes   | Replaces the selection with its base64 encoding (whitespace ignored).  |
| `:ConBase64Decode` | yes   | Decodes base64 — `+`/`/` and `-`/`_` alphabets, padding optional.      |
| `:ConURLEncode`    | yes   | Percent-encodes the selection; line breaks become `%0A`.               |
| `:ConURLDecode`    | yes   | Decodes percent-encoding; `+` becomes a space.                        |
| `:GenSecret`       | no    | Inserts a 48-byte URL-safe JWT secret below the cursor.                |

Every conversion command takes a range, so select lines in visual mode and run
`:ConBase64Encode`, or pass a range explicitly (`:%ConURLDecode`). Without a
range they act on the current line.

## Install

In this repo the plugin is shipped as `vimPlugins.code-helper-nvim` and linked
into the packpath, so `plugin/code_helper.lua` registers the commands at
startup — no `require` from `configuration/` is needed.

With `lazy.nvim`:

```lua
{
  "sergioia-dev/code-helper-nvim",
  cmd = {
    "ConBase64Encode",
    "ConBase64Decode",
    "ConURLEncode",
    "ConURLDecode",
    "GenSecret",
  },
}
```

## API

Buffer handling lives in `plugin/code_helper.lua`; the transforms are pure
string functions in `lua/code_helper/init.lua`, so they can be called from
anywhere:

```lua
local helper = require("code_helper")

helper.encode("hello")      --> "aGVsbG8="
helper.decode("aGVsbG8=")   --> "hello"
helper.decode("aGVsbG8")    --> "hello"   -- padding is added when missing
helper.decode("++8=")     --> "\xFB\xEF" -- url-safe -/_ alphabet accepted
helper.url_encode("a b")    --> "a%20b"
helper.url_decode("a%20b")  --> "a b"
helper.secret()             --> 48 random bytes as url-safe, unpadded base64

local plain, err = helper.decode("not base64!")  -- plain == nil, err == stderr
```

The base64 helpers shell out to `base64`: `encode` relies on GNU coreutils
(`-w 0`), `decode` picks `-D` on macOS and `-d` everywhere else. Failures are
returned as `nil, error` rather than thrown.
