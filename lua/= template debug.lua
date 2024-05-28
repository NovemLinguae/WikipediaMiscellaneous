local p = {}

-- {{#invoke:yourModule|yourFunction|{{{1|}}}}}
function p.yourFunction(frame)
	local yourInput = frame.args[1]
	return yourInput
end

-- return p

if not mw then
	mw = {
		['text'] = {
			-- here come the 2 or 3 i actually use, e.g mw.text.trim
		},
		-- etc. etc.
	}
end

frame = {args = {'yourInput'}}
print(p.yourFunction(frame))

-- https://en.wikipedia.org/wiki/Special:TemplateSandbox
-- https://en.wikipedia.org/wiki/Module:Sandbox/Novem_Linguae
-- https://www.mediawiki.org/wiki/Extension:Scribunto/Lua_reference_manual - list of internal functions
-- https://gitspartv.github.io/lua-patterns/ - RegEx viewer
-- ZeroBrane Studio - step debugger