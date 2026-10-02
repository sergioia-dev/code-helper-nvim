-- User commands for the code-helper.nvim helpers.
--
-- This file lives in `plugin/`, so Neovim sources it automatically from the
-- packpath — nothing under configuration/ has to require the plugin.

local api = vim.api

--- Run a `lua/code_helper` transform over the selected lines and replace them
--- with its output.
--- @param opts table command options ({ line1, line2 })
--- @param method string name of the transform on the code_helper module
--- @param joiner string how the selected lines are joined ("" or "\n")
--- @param label string prefix used when the transform fails
local function convert_range(opts, method, joiner, label)
	local lines = api.nvim_buf_get_lines(0, opts.line1 - 1, opts.line2, false)
	local out, err = require("code_helper")[method](table.concat(lines, joiner))
	if not out then
		api.nvim_err_writeln(label .. " failed: " .. (err or "unknown error"))
		return
	end
	api.nvim_buf_set_lines(0, opts.line1 - 1, opts.line2, false, { out })
end

local conversions = {
	{
		name = "ConBase64Encode",
		method = "encode",
		joiner = "",
		desc = "Base64-encode the selected lines",
		label = "base64 encode",
	},
	{
		name = "ConBase64Decode",
		method = "decode",
		joiner = "",
		desc = "Base64-decode the selected lines",
		label = "base64 decode",
	},
	{
		name = "ConURLEncode",
		method = "url_encode",
		joiner = "\n",
		desc = "Percent-encode the selected lines",
		label = "url encode",
	},
	{
		name = "ConURLDecode",
		method = "url_decode",
		joiner = "\n",
		desc = "Decode the percent-encoded selected lines",
		label = "url decode",
	},
}

for _, conversion in ipairs(conversions) do
	api.nvim_create_user_command(conversion.name, function(opts)
		convert_range(opts, conversion.method, conversion.joiner, conversion.label)
	end, { range = true, desc = conversion.desc })
end

api.nvim_create_user_command("GenSecret", function()
	local secret, err = require("code_helper").secret()
	if not secret then
		vim.notify("Failed to run entropy command: " .. (err or "unknown error"), vim.log.levels.ERROR)
		return
	end
	api.nvim_put({ secret }, "l", true, true)
end, { desc = "Insert a URL-safe JWT secret" })
