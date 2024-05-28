-- Utility functions for {{Tracked in}}, which is a template that displays a link to open source software bug reports and feature requests on Wikipedia talk pages.

local p = {}

-- {{#invoke:Tracked in|getDomain|{{{1|}}}}}
function p.getDomain(frame)
	local url = frame.args[1]
	local domain = string.gsub(url, "www%.", "")
	domain = string.match(domain, 'https?:%/%/(.-)%/.*$')
	return domain
end

-- {{#invoke:Tracked in|getIssueNumber|{{{1|}}}}}
function p.getIssueNumber(frame)
	local url = frame.args[1]
	local issueNumber = string.match(url, '(%d+)/?$')
	if tonumber(issueNumber) == nil then
		return "ERROR: Issue number not found"
	else
		return "Issue &#35;" .. issueNumber -- add a # sign in front of the number. can't use #, that creates a numbered list
	end
end

return p