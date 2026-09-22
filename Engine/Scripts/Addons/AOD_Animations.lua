-- FILE: \AOD_Animations.lua

LevelFuncs.External = LevelFuncs.External or {}
LevelFuncs.External.AOD_Animations = {}

local STATE_STOP = 2
local STATE_GRABBING = 19
local STATE_LADDER_UP = 57
local STATE_CROUCH_IDLE = 71

local ANIM_SAFETY_GRAB_LEFT = 14
local ANIM_FALL_START = 34
local ANIM_LADDER_UP = 161
local ANIM_LADDER_UP_STOP_LEFT = 163
local ANIM_LADDER_DOWN_STOP_LEFT = 166
local ANIM_LADDER_DOWN = 168
local ANIM_SAFE_DROP_FRONT_START_STAND = 578
local ANIM_SAFE_DROP_FRONT_START_CROUCH = 579
local ANIM_SAFE_DROP_BACK_START = 576

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

	if LaraAnim == ANIM_LADDER_UP then
		if LaraFrame >= 26 and LaraFrame <= 29 then
			-- Stopped by player releasing Up key
			if TEN.Input.IsKeyHeld(Input.ActionID.FORWARD) == false then
				Lara:SetAnim(ANIM_LADDER_UP_STOP_LEFT)
				local position = Lara:GetPosition()
				position.y = position.y - 256
				Lara:SetPosition(position, false) -- Do not update rooms automatically, or Lara will get stuck if there are overlapping rooms
			end
			-- Stopped because a ledge was found and Lara is about to vault onto it
			if (Lara:GetState() == STATE_LADDER_UP and Lara:GetTargetState() == STATE_GRABBING) then
				Lara:SetAnim(ANIM_LADDER_UP_STOP_LEFT)
			end
		end
	else
		if LaraAnim == ANIM_LADDER_DOWN then
			if LaraFrame >= 27 and LaraFrame <= 29 and TEN.Input.IsKeyHeld(Input.ActionID.BACK) == false then
				Lara:SetAnim(ANIM_LADDER_DOWN_STOP_LEFT)
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

	if LaraAnim == ANIM_FALL_START
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
			Lara:SetAnim(ANIM_SAFETY_GRAB_LEFT)
			-- Note: ideally we could detect what Lara was doing before running off the ledge, and trigger the correct transition.
			-- But the current implementation relies on triggering the animation after she has started falling, so we only know about that.
		end

	end
end
LevelFuncs.External.AOD_Animations.LastChanceGrab_PostLoop = function()

	local LaraAnim = Lara:GetAnim()
	local LaraFrame = Lara:GetFrame()

	if LaraAnim == ANIM_SAFETY_GRAB_LEFT then
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


