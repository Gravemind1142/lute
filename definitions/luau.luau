local luau = {}

export type Position = {
	line: number,
	column: number,
}

export type Location = {
	begin: Position,
	["end"]: Position, -- TODO: do we really want to have to use brackets everywhere?
}

export type Whitespace = {
	tag: "whitespace",
	location: Location,
	text: string,
}

export type SingleLineComment = {
	tag: "comment",
	location: Location,
	text: string,
}

export type MultiLineComment = {
	tag: "blockcomment",
	location: Location,
	text: string,
	-- TODO: depth: number,
}

export type Trivia = Whitespace | SingleLineComment | MultiLineComment

export type Token<Kind = string> = {
	leadingtrivia: { Trivia },
	position: Position,
	text: Kind,
	trailingtrivia: { Trivia },
	kind: "token",
}

export type Eof = Token<""> & { tag: "eof" }

export type Pair<T, Separator> = { node: T, separator: Token<Separator>? }
export type Punctuated<T, Separator = ","> = { Pair<T, Separator> }

export type NodeKind = "local" | "expr" | "stat" | "type" | "typepack" | "token"

export type AstLocal = {
	name: Token<string>,
	colon: Token<":">?,
	annotation: AstType?,
	shadows: AstLocal?,
	kind: "local",
}

export type AstExprGroup = {
	tag: "group",
	openparens: Token<"(">,
	expression: AstExpr,
	closeparens: Token<")">,
	kind: "expr",
}

export type AstExprConstantNil = Token<"nil"> & { tag: "nil", kind: "expr" }

export type AstExprConstantBool = Token<"true" | "false"> & { tag: "boolean", value: boolean, kind: "expr" }

export type AstExprConstantNumber = Token<string> & { tag: "number", value: number, kind: "expr" }

export type AstExprConstantString = Token<string> & {
	tag: "string",
	quotestyle: "single" | "double" | "block" | "interp",
	blockdepth: number,
	kind: "expr",
}

export type AstExprLocal = {
	tag: "local",
	token: Token<string>,
	["local"]: AstLocal,
	upvalue: boolean,
	kind: "expr",
}

export type AstExprGlobal = {
	tag: "global",
	name: Token,
	kind: "expr",
}

export type AstExprVarargs = Token<"..."> & { tag: "vararg", kind: "expr" }

export type AstExprCall = {
	tag: "call",
	func: AstExpr,
	openparens: Token<"(">?,
	arguments: Punctuated<AstExpr>,
	closeparens: Token<")">?,
	self: boolean,
	argLocation: Location,
	kind: "expr",
}

export type AstExprIndexName = {
	tag: "indexname",
	expression: AstExpr,
	accessor: Token<"." | ":">,
	index: Token<string>,
	indexlocation: Location,
	kind: "expr",
}

export type AstExprIndexExpr = {
	tag: "index",
	expression: AstExpr,
	openbrackets: Token<"[">,
	index: AstExpr,
	closebrackets: Token<"]">,
	kind: "expr",
}

-- I don't like that we have this type; a lot of its data should live in the parents, which should then have `AstStatBlock` as its body
export type AstFunctionBody = {
	opengenerics: Token<"<">?,
	generics: Punctuated<AstGenericType>?,
	genericpacks: Punctuated<AstGenericTypePack>?,
	closegenerics: Token<">">?,
	self: AstLocal?,
	openparens: Token<"(">,
	parameters: Punctuated<AstLocal>,
	vararg: Token<"...">?,
	varargcolon: Token<":">?,
	varargannotation: AstTypePack?,
	closeparens: Token<")">,
	returnspecifier: Token<":">?,
	returnannotation: AstTypePack?,
	body: AstStatBlock,
	endkeyword: Token<"end">,
}

export type AstExprAnonymousFunction = {
	tag: "function",
	attributes: { AstAttribute },
	functionkeyword: Token<"function">,
	body: AstFunctionBody,
	kind: "expr",
}

