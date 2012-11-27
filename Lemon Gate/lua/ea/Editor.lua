/*==============================================================================================
	Expression Advanced: Editor.
	Purpose: We where gona make our own but meh.
	Creditors: Rusketh
==============================================================================================*/
local E_A = LemonGate

E_A.Editor = {}
local Editor = E_A.Editor

/*==============================================================================================
==============================================================================================*/
local HomeScreen = [[/*===================================================
Expression Advanced Alpha
- Rusketh & Oskar94

For documentation and help visit out wiki.
Wiki: https://github.com/SpaceTown-Developers/Lemon-Gate/wiki

To report bugs like your meant to visit out bug tracker.
Bug Tracker: https://github.com/SpaceTown-Developers/Lemon-Gate/issues

Thank you for taking part in this Alpha!
===================================================*/]]

/*==============================================================================================
	Syntax Hilighting
==============================================================================================*/
local function SyntaxColorLine(self, Row)
	return {{self.Rows[Row], { Color(255, 255, 255, 255), false}}}
end -- TODO: Try and make a syntax hilighter!

/*==============================================================================================
	Validator
==============================================================================================*/
local Tokenizer = E_A.Tokenizer
local Parser = E_A.Parser
local Compiler = E_A.Compiler

local ShortTypes = E_A.TypeShorts
local Operators = E_A.OperatorTable

local function Validate(Script)
	local Check, Tokens = Tokenizer.Execute(Script)
	if !Check then return Tokens end
	
	local Check, Instructions = Parser.Execute(Tokens)
	if !Check then return Instructions end
	
	local Check, Executable, Instance = Compiler.Execute(Instructions)
	if !Check then return Executable end
	
	for Cell, Name in pairs( Instance.Inputs ) do
		local Type = ShortTypes[ Types[Cell] ]
		
		if !Type[4] or !Type[5] then
			return "Type '" .. Type[1] .. "' may not be used as input."
		end
	end
	
	for Cell, Name in pairs( Instance.Outputs ) do
		local Type = ShortTypes[ Types[Cell] ]
		
		if !Type[4] or !Type[6] then
			return "Type '" .. Type[1] .. "' may not be used as output."
		end
	end
end

/*==============================================================================================
	Hack the E2 Editor!
==============================================================================================*/
function Editor.Create()
	if Editor.Instance then return end
	
	local Instance = vgui.Create("Expression2EditorFrame")
	Instance:Setup("Expression Advanced Editor", "Expression Advanced", "EA")
	Instance:SetSyntaxColorLine( SyntaxColorLine )
	-- Instance.E2 = true -- Activates the validator, I'll hax that later!
	
	local Panel = Instance:GetCurrentEditor()
	if Panel then
		Panel:SetText( HomeScreen )
		Panel.Start = Panel:MovePosition({1,1}, #HomeScreen)
		Panel.Caret = Panel:MovePosition(Panel.Start, #HomeScreen)
	end
	
	function Instance:OnTabCreated( Tab )
		local Editor = Tab.Panel
		Editor:SetText( HomeScreen )
		Editor.Start = Editor:MovePosition({1,1}, #HomeScreen)
		Editor.Caret = Editor:MovePosition(Editor.Start, #HomeScreen)
	end
	
	function Instance:Validate( Goto )
		local Error = Validate( self:GetCode() )
		local Panel = self.C['Val'].panel
		
		if !Error then
			Panel:SetBGColor(0, 128, 0, 180)
			Panel:SetFGColor(255, 255, 255, 128)
			Panel:SetText( "Valadation Sucessful!" )
		else
			Panel:SetBGColor(128, 0, 0, 180)
			Panel:SetFGColor(255, 255, 255, 128)
			Panel:SetText( Error )
			
			if Goto then
				local Row, Col = Error:match("at line ([0-9]+), char ([0-9]+)$")
				
				if !Row then Row, Col = Error:match("at line ([0-9]+)$"), 1 end
				
				if Row then self:GetCurrentEditor():SetCaret({ tonumber(Row), tonumber(Col) }) end
			end
		end
	end
	
	Editor.Instance = Instance
end

function Editor.Open()
	Editor.Create()
	Editor.Instance:Open()
end

function Editor.GetOpenFile()
	if Editor.Instance then
		return Editor.Instance:GetChosenFile()
	end
end

function Editor.GetCode()
	if Editor.Instance then
		return Editor.Instance:GetCode()
	end
end

function Editor.GetInstance()
	Editor.Create()
	return Editor.Instance
end