TOOL.Category            = "Construction"
TOOL.Name                = "Jedi Force Tool"
TOOL.Command             = nil
TOOL.ConfigName          = nil
TOOL.LeftClickAutomatic  = true
TOOL.RightClickAutomatic = true
TOOL.ClientConVar =
{
  [ "envelocity"   ] = 0  ,
  [ "movemap"      ] = 0  ,
  [ "mcapply"      ] = 0  ,
  [ "enablecs"     ] = 1  ,
  [ "massrelative" ] = 0  ,
  [ "distreverse"  ] = 0  ,
  [ "axislen"      ] = 30 ,
  [ "jumpower"     ] = 200,
  [ "storeposkey"  ] = "" ,
  [ "radiuspos"    ] = 50 ,
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

function GetJediInfo(oPly, bDel)
  if(not oPly) then return nil end
  if(not oPly:IsValid()) then return nil end
  if(not oPly:IsPlayer()) then return nil end
  if(bDel) then gtSaved[oPly] = nil; return end
  local tPly = gtSaved[oPly]
  if(not tPly) then
    gtSaved[oPly] = {
      MovePos = {},
      JumpDef = 200
    }
    tPly = gtSaved[oPly]
  end; return tPly, oPly
end

function TOOL:GetEnableVelocity()
  return ((tonumber(self:GetClientNumber("envelocity", 0)) or 0) ~= 0)
end

function TOOL:GetDistReverse()
  return ((tonumber(self:GetClientNumber("distreverse", 0)) or 0) ~= 0)
end

function TOOL:GetMassRelative()
  return ((tonumber(self:GetClientNumber("massrelative", 0)) or 0) ~= 0)
end

function TOOL:GetForceAtMC()
  return ((tonumber(self:GetClientNumber("mcapply", 0)) or 0) ~= 0)
end

function TOOL:GetMoveMap()
  return ((tonumber(self:GetClientNumber("movemap", 0)) or 0) ~= 0)
end

function TOOL:GetForce()
  return math.Clamp((tonumber(self:GetClientNumber("force", 0)) or 0), 0, 100000)
end

function TOOL:GetDistance()
  return math.Clamp((tonumber(self:GetClientNumber("distance", 0)) or 0), 0, 100000)
end

function TOOL:GetJumpAmount()
  return math.Clamp((tonumber(self:GetClientNumber("jumpower", 0)) or 0), 0, 10000)
end

function TOOL:GetAxisSize()
  return math.Clamp((tonumber(self:GetClientNumber("axislen", 0)) or 0), 0, 500)
end

function TOOL:GetRadiusPos()
  return math.Clamp((tonumber(self:GetClientNumber("radiuspos", 0)) or 0), 0, 300)
end

function TOOL:GetStorePosKey()
  return (self:GetClientInfo("storeposkey") or "")
end

function TOOL:ApplyJediForce(stTr, vVec)
  local oEnt = stTr.Entity
  if(oEnt and oEnt:IsValid()) then
    local oPhy = oEnt:GetPhysicsObject()
    if(oPhy and oPhy:IsValid()) then -- A jedi cant pull the map ...
      local nV           = vVec:Length()
      local force        = self:GetForce()
      local distance     = self:GetDistance()
      local mcapply      = self:GetForceAtMC()
      local massrelative = self:GetMassRelative()
      local distreverse  = self:GetDistReverse()
      local vF           = force * vVec:GetNormalized()
      if(massrelative) then vF:Mul(oPhy:GetMass()) end
      if(distance > 0) then
        if(distreverse) then -- Bigger force
          vF:Mul(math.Clamp(nV / distance, 0, 1))
        else -- Smaller force on distant objects
          vF:Mul(math.Clamp(1 - (nV / distance), 0, 1))
        end
      end
      if(mcapply) then
        oPhy:ApplyForceCenter(vF)
      else
        oPhy:ApplyForceOffset(vF, stTr.HitPos)
      end
    end
  end
end

if(CLIENT) then
  language.Add("tool."..gsToolName..".name", "Jedi Force Tool")
  language.Add("tool."..gsToolName..".desc", "Uses jedi's force to pull/push object")
  language.Add("tool."..gsToolName..".0", "Left click to Push, Right click to Pull, Reload to Grab")
  language.Add("tool."..gsToolName..".force", "Sets the amount of force to be used")
  language.Add("tool."..gsToolName..".force_con", "Force amount")
  language.Add("tool."..gsToolName..".distance", "Adjusts the relative force dropping with distance. Write zero to disable")
  language.Add("tool."..gsToolName..".distance_con", "Force distance")
  language.Add("tool."..gsToolName..".axislen", "Change this to adjust UCS axis length. Write zero to disable")
  language.Add("tool."..gsToolName..".axislen_con", "Axis length")
  language.Add("tool."..gsToolName..".jumpower", "Change this to adjust the jump power")
  language.Add("tool."..gsToolName..".jumpower_con", "Jedi jump power")
  language.Add("tool."..gsToolName..".massrelative", "Enable to multiply force by the entity mass")
  language.Add("tool."..gsToolName..".massrelative_con", "Force multiplyed by mass")
  language.Add("tool."..gsToolName..".distreverse", "Enable to make the force get higher on distant objects")
  language.Add("tool."..gsToolName..".distreverse_con", "Force growing with distance")
  language.Add("tool."..gsToolName..".mcapply", "Enable to make the force applied at the entity masscentre")
  language.Add("tool."..gsToolName..".mcapply_con", "Apply force at the masscentre")
  language.Add("tool."..gsToolName..".movemap", "Enable this to allow moving map props with mind power")
  language.Add("tool."..gsToolName..".movemap_con", "Enable moving map props")
  language.Add("tool."..gsToolName..".radiuspos", "Adjust this to change the distane player is places from world surfaces")
  language.Add("tool."..gsToolName..".radiuspos_con", "Position radius")
  language.Add("tool."..gsToolName..".envelocity", "Enable this to keep the player last velocity when teleporting")
  language.Add("tool."..gsToolName..".envelocity_con", "Enable player velocity")
  language.Add("tool."..gsToolName..".storeposkey_ls", "Different recall location names are stored here")
  language.Add("tool."..gsToolName..".storeposkey_ls_def", "<CHOSE LOCATION>")
  language.Add("tool."..gsToolName..".storeposkey_ls_con", "Location memory")
  language.Add("tool."..gsToolName..".storeposkey_tx", "Write down location name and press ENTER to store it")
  language.Add("tool."..gsToolName..".storeposkey_tx_con", "Location name")
elseif(SERVER) then
  hook.Add("PlayerDisconnected", gsToolName.."_player_quit",
    function(oPly) GetJediInfo(oPly, true) end)

  util.AddNetworkString(gsToolName.."_storeposkey")
  net.Receive(gsToolName.."_storeposkey", function(nLen)
    local oPly = net.ReadEntity()
    if(not (oPly and oPly:IsValid())) then return end
    local vPos = net.ReadVector()
    local sKey = net.ReadString()
    if(sKey:len() <= 0) then return end
    local tPly = GetJediInfo(oPly)
          tPly.MovePos[sKey] = vPos
  end)

  util.AddNetworkString(gsToolName.."_deleteposkey")
  net.Receive(gsToolName.."_deleteposkey", function(nLen)
    local oPly = net.ReadEntity()
    if(not (oPly and oPly:IsValid())) then return end
    local sKey = net.ReadString()
    if(sKey:len() <= 0) then return end
    local tPly = GetJediInfo(oPly)
          tPly.MovePos[sKey] = nil
  end)
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

function TOOL:GetPosRadius(oPly, vHit, nAxs)
  local nRad = (vHit - oPly:GetPos()):Length()
  return math.Clamp(20 * nAxs / nRad, 1, 100)
end

function TOOL:DrawHUD()
  if(SERVER) then return end
  local oPly = self:GetOwner()
  local stTr = oPly:GetEyeTrace()
  if(stTr and oPly) then
    local axislen = self:GetAxisSize()
    if(axislen > 0) then
      local oEnt = stTr.Entity
      if(oEnt and oEnt:IsValid() and not oEnt:IsWorld()) then
        local vPos = oEnt:GetPos()
        local nRad = self:GetPosRadius(oPly, vPos, axislen)
        local O = vPos:ToScreen()
        local B = (oEnt:LocalToWorld(oEnt:OBBCenter())):ToScreen()
        local M = (oEnt:GetNWVector(gsToolName.."_MC")):ToScreen()
        local X = (vPos + axislen * oEnt:GetForward()):ToScreen()
        local Y = (vPos - axislen * oEnt:GetRight()):ToScreen()
        local Z = (vPos + axislen * oEnt:GetUp()):ToScreen()
        surface.SetDrawColor(255,0,0,255)
        surface.DrawLine(O.x, O.y, X.x, X.y)
        surface.SetDrawColor(0,255,0,255)
        surface.DrawLine(O.x, O.y, Y.x, Y.y)
        surface.SetDrawColor(0,0,255,255)
        surface.DrawLine(O.x, O.y, Z.x, Z.y)
        surface.DrawCircle(O.x, O.y, nRad, Color(255,0,255,255))
        surface.DrawCircle(B.x, B.y, nRad, Color(0,255,255,255))
        surface.DrawCircle(M.x, M.y, nRad, Color(255,255,0,255))
      elseif(oEnt:IsWorld()) then
        local vPos = stTr.HitPos
        local nRad = self:GetPosRadius(oPly, vPos, axislen)
        local O = vPos:ToScreen()
        local X = (vPos + axislen * Vector(1,0,0)):ToScreen()
        local Y = (vPos + axislen * Vector(0,1,0)):ToScreen()
        local Z = (vPos + axislen * Vector(0,0,1)):ToScreen()
        surface.SetDrawColor(255,0,0,255)
        surface.DrawLine(O.x, O.y, X.x, X.y)
        surface.SetDrawColor(0,255,0,255)
        surface.DrawLine(O.x, O.y, Y.x, Y.y)
        surface.SetDrawColor(0,0,255,255)
        surface.DrawLine(O.x, O.y, Z.x, Z.y)
        surface.DrawCircle(O.x, O.y, nRad, Color(255,0,255,255))
      end
    end
  end
end

function TOOL:LeftClick(tr)
  if(CLIENT) then return end
  if(not tr) then return end
  if(not tr.Hit) then return end
  self:ApplyJediForce(tr, tr.HitPos - tr.StartPos)
end

function TOOL:RightClick(tr)
  if(CLIENT) then return end
  if(not tr) then return end
  if(not tr.Hit) then return end
  self:ApplyJediForce(tr, tr.StartPos - tr.HitPos)
end

function TOOL:Reload(tr)
  if(CLIENT) then return end
  if(not tr) then return end
  local trEnt = tr.Entity
  local ply = self:GetOwner()
  if(trEnt and trEnt:IsValid()) then
    local movemap = self:GetMoveMap()
    if(not movemap and trEnt:GetClass() ~= "prop_physics") then return end
    local radiuspos = self:GetRadiusPos()
    local vAim = ply:GetAimVector(); vAim.z = 0 -- Dont grab over you
    if(vAim:Length() < radiuspos) then vAim:Mul(radiuspos / vAim:Length()) end
    trEnt:SetPos(ply:GetPos() + vAim + Vector(0, 0, 45))
    return true -- Place the prop in radius of 55 gmu
  elseif(tr.HitWorld) then
    local tPly = GetJediInfo(ply)
    local use = ply:KeyDown(IN_USE)
    local spd = ply:KeyDown(IN_SPEED)
    local key = self:GetStorePosKey()
    if(spd and key:len() > 0 and tPly.MovePos[key]) then
      local tPos = tPly.MovePos[key]
      local nX, nY, nZ = tPos[cvX], tPos[cvY], tPos[cvZ]
      if(nX and nY and nZ) then
        if(not self:GetEnableVelocity()) then
          ply:SetVelocity(-ply:GetVelocity())
        end
        ply:SetPos(Vector(nX, nY, nZ))
        return true
      end; return false
    elseif(use) then
      ply:SetJumpPower(self:GetJumpAmount()); return true
    else
      local radiuspos = self:GetRadiusPos()
      if(not self:GetEnableVelocity()) then
        ply:SetVelocity(-ply:GetVelocity())
      end
      ply:SetPos(tr.HitPos + radiuspos * tr.HitNormal)
      return true
    end
  end
  return false
end

function TOOL:Holster()
  local oPly = self:GetOwner()
  if(not (oPly and oPly:IsValid())) then return end
  local tPly = GetJediInfo(oPly)
  oPly:SetJumpPower(tPly.JumpDef)
end

-- Enter `spawnmenu_reload` in the console to reload the panel
local gtConvarList = TOOL:BuildConVarList()
function TOOL.BuildCPanel(cPanel) local pItem, pComb, pText
  cPanel:ClearControls(); cPanel:DockPadding(5, 0, 5, 10)
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
  pComb, pItem = cPanel:ComboBox(language.GetPhrase("tool."..gsToolName..".storeposkey_ls_con"), gsToolName.."_storeposkey")
  pComb:SetTooltip(language.GetPhrase("tool."..gsToolName..".storeposkey_ls"))
  pComb:SetValue  (language.GetPhrase("tool."..gsToolName..".storeposkey_ls_def"))
  pItem:SetTooltip(language.GetPhrase("tool."..gsToolName..".storeposkey_ls"))
  pComb:Dock(TOP); pComb:SetTall(20)

  local storeposkey = (GetConVar(gsToolName.."_storeposkey"):GetString() or "")
  pText, pItem = cPanel:TextEntry(language.GetPhrase("tool."..gsToolName..".storeposkey_tx_con"))
  pText:SetTooltip(language.GetPhrase("tool."..gsToolName..".storeposkey_tx"))
  pItem:SetTooltip(language.GetPhrase("tool."..gsToolName..".storeposkey_tx"))
  pText:Dock(TOP); pText:SetTall(20)
  pText:SetText(storeposkey == "" and "" or storeposkey)

  pComb.OnSelect = function(pnSelf, iD, aVal)
    if(input.IsKeyDown(KEY_LSHIFT)) then
      local oPly = LocalPlayer()
      if(oPly and oPly:IsValid()) then
        local tPly = GetJediInfo(oPly)
        net.Start(gsToolName.."_deleteposkey")
        net.WriteEntity(oPly)
        net.WriteString(aVal)
        net.SendToServer()
        pnSelf:CloseMenu()
        table.remove(pnSelf.Data   , iD)
        table.remove(pnSelf.Choices, iD)
        tPly.MovePos[aVal] = nil
        if(not pnSelf.Choices[1]) then
          pnSelf:Clear(); GetJediInfo(oPly, true) -- Clear the context menu
          pnSelf:SetValue(language.GetPhrase("tool."..gsToolName..".storeposkey_ls_def"))
        end
      end
    else
      RunConsoleCommand(gsToolName.."_storeposkey", aVal)
    end
  end

  pText.OnEnter = function(pnSelf, aVal)
    local oPly = LocalPlayer()
    if(oPly and oPly:IsValid()) then
      local vPos = oPly:GetPos()
      if(aVal:len() > 0) then
        local tPly = GetJediInfo(oPly)
        if(not tPly.MovePos[aVal]) then
          pComb:AddChoice(aVal, aVal)
        end
        net.Start(gsToolName.."_storeposkey")
        net.WriteEntity(oPly)
        net.WriteVector(vPos)
        net.WriteString(aVal)
        net.SendToServer()
        tPly.MovePos[aVal] = vPos
      end
    end
  end

  pItem = cPanel:NumSlider(language.GetPhrase("tool."..gsToolName..".distance_con"), gsToolName.."_distance", 0, 100000, 3)
          pItem:SetTooltip(language.GetPhrase("tool."..gsToolName..".distance"))
          pItem:SetDefaultValue(gtConvarList[gsToolName.."_distance"])
  pItem = cPanel:NumSlider(language.GetPhrase("tool."..gsToolName..".force_con"), gsToolName.."_force", 0, 100000, 3)
          pItem:SetTooltip(language.GetPhrase("tool."..gsToolName..".force"))
          pItem:SetDefaultValue(gtConvarList[gsToolName.."_force"])
  pItem = cPanel:NumSlider(language.GetPhrase("tool."..gsToolName..".axislen_con"), gsToolName.."_axislen", 0, 500, 3)
          pItem:SetTooltip(language.GetPhrase("tool."..gsToolName..".axislen"))
          pItem:SetDefaultValue(gtConvarList[gsToolName.."_axislen"])
  pItem = cPanel:NumSlider(language.GetPhrase("tool."..gsToolName..".jumpower_con"), gsToolName.."_jumpower", 0, 10000, 3)
          pItem:SetTooltip(language.GetPhrase("tool."..gsToolName..".jumpower"))
          pItem:SetDefaultValue(gtConvarList[gsToolName.."_jumpower"])
  pItem = cPanel:NumSlider(language.GetPhrase("tool."..gsToolName..".radiuspos_con"), gsToolName.."_radiuspos", 0, 300, 3)
          pItem:SetTooltip(language.GetPhrase("tool."..gsToolName..".radiuspos"))
          pItem:SetDefaultValue(gtConvarList[gsToolName.."_radiuspos"])
  pItem = cPanel:CheckBox (language.GetPhrase("tool."..gsToolName..".massrelative_con"), gsToolName.."_massrelative")
          pItem:SetTooltip(language.GetPhrase("tool."..gsToolName..".massrelative"))
  pItem = cPanel:CheckBox (language.GetPhrase("tool."..gsToolName..".distreverse_con"), gsToolName.."_distreverse")
          pItem:SetTooltip(language.GetPhrase("tool."..gsToolName..".distreverse"))
  pItem = cPanel:CheckBox (language.GetPhrase("tool."..gsToolName..".mcapply_con"), gsToolName.."_mcapply")
          pItem:SetTooltip(language.GetPhrase("tool."..gsToolName..".mcapply"))
  pItem = cPanel:CheckBox (language.GetPhrase("tool."..gsToolName..".movemap_con"), gsToolName.."_movemap")
          pItem:SetTooltip(language.GetPhrase("tool."..gsToolName..".movemap"))
  pItem = cPanel:CheckBox (language.GetPhrase("tool."..gsToolName..".envelocity_con"), gsToolName.."_envelocity")
          pItem:SetTooltip(language.GetPhrase("tool."..gsToolName..".envelocity"))
end
