local test = require("@std/test")
local query = require("@std/syntax/query")
local luau = require("@std/luau")

local function mockQuery<T>(nodes: { T }): query.query<T>
	return {
		nodes = nodes,
		filter = query.filter,
		replace = query.replace,
	}
end

-- Helper function to create mock number expressions
local function createNumberExpr(value: number): luau.AstExprConstantNumber
	return {
		tag = "number",
		kind = "expr",
		value = value,
		text = tostring(value),
		position = { line = 1, column = 1 },
		leadingtrivia = {},
		trailingtrivia = {},
	} :: any
end

test.suite("AST Query", function(suite)
	suite:case("filter", function(assert)
		local testQuery = mockQuery({
			createNumberExpr(-2),
			createNumberExpr(-1),
			createNumberExpr(0),
			createNumberExpr(1),
			createNumberExpr(2),
		})

		local filteredQuery = testQuery:filter(function(n)
			return n.value > 0
		end)

		assert.eq(#filteredQuery.nodes, 2)
		assert.eq(filteredQuery.nodes[1].value, 1)
		assert.eq(filteredQuery.nodes[2].value, 2)
		assert.eq(filteredQuery, testQuery) -- ensure the original query is mutated
	end)

	suite:case("replace", function(assert)
		local testQuery = mockQuery({
			createNumberExpr(-2),
			createNumberExpr(-1),
			createNumberExpr(0),
			createNumberExpr(1),
			createNumberExpr(2),
		})

		local replacements = testQuery:replace(function(n)
			if n.value > 0 then
				return "positive_" .. tostring(n.value)
			end
			return nil -- return nil for non-positive numbers
		end)

		-- Should only have replacements for positive numbers
		assert.eq(replacements[testQuery.nodes[4]], "positive_1")
		assert.eq(replacements[testQuery.nodes[5]], "positive_2")

		-- Non-positive numbers should not have replacements (nil values)
		assert.eq(replacements[testQuery.nodes[1]], nil)
		assert.eq(replacements[testQuery.nodes[2]], nil)
		assert.eq(replacements[testQuery.nodes[3]], nil)

		-- Verify the replacement table only contains the expected entries
		local count = 0
		for _, _ in pairs(replacements) do
			count = count + 1
		end
		assert.eq(count, 2) -- Only 2 non-nil replacements
	end)
end)

test.run()
