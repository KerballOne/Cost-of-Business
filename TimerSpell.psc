Scriptname COB:TimerSpell Extends ActiveMagicEffect
 
COB:Questscript Property CBQ Auto Mandatory Const

Event OnEffectStart(ObjectReference akTarget, Actor akCaster, MagicEffect akBaseEffect, float afMagnitude, float afDuration)
    akTarget.SetDestroyed(true)
    CBQ.CDBG("Outpost Construction started on " + akTarget)
EndEvent

Event OnEffectFinish(ObjectReference akTarget, Actor akCaster, MagicEffect akBaseEffect, float afMagnitude, float afDuration)
    CBQ.CDBG("Outpost Construction complete on " + akTarget)
    Debug.Notification("Construction finished for " + akTarget)
    akTarget.RemoveKeyword(CBQ._COB_Refundable)
    akTarget.RemoveKeyword(CBQ._COB_FreeMove)
    akTarget.SetDestroyed(false)
    ;CBQ.TogglePower(akTarget)
    ;CBQ.EndConstruction(akTarget)
EndEvent

