
var/global/datum/power/PowerNode/apsForLighting
#define DEBUG_POWERNODE_BATTERY 1
#define DEBUG_WIRENETWORK_PROCESS 1
#define DEBUG_WIRENETWORK_ADD 1
#define DEBUG_WIRENETWORK_PRINT_TREE 1

var/datum/PowerNetworkController/powerController = new /datum/PowerNetworkController()



/datum/globalNull


/datum/globalNull/proc/runtimeError()
var/global/datum/globalNull/globalNull=null

#define true 1
#define false 0

#define assertTrue(actual) if(actual!=1)	globalNull.runtimeError();

#define assertEquals(expected, actual) if(expected!=actual)	world<<"Expected=[expected], actual=[actual]";if(expected!=actual)	globalNull.runtimeError();

client/verb



	PowerNodeTest()
		/*
		//PowerNode vars
		var/currentSupply=0
		var/currentLoad=0
		var/flagedAsChanged=0
		var/requestedPowerUsage=0
		availableDelta
		*/

		/**** Test network behavior for adding a source of 10 *****/

		//Nothing in controller loop
		assertEquals(0,powerControllerWireNetworkProcessingLoopList.len)
		var/datum/power/PowerNetwork/network = new /datum/power/PowerNetwork()
		//Verify Network Empty
		assertEquals(0,network.currentSupply)
		assertEquals(0,network.currentLoad)
		assertEquals(0,network.flagedAsChanged)
		assertEquals(0,network.requestedAdditionalPower)
		assertEquals(0,network.availableDelta)


		var/datum/power/PowerNode/staticGenerator = new /datum/power/PowerNode("Geneator 10 Static A")
		//Add test network as a source to the power node
		staticGenerator.addPowerNetwork(network)
		staticGenerator.setPower(-10)
		assertEquals(10,network.availableDelta)

		assertEquals(1,powerControllerWireNetworkProcessingLoopList.len)
		powerController.processPower()
		//Verify Network Empty
		assertEquals(10,network.currentSupply)
		assertEquals(0,network.currentLoad)
		assertEquals(0,network.flagedAsChanged)
		assertEquals(0,network.requestedAdditionalPower)
		assertEquals(10,network.availableDelta)
		assertEquals(0,powerControllerWireNetworkProcessingLoopList.len)
		powerController.processPower()
		assertEquals(10,network.currentSupply)
		assertEquals(1,network.attached.len)

		/**** Test network behavior for having a source of 10 and light of 10 *****/
		var/datum/power/PowerNode/lightA = new /datum/power/PowerNode("lightA")
		lightA.setPower(10)
		//No network so no power usage yet
		assertEquals(0,lightA.currentPowerUsage)
		lightA.addPowerNetwork(network)
		//Adding to the network causes an attempt to turn on the machine
		assertEquals(10,lightA.currentPowerUsage)

		assertEquals(10,network.currentSupply)
		assertEquals(0,network.currentLoad)
		assertEquals(1,network.flagedAsChanged)
		assertEquals(0,network.requestedAdditionalPower)
		assertEquals(0,network.availableDelta)
		assertEquals(1,powerControllerWireNetworkProcessingLoopList.len)
		assertEquals(2,network.attached.len)

		powerController.processPower()
		assertEquals(10,network.currentSupply)
		assertEquals(10,network.currentLoad)
		assertEquals(0,network.flagedAsChanged)
		assertEquals(0,network.requestedAdditionalPower)
		assertEquals(0,network.availableDelta)
		assertEquals(0,powerControllerWireNetworkProcessingLoopList.len)
		//>0 means the node is on. Verify it is on
		assertEquals(10,lightA.currentPowerUsage)

		/**** Test network behavior for
			Supply of 10
			LightA using 10
			LightB using 10

			Should see issolating behavior *****/

		var/datum/power/PowerNode/lightB = new /datum/power/PowerNode("lightB")
		lightB.setPower(10)
		//No network so no power usage yet
		assertEquals(0,lightB.currentPowerUsage)
		assertEquals(0,network.flagedAsChanged)
		lightB.addPowerNetwork(network)
		assertEquals(3,network.attached.len)
		//Adding to the network causes an attempt to turn on the machine. but machine can't start because network has no power
		assertEquals(0,lightB.currentPowerUsage)

		//The network is flaged for changes
		assertEquals(10,network.currentSupply)
		assertEquals(10,network.currentLoad)
		assertEquals(1,network.flagedAsChanged)
		assertEquals(0,network.requestedAdditionalPower)
		assertEquals(0,network.availableDelta)
		assertEquals(1,powerControllerWireNetworkProcessingLoopList.len)

		//The network is updated, Causes lightA to turn off
		assertEquals(10,lightA.currentPowerUsage)
		assertEquals(0,lightB.currentPowerUsage)


		powerController.processPower()
		/** B is lit, A is not**/
		assertEquals(0,lightA.currentPowerUsage)
		assertEquals(10,lightB.currentPowerUsage)
		//The network isn't fully active, remains on processing loop
		assertEquals(10,network.currentSupply)
		assertEquals(10,network.currentLoad)
		assertEquals(1,network.flagedAsChanged)
		assertEquals(10,network.requestedAdditionalPower)
		assertEquals(0,network.availableDelta)
		assertEquals(1,powerControllerWireNetworkProcessingLoopList.len)


		powerController.processPower()
		/** A is lit, B is not**/
		assertEquals(10,lightA.currentPowerUsage)
		assertEquals(0,lightB.currentPowerUsage)
		//The network isn't fully active, remains on processing loop
		assertEquals(10,network.currentSupply)
		assertEquals(10,network.currentLoad)
		assertEquals(1,network.flagedAsChanged)
		assertEquals(10,network.requestedAdditionalPower)
		assertEquals(0,network.availableDelta)
		assertEquals(1,powerControllerWireNetworkProcessingLoopList.len)


		powerController.processPower() //ordering the attached list to be a nice order of ABC


		var/datum/power/PowerNode/lightC = new /datum/power/PowerNode("lightC")
		lightC.setPower(10)
		lightC.addPowerNetwork(network)

		/** A is list, B & C are not **/
		powerController.processPower()
		assertEquals(10,lightA.currentPowerUsage)
		assertEquals(0,lightB.currentPowerUsage)
		assertEquals(0,lightC.currentPowerUsage)


		/** B is list, A & C are not **/
		powerController.processPower()
		assertEquals(0,lightA.currentPowerUsage)
		assertEquals(10,lightB.currentPowerUsage)
		assertEquals(0,lightC.currentPowerUsage)


		/** C is list, A & B are not **/
		powerController.processPower()
		assertEquals(0,lightA.currentPowerUsage)
		assertEquals(0,lightB.currentPowerUsage)
		assertEquals(10,lightC.currentPowerUsage)

		/***** Add another generator *****/
		//Note:the order doesn't really matter in this test. as long as the on states issolate, the test is valid


		var/datum/power/PowerNode/staticGeneratorB = new /datum/power/PowerNode("Geneator 10 Static B")
		//Add test network as a source to the power node
		staticGeneratorB.addPowerNetwork(network)
		staticGeneratorB.setPower(-10)

		/** A & C are lit, B is not **/
		powerController.processPower()
		//network.printDebug()
		assertEquals(10,lightA.currentPowerUsage)
		assertEquals(0,lightB.currentPowerUsage)
		assertEquals(10,lightC.currentPowerUsage)


		/** A & B are lit, C is not **/
		powerController.processPower()
		//network.printDebug()
		assertEquals(10,lightA.currentPowerUsage)
		assertEquals(10,lightB.currentPowerUsage)
		assertEquals(0,lightC.currentPowerUsage)

		/** B & C are lit, A is not **/
		powerController.processPower()
		//network.printDebug()
		assertEquals(0,lightA.currentPowerUsage)
		assertEquals(10,lightB.currentPowerUsage)
		assertEquals(10,lightC.currentPowerUsage)


		world<<"Test Passed"
	//	network.printDebug()


