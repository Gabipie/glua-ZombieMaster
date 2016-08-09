-- Original code from Zombie Survival by Jetboom

function WorldVisible(posa, posb)
	return not util.TraceLine({start = posa, endpos = posb, mask = MASK_SOLID_BRUSHONLY}).Hit
end

function TrueVisibleFilters(posa, posb, ...)
	local filt = ents.FindByClass("projectile_*")
	filt = table.Add(filt, player.GetAll())
	if ... ~= nil then
		for k, v in pairs({...}) do
			filt[#filt + 1] = v
		end
	end

	return not util.TraceLine({start = posa, endpos = posb, filter = filt, mask = MASK_SHOT}).Hit
end

function CosineInterpolation(y1, y2, mu)
	local mu2 = (1 - math.cos(mu * math.pi)) / 2
	return y1 * (1 - mu2) + y2 * mu2
end

-- I had to make this since the default function checks visibility vs. the entitiy's center and not the nearest position.
function util.BlastDamageEx(inflictor, attacker, epicenter, radius, damage, damagetype)
	local filter = inflictor
	for _, ent in pairs(ents.FindInSphere(epicenter, radius)) do
		if ent and ent:IsValid() then
			local nearest = ent:NearestPoint(epicenter)
			if TrueVisibleFilters(epicenter, nearest, inflictor, ent) then
				ent:TakeSpecialDamage(((radius - nearest:Distance(epicenter)) / radius) * damage, damagetype, attacker, inflictor, nearest)
			end
		end
	end
end

function util.BlastDamage2(inflictor, attacker, epicenter, radius, damage)
	util.BlastDamageEx(inflictor, attacker, epicenter, radius, damage, DMG_BLAST)
end

function util.FindValidInSphere(pos, radius)
	local ret = {}
	
	for _, ent in pairs(util.FindInSphere(pos, radius)) do
		if ent and ent:IsValid() then
			ret[#ret + 1] = ent
		end
	end

	return ret
end

function util.RemoveAll(class)
	for _, ent in pairs(ents.FindByClass(class)) do
		ent:Remove()
	end
end

function AccessorFuncDT(tab, membername, type, id)
	local emeta = FindMetaTable("Entity")
	local setter = emeta["SetDT"..type]
	local getter = emeta["GetDT"..type]

	tab["Set"..membername] = function(me, val)
		setter(me, id, val)
	end

	tab["Get"..membername] = function(me)
		return getter(me, id)
	end
end

function util.Blood(pos, amount, dir, force, noprediction)
	local effectdata = EffectData()
		effectdata:SetOrigin(pos)
		effectdata:SetMagnitude(amount)
		effectdata:SetNormal(dir)
		effectdata:SetScale(math.max(128, force))
	util.Effect("bloodstream", effectdata, nil, noprediction)
end

-- From ULX csay. Needed to print a colored message at the center of the screen
function util.PrintMessageC(pl, msg, color, duration, fade)
	if SERVER then
		net.Start("zm_coloredprintmessage")
			net.WriteString(msg or "")
			net.WriteColor(color or color_white)
			net.WriteUInt(duration or 5, 32)
			net.WriteFloat(fade or 0.5)
		if IsValid(pl) then net.Send(pl) else net.Broadcast() end
		
		return
	end
	
	color = color or Color(255, 255, 255, 255)
	duration = duration or 5
	fade = fade or 0.5
	local start = CurTime()

	local function drawToScreen()
		local alpha = 255
		local dtime = CurTime() - start

		if dtime > duration then
			hook.Remove( "HUDPaint", "CSayHelperDraw" )
			return
		end

		if fade - dtime > 0 then
			alpha = (fade - dtime) / fade
			alpha = 1 - alpha
			alpha = alpha * 255
		end

		if duration - dtime < fade then
			alpha = (duration - dtime) / fade
			alpha = alpha * 255
		end
		color.a  = alpha

		draw.DrawText(msg, "TargetID", ScrW() * 0.5, ScrH() * 0.25, color, TEXT_ALIGN_CENTER)
	end

	hook.Add("HUDPaint", "PrintMessageCDraw", drawToScreen)
end