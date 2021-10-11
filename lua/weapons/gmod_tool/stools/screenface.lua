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

local function GetOffsetUP(ent, dir)
  if(not (ent and ent:IsValid())) then return end
  local out = ent:OBBCenter()
  local obb = ent:OBBMaxs(); obb:Sub(ent:OBBMins())
  return math.abs(obb:Dot(dir) / 2)
end

local function SetFacePlayer(ply, pos, ent, nrm, ang)
  if(not (ent and ent:IsValid())) then return end
  local norm, epos = Vector(nrm), ent:GetPos()
        norm:Normalize() -- Make sure it is normalized
  local cang = (ang and Angle(ang) or Angle(0,0,0))
  local righ = (pos - ply:GetPos()):Cross(norm)
  local rang = norm:Cross(righ):AngleEx(norm)
  local tang = ent:AlignAngles(ent:LocalToWorldAngles(cang), rang)
        tang:Normalize(); tang:RotateAroundAxis(norm, 180)
  ent:SetAngles(tang) -- Apply the angle as long as it is ready
  local vobb = ent:OBBCenter(); vobb:Rotate(tang)
        vobb.x, vobb.y = -vobb.x, -vobb.y -- Revert OBB to position
        vobb.z = GetOffsetUP(ent, ent:WorldToLocal(norm + epos))
  local tpos = Vector(vobb); tpos:Add(pos) -- Use OBB offset
  ent:SetPos(tpos) -- Apply the calculated position
end

function TOOL:LeftClick(tr)
  if(CLIENT) then return end
  if(not tr) then return end
  if(not tr.Hit) then return end
  local vpos = Vector(self:GetClientInfo("position"))
  local vang = Angle(self:GetClientInfo("angle"))
  SetFacePlayer(self:GetOwner(), vpos, tr.Entity, Vector(0,0,1), vang)
  return true
end

function TOOL:RightClick(tr)
  if(CLIENT) then return end
  if(not tr) then return end
  if(not tr.Hit) then return end
  local ply = self:GetOwner()
  if(ply:KeyDown(IN_SPEED)) then
    print("Position: "..tostring(tr.HitPos))
    ply:ConCommand(gsTool.."_position \""..tostring(tr.HitPos).."\"\n")
  else
    tr.Entity:GetPhysicsObject():EnableMotion(false)
    local angle = tr.HitNormal:AngleEx(Vector(0,0,1))
    local value = tr.Entity:WorldToLocalAngles(angle)
    print("Custiom angle: " ..tostring(value))
    ply:ConCommand(gsTool.."_angle \""..tostring(value).."\"\n")
  end
  return true
end

-- Enter `spawnmenu_reload` in the console to reload the panel
function TOOL.BuildCPanel(cPanel) local pItem, pComb, pText
  cPanel:ClearControls(); cPanel:DockPadding(5, 0, 5, 10)
  pItem = cPanel:SetName(language.GetPhrase("tool."..gsTool..".name"))
  pItem = cPanel:Help   (language.GetPhrase("tool."..gsTool..".desc"))
end