export type AstExprTableItem =
	| { itemkind: "list", value: AstExpr, separator: Token<"," | ";">? }
	| {
		itemkind: "record",
		key: Token<string>,
		equals: Token<"=">,
		value: AstExpr,
		separator: Token<"," | ";">?,
	}
	| {
		itemkind: "general",
		indexeropen: Token<"[">,
		key: AstExpr,
		indexerclose: Token<"]">,
		equals: Token<"=">,
		value: AstExpr,
		separator: Token<"," | ";">?,
	}

export type AstExprTable = {
	tag: "table",
	openbrace: Token<"{">,
	entries: { AstExprTableItem },
	closebrace: Token<"}">,
	kind: "expr",
}

export type AstExprUnary = {
	tag: "unary",
	operator: Token<"not" | "-" | "#">,
	operand: AstExpr,
	kind: "expr",
}

export type AstExprBinary = {
	tag: "binary",
	lhsoperand: AstExpr,
	operator: Token, -- TODO: enforce token type
	rhsoperand: AstExpr,
	kind: "expr",
}

export type AstExprInterpString = {
	tag: "interpolatedstring",
	strings: { Token<string> },
	expressions: { AstExpr },
	kind: "expr",
}

export type AstExprTypeAssertion = {
	tag: "cast",
	operand: AstExpr,
	operator: Token<"::">,
	annotation: AstType,
	kind: "expr",
}

export type AstExprIfElseIfs = {
	elseifkeyword: Token<"elseif">,
	condition: AstExpr,
	thenkeyword: Token<"then">,
	consequent: AstExpr,
}

export type AstExprIfElse = {
	tag: "conditional",
	ifkeyword: Token<"if">,
	condition: AstExpr,
	thenkeyword: Token<"then">,
	consequent: AstExpr,
	elseifs: { AstExprIfElseIfs },
	elsekeyword: Token<"else">,
	antecedent: AstExpr,
	kind: "expr",
}

export type AstExpr =
	| AstExprGroup
	| AstExprConstantNil
	| AstExprConstantBool
	| AstExprConstantNumber
	| AstExprConstantString
	| AstExprLocal
	| AstExprGlobal
	| AstExprVarargs
	| AstExprCall
	| AstExprIndexName
	| AstExprIndexExpr
	| AstExprAnonymousFunction
	| AstExprTable
	| AstExprUnary
	| AstExprBinary
	| AstExprInterpString
	| AstExprTypeAssertion
	| AstExprIfElse

export type AstStatBlock = {
	tag: "block",
	statements: { AstStat },
	kind: "stat",
}

export type AstStatElseIf = {
	elseifkeyword: Token<"elseif">,
	condition: AstExpr,
	thenkeyword: Token<"then">,
	consequent: AstStatBlock,
}

export type AstStatIf = {
	tag: "conditional",
	ifkeyword: Token<"if">,
	condition: AstExpr,
	thenkeyword: Token<"then">,
	consequent: AstStatBlock,
	elseifs: { AstStatElseIf },
	elsekeyword: Token<"else">?, -- TODO: this could be elseif!
	antecedent: AstStatBlock?,
	endkeyword: Token<"end">,
	kind: "stat",
}

export type AstStatWhile = {
	tag: "while",
	whilekeyword: Token<"while">,
	condition: AstExpr,
	dokeyword: Token<"do">,
	body: AstStatBlock,
	endkeyword: Token<"end">,
	kind: "stat",
}

export type AstStatRepeat = {
	tag: "repeat",
	repeatKeyword: Token<"repeat">,
	body: AstStatBlock,
	untilKeyword: Token<"until">,
	condition: AstExpr,
	kind: "stat",
}

export type AstStatBreak = Token<"break"> & { tag: "break", kind: "stat" }

export type AstStatContinue = Token<"continue"> & { tag: "continue", kind: "stat" }

export type AstStatReturn = {
	tag: "return",
	returnkeyword: Token<"return">,
	expressions: Punctuated<AstExpr>,
	kind: "stat",
}

export type AstStatExpr = {
	tag: "expression",
	expression: AstExpr,
	kind: "stat",
}

export type AstStatLocal = {
	tag: "local",
	localkeyword: Token<"local">,
	variables: Punctuated<AstLocal>,
	equals: Token<"=">?,
	values: Punctuated<AstExpr>,
	kind: "stat",
}

