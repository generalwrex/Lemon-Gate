/*============================================================================================================================================ 
	Expression-Advanced Derma 
============================================================================================================================================== 
	Name: EA_ToolBar 
	Author: Oskar 
============================================================================================================================================*/ 

local gradient_up = Material( "vgui/gradient-d" )
local gradient_down = Material( "vgui/gradient-u" )

local string_match = string.match 
local string_find = string.find 
local string_reverse = string.reverse 
local string_sub = string.sub 
local string_lower = string.lower 

local table_concat = table.concat

local LEMON = LEMON
local API = LEMON.API 

local PANEL = {} 

function PANEL:SetupButton( sName, mMaterial, nDock, fDoClick ) 
	local btn = self:Add( "EA_ImageButton" ) 
	btn:Dock( nDock ) 
	btn:SetPadding( 5 ) 
	btn:SetIconFading( false )
	btn:SetIconCentered( false )
	btn:SetTextCentered( false )
	btn:DrawButton( true )
	btn:SetTooltip( sName ) 
	btn:SetMaterial( mMaterial )
	
	if fDoClick then 
		btn.DoClick = fDoClick 
	end 
	return btn 
end 

function PANEL:Init( ) 
	self.btnSave = self:SetupButton( "Save", Material( "fugue/disk.png" ), LEFT )
	self.btnSaveAs = self:SetupButton( "Save As", Material( "fugue/disks.png" ), LEFT )
	self.btnNewTab = self:SetupButton( "New tab", Material( "fugue/script--plus.png" ), LEFT )
	self.btnCloseTab = self:SetupButton( "Close tab", Material( "fugue/script--minus.png" ), LEFT )
	
	self.btnOptions = self:SetupButton( "Options", Material( "fugue/gear.png" ), RIGHT )
	self.btnHelp = self:SetupButton( "Open helper", Material( "fugue/question.png" ), RIGHT )
	self.btnWiki = self:SetupButton( "Open wiki", Material( "fugue/home.png" ), RIGHT )
	
	self.lblLink = self.btnWiki:Add( "DLabelURL" ) 
	self.lblLink:Dock( FILL ) 
	self.lblLink:SetText( "" ) 
	self.lblLink:SetURL( "http://github.com/SpaceTown-Developers/Lemon-Gate/wiki" )
	
	self.repoLink = self:SetupButton( "Open repository", Material( "github.png" ), RIGHT )
	
	local OnCursorEntered = self.lblLink.OnCursorEntered 
	local OnCursorExited = self.lblLink.OnCursorExited 
	
	self.lblLink.OnCursorEntered = function( lbl, ... ) 
		OnCursorEntered( lbl, ... ) 
		self.btnWiki.Hovered = true 
	end 
	
	self.lblLink.OnCursorExited = function( lbl, ... ) 
		OnCursorExited( lbl, ... ) 
		self.btnWiki.Hovered = false 
	end 
	
	local function AddDebugIcon( )
		if GCompute and !self.btnOpenGCompute then 
			self.btnOpenGCompute = self:SetupButton( "Open native code in GCompute", Material( "fugue/bug.png" ), RIGHT, function( self )
				self:GetParent( ):GetParent( ):DoValidate( false, true ) 
				if not self:GetParent( ):GetParent( ).Data then return end
				
				self:GetParent( ):GetParent( ):Close( )
				
				local view = GCompute.IDE:GetInstance( ):GetFrame( ):CreateCodeView( )
				view:Select( )
				view:SetCode( self:GetParent():GetParent().Data.Native )
				
				GCompute.IDE:GetInstance( ):GetFrame( ):SetVisible( true )
			end )
		end
	end
	
	if GCompute then
		AddDebugIcon( )
	else
		hook.Add( "GComputeLoaded", "LemonGate", AddDebugIcon )
	end
	
	function self.btnSave:DoClick( )
		self:GetParent( ):GetParent( ):SaveFile( true ) 
	end 
	
	function self.btnSaveAs:DoClick( )
		self:GetParent( ):GetParent( ):SaveFile( true, true ) 
	end 
	
	function self.btnNewTab:DoClick()
		self:GetParent( ):GetParent( ):NewTab( ) 
	end 
	
	function self.btnCloseTab:DoClick( )
		self:GetParent( ):GetParent( ):CloseTab( nil, true ) 
	end 
		
	function self.btnHelp:DoClick( )
		self:GetParent( ):OpenHelper( ) 
	end 
	
	function self.btnOptions:DoClick( ) end 
	function self.btnWiki:DoClick( ) end
	
	function self.repoLink:DoClick( )
		LEMON.Repo.OpenMenu( )
	end
	
end 

function PANEL:OpenHelper( ) 
	if !ValidPanel( LEMON.Helper ) then LEMON.Helper = vgui.Create( "EA_Helper" ) end 
	LEMON.Helper:SetVisible( true )
	LEMON.Helper:MakePopup( ) 
end 

function PANEL:Paint( w, h ) 
	surface.SetDrawColor( self.btnSave:GetColor( ) )
	surface.DrawRect( 0, 0, w, h )
	
	surface.SetDrawColor( 200, 200, 200, 100 )
	surface.SetMaterial( gradient_down )
	surface.DrawTexturedRect( 0, 0, w, h )
end 

vgui.Register( "EA_ToolBar", PANEL, "Panel" )
