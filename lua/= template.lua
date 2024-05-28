local p = {}

-- {{#invoke:yourModule|yourFunction|{{{1|}}}}}
function p.yourFunction(frame)
    local yourInput = frame.args[1]
    return yourInput
end

return p