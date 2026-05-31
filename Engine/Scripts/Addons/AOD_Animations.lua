-- FILE: \AOD_Animations.lua

LevelFuncs.External = LevelFuncs.External or {}
LevelFuncs.External.AOD_Animations = {}


---Returns a Rotational from a Vec3 - useful for converting for example a face normal into a rotation.
---@deprecated TEN 2.0 should come with a Rotation() constructor which takes a direction Vec3.
---@param dir Vec3
---@return Rotation
local RotationFromDirection = function(dir)
    local yaw = math.deg(math.atan(dir.x, dir.z))
    local pitch = -math.deg(math.atan(dir.y, math.sqrt(dir.x^2 + dir.z^2)))
    local roll = 0
    return Rotation(pitch, yaw, roll)
end


--- Prevents Lara from snapping when she stops going up or down on a ladder in the middle of the animation.
---
--- Handles the snapping that occurs where the player stops moving deliberately.
--- Also handles the snapping when a ledge was found and Lara is about to vault onto it, although there is a visible garbage frame.
--- Snapping still occurs when Lara is stopped by a ceiling or a floor, there is no way around that with the current API.
---
--- Required because of the hardcoded handling of these transitions.
---
--- @author Bagas
--- @author JoeyQuint
LevelFuncs.External.AOD_Animations.FixLadderStopSnap = function()

	local LaraAnim = Lara:GetAnim()
	local LaraFrame = Lara:GetFrame()

	if LaraAnim == 161 --[[ LADDER_UP ]] then
		if LaraFrame >= 26 and LaraFrame <= 29 then
			-- Stopped by player releasing Up key
			if TEN.Input.IsKeyHeld(Input.ActionID.FORWARD) == false then
				Lara:SetAnim(163 --[[ LADDER_UP_STOP_LEFT ]])
				local position = Lara:GetPosition()
				position.y = position.y - 256
				Lara:SetPosition(position, false) -- Do not update rooms automatically, or Lara will get stuck if there are overlapping rooms
			end
			-- Stopped because a ledge was found and Lara is about to vault onto it
			if (Lara:GetState() == 57 --[[ LADDER_UP ]] and Lara:GetTargetState() == 19 --[[ GRABBING ]]) then
				Lara:SetAnim(163 --[[ LADDER_UP_STOP_LEFT ]])
			end
		end
	else
		if LaraAnim == 168 --[[ LADDER_DOWN ]] then
			if LaraFrame >= 27 and LaraFrame <= 29 and TEN.Input.IsKeyHeld(Input.ActionID.BACK) == false then
				Lara:SetAnim(166 --[[ LADDER_DOWN_STOP_LEFT ]])
				local position = Lara:GetPosition()
				position.y = position.y + 256
				Lara:SetPosition(position, false) -- Do not update rooms automatically, or Lara will get stuck if there are overlapping rooms
			end 
		end
	end

end

LevelFuncs.External.AOD_Animations.AODLook = function()
	if GameVars.ProcessedAODLook ~= true and Lara:GetAnim() == 103 and Lara:GetFrame() > 108 and TEN.Input.IsKeyHit(ActionID.LOOK) and Lara:GetHandStatus() == 0 and Lara:GetRotation().y == 0 then
		local rot = Lara:GetRotation()
		Lara:SetAnim(383)
		GameVars.ProcessedAODLook = true
	end
	if Lara:GetAnim() == 383 and TEN.Input.IsKeyHeld(ActionID.LOOK) == false then
		local frame = Lara:GetFrame()
		Lara:SetAnim(103)
		Lara:SetFrame(frame)
	end
end

--- Allows Lara to quickly turn around and grab a ledge when running off it.
--- 
--- @author shabaobab
--- @author JoeyQuint
LevelFuncs.External.AOD_Animations.LastChanceGrab_PreLoop = function()

	local LaraAnim = Lara:GetAnim()
	local LaraFrame = Lara:GetFrame()

	if LaraAnim == 34 --[[ FALL_START ]]
	and LaraFrame == 0
	and TEN.Input.IsKeyHeld(TEN.Input.ActionID.ACTION)
	and Lara:GetVelocity().z > 0 -- Only allow if Lara actually was moving forward (prevents triggering it from exiting DOZY or possible edge cases)
	then

		local DistanceFromFloor = math.abs(
			Lara:GetPosition().y
			- TEN.Collision.Probe(Lara:GetPosition(), Lara:GetRoomNumber()):GetFloorHeight()
		)

		local IsPitDeepEnough = DistanceFromFloor > 3 * 256

		if IsPitDeepEnough
		and TEN.Objects.Lara:GetHandStatus() == TEN.Objects.HandStatus.FREE
		then
			Lara:SetAnim(14 --[[ SAFETY_GRAB_LEFT ]])
			-- Note: ideally we could detect what Lara was doing before running off the ledge, and trigger the correct transition.
			-- But the current implementation relies on triggering the animation after she has started falling, so we only know about that.
		end

	end
