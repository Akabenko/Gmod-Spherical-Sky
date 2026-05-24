AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
	self:SetNoDraw(true)
	self:SetMoveType(MOVETYPE_NONE)  
	self:SetSolid(SOLID_NONE)	
	self.Entity:SetNotSolid( true )
	self:PhysicsInitStatic(SOLID_NONE)
end

function ENT:UpdateTransmitState()
    return TRANSMIT_ALWAYS
end

function ENT:KeyValue( key, value )
	if key == "staticskytexpath" then
		self:SetNWString(key, value) -- staticskytexpath
	end
	
	if key == "brightness" then
		self:SetNWFloat(key, value)
	end
end
