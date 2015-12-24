

/datum/power/PowerNode/CellAdapter
	var/flagedForProcessing=0
	var/obj/item/weapon/stock_parts/cell/cell

/datum/power/PowerNode/CellAdapter/New(var/obj/item/weapon/stock_parts/cell/wrappedCell)
	..(wrappedCell.name)
	power_type=POWER_TYPE_ONDEMAND_PRODUCER


/datum/power/PowerNode/CellAdapter/addPowerNetwork(var/datum/power/PowerNetwork/network)
	//ResetNode
	dispose()
	addPowerNetwork(network)



/datum/power/PowerNode/CellAdapter/processTick()
	//Get wirenetwork status
	if(selectedSource==null)
		flagedForProcessing=0
		return 0

	//Subtract or add last usage
	if(POWERNODE_ISSUPPLYINGPOWER(src))
		cell.give(POWERNODE_GETSUPPLYCURRENT(src))
	if(POWERNODE_ISCONSUMINGPOWER(src))
		cell.use(POWERNODE_GETCONSUMINGCURRENT(src))


	//We have a network, lets check its demand
	var/networkExcessSupply=POWERNETWORK_GETEXCESSSUPPLY_EXCLUDEPOWERNODE(selectedSource,src)
	if(networkExcessSupply>0)
		//Set New Charge Rate
		var/newChargeRate=min(min(cell.chargerate,cell.maxcharge-cell.charge),networkExcessSupply)
		setPower(newChargeRate)
		if(newChargeRate==0)
			//Stop processing this node because no change on future ticks.
			flagedForProcessing=0
			return 0
		return 1

	if(networkExcessSupply<=0)
		//Set new discharge rate
		var/newDischargeRate=min(-networkExcessSupply,cell.charge)
		POWERNODE_SETSUPPLYCURRENT(src,newDischargeRate)
		if(newDischargeRate==0)
			//Stop processing this node because no change on future ticks.
			flagedForProcessing=0
			return 0
		return 1

	//END PROC





/datum/power/PowerNode/CellAdapter/flagForProcessing()
	if(flagedForProcessing==0)
		flagedForProcessing=1
		powerControllerPowerNodeProducerProcessingLoopList+=src
	//END OF PROC