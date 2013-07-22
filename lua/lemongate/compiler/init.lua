/*==============================================================================================
	Expression Advanced: Compiler -> Init.
	Purpose: The core of the compiler.
	Creditors: Rusketh, Oskar94
==============================================================================================*/
local LEMON = LEMON

local API = LEMON.API

LEMON.Compiler = { }

local Compiler = LEMON.Compiler
Compiler.__index = Compiler

/*==============================================================================================
	Section: Tokens
==============================================================================================*/

Compiler.RawTokens = {

	--MATH:

		{ "+", "add", "addition" },
		{ "-", "sub", "subtract" },
		{ "*", "mul", "multiplier" },
		{ "/", "div", "division" },
		{ "%", "mod", "modulus" },
		{ "^", "exp", "power" },
		{ "=", "ass", "assign" },
		{ "+=", "aadd", "increase" },
		{ "-=", "asub", "decrease" },
		{ "*=", "amul", "multiplier" },
		{ "/=", "adiv", "division" },
		{ "++", "inc", "increment" },
		{ "--", "dec", "decrement" },

	-- COMPARISON:

		{ "==", "eq", "equal" },
		{ "!=", "neq", "unequal" },
		{ "<", "lth", "less" },
		{ "<=", "leq", "less or equal" },
		{ ">", "gth", "greater" },
		{ ">=", "geq", "greater or equal" },

	-- BITWISE:

		{ "&", "band", "and" },
		{ "|", "bor", "or" },
		{ "^^", "bxor", "or" },
		{ ">>", "bshr", ">>" },
		{ "<<", "bshl", "<<" },

	-- CONDITION:

		{ "!", "not", "not" },
		{ "&&", "and", "and" },
		{ "||", "or", "or" },

	-- SYMBOLS:

		{ "?", "qsm", "?" }, --Cant get this stable yet =(
		{ ":", "col", "colon" },
		{ ";", "sep", "semicolon" },
		{ ",", "com", "comma" },
		{ "$", "dlt", "delta" },
		{ "#", "len", "length" },
		{ "~", "trg", "trigger" },
		{ "->", "wc", "connect" },

	-- BRACKETS:

		{ "(", "lpa", "left parenthesis" },
		{ ")", "rpa", "right parenthesis" },
		{ "{", "lcb", "left curly bracket" },
		{ "}", "rcb", "right curly bracket" },
		{ "[", "lsb", "left square bracket" },
		{ "]", "rsb", "right square bracket" },

	-- MISC:

		{ "...", "varg", "varargs" },
}

-- Todo: API Hook!

table.sort( Compiler.RawTokens, 
	function( Token, Token2 )
		return #Token[1] > #Token2[1]
	end )
	
/*==============================================================================================
	Section: Compiler Executor
==============================================================================================*/

local pcall, setmetatable, SysTime = pcall, setmetatable, SysTime

function Compiler.Execute( ... )
	return pcall( Compiler.Run, setmetatable( { }, Compiler ), ... )
end

function Compiler:Run( Code, Files, NoCompile )
	
	self.Pos = 0
	
	self.TokenPos = -1
	
	self.Char, self.ReadData = "", ""
	
	self.ReadChar, self.ReadLine = 1, 1
	
	self.Buffer, self.Len = Code, #Code
	
	self:NextChar( )
	
	self.Flags = { }
	
	self.Expire = SysTime( ) + 20
	
	self.Tokens = { self:GetNextToken( ), self:GetNextToken( ) }
	
	self:NextToken( )
	
	self.CompilerRuns = 0
	
	return self:CompileCode( Code, Files, NoCompile )
end

/*==============================================================================================
	Section: Errors
==============================================================================================*/

local Format, error = string.format, error

function Compiler:Error( Offset, Message, A, ... )
	if A then Message = Format( Message, A, ... ) end
	error( Format( "%s at line %i, char %i", Message, self.ReadLine, self.ReadChar + Offset ), 0 )
end

function Compiler:TraceError( Trace, ... )
	if type( Trace ) ~= "table" then
		print( Trace, ... )
		debug.Trace( )
	end
	
	self.ReadLine, self.ReadChar = Trace[1], Trace[2]
	self:Error( 0, ... )
end

function Compiler:TokenError( ... )
	self:TraceError( self:TokenTrace( ), ... )
end

/*==============================================================================================
	Section: Trace
==============================================================================================*/

function Compiler:Trace( )
	return { self.ReadLine, self.ReadChar }
end

function Compiler:CompileTrace( Trace )
	if !Trace then debug.Trace( ) end
	return API.Util.ValueToLua( Trace )
end

/*==============================================================================================
	Section: Operators
==============================================================================================*/
function Compiler:GetOperator( Name, Param1, Param2, ... )
	local Op = API.Operators[ Format( "%s(%s)", Name, table.concat( { Param1 or "", Param2, ... } , "" ) ) ]
	
	if Op or !Param1 then
		return Op
	end
	
	local Class = API:GetClass( Param1, true )
	
	if Class and Class.DownCast then
		return self:GetOperator( Name, Class.DownCast, Param2, ... )
	
	elseif Param2 then
		local Class = API:GetClass( Param2, true )
	
		if Class and Class.DownCast then
			return self:GetOperator( Name, Param1, Class.DownCast, ... )
		end
	end
end

/*==============================================================================================
	Section: Loop Protection
==============================================================================================*/

function Compiler:TimeCheck( )
	if SysTime( ) > self.Expire then
		self:Error( 0, "Code took to long to Compile." )
	end
end

/*==============================================================================================
	Section: Falgs
==============================================================================================*/
function Compiler:PushFlag( Flag, Value )
	local FlagTable = self.Flags[ Flag ]
	
	if !FlagTable then
		FlagTable = { }
		self.Flags[ Flag ] = FlagTable
	end
	
	FlagTable[ #FlagTable + 1 ] = Value
end

function Compiler:PopFlag( Flag )
	local FlagTable = self.Flags[ Flag ]
	
	if FlagTable and #FlagTable > 1 then
		return table.remove( FlagTable, #FlagTable )
	end
end

function Compiler:GetFlag( Flag, Default )
	local FlagTable = self.Flags[ Flag ]
	
	if FlagTable then
		return FlagTable[ #FlagTable ] or Default
	end
	
	return Default
end

function Compiler:SetFlag( Flag, Value )
	local FlagTable = self.Flags[ Flag ]
	
	if FlagTable and #FlagTable > 1 then
		FlagTable[#FlagTable] = Value
	end
end

/*==========================================================================
	Section: Inline Checker
==========================================================================*/
local Valid_Words = {
	["return"] = true,
	["local"] = true,
	["while"] = true,
	["for"] = true,
	["end"] = true,
	["if"] = true,
	["do"] = true
}

function Compiler:IsPreparable( Line )
	Line = string.Trim( Line )
	local _, _, Word = string.find( Line, "^([a-zA-Z][a-zA-Z0-9_]*)" )
	return Valid_Words[ Word ] or (Word and string.find( Line, "[=%(]" ))
end

/*==========================================================================
	Section: Peram Convertor
==========================================================================*/

function Compiler:ConstructOperator( Perf, Types, Second, First, ... )
	
	if !First then
		self:Error( "Unpredicable error: No inline was given!" )
	end
	
	local Values = { ... }
	local Variants, Prepare = { }, { }
	
	local MaxPerams = math.Max( #Types, #Values )
	
	while ( true ) do
		local TestPeram = MaxPerams + 1
		
		if string.find( First, "value %%" .. TestPeram ) or string.find( First, "prepare %%" .. TestPeram ) then
			MaxPerams = MaxPerams + 1
		elseif !Second then
			break
		elseif string.find( Second, "value %%" .. TestPeram ) or string.find( Second, "prepare %%" .. TestPeram ) then
			MaxPerams = MaxPerams + 1
		else
			break
		end
	end
	
	for I = 1, MaxPerams do
			
			local Prep
			
			local RType, IType = Types[I] or ""
			local Input = Values[I] or "nil"
		
		-- 1) Read the instruction.
			
			if type( Input ) == "table" then
				Prep = Input.Prepare
				Value = Input.Inline
				Perf = Perf + ( Input.Perf or 0 )
				IType = Input.Return
			elseif Input then
				Value = Input or "nil"
			end
			
			Value = string.gsub( Value, "(%%)", "%%%%" )
			
		-- 2) Count usage of instruction.
			
			local _, Usages = string.gsub( First, "value %%" .. I, "" )
			
			if Second then
				local _, Count = string.gsub( Second, "value %%" .. I, "" )
				Usages = Usages + Count
			end
		
		-- 3) Replace instruction with variable if needed.
			
			if Usages > 1 and type( Input ) ~= "number" then
				if !string.find( Value, "^_[a-zA-z0-9]+" ) then
					local ID = self:NextLocal( )
					Prep = Format( "%s\nlocal %s = %s\n", Prep or "", ID, Value )
					Value = ID
					
					if type( Input ) == "table" then
						-- THIS IS A TEMPORARY TEST!
						Input.Perf = 0
						Input.Inline = ID
						Input.Prepare = nil
					end
				end
			end
		
		-- 4) Creat a var-arg variant
			
			if Variants[1] or RType == "..." and IType then
				RType = IType
				table.insert( Variants, RType ~= "?" and Format( "{%s,%q}", Value, RType ) or Value )
			end
			
		-- 5) Replace the inlined data
			
			First = string.gsub( First, "type %%" .. I, Format( "%q", RType or IType or "" ) )
			First = string.gsub( First, "value %%" .. I, Value )
			
			if Second then
				Second = string.gsub( Second, "type %%" .. I, Format( "%q", RType or IType or "" ) )
				Second = string.gsub( Second, "value %%" .. I, Value )
		
		-- 6) Check for any specific prepare
				if string.find( Second, "prepare %%" .. I ) then
					Second = string.gsub( Second, "prepare %%" .. I, Prep )
					Prep = nil
				end
			end
				
			if Prep then
				table.insert( Prepare, Prep )
			end
	end
	
	-- 7) Replace Var-Args
		local Varargs = string.Implode( ",", Variants )
		
		First = string.gsub( First, "(%%%.%.%.)", Varargs )
		
		if Second then
			Second = string.gsub( Second, "(%%%.%.%.)", Varargs )
		end
		
	-- 8) Insert global prepare
		
		if Second and string.find( Second, "%%prepare" ) then
			Second = string.gsub( Second, "%%prepare", string.Implode( "\n", Prepare ) ) .. "\n"
		else
			Second = string.Implode( "\n", Prepare ) .. ( Second or "" ) .. "\n"
		end
		
	-- 9) Import to enviroment
	
		for RawImport in string.gmatch( First, "(%$[a-zA-Z0-9_]+)" ) do
			local What = string.sub( RawImport, 2 )
			First = string.gsub( First, RawImport, What )
			self:Import( What )
		end
		
		if Second then
			for RawImport in string.gmatch( Second, "(%$[a-zA-Z0-9_]+)" ) do
				local What = string.sub( RawImport, 2 )
				Second = string.gsub( Second, RawImport, What )
				self:Import( What )
			end
		end
		
	return First, Second, Perf
end

/*==============================================================================================
	Section: Load the Compiler Stages!
==============================================================================================*/
include( "tokenizer.lua" )
include( "parser.lua" )
include( "compiler.lua" )
include( "debugger.lua" )
