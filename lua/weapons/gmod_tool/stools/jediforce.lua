TOOL.Category            = "Construction"
TOOL.Name                = "Jedi Force Tool"
TOOL.Command             = nil
TOOL.ConfigName          = nil
TOOL.LeftClickAutomatic  = true
TOOL.RightClickAutomatic = true

TOOL.ClientConVar =
{
  [ "forceamount" ]       = 500,
  [ "forcemaxdistance" ]  = 500,
  [ "forcemassrelative" ] = 0,
  [ "forcedistrelative" ] = 1,
  [ "forcemcapply" ]      = 0,
  [ "enablecs" ]          = 1,
  [ "axislen" ]           = 30
}



function ApplyJediForce(oSelf,stTrace,vVec)
  local oEnt = stTrace.Entity
  if(oEnt and oEnt:IsValid()) then
    local oPhy = oEnt:GetPhysicsObject()
    if(oPhy and oPhy:IsValid()) then
      -- A jedi cant pull the map ...
      local force       = oSelf:GetClientNumber( "forceamount", 0 )
      local maxdistance = oSelf:GetClientNumber( "forcemaxdistance", 0 )
      local massrelative= oSelf:GetClientNumber( "forcemassrelative", 0 )
      local distrelative= oSelf:GetClientNumber( "forcedistrelative", 0 )
      local mcapply     = oSelf:GetClientNumber( "forcemcapply", 0 )
      local vF          = force*vVec:GetNormalized()
      if(massrelative ~= 0) then
        vF:Mul(oPhy:GetMass())
      end
      if(distrelative ~= 0) then
        vF:Mul(math.Clamp((1-vVec:Length()/maxdistance),0,1))
      end
      if(maxdistance > vVec:Length()) then
        if(mcapply ~= 0) then
          oPhy:ApplyForceCenter(vF)
        else
          oPhy:ApplyForceOffset(vF,stTrace.HitPos)
        end
      end
    end
  end
end


if CLIENT then
  language.Add("tool.jediforce.name", "Jedi Force Tool")
  language.Add("tool.jediforce.desc", "Uses jedi's force to pull/push object")
  language.Add("tool.jediforce.0", "Left click to Push, Right click to Pull, Reload to Grab")
  language.Add("tool.jediforce.force", "Force Amount")
  language.Add("tool.jediforce.distance", "Force Max Distance")
  language.Add("tool.jediforce.axislen", "Vision Axis Length")
end

function TOOL:Think()
  if(CLIENT) then return end
  local stTrace = self:GetOwner():GetEyeTrace()
  if(stTrace) then
    local oEnt = stTrace.Entity
    if(oEnt and oEnt:IsValid() and not oEnt:IsWorld()) then
      -- If "oEnt" is a prop
      local oPhy = oEnt:GetPhysicsObject()
      if(oPhy and oPhy:IsValid()) then
        -- When "oEnt" is a valid phys prop
        -- make sure that MC is calculated an send it faster for usage in DrawHUD
        oEnt:SetNWVector( "jediforce_MC_vector", oEnt:LocalToWorld(oPhy:GetMassCenter()))
      end
    end
  end
end

function TOOL:DrawHUD()
  if(SERVER) then return end
  local oPly    = self:GetOwner()
  local stTrace = oPly:GetEyeTrace()
  if(stTrace and oPly) then
    local oEnt    = stTrace.Entity
    local axislen = self:GetClientNumber( "axislen",  30 )
    local enucs   = self:GetClientNumber( "enablecs", 0 )
    if(enucs ~= 0) then
      if(oEnt and oEnt:IsValid() and not oEnt:IsWorld()) then
        local vPos = oEnt:GetPos()
        local nRad = (vPos - oPly:GetPos()):Length()
              nRad = math.Clamp(20*axislen/nRad,1,100)
        local O = vPos:ToScreen()
        local B = (oEnt:LocalToWorld(oEnt:OBBCenter())):ToScreen()
        local M = (oEnt:GetNWVector("jediforce_MC_vector")):ToScreen()
        local X = (vPos + axislen*oEnt:GetForward()):ToScreen()
        local Y = (vPos - axislen*oEnt:GetRight()):ToScreen()
        local Z = (vPos + axislen*oEnt:GetUp()):ToScreen()
        surface.SetDrawColor(255,0,0,255)
        surface.DrawLine( O.x, O.y, X.x, X.y )
        surface.SetDrawColor(0,255,0,255)
        surface.DrawLine( O.x, O.y, Y.x, Y.y )
        surface.SetDrawColor(0,0,255,255)
        surface.DrawLine( O.x, O.y, Z.x, Z.y )
        surface.DrawCircle( O.x, O.y, nRad, Color(255,0,255,255) )
        surface.DrawCircle( B.x, B.y, nRad, Color(0,255,255,255) )
        surface.DrawCircle( M.x, M.y, nRad, Color(255,255,0,255) )
      elseif(oEnt:IsWorld()) then
        local vPos = stTrace.HitPos
        local nRad = (vPos - oPly:GetPos()):Length()
              nRad = math.Clamp(20*axislen/nRad,1,100)
        local O = vPos:ToScreen()
        local X = (vPos + axislen*Vector(1,0,0)):ToScreen()
        local Y = (vPos + axislen*Vector(0,1,0)):ToScreen()
        local Z = (vPos + axislen*Vector(0,0,1)):ToScreen()
        surface.SetDrawColor(255,0,0,255)
        surface.DrawLine( O.x, O.y, X.x, X.y )
        surface.SetDrawColor(0,255,0,255)
        surface.DrawLine( O.x, O.y, Y.x, Y.y )
        surface.SetDrawColor(0,0,255,255)
        surface.DrawLine( O.x, O.y, Z.x, Z.y )
        surface.DrawCircle( O.x, O.y, nRad, Color(255,0,255,255) )
      end
    end
  end
