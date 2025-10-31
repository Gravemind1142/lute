--!strict
local test = require("@std/test")

type MyType = {
	prop: string,
	value: number,
}

local function someOptionalCall(): MyType?
	-- Simulate a function that might return nil
	if math.random() > 0.5 then
		return { prop = "hello", value = 42 }
	else
		return nil
	end
end

test.case("smart assertion example", function(assert)
	local x = someOptionalCall() -- x has type MyType?
	-- assert.nonil returns the value with nil stripped from the type
	-- After this line, x2 has type MyType (not MyType?)
	assert.neq(x, nil)
	local x2 = assert.nonnil(nil)
	-- Now we can safely access properties without type errors
	assert.eq(x2.prop, "hello")
	assert.eq(x2.value, 42)

	-- This demonstrates the type refinement in action
	print(`Property: {x2.prop}, Value: {x2.value}`)
end)

test.run()
