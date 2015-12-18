

/datum/power/PowerNode
	var/list/sources = null
	var/datum/power/PowerNetwork/selectedSource = null
	var/currentPowerUsage=0
	var/uuid=0

	var/name="NAME NOT SET"
//	var/power_type=POWER_TYPE_CONSUMER

	//boolean flags: 1=true, 0=false
	var/requestedPowerUsage=0


/datum/power/PowerNode/New(var/powerNodeName)
	uuid=getUniqueID()
	if(powerNodeName!=null)
		name=powerNodeName



/datum/power/PowerNode/proc/addPowerNetwork(var/datum/power/PowerNetwork/network)
	if(sources==null)
		sources= list()
	LIST_ADDLAST(sources,network)

	//Adding a new network causes a possible network shift
	setPower(requestedPowerUsage)
	//END OF PROC

//PowerNode is turned off without any auto restart
//datum/power/PowerNode/proc/turnOff()






//Turn machine off, but it will receive an POWER_ON event when power is restored.
/datum/power/PowerNode/proc/brownOut()
	var/oldPowerRequest = requestedPowerUsage
	setPower(0)
	//Setpower 0 will setRequestedPowerUsage to 0. restore that.
	requestedPowerUsage=oldPowerRequest
	if(selectedSource!=null)
		LIST_ADDLAST(selectedSource.autoResumePower,src)
		selectedSource.flagAsChanged()
	//END OF PROC


/* Sets the power for the current Machine.
 * amount: Attempt to set this amount of power
 * Returns: 0 if power was set. 1 if not
 * Triggered Events
 * -
 */
/datum/power/PowerNode/proc/setPower(var/amount)
//	world<<"DEBUG: [name]([uuid]) Attempting to set power usage at: [amount]"
	requestedPowerUsage = amount
	var/deltaChange = amount-currentPowerUsage
	if(deltaChange==0)
		//world<<"DEBUG: [name]([uuid]) No Change: [amount]"
		return 0

	if(sources!=null)
		for(var/datum/power/PowerNetwork/source in sources)
		//	world<<"DEBUG: [name]([uuid]) Checking network [source.uuid]"
			var/maxPower = 0
			if(selectedSource==source)
			//	world<<"DEBUG: [name]([uuid]) selectedSource==source)"
				maxPower = source.availableDelta + currentPowerUsage
				if(maxPower>=amount)
					//world<<"DEBUG: [name]([uuid]) Current network has enough power"
					source.availableDelta -= deltaChange
					source.flagAsChanged()
					currentPowerUsage=amount
					return 0
			else
				//world<<"DEBUG: [name]([uuid]) selectedSource!=source"
				maxPower = source.availableDelta
				if(maxPower>=amount)
					//world<<"DEBUG: [name]([uuid]) New network has enough power"
					//Detach from current network
					if(selectedSource!=null)
						selectedSource.availableDelta+=currentPowerUsage
						selectedSource.attached-=src


						selectedSource.flagAsChanged()

					selectedSource=source
					source.availableDelta-=amount
					source.attached+=src
					currentPowerUsage=amount
					selectedSource.flagAsChanged()
					return 0


	//Unable to set power
	//Keep network affinity
	if(selectedSource!=null)
		selectedSource.availableDelta+=currentPowerUsage
	currentPowerUsage=0
	//world<<"DEBUG: [name]([uuid]) Done checking networks"
	//Auto firstNetwork so that one network will attempt to start this.
	if(sources!=null)

		if(selectedSource==null & sources.len >0)
		//	world<<"DEBUG: [name]([uuid]) Register with first network"
			selectedSource=sources[1] //Arrays are 1 based
			LIST_ADDLAST(selectedSource.attached,src)

		//world<<"DEBUG: [name]([uuid]) Network doesn't have enough power"
		selectedSource.flagAsChanged()

	return 1
	//END OF PROC


//abstract Methods
/datum/power/PowerNode/proc/processTick()
