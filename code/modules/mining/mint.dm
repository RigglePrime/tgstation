/**********************Mint**************************/


/obj/machinery/mineral/mint
	name = "coin press"
	icon = 'icons/obj/economy.dmi'
	icon_state = "coinpress0"
	density = TRUE
	var/newCoins = 0   //how many coins the machine made in it's last load
	var/processing = FALSE
	var/chosen = MAT_METAL //which material will be used to make coins
	var/coinsToProduce = 10
	speed_process = TRUE


/obj/machinery/mineral/mint/Initialize()
	. = ..()
	AddComponent(/datum/component/material_container, list(MAT_METAL, MAT_PLASMA, MAT_SILVER, MAT_GOLD, MAT_URANIUM, MAT_DIAMOND, MAT_BANANIUM), MINERAL_MATERIAL_AMOUNT * 50, FALSE, /obj/item/stack)

/obj/machinery/mineral/mint/process()
	var/turf/T = get_step(src, input_dir)
	if(!T)
		return

	GET_COMPONENT(materials, /datum/component/material_container)
	for(var/obj/item/stack/sheet/O in T)
		materials.insert_stack(O, O.amount)

/obj/machinery/mineral/mint/attack_hand(mob/user)
	. = ..()
	if(.)
		return
	var/dat = "<b>Coin Press</b><br>"

	GET_COMPONENT(materials, /datum/component/material_container)
	for(var/mat_id in materials.materials)
		var/datum/material/M = materials.materials[mat_id]
		if(!M.amount && chosen != mat_id)
			continue
		dat += "<br><b>[M.name] amount:</b> [M.amount] cm<sup>3</sup> "
		if (chosen == mat_id)
			dat += "<b>Chosen</b>"
		else
			dat += "<A href='?src=[REF(src)];choose=[mat_id]'>Choose</A>"

	var/datum/material/M = materials.materials[chosen]

	dat += "<br><br>Will produce [coinsToProduce] [lowertext(M.name)] coins if enough materials are available.<br>"
	dat += "<A href='?src=[REF(src)];chooseAmt=-10'>-10</A> "
	dat += "<A href='?src=[REF(src)];chooseAmt=-5'>-5</A> "
	dat += "<A href='?src=[REF(src)];chooseAmt=-1'>-1</A> "
	dat += "<A href='?src=[REF(src)];chooseAmt=1'>+1</A> "
	dat += "<A href='?src=[REF(src)];chooseAmt=5'>+5</A> "
	dat += "<A href='?src=[REF(src)];chooseAmt=10'>+10</A> "

	dat += "<br><br>In total this machine produced <font color='green'><b>[newCoins]</b></font> coins."
	dat += "<br><A href='?src=[REF(src)];makeCoins=[1]'>Make coins</A>"
	user << browse(dat, "window=mint")

/obj/machinery/mineral/mint/Topic(href, href_list)
	if(..())
		return
	usr.set_machine(src)
	src.add_fingerprint(usr)
	if(processing==1)
		to_chat(usr, "<span class='notice'>The machine is processing.</span>")
		return
	GET_COMPONENT(materials, /datum/component/material_container)
	if(href_list["choose"])
		if(materials.materials[href_list["choose"]])
			chosen = href_list["choose"]
	if(href_list["chooseAmt"])
		coinsToProduce = CLAMP(coinsToProduce + text2num(href_list["chooseAmt"]), 0, 1000)
	if(href_list["makeCoins"])
		var/temp_coins = coinsToProduce
		processing = TRUE
		icon_state = "coinpress1"
		var/coin_mat = MINERAL_MATERIAL_AMOUNT * 0.2
		var/datum/material/M = materials.materials[chosen]
		if(!M || !M.coin_type)
			updateUsrDialog()
			return

		while(coinsToProduce > 0 && materials.use_amount_type(coin_mat, chosen))
			create_coins(M.coin_type)
			coinsToProduce--
			newCoins++
			src.updateUsrDialog()
			sleep(5)

		icon_state = "coinpress0"
		processing = FALSE
		coinsToProduce = temp_coins
	src.updateUsrDialog()
	return

/obj/machinery/mineral/mint/proc/create_coins(P)
	var/turf/T = get_step(src,output_dir)
	var/temp_list = list()
	temp_list[chosen] = 400
	if(T)
		var/obj/item/storage/bag/money/bag_to_use = locate(/obj/item/storage/bag/money, T)
		var/obj/item/O = new P(src)
		if(QDELETED(bag_to_use) || (bag_to_use.loc != T) || !SEND_SIGNAL(bag_to_use, COMSIG_TRY_STORAGE_INSERT, O, null, TRUE)) //important to send the signal so we don't overfill the bag.
			bag_to_use = new(src) //make a new bag if we can't find or use the old one.
			unload_mineral(bag_to_use) //just forcemove memes.
			O.forceMove(bag_to_use) //don't bother sending the signal, the new bag is empty and all that.

		SSblackbox.record_feedback("amount", "coins_minted", 1)