end
LevelFuncs.External.AOD_Animations.LastChanceGrab_PostLoop = function()

	local LaraAnim = Lara:GetAnim()
	local LaraFrame = Lara:GetFrame()

	if LaraAnim == 14 --[[ SAFETY_GRAB_LEFT ]] then
		if LaraFrame ~= Lara:GetEndFrame() then
			Lara:SetAirborne(false)

			-- Force Lara's orientation to remain aligned to the ledge.

			-- Note: Lara has played the fall animation 1 frame (= moved down 6 units with gravity at 6), but her vertical position is stuck during the entire safety grab animation.
			-- We use that to our advantage: we can reliably check if there's a ledge she can grab "behind" her, and if so we align her to it during the entire safety grab animation.
			local ray = TEN.Collision.Ray(
				Lara:GetPosition(),
				Lara:GetRoomNumber(),
				(Lara:GetRotation() + TEN.Rotation(0, 180, 0)):Direction(), -- direction: Use Lara's current orientation, but backwards
				256, -- distance: Check back up to 2 clicks, because she has moved a little forward because of the fall animation
				TEN.Collision.IntersectionType.NONE, -- hitMoveables
				TEN.Collision.IntersectionType.NONE -- hitStatics
			)
			local roomSurfaceNormal = ray:GetRoomNormal()

			if roomSurfaceNormal ~= nil then
				local targetRot = TEN.Rotation(0, RotationFromDirection(roomSurfaceNormal).y, 0) -- We only want to change Lara's Y rotation
				-- Note: instinctively, we might want to use the opposite direction of the normal (+180°). But no: Lara real rotation hasn't actually been flipped yet during the animation.
				Lara:SetRotation(targetRot)
			end

		else
			Lara:SetAirborne(true)

			-- As we prevent gravity from operating during the animation (since it's visually baked in the animation), we have to compensate at the end.

			-- Fall speed is required to:
			-- - Prevent a jarring visual stop in her momentum
			-- - Have her take about the same damage as if she had simply run off the ledge
			-- With the default gravity of 6.0, tests show a hop back gives her a fall speed of about 84 (when she reaches an equivalent vertical position).
			-- We take the actual gravity into account in case the builder has changed it in their game.
			local fallSpeed = 84 * (6.0 / TEN.Flow.GetSettings().Physics.gravity) -- TODO: broken?

			-- Forward speed is also required to grab the ledge.
			-- When running off the ledge, or even with a back hop, her forward speed is simply the same that she had when she was still on the ground.
			-- At this point, animations have switched and forward velocity has been reset, so we've lost that info. Also, high speed makes Lara embed into diagonal ledges.
			local forwardSpeed = 2

			Lara:SetVelocity(TEN.Vec3(0, fallSpeed, forwardSpeed))
			-- Note: To grab the ledge, Lara needs a forward speed > 0. With a forward speed of 1, the max fall speed that allows her to succesfully grab the ledge is 54.
			-- This limit increases as the forward speed increases.

			-- Also shift Lara away from the wall, to prevent her embedding (and failing to grab) on certain angles with diagonal ledges
			Lara:SetPosition(Lara:GetPosition():Translate(Lara:GetRotation(), 16)) -- Positive value, because she still hasn't flipped yet

		end
	end

end

TEN.Logic.AddCallback(CallbackPoint.PRELOOP, LevelFuncs.External.AOD_Animations.FixLadderStopSnap)
TEN.Logic.AddCallback(CallbackPoint.PRELOOP, LevelFuncs.External.AOD_Animations.AODLook)
TEN.Logic.AddCallback(CallbackPoint.PRELOOP, LevelFuncs.External.AOD_Animations.LastChanceGrab_PreLoop)
TEN.Logic.AddCallback(CallbackPoint.POSTLOOP, LevelFuncs.External.AOD_Animations.LastChanceGrab_PostLoop)