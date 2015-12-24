var/datum/subsystem/machines/SSmachine

/datum/subsystem/machines
	name = "Machines"
	priority = 9
	display = 3

	var/list/processing = list()
	var/list/powernets = list()


/datum/subsystem/machines/Initialize()
	fire()
	..()



/datum/subsystem/machines/New()
	NEW_SS_GLOBAL(SSmachine)


/datum/subsystem/machines/stat_entry()
	..("M:[processing.len]|PN:[powernets.len]")


/datum/subsystem/machines/fire()
	var/seconds = wait * 0.1
	for(var/thing in processing)
		if(thing && (thing:process(seconds) != PROCESS_KILL))
			continue
		processing.Remove(thing)

