Scriptname SurgeonScript extends Actor  Conditional
{script for anyone who does face/body surgery}

ObjectReference Property SurgeryGurney Auto Const
{Gurney to sit in for the surgery. Be sure to flag HasSurgeon on the FaceGenFullSurgeryScript on the Gurney!}

GlobalVariable Property SurgeonCost Auto Const
{Global value for how much the surgery costs}

ActorValue Property BoughtSurgeryAV auto Const
{Used to Condition dialogue}

Keyword Property AnimFaceArchetypePlayer Auto Const
{Store Player Face Archetype. We need to switch player to Neutral while in the menu.}

InputEnableLayer Property FaceSurgeryInputLayer Auto Hidden

Bool var_SkeletonResetDone

Race Property HumanRace Auto Const
Race Property GhoulRace Auto Const
ActorBase Property EncCurieSynth Auto Const
Actor Property CurieRef Auto Const
Quest Property CompanionEditQuest Auto Const
ReferenceAlias Property CurieAlias Auto Const
Static Property XMarker Auto Const

Actor[] PlayerFollowers
Actor PlayerREF
Actor TargetREF
Bool FirstPerson

; purchase surgery
function BoughtSurgery()
	debug.trace(self + " BoughtSurgery called on SurgeonScript - Gurney is available")
	PlayerREF = Game.GetPlayer()
	SurgeryGurney.BlockActivation(True, False)
	SurgeryGurney.SetNoFavorAllowed(False)
	PlayerREF.RemoveItem(Game.GetCaps(), SurgeonCost.GetValueInt())
	; used to condition dialogue and packages
	SetValue(BoughtSurgeryAV, 1.0)
	Self.EvaluatePackage()
	RegisterForRemoteEvent(PlayerREF, "OnSit")
	RegisterForRemoteEvent(PlayerREF, "OnGetup")
	RegisterForRemoteEvent(SurgeryGurney, "OnActivate")
	RegisterForMenuOpenCloseEvent("LooksMenu")
	PlayerFollowers = Game.GetPlayerFollowers()
	int CurrentFollowerIndex = 0
	while (CurrentFollowerIndex < PlayerFollowers.Length)
		RegisterForRemoteEvent(PlayerFollowers[CurrentFollowerIndex], "OnSit")
		RegisterForRemoteEvent(PlayerFollowers[CurrentFollowerIndex], "OnGetUp")
		CurrentFollowerIndex += 1
	endWhile
endFunction

;reset everything
function ResetSurgeryGurney()
 	debug.trace(self + " ResetSurgeryGurney called on SurgeonScript - surgery used or expired")
	SurgeryGurney.BlockActivation(True, True)
	SurgeryGurney.SetNoFavorAllowed()
	; used to conditionalize dialogue and packages
	SetValue(BoughtSurgeryAV, 0.0)
	Self.EvaluatePackage()
	UnRegisterForRemoteEvent(PlayerREF, "OnSit")
	UnRegisterForRemoteEvent(PlayerREF, "OnGetup")
	UnRegisterForRemoteEvent(SurgeryGurney, "OnActivate")
	UnRegisterForMenuOpenCloseEvent("LooksMenu")
	int CurrentFollowerIndex = 0
	while (CurrentFollowerIndex < PlayerFollowers.Length)
		UnRegisterForRemoteEvent(PlayerFollowers[CurrentFollowerIndex], "OnSit")
		UnRegisterForRemoteEvent(PlayerFollowers[CurrentFollowerIndex], "OnGetUp")
		CurrentFollowerIndex += 1
	endWhile
	If TargetREF.GetActorBase() == EncCurieSynth
		UnRegisterForRemoteEvent(TargetREF, "OnGetUp")
	Endif
endFunction

;if I load again, reset the chair
Event OnLoad()
	ResetSurgeryGurney()
EndEvent

; if I die, reset the chair
Event OnDeath(Actor akKiller)
	ResetSurgeryGurney()
endEvent

