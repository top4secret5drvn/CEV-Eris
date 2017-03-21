/mob/observer/angel
	name = "\improper ANGEL"
	desc = "A soul of someone dead, now lurking in the corporate networks of NeoTheology."

	icon = 'icons/mob/mob.dmi'
	icon_state = "angel"		// Placeholders!

	canmove = 0
	blinded = 0
	anchored = 1	// don't get pushed around
	universal_speak = 1
	incorporeal_move = 1


/mob/observer/angel/New(mob/body)
	see_in_dark = 100

	var/turf/T
	name += " #[rand(1000, 9999)]"

	if(ismob(body))
		T = get_turf(body)				//Where is the body located?
		attack_log = body.attack_log	//preserve our attack logs by copying them to our ghost

		alpha = 127

		gender = body.gender
		if(body.mind && body.mind.name)
			name += " of [body.mind.name]"
		else if(body.real_name)
			name += " of [body.real_name]"

		mind = body.mind	//we don't transfer the mind but we keep a reference to it.

	if(!T)	T = pick(latejoin)			//Safety in case we cannot find the body's position
	forceMove(T)

	real_name = name

	..()

