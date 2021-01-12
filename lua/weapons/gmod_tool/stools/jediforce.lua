TOOL.Category            = "Construction"
TOOL.Name                = "Jedi Force Tool"
TOOL.Command             = nil
TOOL.ConfigName          = nil
TOOL.LeftClickAutomatic  = true
TOOL.RightClickAutomatic = true
TOOL.ClientConVar =
{
  [ "movemap"      ] = 0  ,
  [ "mcapply"      ] = 0  ,
  [ "enablecs"     ] = 1  ,
  [ "massrelative" ] = 0  ,
  [ "distrelative" ] = 1  ,
  [ "axislen"      ] = 30 ,
  [ "jumpower"     ] = 200,
  [ "storeposkey"  ] = "" ,
  [ "force"        ] = 500,
  [ "distance"     ] = 500
}

local gtSaved           = {}
local cvX               = 1
local cvY               = 2
local cvZ               = 3
local gsToolName        = "jediforce"
local string            = string
local surface           = surface
local table             = table
local language          = language
local math              = math
local vgui              = vgui
local surface           = surface
local LocalPlayer       = LocalPlayer
local GetConVarString   = GetConVarString
local RunConsoleCommand = RunConsoleCommand

function GetJediInfo(oPly)
  if(not oPly) then return nil end
  if(not oPly:IsValid()) then return nil end
  if(not oPly:IsPlayer()) then return nil end
  local tPly = gtSaved[oPly]
  if(not tPly) then
    gtSaved[oPly] = {
      JumpPow = -1,
      MovePos = {},
      JumpDef = oPly:GetJumpPower()
    }
    tPly = gtSaved[oPly]
  end; return tPly, oPly
end

function TOOL:ApplyJediForce(stTrace, vVec)
  local oEnt = stTrace.Entity
  if(oEnt and oEnt:IsValid()) then
    local oPhy = oEnt:GetPhysicsObject()
    if(oPhy and oPhy:IsValid()) then -- A jedi cant pull the map ...
      local force        = self:GetClientNumber("force", 0)
      local mcapply      = self:GetClientNumber("mcapply", 0)
      local distance     = self:GetClientNumber("distance", 0)
      local massrelative = self:GetClientNumber("massrelative", 0)
      local distrelative = self:GetClientNumber("distrelative", 0)
      local vF           = force * vVec:GetNormalized()
      if(massrelative and massrelative ~= 0) then
        vF:Mul(oPhy:GetMass())
      end
      if(distrelative and distance and distrelative ~= 0) then
        vF:Mul(math.Clamp((1 - vVec:Length() / distance), 0, 1))
      end
      if(distance and distance > vVec:Length()) then
        if(mcapply ~= 0) then
          oPhy:ApplyForceCenter(vF)
        else
          oPhy:ApplyForceOffset(vF, stTrace.HitPos)
        end
      end
    end
  end
end

if CLIENT then
  language.Add("tool."..gsToolName..".name", "Jedi Force Tool")
  language.Add("tool."..gsToolName..".desc", "Uses jedi's force to pull/push object")
  language.Add("tool."..gsToolName..".0", "Left click to Push, Right click to Pull, Reload to Grab")
  language.Add("tool."..gsToolName..".force", "Force amount")
  language.Add("tool."..gsToolName..".force_con", "Sets the amount of force to be used")
  language.Add("tool."..gsToolName..".distance", "Change here to adjust the dorce distance")
  language.Add("tool."..gsToolName..".distance_con", "Force distance")
  language.Add("tool."..gsToolName..".axislen", "Sets the UCS axis length")
  language.Add("tool."..gsToolName..".axislen_con", "Vision axis length")
  language.Add("tool."..gsToolName..".jumpower", "Change this to adjust the jump power")
  language.Add("tool."..gsToolName..".jumpower_con", "Jedi Jump power")
  language.Add("tool."..gsToolName..".massrelative", "Enable to multiply force by the entity mass")
  language.Add("tool."..gsToolName..".massrelative_con", "Force multiplyed by mass")
  language.Add("tool."..gsToolName..".distrelative", "Enable to make the force get lower on distant objects")
  language.Add("tool."..gsToolName..".distrelative_con", "Force dropping with distance")
  language.Add("tool."..gsToolName..".mcapply", "Enable to make the force applied at the entity masscentre")
  language.Add("tool."..gsToolName..".mcapply_con", "Apply force at the masscentre")
  language.Add("tool."..gsToolName..".enablecs", "Enable this to view entity or world coordinate system")
  language.Add("tool."..gsToolName..".enablecs_con", "Enable Jedi's UCS Vision")
  language.Add("tool."..gsToolName..".movemap", "Enable this to allow moving map props with mind power")
  language.Add("tool."..gsToolName..".movemap_con", "Enable moving map props")
  language.Add("tool."..gsToolName..".storeposkey_ls", "Different recall locations are stored here")
  language.Add("tool."..gsToolName..".storeposkey_ls_con", "MovePos memory")
  language.Add("tool."..gsToolName..".storeposkey_tx", "Write down location name and press ENTER to store it")
  language.Add("tool."..gsToolName..".storeposkey_tx_con", "Locationn name")