export type AstStatFor = {
	tag: "for",
	forkeyword: Token<"for">,
	variable: AstLocal,
	equals: Token<"=">,
	from: AstExpr,
	tocomma: Token<",">,
	to: AstExpr,
	stepcomma: Token<",">?,
	step: AstExpr?,
	dokeyword: Token<"do">,
	body: AstStatBlock,
	endkeyword: Token<"end">,
	kind: "stat",
}

export type AstStatForIn = {
	tag: "forin",
	forkeyword: Token<"for">,
	variables: Punctuated<AstLocal>,
	inkeyword: Token<"in">,
	values: Punctuated<AstExpr>,
	dokeyword: Token<"do">,
	body: AstStatBlock,
	endkeyword: Token<"end">,
	kind: "stat",
}

export type AstStatAssign = {
	tag: "assign",
	variables: Punctuated<AstExpr>,
	equals: Token<"=">,
	values: Punctuated<AstExpr>,
	kind: "stat",
}

export type AstStatCompoundAssign = {
	tag: "compoundassign",
	variable: AstExpr,
	operand: Token, -- TODO: enforce token type,
	value: AstExpr,
	kind: "stat",
}

export type AstAttribute = Token<"@checked" | "@native" | "@deprecated"> & { tag: "attribute" }

export type AstStatFunction = {
	tag: "function",
	attributes: { AstAttribute },
	functionkeyword: Token<"function">,
	name: AstExpr,
	body: AstFunctionBody,
	kind: "stat",
}

export type AstStatLocalFunction = {
	tag: "localfunction",
	attributes: { AstAttribute },
	localkeyword: Token<"local">,
	functionkeyword: Token<"function">,
	name: AstLocal,
	body: AstFunctionBody,
	kind: "stat",
}

export type AstStatTypeAlias = {
	tag: "typealias",
	export: Token<"export">?,
	typeToken: Token<"type">,
	name: Token,
	opengenerics: Token<"<">?,
	generics: Punctuated<AstGenericType>?,
	genericpacks: Punctuated<AstGenericTypePack>?,
	closegenerics: Token<">">?,
	equals: Token<"=">,
	type: AstType,
	kind: "stat",
}

export type AstStatTypeFunction = {
	tag: "typefunction",
	export: Token<"export">?,
	type: Token<"type">,
	functionkeyword: Token<"function">,
	name: Token,
	body: AstFunctionBody,
	kind: "stat",
}

export type AstStat =
	| AstStatBlock
	| AstStatIf
	| AstStatWhile
	| AstStatRepeat
	| AstStatBreak
	| AstStatContinue
	| AstStatReturn
	| AstStatExpr
	| AstStatLocal
	| AstStatFor
	| AstStatForIn
	| AstStatAssign
	| AstStatCompoundAssign
	| AstStatFunction
	| AstStatLocalFunction
	| AstStatTypeAlias
	| AstStatTypeFunction

export type AstGenericType = {
	tag: "generic",
	name: Token<string>,
	equals: Token<"=">?,
	default: AstType?,
	kind: "type",
}

export type AstGenericTypePack = {
	tag: "genericpack",
	name: Token<string>,
	ellipsis: Token<"...">,
	equals: Token<"=">?,
	default: AstTypePack?,
	kind: "typepack",
}

export type AstTypeReference = {
	tag: "reference",
	prefix: Token<string>?,
	prefixpoint: Token<".">?,
	name: Token<string>,
	openparameters: Token<"<">?,
	parameters: Punctuated<AstType | AstTypePack>?,
	closeparameters: Token<">">?,
	kind: "type",
}

export type AstTypeSingletonBool = Token<"true" | "false"> & {
	tag: "boolean",
	value: boolean,
	kind: "type",
}

export type AstTypeSingletonString = Token<string> & {
	tag: "string",
	quotestyle: "single" | "double",
	kind: "type",
}

export type AstTypeTypeof = {
	tag: "typeof",
	typeof: Token<"typeof">,
	openparens: Token<"(">,
	expression: AstExpr,
	closeparens: Token<")">,
	kind: "type",
}