end

function TOOL:LeftClick( Trace )
  if ( CLIENT ) then return end
  if (not Trace) then return end
  ApplyJediForce(self,Trace,Trace.HitPos - Trace.StartPos)
end

function TOOL:RightClick( Trace )
  if ( CLIENT ) then return end
  if (not Trace) then return end
  ApplyJediForce(self,Trace,Trace.StartPos - Trace.HitPos)
end

function TOOL:Reload( Trace )
  if(CLIENT) then return end
  if(not Trace) then return end
  local oPly = self:GetOwner()
  local oEnt = Trace.Entity
  if(oEnt and oEnt:IsValid()) then
    if(oEnt:GetPhysicsObject():IsValid()) then
      -- A jedi cant grab the map ...
      local vAim = oPly:GetAimVector()
      -- Dont grab over you
      vAim.z = 0
      -- Place the prop in radius of 55 gmu
      if(vAim:Length() < 55) then
        vAim:Mul(55/vAim:Length())
      end
      oEnt:SetPos(oPly:GetPos()+vAim+Vector(0,0,45))
    end
  elseif(Trace.HitWorld) then
    oPly:SetPos(Trace.HitPos + 20 * Trace.HitNormal)
  end
  return true
end

function TOOL.BuildCPanel( cPanel )
  cPanel:AddControl("Header",{
    Text = "#tool.jediforce.name",
    Description = "#tool.jediforce.desc"})
  
  cPanel:AddControl("ComboBox",
  {
    Label      = "#Presets",
    MenuButton = 1,
    Folder     = "jediforce",
    Options    = {},
    CVars      =
    {
      [0] = "jediforce_forcedistance",
      [1] = "jediforce_forceamount",
      [2] = "jediforce_forcemassrelative",
      [3] = "jediforce_forcedistrelative",
      [4] = "jediforce_forcemcapply",
      [5] = "jediforce_enablecs",
      [6] = "jediforce_axislen"
    }
  })
  cPanel:AddControl( "Slider",  {
      Label   = "#tool.jediforce.distance",
      Type    = "Float",
      Min     = 1,
      Max     = 100000,
      Command = "jediforce_forcemaxdistance",
      Description = "Sets the max distance"})
      
  cPanel:AddControl( "Slider",  {
      Label   = "#tool.jediforce.force",
      Type    = "Float",
      Min     = 1,
      Max     = 100000,
      Command = "jediforce_forceamount",
      Description = "Sets the amount of force to be used"})
      
  cPanel:AddControl( "Slider",  {
      Label   = "#tool.jediforce.axislen",
      Type    = "Float",
      Min     = 1,
      Max     = 500,
      Command = "jediforce_axislen",
      Description = "Sets the UCS axis length"})
      
  cPanel:AddControl("CheckBox",{
      Label       = "Force multiplyed by prop mass",
      Description = "",
      Command     = "jediforce_forcemassrelative"})
      
  cPanel:AddControl("CheckBox",{
      Label = "Force dropping with distance",
      Description = "",
      Command = "jediforce_forcedistrelative"})
      
  cPanel:AddControl("CheckBox",{
      Label       = "Apply the force on the prop masscentre",
      Description = "",
      Command     = "jediforce_forcemcapply"})
      
  cPanel:AddControl("CheckBox",{
      Label       = "Enable Jedi's UCS Vision",
      Description = "",
      Command     = "jediforce_enablecs"})
end