Event ObjectReference.OnActivate(ObjectReference akSender, ObjectReference akActionRef)
	TargetREF = akActionRef as Actor
	If TargetREF == PlayerREF
		If TargetREF.IsInCombat()
			;do nothing
		ElseIf TargetREF.IsInPowerArmor()
			;do nothing
		ElseIf TargetREF.GetSitState()!=0
			;do nothing
		ElseIf akSender.IsFurnitureInUse()
			;do nothing
		Else
			;disable controls and force player into the chair
			FaceSurgeryInputLayer = InputEnableLayer.Create()
			FaceSurgeryInputLayer.DisablePlayerControls()

			;must force the player into first person is order to get the proper animation events
			Game.ForceFirstPerson()

			;start fading the game out during activation to hide resetting the chargen skeleton
			Game.FadeOutGame(True, True, 0.0, 2.0, True)

			;make sure player has CharGen Skeleton for editing
			;we also need to know when the player's skeleton has re-initialized before we force them into furniture, so listen for that anim event
			RegisterForAnimationEvent(PlayerREF, "FirstPersonInitialized")
			PlayerREF.SetHasCharGenSkeleton()

			;wait until the player graph has been fully re-initialized from the chargenskeleton set
			;failsafe the wait to last 10 seconds, if we haven't gotten the animation event by then, move forward
			int var_SkeletonResetFailsafeCount = 0
			While (var_SkeletonResetDone == False) && (var_SkeletonResetFailsafeCount < 10)
				Utility.Wait(1.0)
				var_SkeletonResetFailsafeCount += 1
			EndWhile

			UnRegisterForAnimationEvent(PlayerREF, "initiateStart")
			var_SkeletonResetDone=False

			akSender.Activate(TargetREF, True)
		EndIf
	ElseIf (TargetREF.getRace() == HumanRace || TargetREF.getRace() == GhoulRace)
		If TargetREF.IsInCombat()
			;do nothing
		ElseIf TargetREF.IsInPowerArmor()
			;do nothing
		Else
			;start fading the game out during activation to hide resetting the chargen skeleton
			Game.FadeOutGame(True, True, 0.0, 2.0, True)
		EndIf
	EndIf
EndEvent

;we registered for the FirstPersonIntitialized event, but what we really want to know is when it unregisters, because the CharGenSkeleton reset unregisters automatically when called
Event OnAnimationEventUnregistered(ObjectReference akSource, string asEventName)
	If asEventName == "FirstPersonInitialized"
		;now register for the event that fires when the third person graph is fully available
		RegisterForAnimationEvent(Game.GetPlayer(), "initiateStart")
	EndIf
EndEvent

Event OnAnimationEvent(ObjectReference akSource, string asEventName)
	;CharGenSkeleton has finished being removed or added, let any scripting waiting for this to move forward
	If (asEventName == "initiateStart")
		var_SkeletonResetDone = True
	EndIf
EndEvent

Event Actor.OnSit(Actor akSender, ObjectReference akFurniture)
	If (akFurniture == SurgeryGurney)
		SurgeryGurney.BlockActivation(True, True)
		If (TargetREF == PlayerREF || TargetREF.getRace() == HumanRace || TargetREF.getRace() == GhoulRace)
			SurgeryGurney.BlockActivation(False, False)
			If TargetREF == PlayerREF
				;make sure player face is Neutral
				PlayerREF.ChangeAnimFaceArchetype(None)
			Else
				If TargetREF == CurieRef
					CurieRef.Disable()
					TargetREF = CurieRef.PlaceActorAtMe(EncCurieSynth)
					TargetREF.WaitFor3DLoad()
					CurieAlias.ForceRefTo(TargetREF)
					TargetREF.SetHasCharGenSkeleton()
					TargetREF.SnapIntoInteraction(SurgeryGurney)
					RegisterForRemoteEvent(TargetREF, "OnGetUp")
				Endif
				Utility.Wait(1)
				If PlayerREF.IsWeaponDrawn()
					InputEnableLayer HolsterWeaponLayer = InputEnableLayer.Create()
						HolsterWeaponLayer.DisablePlayerControls()
						HolsterWeaponLayer.EnablePlayerControls()
					HolsterWeaponLayer = None
				Endif
				FirstPerson = PlayerREF.GetAnimationVariableBool("IsFirstPerson")
				Game.ForceFirstPerson()
				ObjectReference CameraMarker = SurgeryGurney.PlaceAtMe(XMarker)
				Float ChairAngle = SurgeryGurney.GetAngleZ()
				Float OffsetX = Math.sin(ChairAngle) * 50
				Float OffsetY = Math.cos(ChairAngle) * 50
				CameraMarker.MoveTo(SurgeryGurney, afXOffset = OffsetX, afYOffset = OffsetY)
				CameraMarker.SetAngle(0, 0, CameraMarker.GetAngleZ() + CameraMarker.GetHeadingAngle(SurgeryGurney))
				PlayerREF.MoveTo(CameraMarker)
				CameraMarker.Delete()
				If !PlayerREF.IsSneaking()
					PlayerREF.StartSneaking()
				Endif
				RegisterForMenuOpenCloseEvent("LooksMenu")
			Endif
			Game.ShowRaceMenu(uimode = 3, akMenuTarget = TargetREF)
			UnRegisterForRemoteEvent(TargetREF, "OnSit")
			;fade the game back up
			Game.FadeOutGame(False, True, 1.0, 2.0)
		EndIf
	EndIf
