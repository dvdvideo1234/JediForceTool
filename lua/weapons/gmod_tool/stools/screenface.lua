TOOL.Category            = "Construction"
TOOL.Name                = "Screen Facer Tool"
TOOL.Command             = nil
TOOL.ConfigName          = nil
TOOL.LeftClickAutomatic  = false
TOOL.RightClickAutomatic = false
TOOL.ClientConVar =
{
  [ "position" ] = "",
  [ "angle"    ] = ""
}

local gsTool = "screenface"

if(CLIENT) then
  language.Add("tool."..gsTool..".name", "Screen Facer Tool")
  language.Add("tool."..gsTool..".desc", "Transfer the tcreen and make it face you!")
  language.Add("tool."..gsTool..".0", "Left click to face the player, right to pick angle, right+shift to pick location")
end

local NTIF = {
  "GAMEMODE:AddNotify(\"%s\", NOTIFY_%s, 6)",
  "surface.PlaySound(\"ambient/water/drip%d.wav\")"
}

local function Notify(user, text, mtyp)
  if(LaserLib.IsValid(user)) then
    if(SERVER) then local ran = math.random(1, 4)
      user:SendLua(NTIF[1]:format(text, mtyp))
      user:SendLua(NTIF[2]:format(ran))
    end
  end
end

local function GetOffsetUP(ent, dir)
  if(not (ent and ent:IsValid())) then return end
  local out = ent:OBBCenter()
  local obb = ent:OBBMaxs(); obb:Sub(ent:OBBMins())
  return math.abs(obb:Dot(dir) / 2)
end

local function SetFacePlayer(ply, ent, nrm, pos, ang)
  if(not (ent and ent:IsValid())) then return end
  local norm, epos = Vector(nrm), ent:GetPos()
  norm:Normalize() -- Make sure it is normalized
  local cang = (ang and Angle(ang) or Angle(0,0,0))
  local righ = (pos - ply:GetPos()):Cross(norm)
  local rang = norm:Cross(righ):AngleEx(norm)
  local tang = ent:AlignAngles(ent:LocalToWorldAngles(cang), rang)
  tang:Normalize(); tang:RotateAroundAxis(norm, 180)
  ent:SetAngles(tang) -- Apply the angle as long as it is ready
  local vobb = ent:OBBCenter() -- Revert OBB to position
  vobb.x, vobb.y, vobb.z = -vobb.x, -vobb.y, -vobb.z
  local marg = GetOffsetUP(ent, ent:WorldToLocal(norm + epos))
  vobb:Rotate(tang); vobb:Add(norm * marg)
  local tpos = Vector(vobb); tpos:Add(pos) -- Use OBB offset
  ent:SetPos(tpos) -- Apply the calculated position
end

function TOOL:LeftClick(tr)
  if(CLIENT) then return end
  if(not tr) then return end
  if(not tr.Hit) then return end
  local vpos = Vector(self:GetClientInfo("position"))
  local vang = Angle(self:GetClientInfo("angle"))
  SetFacePlayer(self:GetOwner(), tr.Entity, Vector(0,0,1), vpos, vang)
  return true
end

function TOOL:RightClick(tr)
  if(CLIENT) then return end
  if(not tr) then return end
  if(not tr.Hit) then return end
  local ply = self:GetOwner()
  if(ply:KeyDown(IN_SPEED)) then
    local strvc = tostring(tr.HitPos)
    Notify(ply, "Position: ["..strvc.."]", "GENERIC")
    print("Position: "..strvc)
    ply:ConCommand(gsTool.."_position \""..strvc.."\"\n")
  else
    local up = Vector(0,0,1)
    local dt = tr.HitNormal:Dot(up)
    tr.Entity:GetPhysicsObject():EnableMotion(false)
    if(dt > 0.9) then
      Notify(ply, "Angle mismatch for ["..dt.."]", "ERROR")
      return false
    end
    local angle = tr.HitNormal:AngleEx(Vector(0,0,1))
    local value = tr.Entity:WorldToLocalAngles(angle)
    local strvc = tostring(value)
    print("Custiom angle: " ..strvc)
    Notify(ply, "Custiom angle: ["..strvc.."]", "GENERIC")
    ply:ConCommand(gsTool.."_angle \""..strvc.."\"\n")
  end
  return true
end

-- Enter `spawnmenu_reload` in the console to reload the panel
function TOOL.BuildCPanel(cPanel) local pItem, pComb, pText
  cPanel:ClearControls(); cPanel:DockPadding(5, 0, 5, 10)
  pItem = cPanel:SetName(language.GetPhrase("tool."..gsTool..".name"))
  pItem = cPanel:Help   (language.GetPhrase("tool."..gsTool..".desc"))
end
