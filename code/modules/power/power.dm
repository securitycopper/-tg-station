//////////////////////////////
// POWER MACHINERY BASE CLASS
//////////////////////////////

/////////////////////////////
// Definitions
/////////////////////////////

/obj/machinery/power
	name = null
	icon = 'icons/obj/power.dmi'
	anchored = 1
	//var/datum/powernet/powernet = null
	use_power = 0
	idle_power_usage = 0
	active_power_usage = 0

/obj/machinery/power/Destroy()
	disconnect_from_network()
	return ..()

///////////////////////////////
// General procedures
//////////////////////////////

// common helper procs for all power machines
/obj/machinery/power/proc/add_avail(amount)
	if(powerNode!=null)
		POWERNODE_SETSUPPLYCURRENT(powerNode,amount)

/obj/machinery/power/proc/add_load(amount)
	if(powerNode!=null)
		POWERNODE_SETCONSUMINGCURRENT(powerNode,amount)

/obj/machinery/power/proc/surplus()
	if(powerNode!=null && powerNode.selectedSource!=null)
		return POWERNETWORK_GETEXCESSSUPPLY(powerNode.selectedSource)
	else
		return 0

/obj/machinery/power/proc/avail()
	if(powerNode!=null && powerNode.selectedSource!=null)
		return POWERNETWORK_GETEXCESSSUPPLY_EXCLUDEPOWERNODE(powerNode.selectedSource,powerNode)
	else
		return 0

/obj/machinery/power/proc/disconnect_terminal() // machines without a terminal will just return, no harm no fowl.
	return

// returns true if the area has power on given channel (or doesn't require power).
// defaults to power_channel
/obj/machinery/proc/powered(var/chan = -1) // defaults to power_channel

	if(!src.loc)
		return 0

	if(!use_power)
		return 1

	var/area/A = src.loc.loc		// make sure it's in an area
	if(!A || !isarea(A) || !A.master)
		return 0					// if not, then not powered
	if(chan == -1)
		chan = power_channel
	return A.master.powered(chan)	// return power status of the area

// increment the power usage stats for an area
/obj/machinery/proc/use_power(amount, chan = -1) // defaults to power_channel
	var/area/A = get_area(src)		// make sure it's in an area
	if(!A || !isarea(A) || !A.master)
		return
	if(chan == -1)
		chan = power_channel
	A.master.use_power(amount, chan)

/obj/machinery/proc/addStaticPower(value, powerchannel)
	var/area/A = get_area(src)
	if(!A || !A.master)
		return
	A.master.addStaticPower(value, powerchannel)

/obj/machinery/proc/removeStaticPower(value, powerchannel)
	addStaticPower(-value, powerchannel)

/obj/machinery/proc/power_change()		// called whenever the power settings of the containing area change
										// by default, check equipment channel & set flag
										// can override if needed
	if(powered(power_channel))
		MACHINERY_SETPOWERED(src)
	else

		MACHINERY_SETNOPOWER(src)
	return

// connect the machine to a powernet if a node cable is present on the turf
/obj/machinery/power/proc/connect_to_network()
	var/turf/T = src.loc
	if(!T || !istype(T))
		return 0

	var/obj/structure/cable/C = T.get_cable_node() //check if we have a node cable on the machine turf, the first found is picked
	if(C==null || C.parentNetwork==null)
		return 0

	if(powerNode!=null)
		powernode.addPowerNetwork(C.parentNetwork)

	return 1

// remove and disconnect the machine from its current powernet
/obj/machinery/power/proc/disconnect_from_network()
	var/turf/T = src.loc
	if(!T || !istype(T))
		return 0

	var/obj/structure/cable/C = T.get_cable_node() //check if we have a node cable on the machine turf, the first found is picked
	if(C==null || C.parentNetwork==null)
		return 0

	if(powerNode!=null)
		powernode.removePowerNetwork(C.parentNetwork)

	return 1

// attach a wire to a power machine - leads from the turf you are standing on
//almost never called, overwritten by all power machines but terminal and generator
/obj/machinery/power/attackby(obj/item/weapon/W, mob/user, params)

	if(istype(W, /obj/item/stack/cable_coil))

		var/obj/item/stack/cable_coil/coil = W

		var/turf/T = user.loc

		if(T.intact || !istype(T, /turf/simulated/floor))
			return

		if(get_dist(src, user) > 1)
			return

		coil.place_turf(T, user)
		return
	else
		..()
	return




/mob/living
	var/datum/power/PowerNode/powerNode=null

//Determines how strong could be shock, deals damage to mob, uses power.
//M is a mob who touched wire/whatever
//power_source is a source of electricity, can be powercell, area, apc, cable, powernet or null
//source is an object caused electrocuting (airlock, grille, etc)
//No animations will be performed by this proc.
/proc/electrocute_mob(mob/living/carbon/M, power_source, obj/source, siemens_coeff = 1)
	if(istype(M.loc,/obj/mecha))	return 0	//feckin mechs are dumb
	if(istype(M,/mob/living/carbon/human))
		var/mob/living/carbon/human/H = M
		if(H.gloves)
			var/obj/item/clothing/gloves/G = H.gloves
			if(G.siemens_coefficient == 0)	return 0		//to avoid spamming with insulated glvoes on

	/*** Folix power rewrite. Find a powernode to drain. use power first (it will use the power on the next tick but for the
	point of taking power from the network, it is close enough to real time.
	**/



	//Source can be one of 2 types. PowerNetwork or Cell.


	var/datum/power/PowerNetwork/targetNetwork=null
	var/obj/item/weapon/stock_parts/cell/cell


	/***** Source Selection *****/
	//For apc power short, we will use the max supply to the apc, not the internal PowerNetwork of the apc.
	if(istype(power_source,/area)||istype(power_source,/obj/machinery/power/apc))
		var/area/source_area = power_source
		var/obj/machinery/power/apc/apc = source_area.get_apc()
		if(apc.powerNode!=null)
			targetNetwork=POWERNODE_PARENTNETWORK(apc.powerNode)

	//For cable, we use the PowerNetwork it is carrying
	if(istype(power_source,/obj/structure/cable))
		var/obj/structure/cable/Cable = power_source
		targetNetwork = Cable.parentNetwork

	//For cell we will use old way
	if(istype(power_source,/obj/item/weapon/stock_parts/cell))
		cell = power_source

	if(cell==null&&targetNetwork==null)
		//log_admin("ERROR: /proc/electrocute_mob([M], [power_source], [source]): wrong power_source")
		return 0


	/***** Calculate Capacity Potential *****/
	var/supply=0
	if(targetNetwork!=null)
		supply=POWERNETWORK_GETSUPPLY(targetNetwork)
	else if (cell!=null)
		supply=cell.charge

	if(supply==0)
		return 0


	/***** Calcuate Damage *****/
	var/shock_damage=electrocute_damage(supply)
	var/drained_hp = M.electrocute_act(shock_damage, source, siemens_coeff) //zzzzzzap!

	/***** Drain Used Energy (only valid for cells) *****/

	if(cell!=null)
		cell.use(supply)

	return supply



////////////////////////////////////////////////
// Misc.
///////////////////////////////////////////////


// return a knot cable (O-X) if one is present in the turf
// null if there's none
/turf/proc/get_cable_node()
	if(!can_have_cabling())
		return null
	for(var/obj/structure/cable/C in src)
		if(C.d1 == 0)
			return C
	return null

/area/proc/get_apc()
	for(var/obj/machinery/power/apc/APC in apcs_list)
		if(APC.area == src)
			return APC
