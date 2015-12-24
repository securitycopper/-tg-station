
/datum/power/PowerNetwork
	var/uuid=0

	var/name="Unkown Power Network"
	//ManagedBy: PowerNetwork
	var/currentSupply=0
	var/currentLoad=0
	var/flagedAsChanged=0
	var/requestedAdditionalPower=0

	var/list/attached= list()

	var/list/autoResumePower = list()

	//ManagedBy: PowerNetwork,PowerNode
	var/availableDelta=0

/datum/power/PowerNetwork/New()
	uuid=getUniqueID()



/**
//add to correct list and update network size
/datum/power/PowerNetwork/proc/addPowerNode(var/datum/power/PowerNode/node)
	if(flagedAsChanged==0)
		flagedAsChanged=1
		LIST_ADDLAST(powerControllerWireNetworkProcessingLoopList,src)
	LIST_ADDLAST(attached,node)
	if
**/
/datum/power/PowerNetwork/proc/printDebug()
	world<<"Power network [uuid]: currentSupply=[currentSupply], currentLoad=[currentLoad], availableDelta=[availableDelta], flagedAsChanged=[flagedAsChanged]"
	for(var/datum/power/PowerNode/node in attached)
		world<<"Attached: PowerNode:[node.name] PowerUsage: [node.currentPowerUsage]"


/datum/power/PowerNetwork/proc/processTick()
	//TODO: Remove reclaculate logic. it is here for intial testing and should be replaced with more efficent processing
	//world<<"Power network [uuid]:processTick"

	recalculate()

	//Iterate though each autoResumePower and

	//For now will only process one new offline node per tick
	//Find a node that can be turned on, that is in a brown out state
	var/datum/power/PowerNode/targetRestartNode = null

	//world<<"Power network [uuid]:autoResumePowerLen:[autoResumePower.len]"
	for(var/datum/power/PowerNode/node in autoResumePower)
		if(node.requestedPowerUsage<=currentSupply)
			targetRestartNode=node
			break

	//world<<"Power network [uuid]: end of for loop"
	//Check if a target was found
	if(targetRestartNode!=null)
		//world<<"Power network [uuid]:Restarting Node: [targetRestartNode.name]"

		//Roll
		attached-=targetRestartNode
		LIST_ADDLAST(attached,targetRestartNode)


		var/amountNeeded=targetRestartNode.requestedPowerUsage

		for(var/datum/power/PowerNode/node in attached)
			if(amountNeeded>availableDelta)
				if(node.currentPowerUsage>0)
					node.brownOut()
			else
				break


		targetRestartNode.setPower(amountNeeded)
		return 1

	//Return 0 if no aditional processing is needed
	//Do this at very end of tick
	flagedAsChanged=0
	return 0


//Force a reprocessing of the PowerNetwork. This method will be removed once delta logic is put in place
/datum/power/PowerNetwork/proc/recalculate()
//	world<<"Power network [uuid]:Recalculating"

	autoResumePower = list()
	currentSupply=0
	currentLoad=0
	requestedAdditionalPower=0
	for(var/datum/power/PowerNode/node in attached)
		//world<<"node:[node.name] currentPowerUsage=[node.currentPowerUsage]"
		if(node.currentPowerUsage<0)
			//Supply
			currentSupply-=node.currentPowerUsage
		else
			if(node.currentPowerUsage>0)
				//Consumer
				currentLoad+=node.currentPowerUsage
			else
				if(node.requestedPowerUsage>0)
					//Off and is set to auto start
					autoResumePower+=node
					requestedAdditionalPower+=node.requestedPowerUsage

	if(currentLoad>currentSupply)
		world<<"Power network [uuid] has errors"


	availableDelta=currentSupply-currentLoad


	//END OF PROC


/datum/power/PowerNetwork/proc/flagAsChanged()
	if(flagedAsChanged==0)
		powerControllerWireNetworkProcessingLoopList+=src
		flagedAsChanged=1
	//END OF PROC