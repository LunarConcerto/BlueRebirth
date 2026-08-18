local m = {}

function m:GetFloat(name)
end

function m:SetFloat(name, value)
end

function m:GetBool(name)
end

function m:SetBool(name, value)
end

function m:GetInteger(name)
end

function m:SetInteger(name, value)
end

function m:SetTrigger(name)
end

function m:ResetTrigger(name)
end

function m:IsParameterControlledByCurve(name)
end

function m:GetIKPosition(goal)
end

function m:SetIKPosition(goal, goalPosition)
end

function m:GetIKRotation(goal)
end

function m:SetIKRotation(goal, goalRotation)
end

function m:GetIKPositionWeight(goal)
end

function m:SetIKPositionWeight(goal, value)
end

function m:GetIKRotationWeight(goal)
end

function m:SetIKRotationWeight(goal, value)
end

function m:GetIKHintPosition(hint)
end

function m:SetIKHintPosition(hint, hintPosition)
end

function m:GetIKHintPositionWeight(hint)
end

function m:SetIKHintPositionWeight(hint, value)
end

function m:SetLookAtPosition(lookAtPosition)
end

function m:SetLookAtWeight(weight)
end

function m:SetBoneLocalRotation(humanBoneId, rotation)
end

function m:GetBehaviours(fullPathHash, layerIndex)
end

function m:GetLayerName(layerIndex)
end

function m:GetLayerIndex(layerName)
end

function m:GetLayerWeight(layerIndex)
end

function m:SetLayerWeight(layerIndex, weight)
end

function m:GetCurrentAnimatorStateInfo(layerIndex)
end

function m:GetNextAnimatorStateInfo(layerIndex)
end

function m:GetAnimatorTransitionInfo(layerIndex)
end

function m:GetCurrentAnimatorClipInfoCount(layerIndex)
end

function m:GetNextAnimatorClipInfoCount(layerIndex)
end

function m:GetCurrentAnimatorClipInfo(layerIndex)
end

function m:GetNextAnimatorClipInfo(layerIndex)
end

function m:IsInTransition(layerIndex)
end

function m:GetParameter(index)
end

function m:MatchTarget(matchPosition, matchRotation, targetBodyPart, weightMask, startNormalizedTime)
end

function m:InterruptMatchTarget()
end

function m:CrossFadeInFixedTime(stateName, fixedTransitionDuration)
end

function m:CrossFade(stateName, normalizedTransitionDuration, layer, normalizedTimeOffset)
end

function m:PlayInFixedTime(stateName, layer)
end

function m:Play(stateName, layer)
end

function m:SetTarget(targetIndex, targetNormalizedTime)
end

function m:GetBoneTransform(humanBoneId)
end

function m:StartPlayback()
end

function m:StopPlayback()
end

function m:StartRecording(frameCount)
end

function m:StopRecording()
end

function m:HasState(layerIndex, stateID)
end

function m.StringToHash(name)
end

function m:Update(deltaTime)
end

function m:Rebind()
end

function m:ApplyBuiltinRootMotion()
end

return m