EndEvent

Event Actor.OnGetUp(Actor akSender, ObjectReference akFurniture)
	If (akFurniture == SurgeryGurney)
		SurgeryGurney.BlockActivation(True, False)
		If (TargetREF == PlayerREF || TargetREF.getRace() == HumanRace || TargetREF.getRace() == GhoulRace)
			ResetSurgeryGurney()
			If TargetREF == PlayerREF
				;we need to know when the player's skeleton has re-initialized before we can let them move
				RegisterForAnimationEvent(PlayerREF, "FirstPersonInitialized")
				;make sure the CharGen skeleton has been removed
				PlayerREF.SetHasCharGenSkeleton(False)
				;make sure player face is back to Player archetype
				PlayerREF.ChangeAnimFaceArchetype(AnimFaceArchetypePlayer)

				;wait until the player graph has been fully re-initialized from the chargenskeleton set
				;failsafe the wait to last 10 seconds, if we haven't gotten the animation event by then, move forward
				int var_SkeletonResetFailsafeCount = 0
				While (var_SkeletonResetDone == False) && (var_SkeletonResetFailsafeCount < 10)
					Utility.Wait(1.0)
					var_SkeletonResetFailsafeCount += 1
					debug.trace(var_SkeletonResetDone)
					debug.trace(var_SkeletonResetFailsafeCount)
				EndWhile

				UnRegisterForAnimationEvent(PlayerREF, "initiateStart")
				var_SkeletonResetDone=False

				Game.FadeOutGame(False, True, 1.0, 2.0)
				
				;enable controls
				FaceSurgeryInputLayer.EnablePlayerControls()
				FaceSurgeryInputLayer = None
			Else
				TargetREF.SetHasCharGenSkeleton(False)
			EndIf
			UnRegisterForRemoteEvent(TargetREF, "OnGetUp")
		EndIf
	EndIf
EndEvent

Event OnMenuOpenCloseEvent(string asMenuName, bool abOpening)
	if (asMenuName == "LooksMenu" && !abOpening)
		If TargetREF == PlayerREF
			Game.FadeOutGame(True, True, 0.0, 2.0, True)
		Else
			If PlayerREF.IsSneaking()
				PlayerREF.StartSneaking()
			Endif
			If !FirstPerson
				Game.ForceThirdPerson()
			Endif
			If TargetREF.GetActorBase() == EncCurieSynth
				CurieAlias.Clear()
				TargetREF.SetHasCharGenSkeleton(False)
				TargetREF.Delete()
				CurieRef.Enable()
				CompanionEditQuest.SetStage(10)
			Else
				TargetREF.Disable()
				TargetREF.Enable()
			Endif
			UnRegisterForMenuOpenCloseEvent("LooksMenu")
		EndIf
	EndIf
EndEvent

;84093 - do not set the chargen skeleton during OnLoad/OnUnload events, as the player might be in power armor and the skeletons are incompatible
;Event ObjectReference.OnUnload(ObjectReference akSender)
;	Actor PlayerREF = Game.GetPlayer()
	;when the player unloads next, clear the chargenskeleton
	;PlayerREF.SetHasCharGenSkeleton(False)
;	UnRegisterForRemoteEvent(PlayerREF, "OnUnload")
;EndEvent