--- String conversions behind the `:Con*` user commands: base64 (standard and
--- URL-safe) and URL/percent encoding, plus a URL-safe JWT secret generator.
---
--- Every function here is a pure string transform — reading and writing the
--- buffer happens in `plugin/code_helper.lua` — so they can be called directly:
---
--- ```lua
--- local helper = require("code_helper")
--- helper.decode(helper.encode("hello")) --> "hello"
--- ```
---
--- The base64 helpers shell out to the coreutils `base64` binary, so it has to
--- be on `PATH`. Failures come back as `nil, stderr` instead of throwing.
local M = {}

--- Remove every whitespace character from `input`, so a multi-line selection or
--- a wrapped payload can be handed to the base64 helpers as a single token.
--- @param input string
--- @return string
local function squeeze(input)
	return (input:gsub("%s+", ""))
end

--- Base64-encode `input`, ignoring whitespace, as a single line.
--- @param input string
--- @return string|nil encoded
--- @return string|nil error stderr of the encoder when it failed
function M.encode(input)
	local out = vim.fn.system({ "base64", "-w", "0" }, squeeze(input))
	if vim.v.shell_error ~= 0 then
		return nil, vim.trim(out)
	end
	return (out:gsub("\n$", "")), nil
end

--- Base64-decode `input`. Whitespace is ignored, both the standard (`+`, `/`)
--- and the URL-safe (`-`, `_`) alphabets are accepted, and missing padding is
--- added.
--- @param input string
--- @return string|nil decoded
--- @return string|nil error stderr of the decoder when it failed
function M.decode(input)
	local data = squeeze(input):gsub("-", "+"):gsub("_", "/")
	data = data .. string.rep("=", (4 - #data % 4) % 4)

	-- GNU coreutils decodes with -d, BSD/macOS with -D.
	local flag = vim.fn.has("mac") == 1 and "-D" or "-d"
	local out = vim.fn.system({ "base64", flag }, data)
	if vim.v.shell_error ~= 0 then
		return nil, vim.trim(out)
	end
	return (out:gsub("\n$", "")), nil
end

--- Percent-encode `input` (RFC 3986): unreserved characters are kept as they
--- are, everything else becomes `%XX`. Line breaks become `%0A`.
--- @param input string
--- @return string
function M.url_encode(input)
	return (input:gsub("([^%w%-_.~])", function(c)
		return string.format("%%%02X", string.byte(c))
	end))
end

--- Decode a percent-encoded string: `+` becomes a space and every `%XX`
--- becomes its byte.
--- @param input string
--- @return string
function M.url_decode(input)
	return (input:gsub("+", " "):gsub("%%(%x%x)", function(hex)
		return string.char(tonumber(hex, 16))
	end))
end

--- Generate a URL-safe JWT secret: 48 random bytes, base64, without padding.
--- @return string|nil secret
--- @return string|nil error when /dev/urandom could not be read
function M.secret()
	local pipe = io.popen("head -c 48 /dev/urandom | base64 | tr -d '=\\n' | tr '+/' '-_'")
	if not pipe then
		return nil, "could not read /dev/urandom"
	end
	local secret = pipe:read("*a")
	pipe:close()
	return vim.trim(secret), nil
end

return M
