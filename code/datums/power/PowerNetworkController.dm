//1. Process nodes that supply power
//2. Update the wire networks that changed due to the supply changes
//3. Update the consumers
var/global/list/powerControllerPowerNodeProducerProcessingLoopList = list()
var/global/list/powerControllerWireNetworkProcessingLoopList = list()
var/global/list/powerControllerPowerNodeConsumerProcessingLoopList = list()


var/global/list/powerControllerPowerActivePowerTicks = list()


var/global/currentUniqueId = 0
proc/global/getUniqueID()
	currentUniqueId++
	return currentUniqueId



/datum/PowerNetworkController


/datum/PowerNetworkController/proc/processPower()
	//world<<"PowerNetworkController processPower"
	//Simulate an iteration
	for(var/datum/power/PowerNode/powerNodeProducer in powerControllerPowerNodeProducerProcessingLoopList)
		powerNodeProducer.processTick()

	//Process PowerNetworks that requested ticks
	var/list/toRemovePowerNetwork = list()
	for(var/datum/power/PowerNetwork/network in powerControllerWireNetworkProcessingLoopList)
	//	world<<"PowerNetworkController network uuid=[network.uuid]"
		if(network.processTick()==0)
			toRemovePowerNetwork+=network
	for(var/datum/power/PowerNetwork/network in toRemovePowerNetwork)
		powerControllerWireNetworkProcessingLoopList-=network



	for(var/datum/power/PowerNode/powerNodeConsumer in powerControllerPowerNodeConsumerProcessingLoopList)
		powerNodeConsumer.processTick()
	//END OF PROC
