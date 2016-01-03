///////////////////////////////
//CABLE STRUCTURE
///////////////////////////////


////////////////////////////////
// Definitions
////////////////////////////////

/* Cable directions (d1 and d2)


  9   1   5
	\ | /
  8 - 0 - 4
	/ | \
  10  2   6

If d1 = 0 and d2 = 0, there's no cable
If d1 = 0 and d2 = dir, it's a O-X cable, getting from the center of the tile to dir (knot cable)
If d1 = dir1 and d2 = dir2, it's a full X-X cable, getting from dir1 to dir2
By design, d1 is the smallest direction and d2 is the highest
*/

/obj/structure/cable
	level = 1 //is underfloor
	anchored =1
	var/datum/power/PowerNetwork/parentNetwork
	name = "power cable"
	desc = "A flexible superconducting cable for heavy-duty power transfer"
	icon = 'icons/obj/power_cond/power_cond_red.dmi'
	icon_state = "0-1"
	var/d1 = 0   // cable direction 1 (see above)
	var/d2 = 1   // cable direction 2 (see above)
	layer = 2.44 //Just below unary stuff, which is at 2.45 and above pipes, which are at 2.4
	var/cable_color = "red"
	var/obj/item/stack/cable_coil/stored

/obj/structure/cable/yellow
	cable_color = "yellow"
	icon = 'icons/obj/power_cond/power_cond_yellow.dmi'

/obj/structure/cable/green
	cable_color = "green"
	icon = 'icons/obj/power_cond/power_cond_green.dmi'

/obj/structure/cable/blue
	cable_color = "blue"
	icon = 'icons/obj/power_cond/power_cond_blue.dmi'

/obj/structure/cable/pink
	cable_color = "pink"
	icon = 'icons/obj/power_cond/power_cond_pink.dmi'

/obj/structure/cable/orange
	cable_color = "orange"
	icon = 'icons/obj/power_cond/power_cond_orange.dmi'

/obj/structure/cable/cyan
	cable_color = "cyan"
	icon = 'icons/obj/power_cond/power_cond_cyan.dmi'

/obj/structure/cable/white
	cable_color = "white"
	icon = 'icons/obj/power_cond/power_cond_white.dmi'

// the power cable object
/obj/structure/cable/New()
	..()


	// ensure d1 & d2 reflect the icon_state for entering and exiting cable
	var/dash = findtext(icon_state, "-")

	d1 = text2num( copytext( icon_state, 1, dash ) )

	d2 = text2num( copytext( icon_state, dash+1 ) )

	var/turf/T = src.loc			// hide if turf is not intact

	if(level==1) hide(T.intact)
	cable_list += src //add it to the global cable list

	if(d1)
		stored = new/obj/item/stack/cable_coil(null,2,cable_color)
	else
		stored = new/obj/item/stack/cable_coil(null,1,cable_color)

/obj/structure/cable/Destroy()					// called when a cable is deleted
	if(parentNetwork!=null)
		cut_cable_from_powernet()				// update the powernets
	cable_list -= src							//remove it from global cable list
	return ..()									// then go ahead and delete the cable

/obj/structure/cable/Deconstruct()
	var/turf/T = loc
	stored.loc = T
	..()

///////////////////////////////////
// General procedures
///////////////////////////////////

//If underfloor, hide the cable
/obj/structure/cable/hide(i)

	if(level == 1 && istype(loc, /turf))
		invisibility = i ? 101 : 0
	updateicon()

/obj/structure/cable/proc/updateicon()
	if(invisibility)
		icon_state = "[d1]-[d2]-f"
	else
		icon_state = "[d1]-[d2]"



//Telekinesis has no effect on a cable
/obj/structure/cable/attack_tk(mob/user)
	return