export type AstTypeGroup = {
	tag: "group",
	openparens: Token<"(">,
	type: AstType,
	closeparens: Token<">">,
	kind: "type",
}

export type AstTypeOptional = Token<"?"> & { tag: "optional", kind: "type" }

export type AstTypeUnion = {
	tag: "union",
	leading: Token<"|">?,
	-- Separator may be nil for AstTypeOptional
	types: Punctuated<AstType, "|">,
	kind: "type",
}

export type AstTypeIntersection = {
	tag: "intersection",
	leading: Token<"&">?,
	types: Punctuated<AstType, "&">,
	kind: "type",
}

export type AstTypeArray = {
	tag: "array",
	openbrace: Token<"{">,
	access: Token<"read" | "write">?,
	type: AstType,
	closebrace: Token<"}">,
	kind: "type",
}

export type AstTypeTableItem =
	{
		kind: "indexer",
		access: Token<"read" | "write">?,
		indexeropen: Token<"[">,
		key: AstType,
		indexerclose: Token<"]">,
		colon: Token<":">,
		value: AstType,
		separator: Token<"," | ";">?,
	}
	| {
		kind: "stringproperty",
		access: Token<"read" | "write">?,
		indexeropen: Token<"[">,
		key: AstTypeSingletonString,
		indexerclose: Token<"]">,
		colon: Token<":">,
		value: AstType,
		separator: Token<"," | ";">?,
	}
	| {
		kind: "property",
		access: Token<"read" | "write">?,
		key: AstTypeSingletonString,
		indexerclose: Token<"]">,
		colon: Token<":">,
		value: AstType,
		separator: Token<"," | ";">?,
	}

export type AstTypeTable = {
	tag: "table",
	openbrace: Token<"{">,
	entries: { AstTypeTableItem },
	closebrace: Token<"}">,
	kind: "type",
}

export type AstTypeFunctionParameter = {
	name: Token?,
	colon: Token<":">?,
	type: AstType,
}

export type AstTypeFunction = {
	tag: "function",
	opengenerics: Token<"<">?,
	generics: Punctuated<AstGenericType>?,
	genericpacks: Punctuated<AstGenericTypePack>?,
	closegenerics: Token<">">?,
	openparens: Token<"(">,
	parameters: Punctuated<AstTypeFunctionParameter>,
	vararg: AstTypePack?,
	closeparens: Token<")">,
	returnarrow: Token<"->">,
	returntypes: AstTypePack,
	kind: "type",
}

export type AstType =
	| AstTypeReference
	| AstTypeSingletonBool
	| AstTypeSingletonString
	| AstTypeTypeof
	| AstTypeGroup
	| AstTypeUnion
	| AstTypeIntersection
	| AstTypeOptional
	| AstTypeArray
	| AstTypeTable
	| AstTypeFunction

export type AstTypePackExplicit = {
	tag: "explicit",
	openparens: Token<"(">?,
	types: Punctuated<AstType>,
	tailtype: AstTypePack?,
	closeparens: Token<")">?,
	kind: "typepack",
}

export type AstTypePackGeneric = {
	tag: "generic",
	name: Token,
	ellipsis: Token<"...">,
	kind: "typepack",
}

export type AstTypePackVariadic = {
	tag: "variadic",
	--- May be nil when present as the vararg annotation in a function body
	ellipsis: Token<"...">?,
	type: AstType,
	kind: "typepack",
}

export type AstTypePack = AstTypePackExplicit | AstTypePackGeneric | AstTypePackVariadic

export type AstNode = AstLocal | AstExpr | AstStat | AstType | AstTypePack | Token

export type ParseResult = {
	root: AstStatBlock,
	eof: Eof,
	lines: number,
	lineoffsets: { number },
}

function luau.parse(source: string): ParseResult
	error("not implemented")
end

function luau.parseexpr(source: string): AstExpr
	error("not implemented")
end

export type Bytecode = { bytecode: string }

function luau.compile(source: string): Bytecode
	error("not implemented")
end

function luau.load(bytecode: Bytecode, chunkname: string, env: { [any]: any }?): (...any) -> ...any
	error("not implemented")
end

return luau