---Tests for a ledge "in front" of a position.
---1. First, checks that there is a pit which is deep enough (3 clicks). It is tested in 3 lateral positions to check if it's wide enough (the width Lara has when hanging).
---2. If there is a pit wide enough, finds the ledge's exact position and normal, and returns it.
---
---This piece of art describes how the check is done:
--- >            /O
--- >           //│\
--- >           / ╽ \
--- >            ◞█◟  pos    -> rot
--- >            │ │   ○┄┄┄┄┄┄┄┄┄┄┄┐
--- >            │ │               ┊
--- > ══════════════════════╕      ┊
--- >                2. Ray │      ┊
--- >                 🯄 ◀┄┄┄┼┄┄┄┄┄┄┤
--- >                       │      ┊
--- >                      ╱       ┊
--- >                     ╱        ┊
--- >                    ╱         ▼ 1. Probe
--- >                   ╱    
--- 
---@param pos Vec3					Lara's position
---@param roomNumber number			Lara's current room number
---@param rot Rotation				Lara's rotation. The ledge will be probed for in the opposite direction
---@return boolean	IsLedgeFound	True if a ledge was found
---@return Vec3|nil	LedgeNormal		If a ledge was found, its normal
---@return Vec3|nil	LedgePosition	If a ledge was found, its position
function TestForLedgeInFront(pos, roomNumber, rot)

	local PROBE_X_POSITIONS = {-113, 0, 113} -- When hanging (animation 45), her collision box extends to ~113 units on each side of the X axis
	local PROBE_DISTANCE = 256
	local PROBE_DEPTH = 1
	local MIN_HEIGHT = 3 * 256

	local IsLedgeFound = false
	local LedgeNormal = nil
	local LedgePosition = nil

	local HasRoomToHang = {false, false, false} -- Left, Front, Right

	-- 1. Test for a pit in front of Lara
	-- We test at 3 positions: front-left & front & front-right, to make sure she actually has enough room to hang
	for i = 1, 3, 1 do
		local ProbePos = pos
			:Translate(rot:Direction(), PROBE_DISTANCE) -- Move the probe forward
			:Translate((rot + Rotation(0, 90, 0)):Direction(), PROBE_X_POSITIONS[i]) -- Move the probe to the side (to check if the pit is wide enough)

		local ProbeFront = TEN.Collision.Probe(ProbePos, roomNumber)
		local DistanceFromFloorFront = math.abs(
			pos.y
			- (ProbeFront:GetFloorHeight() or 0)
		)
		HasRoomToHang[i] = (not ProbeFront:IsWall()) and DistanceFromFloorFront > MIN_HEIGHT
	end

	-- print("HasRoomToHang="..tostring(HasRoomToHang[1])..","..tostring(HasRoomToHang[2])..","..tostring(HasRoomToHang[3]))

	-- 2. There's a pit, and it's deep AND wide enough? Find the ledge normal
	if HasRoomToHang[1] and HasRoomToHang[2] and HasRoomToHang[3] then

		local rayStartPos = pos:Translate(rot:Direction(), PROBE_DISTANCE):Translate(Vec3(0, 1, 0), PROBE_DEPTH) -- Move forward, then downward

		-- First, we need to room number at the start position of the ray.
		-- So we probe from Lara's position (slightly above) into the position we want the ray to start.
		local probeRayStart = TEN.Collision.Probe(
			pos,
			roomNumber,
			(rayStartPos - pos):Normalize(), -- direction
			(rayStartPos - pos):Length() -- dist
		)
		local rayStartRoomNumber = probeRayStart:GetRoomNumber() -- or roomNumber
		-- print("rayStartRoomNumber= "..tostring(rayStartRoomNumber))

		-- We start a ray a bit in front, a bit below the source position, and point backwards to hit the wall that makes the ledge
		local ledgeRay = TEN.Collision.Ray(
			rayStartPos,
			rayStartRoomNumber,
			(rot + Rotation(0, 180, 0)):Direction(), -- direction: we're probing from the front into the ledge (ie. backward)
			PROBE_DISTANCE, -- distance
			TEN.Collision.IntersectionType.NONE, -- hitMoveables
			TEN.Collision.IntersectionType.NONE -- hitStatics
		)

		-- print("ledgeRay:GetRoomPosition()="..tostring(ledgeRay:GetRoomPosition()))
		ledgeRay:Preview()

		-- if ray:HitRoom() then
		if ledgeRay:GetRoomNormal() ~= nil then
			IsLedgeFound = true
			LedgeNormal = ledgeRay:GetRoomNormal()
			LedgePosition = ledgeRay:GetRoomPosition()
		end

	end

	return IsLedgeFound, LedgeNormal, LedgePosition

end