// Items usable on a cable :
//   - Wirecutters : cut it duh !
//   - Cable coil : merge cables
//   - Multitool : get the power currently passing through the cable
//
/obj/structure/cable/attackby(obj/item/W, mob/user, params)
	var/turf/T = src.loc
	if(T.intact)
		return
	if(istype(W, /obj/item/weapon/wirecutters))
		if (shock(user, 50))
			return
		user.visible_message("[user] cuts the cable.", "<span class='notice'>You cut the cable.</span>")
		stored.add_fingerprint(user)
		investigate_log("was cut by [key_name(usr, usr.client)] in [user.loc.loc]","wires")
		Deconstruct()
		return

	else if(istype(W, /obj/item/stack/cable_coil))
		var/obj/item/stack/cable_coil/coil = W
		if (coil.get_amount() < 1)
			user << "<span class='warning'>Not enough cable!</span>"
			return
		coil.cable_join(src, user)

	else if(istype(W, /obj/item/device/multitool))
		if(parentNetwork==null)
			//This case shouldn't ever happen, display if it happens
			user << "<span class='danger'>[ERROR_CABLE_NO_PARENTNETWORK]</span>"


		else if(parentNetwork != null && (POWERNETWORK_GETSUPPLY(parentNetwork) > 0))		// is it powered?
			user << "<span class='danger'>[POWERNETWORK_GETSUPPLY(parentNetwork)]W in power network.</span>"
		else
			user << "<span class='danger'>The cable is not powered.</span>"
		shock(user, 5, 0.2)

	else
		if (W.flags & CONDUCT)
			shock(user, 50, 0.7)

	src.add_fingerprint(user)

// shock the user with probability prb
/obj/structure/cable/proc/shock(mob/user, prb, siemens_coeff = 1)
	if(!prob(prb))
		return 0
	if (electrocute_mob(user, parentNetwork, src, siemens_coeff))
		var/datum/effect_system/spark_spread/s = new /datum/effect_system/spark_spread
		s.set_up(5, 1, src)
		s.start()
		return 1
	else
		return 0

//explosion handling
/obj/structure/cable/ex_act(severity, target)
	..()
	if(!gc_destroyed)
		switch(severity)
			if(2)
				if(prob(50))
					Deconstruct()
			if(3)
				if(prob(25))
					Deconstruct()

/obj/structure/cable/singularity_pull(S, current_size)
	if(current_size >= STAGE_FIVE)
		Deconstruct()

/obj/structure/cable/proc/cableColor(colorC = "red")
	cable_color = colorC
	switch(colorC)
		if("red")
			icon = 'icons/obj/power_cond/power_cond_red.dmi'
		if("yellow")
			icon = 'icons/obj/power_cond/power_cond_yellow.dmi'
		if("green")
			icon = 'icons/obj/power_cond/power_cond_green.dmi'
		if("blue")
			icon = 'icons/obj/power_cond/power_cond_blue.dmi'
		if("pink")
			icon = 'icons/obj/power_cond/power_cond_pink.dmi'
		if("orange")
			icon = 'icons/obj/power_cond/power_cond_orange.dmi'
		if("cyan")
			icon = 'icons/obj/power_cond/power_cond_cyan.dmi'
		if("white")
			icon = 'icons/obj/power_cond/power_cond_white.dmi'

/obj/structure/cable/proc/update_stored(var/length = 1, var/color = "red")
	stored.amount = length
	stored.item_color = color
	stored.update_icon()



/////////////////////////////////////////////////
// Cable laying helpers
////////////////////////////////////////////////


// merge with the powernets of power objects in the source turf
/obj/structure/cable/proc/mergeConnectedNetworksOnTurf()
	autoMergePowerNetwork(src)


//should be called after placing a cable which extends another cable, creating a "smooth" cable that no longer terminates in the centre of a turf.
//needed as this can, unlike other placements, disconnect cables
/obj/structure/cable/proc/denode()


	return

	//TODO Folix: this logic


	/*
	var/turf/T1 = loc
	if(!T1) return

	var/list/powerlist = power_list(T1,src,0,0) //find the other cables that ended in the centre of the turf, with or without a powernet
	if(powerlist.len>0)
		var/datum/powernet/PN = new()
		propagate_network(powerlist[1],PN) //propagates the new powernet beginning at the source cable

		if(PN.is_empty()) //can happen with machines made nodeless when smoothing cables
			qdel(PN)
*/