end

function TOOL:Think()
  if(CLIENT) then return end
  local stTrace = self:GetOwner():GetEyeTrace()
  if(stTrace) then
    local oEnt = stTrace.Entity -- If "oEnt" is a prop
    if(oEnt and oEnt:IsValid() and not oEnt:IsWorld()) then
      local oPhy = oEnt:GetPhysicsObject()
      if(oPhy and oPhy:IsValid()) then -- When "oEnt" is a valid phys prop
        -- make sure that MC is calculated an send it faster for usage in DrawHUD
        oEnt:SetNWVector(gsToolName.."_MC", oEnt:LocalToWorld(oPhy:GetMassCenter()))
      end
    end
  end
end

function TOOL:DrawHUD()
  if(SERVER) then return end
  local oPly = self:GetOwner()
  local stTr = oPly:GetEyeTrace()
  if(stTr and oPly) then
    local enucs   = self:GetClientNumber("enablecs", 0)
    if(enucs ~= 0) then
      local oEnt    = stTr.Entity
      local axislen = self:GetClientNumber("axislen", 30)
      if(oEnt and oEnt:IsValid() and not oEnt:IsWorld()) then
        local vPos = oEnt:GetPos()
        local nRad = (vPos - oPly:GetPos()):Length()
              nRad = math.Clamp(20*axislen/nRad,1,100)
        local O = vPos:ToScreen()
        local B = (oEnt:LocalToWorld(oEnt:OBBCenter())):ToScreen()
        local M = (oEnt:GetNWVector(gsToolName.."_MC")):ToScreen()
        local X = (vPos + axislen * oEnt:GetForward()):ToScreen()
        local Y = (vPos - axislen * oEnt:GetRight()):ToScreen()
        local Z = (vPos + axislen * oEnt:GetUp()):ToScreen()
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
        local vPos = stTr.HitPos
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

function TOOL:LeftClick(tr)
  if ( CLIENT ) then return end
  if (not Trace) then return end
  self:ApplyJediForce(tr, tr.HitPos - tr.StartPos)
end

function TOOL:RightClick(tr)
  if ( CLIENT ) then return end
  if (not Trace) then return end
  self:ApplyJediForce(tr, tr.StartPos - tr.HitPos)
end

function TOOL:Reload(tr)
  if(CLIENT) then return end
  if(not tr) then return end
  local ply = self:GetOwner()
  local trEnt = tr.Entity
  if(trEnt and trEnt:IsValid()) then
    local movemap = (self:GetClientNumber("movemap") or 0)
    if(trEnt:GetClass() ~= "prop_physics" and movemap == 0) then return end
    local vAim = ply:GetAimVector()
    vAim.z = 0 -- Dont grab over you
    if(vAim:Length() < 55) then
      vAim:Mul(55 / vAim:Length())
    end -- Place the prop in radius of 55 gmu
    trEnt:SetPos(ply:GetPos() + vAim + Vector(0, 0, 45))
    return true
  elseif(tr.HitWorld) then
    local tPly = self:GetJediInfo(ply)
    local use = ply:KeyDown(IN_USE)
    local duc = ply:KeyDown(IN_DUCK)
    local spd = ply:KeyDown(IN_SPEED)
    local storeposkey = (self:GetClientInfo("storeposkey") or "")
    if(use and storeposkey:len() > 0) then
      local plPos = ply:GetPos()
      tPly.MovePos[storeposkey] = {plPos[cvX], plPos[cvY], plPos[cvZ]}
      return true
    elseif(spd and storeposkey:len() > 0 and tPly.MovePos[storeposkey]) then
      local loc = tPly.MovePos[storeposkey]
      local x, y, z = loc[cvX], loc[cvY], loc[cvZ]
      if(x and y and z) then
        ply:SetVelocity(-ply:GetVelocity())
        ply:SetPos(Vector(x, y, z))
        return true
      end
      return false
    elseif(duc) then
      jumpower = math.Clamp(self:GetClientNumber("jumpower"),0,10000)
      tPly.JumpPow = jumpower; ply:SetJumpPower(jumpower)
    elseif(not use and not spd and not duc) then
      ply:SetVelocity(-ply:GetVelocity())
      ply:SetPos(tr.HitPos + 20 * tr.HitNormal)
      return true
    end
    return true
  end
  return false
end

function TOOL:Holster()
  local tPly = self:GetJediInfo()
  if(not tPly) then return false end
  self:GetOwner():SetJumpPower(tPly.JumpDef)
