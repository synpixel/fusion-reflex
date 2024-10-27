local fusionTypes = require(script.Parent.fusionTypes)
local reflexTypes = require(script.Parent.reflexTypes)

local function Selector<State, Result>(
	scope: fusionTypes.Scope<
		fusionTypes.Fusion & { Producer: reflexTypes.Producer<State, {}> }
	>,
	selector: (state: State) -> Result,
	equalityFn: ((next: Result, prev: Result) -> boolean)?
): fusionTypes.StateObject<Result>
	local prevResult = selector(scope.Producer:getState())
	local result = scope:Value(prevResult)

	local disconnect = scope.Producer:subscribe(function(nextState)
		local nextResult = selector(nextState)
		local shouldUpdate = if equalityFn ~= nil
			then not equalityFn(nextResult, prevResult)
			else nextResult ~= prevResult

		if shouldUpdate then
			prevResult = nextResult
			result:set(nextResult)
		end
	end)

	table.insert(scope, disconnect)

	return result
end

return Selector