// cut the cable's powernet at this cable and updates the powergrid
/obj/structure/cable/proc/cut_cable_from_powernet()

	return


	//TODO Folix: Make it so when one network is cut, it propergates a new network

	/*

	var/turf/T1 = loc
	var/list/P_list
	if(!T1)	return
	if(d1)
		T1 = get_step(T1, d1)
		P_list = power_list(T1, src, turn(d1,180),0,cable_only = 1)	// what adjacently joins on to cut cable...

	P_list += power_list(loc, src, d1, 0, cable_only = 1)//... and on turf


	if(P_list.len == 0)//if nothing in both list, then the cable was a lone cable, just delete it and its powernet
		powernet.remove_cable(src)

		for(var/obj/machinery/power/P in T1)//check if it was powering a machine
			if(!P.connect_to_network()) //can't find a node cable on a the turf to connect to
				P.disconnect_from_network() //remove from current network (and delete powernet)
		return

	var/obj/O = P_list[1]
	// remove the cut cable from its turf and powernet, so that it doesn't get count in propagate_network worklist
	loc = null
	powernet.remove_cable(src) //remove the cut cable from its powernet

	spawn(0) //so we don't rebuild the network X times when singulo/explosion destroys a line of X cables
		if(O && !qdeleted(O))
			var/datum/powernet/newPN = new()// creates a new powernet...
			propagate_network(O, newPN)//... and propagates it to the other side of the cable

	// Disconnect machines connected to nodes
	if(d1 == 0) // if we cut a node (O-X) cable
		for(var/obj/machinery/power/P in T1)
			if(!P.connect_to_network()) //can't find a node cable on a the turf to connect to
				P.disconnect_from_network() //remove from current network
*/
///////////////////////////////////////////////
// The cable coil object, used for laying cable
///////////////////////////////////////////////

////////////////////////////////
// Definitions
////////////////////////////////

var/global/list/datum/stack_recipe/cable_coil_recipes = list ( \
	new/datum/stack_recipe("cable restraints", /obj/item/weapon/restraints/handcuffs/cable, 15), \
	)

/obj/item/stack/cable_coil
	name = "cable coil"
	gender = NEUTER //That's a cable coil sounds better than that's some cable coils
	icon = 'icons/obj/power.dmi'
	icon_state = "coil_red"
	item_state = "coil_red"
	max_amount = MAXCOIL
	amount = MAXCOIL
	merge_type = /obj/item/stack/cable_coil // This is here to let its children merge between themselves
	item_color = "red"
	desc = "A coil of power cable."
	throwforce = 0
	w_class = 2
	throw_speed = 3
	throw_range = 5
	materials = list(MAT_METAL=50, MAT_GLASS=20)
	flags = CONDUCT
	slot_flags = SLOT_BELT
	attack_verb = list("whipped", "lashed", "disciplined", "flogged")
	singular_name = "cable piece"

/obj/item/stack/cable_coil/cyborg
	is_cyborg = 1
	materials = list()
	cost = 1

/obj/item/stack/cable_coil/cyborg/attack_self(mob/user)
	var/cable_color = input(user,"Pick a cable color.","Cable Color") in list("red","yellow","green","blue","pink","orange","cyan","white")
	item_color = cable_color
	update_icon()

/obj/item/stack/cable_coil/suicide_act(mob/user)
	if(locate(/obj/structure/bed/stool) in user.loc)
		user.visible_message("<span class='suicide'>[user] is making a noose with the [src.name]! It looks like \he's trying to commit suicide.</span>")
	else
		user.visible_message("<span class='suicide'>[user] is strangling \himself with the [src.name]! It looks like \he's trying to commit suicide.</span>")
	return(OXYLOSS)

/obj/item/stack/cable_coil/New(loc, amount = MAXCOIL, var/param_color = null)
	..()
	src.amount = amount
	if(param_color)
		item_color = param_color
	pixel_x = rand(-2,2)
	pixel_y = rand(-2,2)
	update_icon()
	recipes = cable_coil_recipes

