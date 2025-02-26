Scriptname COB:DetectiveScript Extends ReferenceAlias

COB:Questscript Property CBQ Auto Mandatory Const
{ This is our QuestScript so we can call events cleanly there }

Spell Property _COB_PlacementCooldown Mandatory Const Auto 

;These just pass the ObjectReference into our quests scripts to do whatever with
Event OnWorkshopObjectPlaced(ObjectReference akReference)
    CBQ.PlacementHandler(akReference)
    _COB_PlacementCooldown.Cast(akReference)
EndEvent

Event OnWorkshopObjectMoved(ObjectReference akReference)
    CBQ.MovementHandler(akReference)
    _COB_PlacementCooldown.Cast(akReference)
EndEvent

Event OnWorkshopObjectRemoved(ObjectReference akReference)
    CBQ.RemovalHandler(akReference)
EndEvent

Event OnWorkshopMode(bool aStart)
    CBQ.WorkshopModeHandler(aStart)   
EndEvent