/*
		powerNetworkControllerProcessingLoopList = list()
		assertEquals(0,powerNetworkControllerProcessingLoopList.len)


		var/area/kitchenArea = new /area()
		var/datum/wire_network/kitchenWireNetwork = kitchenArea.getWireNetwork();

		kitchenWireNetwork.setName = "Kitchen Area"

		var/datum/power/PowerNode/kitchenLight = new /datum/power/PowerNode()
		kitchenLight.setName = "obj/machinery/light"
		kitchenLight.setCanAutoStartToIdle = 1
		kitchenLight.setIdleLoad = 2
		kitchenLight.init(kitchenArea)

		//At this point the parent network hasn't started the child item yet


		assertEquals(0, kitchenWireNetwork.wireNetworkLoad)
		assertEquals(0, kitchenWireNetwork.wireNetworkCurrentSupply)
		assertEquals(0, kitchenWireNetwork.wireNetworkMaxPotentialSupply)
		assertEquals(0, kitchenLight.isOn)

		kitchenWireNetwork.process()

		assertEquals(0, kitchenWireNetwork.wireNetworkLoad)
		assertEquals(0, kitchenWireNetwork.wireNetworkCurrentSupply)
		assertEquals(0, kitchenWireNetwork.wireNetworkMaxPotentialSupply)
		assertEquals(0, kitchenLight.isOn)




		var/datum/power/PowerNode/kitchenApc = new /datum/power/PowerNode()
		kitchenApc.initApcConfiguration(kitchenArea)
		var/datum/power/PowerNode/kitchenApcOutputNode = kitchenApc.outputNode
		kitchenApc.setBattery(40,13,13,40)
		kitchenApc.update()

		smesNetwork.add(kitchenApc)

		assertEquals(0, kitchenLight.isOn)
		assertEquals(0, kitchenWireNetwork.wireNetworkLoad)
		assertEquals(0, kitchenWireNetwork.wireNetworkCurrentSupply)
		assertEquals(0, kitchenWireNetwork.wireNetworkMaxPotentialSupply)


		assertEquals(0, kitchenApc.isOn)

		assertEquals(0, kitchenApcOutputNode.isOn)


		//kitchenApc.privatePrcessBattery()

		assertEquals(0, kitchenApcOutputNode.isOn)
		assertEquals(0, kitchenApcOutputNode.setCurrentLoad)
		assertEquals(0, kitchenApcOutputNode.setMaxPotentialSupply)
		assertEquals(0, kitchenApcOutputNode.setCurrentSupply)

		kitchenWireNetwork.process()
		kitchenWireNetwork.process()
		kitchenWireNetwork.process()

		assertEquals(1, kitchenApcOutputNode.isOn)
		assertEquals(0, kitchenApcOutputNode.setCurrentLoad)
		assertEquals(0, kitchenApcOutputNode.setMaxPotentialSupply)
		assertEquals(0, kitchenApcOutputNode.setCurrentSupply)

		assertEquals(0, kitchenApc.isOn)
		kitchenApc.privatePrcessBattery()
		assertEquals(0, kitchenApc.isOn)
		assertEquals(1, kitchenApcOutputNode.isOn)
		assertEquals(0, kitchenApcOutputNode.setCurrentLoad)
		assertEquals(13, kitchenApcOutputNode.setMaxPotentialSupply)
		assertEquals(0, kitchenApcOutputNode.setCurrentSupply)

		kitchenWireNetwork.process()

		assertEquals(1, kitchenLight.isOn)


		assertEquals(1, kitchenApcOutputNode.isOn)
		assertEquals(0, kitchenApcOutputNode.setCurrentLoad)
		assertEquals(13, kitchenApcOutputNode.setMaxPotentialSupply)
		assertEquals(2, kitchenApcOutputNode.setCurrentSupply)
		assertEquals(2, kitchenWireNetwork.wireNetworkLoad)
		assertEquals(2,kitchenWireNetwork.wireNetworkCurrentSupply)
		assertEquals(13,kitchenWireNetwork.wireNetworkMaxPotentialSupply)

		kitchenApc.privatePrcessBattery()

		assertEquals(1, kitchenApcOutputNode.isOn)
		assertEquals(0, kitchenApcOutputNode.setCurrentLoad)

		assertEquals(2, kitchenApcOutputNode.setCurrentSupply)
		assertEquals(2, kitchenWireNetwork.wireNetworkLoad)
		assertEquals(2,kitchenWireNetwork.wireNetworkCurrentSupply)
		assertEquals(11,kitchenWireNetwork.wireNetworkMaxPotentialSupply)
		assertEquals(11, kitchenApcOutputNode.setMaxPotentialSupply)


		kitchenWireNetwork.process() // No effect


		assertEquals(1, kitchenApcOutputNode.isOn)
		assertEquals(0, kitchenApcOutputNode.setCurrentLoad)

		assertEquals(2, kitchenApcOutputNode.setCurrentSupply)
		assertEquals(2, kitchenWireNetwork.wireNetworkLoad)
		assertEquals(2,kitchenWireNetwork.wireNetworkCurrentSupply)
		assertEquals(11,kitchenWireNetwork.wireNetworkMaxPotentialSupply)
		assertEquals(11, kitchenApcOutputNode.setMaxPotentialSupply)


		kitchenApc.privatePrcessBattery()

		assertEquals(9,kitchenWireNetwork.wireNetworkMaxPotentialSupply)
		assertEquals(9, kitchenApcOutputNode.setMaxPotentialSupply)

		kitchenApc.privatePrcessBattery()

		assertEquals(7,kitchenWireNetwork.wireNetworkMaxPotentialSupply)
		assertEquals(7, kitchenApcOutputNode.setMaxPotentialSupply)

		kitchenApc.privatePrcessBattery()

		assertEquals(5,kitchenWireNetwork.wireNetworkMaxPotentialSupply)
		assertEquals(5, kitchenApcOutputNode.setMaxPotentialSupply)

		kitchenApc.privatePrcessBattery()

		assertEquals(3,kitchenWireNetwork.wireNetworkMaxPotentialSupply)
		assertEquals(3, kitchenApcOutputNode.setMaxPotentialSupply)

		kitchenApc.privatePrcessBattery()


		assertEquals(1,kitchenWireNetwork.wireNetworkMaxPotentialSupply)
		assertEquals(1, kitchenApcOutputNode.setMaxPotentialSupply)

		/***********************************************/
		kitchenApc.privatePrcessBattery()

		// Now out of power the apc will be off
		assertEquals(0, kitchenApcOutputNode.isOn)
		assertEquals(0, kitchenApcOutputNode.setCurrentLoad)
		assertEquals(0, kitchenApcOutputNode.setMaxPotentialSupply)
		assertEquals(0, kitchenApcOutputNode.setCurrentSupply)

		assertEquals(0,kitchenWireNetwork.wireNetworkMaxPotentialSupply)
		assertEquals(0, kitchenApcOutputNode.setMaxPotentialSupply)

		//Kitchen light is still on because the network hasn't been processed yet
		assertEquals(1, kitchenLight.isOn)

		/*******************************************/
		//Battery allready depleated and isn't charging so this call won't do anything.
		kitchenApc.privatePrcessBattery()
				// Now out of power the apc will be off
		assertEquals(0, kitchenApcOutputNode.isOn)
		assertEquals(0, kitchenApcOutputNode.setCurrentLoad)
		assertEquals(0, kitchenApcOutputNode.setMaxPotentialSupply)
		assertEquals(0, kitchenApcOutputNode.setCurrentSupply)

		assertEquals(0,kitchenWireNetwork.wireNetworkMaxPotentialSupply)
		assertEquals(0, kitchenApcOutputNode.setMaxPotentialSupply)

		//Kitchen light is still on because the network hasn't been processed yet
		assertEquals(1, kitchenLight.isOn)


		/*******************************************/
		//Process the wire network. This will cause the apc output to turn back on (with 0 supply) and will turn the light off
		kitchenWireNetwork.process()

		assertEquals(0, kitchenApcOutputNode.isOn)
		assertEquals(0, kitchenApcOutputNode.setCurrentLoad)
		assertEquals(0, kitchenApcOutputNode.setMaxPotentialSupply)
		assertEquals(0, kitchenApcOutputNode.setCurrentSupply)

		assertEquals(0,kitchenWireNetwork.wireNetworkMaxPotentialSupply)
		assertEquals(0, kitchenApcOutputNode.setMaxPotentialSupply)


		//Kitchen light is still on because the network hasn't been processed yet
		assertEquals(0, kitchenLight.isOn)




		//Now process the network. The light will draw power and apc load will match power drain of 2



		world << "Test Passed"
		/*

		smesNetwork.setName = "SMES Network"






		var/datum/power/PowerNode/kitchenApc = new /datum/power/PowerNode()



		kitchenApc.initApcConfiguration(kitchenArea)

		smesNetwork.add(kitchenApc)

		world << "Constructed wirenetwork "




		assertEquals(1,1)
		assertEquals(1,2)
*/

	processWireNetwork()
		powerController.processPower()

		world << null
		world << null

		for(var/datum/wire_network/wireNetwork in powerNetworkControllerProcessingLoopList)
			//wireNetwork.process()
			wireNetwork.debugDebugNetwork()

	MagicInjectPower()
		for(var/datum/wire_network/wireNetwork in powerNetworkControllerProcessingLoopList)
			wireNetwork.wireNetworkCurrentSupply+=90000
			wireNetwork.wireNetworkMaxPotentialSupply+=90000


	ConstructLargeLoadNetwork()
		var/datum/wire_network/kitchenWireNetwork = new /datum/wire_network()


		var/datum/power/PowerNode/kitchenLight = new /datum/power/PowerNode()
		kitchenLight.setName = "obj/machinery/light"
		kitchenLight.setCanAutoStartToIdle = 1
		kitchenLight.setIdleLoad = 400000


		kitchenWireNetwork.add(kitchenLight)


		var/datum/power/PowerNode/terminalPowerNode = new /datum/power/PowerNode()
		terminalPowerNode.initSmesConfiguration()
		var/datum/power/smesOutput = terminalPowerNode.outputNode
		kitchenWireNetwork.add(smesOutput)






	ConstructWireNetwork()

		var/area/kitchenArea = new /area()
		var/datum/wire_network/kitchenWireNetwork = kitchenArea.getWireNetwork();

		kitchenWireNetwork.setName = "Kitchen Area"

		var/datum/power/PowerNode/kitchenLight = new /datum/power/PowerNode()
		kitchenLight.setName = "obj/machinery/light"
		kitchenLight.setCanAutoStartToIdle = 1
		kitchenLight.setIdleLoad = 1
		kitchenLight.init(kitchenArea)




		smesNetwork.setName = "SMES Network"





		var/datum/power/PowerNode/kitchenApc = new /datum/power/PowerNode()



		kitchenApc.initApcConfiguration(kitchenArea)

		smesNetwork.add(kitchenApc)

		world << "Constructed wirenetwork "


	Power_Count_Networks()
		world << "[powerNetworkControllerProcessingLoopList.len]"

	addSMESWith300Energy()
		var/datum/power/PowerNode/terminalPowerNode = new /datum/power/PowerNode()
		terminalPowerNode.initSmesConfiguration()
		var/datum/power/smesOutput = terminalPowerNode.outputNode
		smesNetwork.add(smesOutput)





/datum/wire_network/proc/debugDebugNetwork()
	world << "[setName] - #[gridId] Current Load([wireNetworkLoad]/[wireNetworkCurrentSupply]) Max Potential Supply = [wireNetworkMaxPotentialSupply], "

	for(var/datum/power/PowerNode/node in powerNodesThatCanSupplyPower)
		world << "--> Supply: [node.setName] - #[node.gridId] isOn = [node.isOn], Load=[node.setCurrentLoad], Supply([node.setCurrentSupply]/[node.setMaxPotentialSupply])"
	for(var/datum/power/PowerNode/node in powerNodesThatCanNotSupplyPower)
		world << "--> Consumer: [node.setName] - #[node.gridId] isOn = [node.isOn] Load=[node.setCurrentLoad],Battery([node.calculatedBatteryStoredEnergy]/[node.batteryMaxCapacity]+[node.setBatteryChargeRate]-[node.calculatedCurrentBatteryDistargeRate])"

*/