---comment
---@todo A few issues with this:
--- - Safe drop triggers if you save your game using Action. But not with the inventory for some reason (maybe the inventory does some "Clear key" thing when the key was used to exit the inventory?)
--- - Safe drop triggers even if Lara is able to do some interaction (eg. the player wants to push/pull a block - could happen in other situations, so an extra check should be done even if the following bug is solved)
--- - If Lara is standing on a pushable block, and in front of her is another pushable block (itself sitting on a pushable block), she might trigger the safe drop animation. Happens when facing North at least in the demo level. Some check might be missing.
--- 
--- Unrelated but before it's lost:
--- - Crawling back into a death sector triggers the original "climb down to ledge" animation, rather than stopping and dying. Probably a typo in state changes. Check if it happens with official TEN anims, could be a bug there too?
--- - Side-stepping into a death sector doesn't stop the side stepping (check if original TEN anims do that too)
--- - Just to be sure: check if wading is interrupted when Lara dies (check if original TEN anims do that)
LevelFuncs.External.AOD_Animations.SafeDrop = function()

	local LaraState = Lara:GetState()
	local LaraAnim = Lara:GetAnim()
	local LaraFrame = Lara:GetFrame()

	if (LaraState == STATE_STOP or LaraState == STATE_CROUCH_IDLE)
	and TEN.Input.IsKeyHit(TEN.Input.ActionID.ACTION)
	and TEN.Objects.Lara:GetHandStatus() == TEN.Objects.HandStatus.FREE
	then

		local IsLedgeFound = false
		local WillLaraFlip = false
		local LedgeNormal = nil
		local LedgePosition = nil

		local pos = Lara:GetPosition()
		local rot = Lara:GetRotation()
		local roomNumber = Lara:GetRoomNumber()

		local newAnim = nil
		local newPos = nil
		local newRot = nil

		-- First, test for a ledge in front of Lara
		IsLedgeFound, LedgeNormal, LedgePosition = TestForLedgeInFront(pos, roomNumber, rot)

		if IsLedgeFound then
			WillLaraFlip = true
			newAnim = (LaraState == STATE_STOP
				and ANIM_SAFE_DROP_FRONT_START_STAND
				or ANIM_SAFE_DROP_FRONT_START_CROUCH
			)
		else

			-- No ledge found in front of Lara:
			-- Test for a ledge behind Lara
			if LaraState == STATE_STOP then

				IsLedgeFound, LedgeNormal, LedgePosition = TestForLedgeInFront(pos, roomNumber, rot + Rotation(0, 180, 0))
				if IsLedgeFound then
					WillLaraFlip = false
					newAnim = ANIM_SAFE_DROP_BACK_START
				end

			end
		end


		-- Ledge found? Align Lara and trigger the appropriate animation
		if IsLedgeFound then

			-- If the ledge was found in Lara's front, she will flip 180° - we have to take that into account
			local rotFlipCompensation = Rotation(0, 180, 0)
			if WillLaraFlip then
				rotFlipCompensation = Rotation(0, 0, 0)
			end

			-- Rotate Lara so she faces the ledge correctly
			newRot = RotationFromDirection(LedgeNormal) + rotFlipCompensation
			-- We only want to change Lara's Y rotation
			newRot.x = 0
			newRot.z = 0

			-- Move Lara so she's at the exact required distance from the ledge
			newPos = TEN.Vec3(LedgePosition.x, pos.y, LedgePosition.z)
				:Translate((newRot + Rotation(0, 180, 0) + rotFlipCompensation):Direction(), -99) -- Lara needs to land at -99 units from the ledge
				:Translate((newRot + Rotation(0, 180, 0) + rotFlipCompensation):Direction(), 200) -- But we need to take into account that she moves 200 units with the animation (the Set Position command)

			Lara:SetAnim(newAnim)
			Lara:SetPosition(newPos)
			Lara:SetRotation(newRot)
			Lara:SetHandStatus(TEN.Objects.HandStatus.BUSY)
		end

	end

end

TEN.Logic.AddCallback(CallbackPoint.PRELOOP, LevelFuncs.External.AOD_Animations.FixLadderStopSnap)
TEN.Logic.AddCallback(CallbackPoint.PRELOOP, LevelFuncs.External.AOD_Animations.AODLook)
TEN.Logic.AddCallback(CallbackPoint.PRELOOP, LevelFuncs.External.AOD_Animations.LastChanceGrab_PreLoop)
TEN.Logic.AddCallback(CallbackPoint.POSTLOOP, LevelFuncs.External.AOD_Animations.LastChanceGrab_PostLoop)
TEN.Logic.AddCallback(CallbackPoint.POSTLOOP, LevelFuncs.External.AOD_Animations.SafeDrop)