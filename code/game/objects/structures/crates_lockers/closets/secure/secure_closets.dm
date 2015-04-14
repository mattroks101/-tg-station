/obj/structure/closet/secure_closet
	name = "secure locker"
	desc = "It's an immobile card-locked storage unit."
	locked = 1
	var/icon_locked = "secure1"
	var/icon_broken = "securebroken"
	var/icon_off = "secureoff"
	var/code1[5]
	var/code2[5]
	wall_mounted = 0 //never solid (You can always pass over it)
	health = 200

/obj/structure/closet/secure_closet/New()
	..()
	for(var/i=1; i<=5; i++)
		code1[i] = rand(0,9)
		code2[i] = rand(0,9)
	icon_state = "secure"
	health = 200

/obj/structure/closet/secure_closet/update_icon()//Putting the welded stuff in updateicon() so it's easy to overwrite for special cases (Fridges, cabinets, and whatnot)
	..()
	if(!opened)
		if(!broken)
			if(locked)
				overlays += "locked"
			else
				overlays += "unlocked"
		else
			overlays += "off"

/obj/structure/closet/secure_closet/examine(mob/user)
	..()
	if(broken || opened || !ishuman(user))
		return //Monkeys don't get a message, nor does anyone ief it's open or emagged
	else
		user << "<span class='notice'>Alt-click the locker to [locked ? "unlock" : "lock"] it.</span>"

/obj/structure/closet/secure_closet/AltClick(var/mob/user)
	..()
	if(!in_range(src, user))
		return
	if(!ishuman(user))
		user << "<span class='notice'>You have no idea how this thing is supposed to work.</span>"
		return
	if(user.stat || !user.canmove || user.restrained() || broken)
		user << "<span class='notice'>You can't do that right now.</span>"
		return
	if(src.opened)
		return
	else
		togglelock(user)

/obj/structure/closet/secure_closet/can_open()
	if(src.locked || src.welded)
		return 0
	return 1

/obj/structure/closet/secure_closet/emp_act(severity)
	for(var/obj/O in src)
		O.emp_act(severity)
	if(!broken)
		if(prob(50/severity))
			src.locked = !src.locked
			src.update_icon()
		if(prob(20/severity) && !opened)
			if(!locked)
				open()
			else
				src.req_access = list()
				src.req_access += pick(get_all_accesses())
	..()

/obj/structure/closet/secure_closet/proc/togglelock(mob/user as mob)
	if(src.allowed(user))
		src.locked = !src.locked
		add_fingerprint(user)
		for(var/mob/O in viewers(user, 3))
			if((O.client && !( O.eye_blind )))
				O << "<span class='notice'>[user] has [locked ? null : "un"]locked the locker.</span>"
		update_icon()
	else
		user << "<span class='notice'>Access Denied</span>"

/obj/structure/closet/secure_closet/place(var/mob/user, var/obj/item/I)
	if(!src.opened)
		togglelock(user)
		return 1
	return 0

/obj/structure/closet/secure_closet/attackby(obj/item/weapon/W as obj, mob/user as mob, params)
	if(istype(W, /obj/item/device/multitool/multimeter))
		var/obj/item/device/multitool/multimeter/O = W
		if(O.mode!=1)
			user << "����������� ����������"
		else
			src.interact(usr)

	if(!src.opened && src.broken)
		user << "<span class='notice'>The locker appears to be broken.</span>"
		return
	else

		..(W, user)

/obj/structure/closet/secure_closet/emag_act(mob/user as mob)
	if(!broken)
		broken = 1
		locked = 0
		desc += "It appears to be broken."
		update_icon()

		for(var/mob/O in viewers(user, 3))
			O.show_message("<span class='warning'>The locker has been broken by [user] with an electromagnetic card!</span>", 1, "You hear a faint electrical spark.", 2)
		overlays += "sparking"
		spawn(4) //overlays don't support flick so we have to cheat
		update_icon()

/obj/structure/closet/secure_closet/relaymove(mob/user as mob)
	if(user.stat || !isturf(src.loc))
		return

	if(!(src.locked))
		open()
	else
		user << "<span class='notice'>The locker is locked!</span>"
		if(world.time > lastbang+5)
			lastbang = world.time
			for(var/mob/M in get_hearers_in_view(src, null))
				M.show_message("<FONT size=[max(0, 5 - get_dist(src, M))]>BANG, bang!</FONT>", 2)
	return

/obj/structure/closet/secure_closet/attack_hand(mob/user as mob)
	src.add_fingerprint(user)

	if(!src.toggle())
		return src.attackby(null, user)

/obj/structure/closet/secure_closet/attack_paw(mob/user as mob)
	return src.attack_hand(user)

/obj/structure/closet/secure_closet/interact(mob/user)
	src.add_fingerprint(user)
	var/dat = ""
	dat += "<a href='?src=\ref[src];check=1'>��������� �����</a>"
	dat += "<br><a href='?src=\ref[src];inc=1'>+</a><a href='?src=\ref[src];inc=2'>+</a><a href='?src=\ref[src];inc=3'>+</a><a href='?src=\ref[src];inc=4'>+</a><a href='?src=\ref[src];inc=5'>+</a><br>"
	for(var/i=1; i<=5; i++)
		dat += "[code2[i]]"
	dat += "<br><a href='?src=\ref[src];dec=1'>-</a><a href='?src=\ref[src];dec=2'>-</a><a href='?src=\ref[src];dec=3'>-</a><a href='?src=\ref[src];dec=4'>-</a><a href='?src=\ref[src];dec=5'>-</a>"

	user.set_machine(src)
	var/datum/browser/popup = new(user, "closet", "[name]")
	popup.set_content(dat)
	popup.open(1)

/obj/structure/closet/secure_closet/Topic(href, href_list)
	if(!ishuman(usr))	return
	var/mob/living/carbon/human/user = usr
	var/obj/item/device/multitool/multimeter/W = user.get_active_hand()
	var/validate = 0
	user.set_machine(src)

	if(href_list["check"])
		validate = 0
		if(W.mode != 1)
			usr << "<span class='notice'>����������� ����������</span>"
		else
			usr << "<span class='notice'>��������� �����</span>"
			for(var/i=1; i<=5; i++)
				if(do_after(user, 10))
					if(code2[i]==code1[i])
						validate++
						usr << "<span class='notice'>���� ��������</span>"
						playsound(W.loc, 'sound/machines/ping.ogg', 30, 1)
					else
						usr << "<span class='notice'>���� �� ��������</span>"
						playsound(W.loc, 'sound/machines/twobeep.ogg', 30, 1)
		if(validate>4)
			src.locked = !src.locked
			add_fingerprint(user)
			visible_message("<span class='warning'>[user] has hacked [src]!</span>")
			update_icon()

	if(href_list["inc"])
		if(W.mode != 1)
			usr << "<span class='notice'>����������� ����������</span>"
		else
			var/inc = text2num(href_list["inc"])
			code2[inc]++
			if(code2[inc] > 9)
				code2[inc] = 0
			interact(user)

	if(href_list["dec"])
		if(W.mode != 1)
			usr << "<span class='notice'>����������� ����������</span>"
		else
			var/inc = text2num(href_list["dec"])
			code2[inc]--
			if(code2[inc]<0)
				code2[inc] = 9
			interact(user)