end

-- Enter `spawnmenu_reload` in the console to reload the panel
local gtConvarList = TOOL:BuildConVarList()
function TOOL.BuildCPanel(cPanel)
  cPanel:ClearControls(); cPanel:DockPadding(5, 0, 5, 10); local pItem
  pItem = cPanel:SetName(language.GetPhrase("tool."..gsToolName..".name"))
  pItem = cPanel:Help   (language.GetPhrase("tool."..gsToolName..".desc"))

  local pPresets = vgui.Create("ControlPresets", cPanel)
        pPresets:SetPreset(gsToolName)
        pPresets:Dock(TOP); pPresets:SetTall(20)
        pPresets:AddOption("Default", gtConvarList)
        for key, val in pairs(table.GetKeys(gtConvarList)) do
          pPresets:AddConVar(val)
        end
  cPanel:AddItem(pPresets)

  -- http://wiki.garrysmod.com/page/Category:DComboBox
  local pComb = cPanel:ComboBox(language.GetPhrase("tool."..gsToolName..".storeposkey_ls_con"), gsToolName.."_storeposkey")
               pComb:SetTooltip(language.GetPhrase("tool."..gsToolName..".storeposkey_ls"))
  local storeposkey = (GetConVar(gsToolName.."_storeposkey"):GetString() or "")
  local pText = cPanel:TextEntry(language.GetPhrase("tool."..gsToolName..".storeposkey_tx_con"))
                pText:SetTooltip(language.GetPhrase("tool."..gsToolName..".storeposkey_tx"))

  -- Combo box modifies text entry and vice-versa
  pComb:Dock(TOP); pComb:SetTall(20)
  pComb:SetValue("<Select location NAME>")
  pComb.OnSelect = function(pnSelf, iD, aVal)
    RunConsoleCommand(gsToolName.."_storeposkey", aVal)
  end

  pText:Dock(TOP); pText:SetTall(20)
  pText:SetText(storeposkey == "" and "" or storeposkey)
  pText.OnEnter = function(pnSelf, iD, aVal)
    local opPly = LocalPlayer()
    if(opPly and opPly:IsValid()) then
      local psKey = (pnSelf:GetValue() or "")
      local vpPos = opPly:GetPos()
      if(psKey:len() > 0) then
        local tPly = GetJediInfo(opPly)
        if(not tPly.MovePos[psKey]) then
          pComb:AddChoice(psKey)
        end
        tPly.MovePos[psKey] = {plPos[cvX], plPos[cvY], plPos[cvZ]}
      end
    end
  end

  pItem = cPanel:NumSlider(language.GetPhrase("tool."..gsToolName..".distance_con"), gsToolName.."_distance", 0, 100000, 3)
          pItem:SetTooltip(language.GetPhrase("tool."..gsToolName..".distance"))
  pItem = cPanel:NumSlider(language.GetPhrase("tool."..gsToolName..".force_con"), gsToolName.."_force", 1, 100000, 3)
          pItem:SetTooltip(language.GetPhrase("tool."..gsToolName..".force"))
  pItem = cPanel:NumSlider(language.GetPhrase("tool."..gsToolName..".axislen_con"), gsToolName.."_axislen", 1, 500, 3)
          pItem:SetTooltip(language.GetPhrase("tool."..gsToolName..".axislen"))
  pItem = cPanel:NumSlider(language.GetPhrase("tool."..gsToolName..".jumpower_con"), gsToolName.."_jumpower", 0, 10000, 3)
          pItem:SetTooltip(language.GetPhrase("tool."..gsToolName..".jumpower"))
  pItem = cPanel:CheckBox (language.GetPhrase("tool."..gsToolName..".massrelative_con"), gsToolName.."_massrelative")
          pItem:SetTooltip(language.GetPhrase("tool."..gsToolName..".massrelative"))
  pItem = cPanel:CheckBox (language.GetPhrase("tool."..gsToolName..".distrelative_con"), gsToolName.."_distrelative")
          pItem:SetTooltip(language.GetPhrase("tool."..gsToolName..".distrelative"))
  pItem = cPanel:CheckBox (language.GetPhrase("tool."..gsToolName..".mcapply_con"), gsToolName.."_mcapply")
          pItem:SetTooltip(language.GetPhrase("tool."..gsToolName..".mcapply"))
  pItem = cPanel:CheckBox (language.GetPhrase("tool."..gsToolName..".enablecs_con"), gsToolName.."_enablecs")
          pItem:SetTooltip(language.GetPhrase("tool."..gsToolName..".enablecs"))
  pItem = cPanel:CheckBox (language.GetPhrase("tool."..gsToolName..".movemap_con"), gsToolName.."_movemap")
          pItem:SetTooltip(language.GetPhrase("tool."..gsToolName..".movemap"))
end