///////////////////////////////////
// General procedures
///////////////////////////////////

//you can use wires to heal robotics
/obj/item/stack/cable_coil/attack(mob/living/carbon/human/H, mob/user)
	if(!istype(H))
		return ..()

	var/obj/item/organ/limb/affecting = H.get_organ(check_zone(user.zone_sel.selecting))
	if(affecting.status == ORGAN_ROBOTIC)
		user.visible_message("<span class='notice'>[user] starts to fix some of the wires in [H]'s [affecting.getDisplayName()].</span>", "<span class='notice'>You start fixing some of the wires in [H]'s [affecting.getDisplayName()].</span>")
		if(!do_mob(user, H, 50))	return
		item_heal_robotic(H, user, 0, 5)
		src.use(1)
		return
	else
		return ..()


/obj/item/stack/cable_coil/update_icon()
	if (!item_color)
		item_color = pick("red", "yellow", "blue", "green")
	if(amount == 1)
		icon_state = "coil_[item_color]1"
		name = "cable piece"
	else if(amount == 2)
		icon_state = "coil_[item_color]2"
		name = "cable piece"
	else
		icon_state = "coil_[item_color]"
		name = "cable coil"

/obj/item/stack/cable_coil/attack_hand(mob/user)
	var/obj/item/stack/cable_coil/new_cable = ..()
	if(istype(new_cable))
		new_cable.item_color = item_color
		new_cable.update_icon()

//add cables to the stack
/obj/item/stack/cable_coil/proc/give(extra)
	if(amount + extra > max_amount)
		amount = max_amount
	else
		amount += extra
	update_icon()



///////////////////////////////////////////////
// Cable laying procedures
//////////////////////////////////////////////

/obj/item/stack/cable_coil/proc/get_new_cable(location)
	var/path = "/obj/structure/cable" + (item_color == "red" ? "" : "/" + item_color)
	return new path (location)

// called when cable_coil is clicked on a turf
/obj/item/stack/cable_coil/proc/place_turf(turf/T, mob/user)
	if(!isturf(user.loc))
		return

	if(!T.can_have_cabling())
		user << "<span class='warning'>You can only lay cables on catwalks and plating!</span>"
		return

	if(get_amount() < 1) // Out of cable
		user << "<span class='warning'>There is no cable left!</span>"
		return

	if(get_dist(T,user) > 1) // Too far
		user << "<span class='warning'>You can't lay cable at a place that far away!</span>"
		return

	else
		var/dirn

		if(user.loc == T)
			dirn = user.dir			// if laying on the tile we're on, lay in the direction we're facing
		else
			dirn = get_dir(T, user)

		for(var/obj/structure/cable/LC in T)
			if(LC.d2 == dirn && LC.d1 == 0)
				user << "<span class='warning'>There's already a cable at that position!</span>"
				return

		var/obj/structure/cable/C = get_new_cable(T)

		//set up the new cable
		C.d1 = 0 //it's a O-X node cable
		C.d2 = dirn
		C.add_fingerprint(user)
		C.updateicon()

		//create a new powernet with the cable, if needed it will be merged later
		//TODO Folix: review next two lines
		//var/datum/powernet/PN = new()
		//PN.add_cable(C)

		C.mergeConnectedNetworksOnTurf() //merge the powernet with on turf powernets


		use(1)

		if (C.shock(user, 50))
			if (prob(50)) //fail
				C.Deconstruct()

