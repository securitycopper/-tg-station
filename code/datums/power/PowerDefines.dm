
#define LIST_ADDLAST(list,element) list.Insert(list.len+1 ,element)
#define LIST_ADDFIRST(list,element) LIST_PUSH(list,element)
#define LIST_PUSH(list,element) list.Insert(1,element)

#define LIST_POP(list) list[1];list.Cut(1,2);

//The PowerNode didn't have power, now it is on.
#define POWER_EVENT_ON 1
//The power node was on but now the power changed.
//The machine needs to determine how it is affected by the power change.
#define POWER_EVENT_POWER_CHANGED 2
//The machine had power other then 0 and now is set to 0
#define POWER_EVENT_OFF 3

#define POWER_TYPE_NOTSET 0
#define POWER_TYPE_PRODUCER 1
#define POWER_TYPE_CONSUMER 2
#define POWER_TYPE_ONDEMAND_PRODUCER 3

#define POWER_STATE_OFF 0
#define POWER_STATE_ON 1


/*** Direct Access to PowerNode variables can cause issues. Use these utility defines to determine power node state **/
// They make the code easier to read and are efficent because they are not procs

#define POWERNODE_ISON(powerNode) powerNode.currentPowerUsage!=0
#define POWERNODE_ISOFF(powerNode) powerNode.currentPowerUsage==0
#define POWERNODE_ISSUPPLYINGPOWER(powerNode) powerNode.currentPowerUsage<0
//Note: POWERNODE_GETSUPPLYCURRENT can only be used if POWERNODE_ISSUPPLYINGPOWER is true
#define POWERNODE_GETSUPPLYCURRENT(powerNode) -powerNode.currentPowerUsage
#define POWERNODE_ISCONSUMINGPOWER(powerNode) powerNode.currentPowerUsage>0
#define POWERNODE_GETCONSUMINGCURRENT(powerNode) powerNode.currentPowerUsage
#define POWERNODE_SETSUPPLYCURRENT(powerNode,amount) powerNode.setPower(-amount)
#define POWERNODE_SETCONSUMINGCURRENT(powerNode,amount) powerNode.setPower(amount)


#define POWERNODE_PARENTNETWORK(powerNode) powerNode.selectedSource

#define POWERNETWORK_GETSUPPLY(powerNetwork) powerNetwork.currentSupply
#define POWERNETWORK_GETLOAD(powerNetwork) powerNetwork.currentLoad
#define POWERNETWORK_GETEXCESSSUPPLY(powerNetwork) powerNetwork.availableDelta-powerNetwork.requestedAdditionalPower
#define POWERNETWORK_GETEXCESSSUPPLY_EXCLUDEPOWERNODE(powerNetwork,powerNode) powerNetwork.availableDelta+powerNode.currentPowerUsage-powerNetwork.requestedAdditionalPower
#define POWERNETWORK_GETNODESCONNECTED(powerNetwork) powerNetwork.attached.len

#define CABLE_GETPOWERNETWORK(cable) cable.parentNetwork


#define ERROR_CABLE_NO_PARENTNETWORK "PowerNetwork Error#1: Cable has no parent network."

//Taken from cell
/proc/electrocute_damage(var/charge)
	if(charge >= 1000)
		return Clamp(round(charge/10000), 10, 90) + rand(-5,5)
	else
		return 0




/proc/autoMergePowerNetwork(var/obj/structure/cable/cable)

	var/list/connectedCables = list()
	var/list/connectedWireNetworks = list()
	var/datum/power/PowerNetwork/maxSize = null


	//***** Get populate a list of connected cables, populate (connectedCables) *****

	//Get current cable Network
	var/datum/power/PowerNetwork/cableNetwork=cable.parentNetwork

	//Get ajacent networks


	var/obj/structure/cable/currentNode = cable
	var/cdir
	var/turf/T
	for(var/card in cardinal)
		T = get_step(currentNode.loc,card)
		cdir = get_dir(T,currentNode.loc)
		for(var/obj/structure/cable/C in T)
			if(C.d1 == cdir || C.d2 == cdir)
				LIST_PUSH(connectedCables,C)
				if(C.parentNetwork!=null)
					var/datum/power/PowerNetwork/cParentNetwork = C.parentNetwork
					LIST_PUSH(connectedWireNetworks,cParentNetwork)
					if(maxSize==null)
						maxSize = cParentNetwork
					if(maxSize!=null && POWERNETWORK_GETNODESCONNECTED(maxSize) < POWERNETWORK_GETNODESCONNECTED(cParentNetwork))
						maxSize = cParentNetwork


	//***** Linking Logic *****
	//connectedCables: Cables now connected to this cable.
	//maxSize: wirenetwork that has the most nodes attached to it
	//connectedWireNetworks: wire networks of the connected cables

	//Loop though cables and replace them with the greatest size network
	for(var/obj/structure/cable/c in connectedCables)

		propagate_network(c,maxSize,c.parentNetwork)



/*
	Propagate network along wires
*/
/proc/propagate_network(var/obj/structure/cable/powerNodeSpaceWithoutNetowrk
, var/datum/power/PowerNetwork/toPropagate, var/datum/power/PowerNetwork/toReplace)
	//world.log << "propagating new network"

	//Safty Check
	if(toPropagate==toReplace)
		return

	var/list/toProcessCable = list()


	LIST_PUSH(toProcessCable,powerNodeSpaceWithoutNetowrk)

	//Propagate along wires
	while(toProcessCable.len >0)
		//Pop first element
		var/obj/structure/cable/currentNode = LIST_POP(toProcessCable)

		if(currentNode.parentNetwork==toReplace)

			currentNode.parentNetwork = toPropagate

			//This gets adjacent cables and adds them to the queue
			var/cdir
			var/turf/T
			for(var/card in cardinal)
				T = get_step(currentNode.loc,card)
				cdir = get_dir(T,currentNode.loc)
				for(var/obj/structure/cable/C in T)
					if(C.d1 == cdir || C.d2 == cdir)
						LIST_PUSH(toProcessCable,C)

			//Attach any machines if found on this space
			for(var/obj/machinery/machine in currentNode.loc)

				/*** Terminal Logic get and set powerNode from master ***/

				//For terminals, we replace the terminal's power node with its masters
				if(istype(machine,/obj/machinery/power/terminal))
					var/obj/machinery/power/terminal/terminal = machine
					var/obj/machinery/terminalMaster = terminal.master
					terminal.powerNode = terminalMaster.powerNode
					//Note: the adding and roving happens in next if block

				var/datum/power/PowerNode/machinepowerNode = machine.powerNode
				//Normal machine logic
				if(machinepowerNode!=null && machine.anchored )
					//remove machine from existing network and add to new one
					machinepowerNode.removePowerNetwork(toReplace)
					machinepowerNode.addPowerNetwork(toPropagate)
	//END OF PROC

