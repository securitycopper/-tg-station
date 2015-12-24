
//Attaching this to a network will cause the network to turn off all other machines to power this one.
/datum/power/PowerNode/Short
	var/flagedForProcessing=0
	var/shortedAmount=0

/datum/power/PowerNode/Short/addPowerNetwork(var/datum/power/PowerNetwork/network)
	if(flagedForProcessing==1)
		//Can only be called once per tick
		return
	..()
	//It won't be able to set this power so it will brown out. but on next tick, all other machines will turn off to power this on
	// so even though it is delayed by one tick, it effectifly did short the network for a tick
	shortedAmount=network.currentSupply
	setPower(shortedAmount)
	//However the node is added to the end. to force it to be the next one to be processed, we are going to modify the network
	network.attached-=src
	//now put it at the front so it will be the first brownout to turn on.
	LIST_ADDFIRST(network.attached,src)

	//This line may be redundent but it does't hurt anything
	network.flagAsChanged()

	flagForProcessing()


	//END OF PROC

/datum/power/PowerNode/Short/processTick()

	//Remove from network
	dispose()


	flagedForProcessing=0
	//Return 0 will remove it from being processed again
	return 0
	//END of PROC

/datum/power/PowerNode/Short/flagForProcessing()
	if(flagedForProcessing==1)
		return
	//Add to processing loop
	powerControllerPowerNodeConsumerProcessingLoopList+=src
	flagedForProcessing=1