// called when cable_coil is click on an installed obj/cable
// or click on a turf that already contains a "node" cable
/obj/item/stack/cable_coil/proc/cable_join(obj/structure/cable/C, mob/user)
	var/turf/U = user.loc
	if(!isturf(U))
		return

	var/turf/T = C.loc

	if(!isturf(T) || T.intact)		// sanity checks, also stop use interacting with T-scanner revealed cable
		return

	if(get_dist(C, user) > 1)		// make sure it's close enough
		user << "<span class='warning'>You can't lay cable at a place that far away!</span>"
		return


	if(U == T) //if clicked on the turf we're standing on, try to put a cable in the direction we're facing
		place_turf(T,user)
		return

	var/dirn = get_dir(C, user)

	// one end of the clicked cable is pointing towards us
	if(C.d1 == dirn || C.d2 == dirn)
		if(!U.can_have_cabling())						//checking if it's a plating or catwalk
			user << "<span class='warning'>You can only lay cables on catwalks and plating!</span>"
			return
		if(U.intact)						//can't place a cable if it's a plating with a tile on it
			user << "<span class='warning'>You can't lay cable there unless the floor tiles are removed!</span>"
			return
		else
			// cable is pointing at us, we're standing on an open tile
			// so create a stub pointing at the clicked cable on our tile

			var/fdirn = turn(dirn, 180)		// the opposite direction

			for(var/obj/structure/cable/LC in U)		// check to make sure there's not a cable there already
				if(LC.d1 == fdirn || LC.d2 == fdirn)
					user << "<span class='warning'>There's already a cable at that position!</span>"
					return

			var/obj/structure/cable/NC = get_new_cable (U)

			NC.d1 = 0
			NC.d2 = fdirn
			NC.add_fingerprint()
			NC.updateicon()



			NC.mergeConnectedNetworksOnTurf() //merge the powernet with on turf powernets


			use(1)

			if (NC.shock(user, 50))
				if (prob(50)) //fail
					NC.Deconstruct()

			return

	// exisiting cable doesn't point at our position, so see if it's a stub
	else if(C.d1 == 0)
							// if so, make it a full cable pointing from it's old direction to our dirn
		var/nd1 = C.d2	// these will be the new directions
		var/nd2 = dirn


		if(nd1 > nd2)		// swap directions to match icons/states
			nd1 = dirn
			nd2 = C.d2


		for(var/obj/structure/cable/LC in T)		// check to make sure there's no matching cable
			if(LC == C)			// skip the cable we're interacting with
				continue
			if((LC.d1 == nd1 && LC.d2 == nd2) || (LC.d1 == nd2 && LC.d2 == nd1) )	// make sure no cable matches either direction
				user << "<span class='warning'>There's already a cable at that position!</span>"
				return


		C.cableColor(item_color)

		C.d1 = nd1
		C.d2 = nd2

		//updates the stored cable coil
		C.update_stored(2, item_color)

		C.add_fingerprint()
		C.updateicon()


		C.mergeConnectedNetworksOnTurf()


		use(1)

		if (C.shock(user, 50))
			if (prob(50)) //fail
				C.Deconstruct()
				return

		C.denode()// this call may have disconnected some cables that terminated on the centre of the turf, if so split the powernets.
		return

//////////////////////////////
// Misc.
/////////////////////////////

/obj/item/stack/cable_coil/cut
	item_state = "coil_red2"

/obj/item/stack/cable_coil/cut/New(loc)
	..()
	src.amount = rand(1,2)
	pixel_x = rand(-2,2)
	pixel_y = rand(-2,2)
	update_icon()

/obj/item/stack/cable_coil/yellow
	item_color = "yellow"
	icon_state = "coil_yellow"

/obj/item/stack/cable_coil/blue
	item_color = "blue"
	icon_state = "coil_blue"
	item_state = "coil_blue"

/obj/item/stack/cable_coil/green
	item_color = "green"
	icon_state = "coil_green"

/obj/item/stack/cable_coil/pink
	item_color = "pink"
	icon_state = "coil_pink"

/obj/item/stack/cable_coil/orange
	item_color = "orange"
	icon_state = "coil_orange"

/obj/item/stack/cable_coil/cyan
	item_color = "cyan"
	icon_state = "coil_cyan"

/obj/item/stack/cable_coil/white
	item_color = "white"
	icon_state = "coil_white"

/obj/item/stack/cable_coil/random/New()
	item_color = pick("red","yellow","green","blue","pink")
	icon_state = "coil_[item_color]"
	..()
