

#define MAP_PATH "maps"
#define MAP_FILE "CEV_Eris-1.dmm"


var/datum/minimap/global_minimap = new/datum/minimap

/datum/minimap
	var/const/MINIMAP_SIZE = 2500
	var/const/TILE_SIZE = 16

	var/list/z_levels

/datum/minimap/proc/initialize()
	var/hash = md5(file2text("[MAP_PATH]/[MAP_FILE]"))
	z_levels = config.station_levels

	if(config.generate_minimaps)
		if(hash == trim(file2text(hash_path())))
			for(var/z in z_levels)
				register_asset("minimap_[z].png", fcopy_rsc(map_path(z)))
				return
		for(var/z in z_levels)
			generate(z)
			register_asset("minimap_[z].png", fcopy_rsc(map_path(z)))
		fdel(hash_path())
		text2file(hash, hash_path())
	else
		admin_notice("<span class='danger'>Minimap generation disabled. Loading from cache...</span>", R_DEBUG)
		var/fileloc = 0
		if(check_files(0))
			if(hash != trim(file2text(hash_path())))
				admin_notice("<span class='danger'>Loaded cached minimap is outdated. There may be minor discrepancies in layout.</span>", R_DEBUG)
			fileloc = 0
		else
			if(!check_files(1))
				admin_notice("<span class='danger'>Failed to load backup minimap file. Aborting.</span>", R_DEBUG)
				return
			fileloc = 1 //No map image cached with the current map, and we have a backup. Let's fall back to it.
			admin_notice("<span class='danger'>No cached minimaps detected. Backup files loaded.</span>", R_DEBUG)
		for(var/z in z_levels)
			register_asset("minimap_[z].png", fcopy_rsc(map_path(z, fileloc)))

/datum/minimap/proc/check_files(backup)
	for(var/z in z_levels)
		if(!fexists(file(map_path(z, backup))))
			if(backup)
				admin_notice("<span class='danger'>Failed to find backup file for map [MAP_FILE] on zlevel [z].</span>", R_DEBUG)
				return 0
	return 1

/datum/minimap/proc/hash_path(backup)
	if(backup)
		return "icons/minimaps/[MAP_FILE].md5"
	else
		return "data/minimaps/[MAP_FILE].md5"

/datum/minimap/proc/map_path(z, backup)
	if(backup)
		return "icons/minimaps/[MAP_FILE]_[z].png"
	else
		return "data/minimaps/[MAP_FILE]_[z].png"

/datum/minimap/proc/send(client/client)
	for(var/z in z_levels)
		send_asset(client, "minimap_[z].png")


/datum/minimap/proc/generate(z = 1, x1 = 1, y1 = 1, x2 = world.maxx, y2 = world.maxy)
	// Load the background.
	var/icon/final = new /icon()
	var/icon/minimap = new /icon('icons/minimap.dmi')
	// Scale it up to our target size.
	minimap.Scale(MINIMAP_SIZE, MINIMAP_SIZE)

	// Loop over turfs and generate icons.


	for(var/T in block(locate(x1, y1, z), locate(x2, y2, z)))
		generate_tile(T, minimap)


	// Create a new icon and insert the generated minimap, so that BYOND doesn't generate different directions.

	final.Insert(minimap, "", SOUTH, 1, 0)
	fcopy(final, map_path(z))


/datum/minimap/proc/generate_tile(turf/tile, icon/minimap)
	var/icon/tile_icon
	var/obj/obj
	var/list/obj_icons

	// Don't use icons for space, just add objects in space if they exist.

	if(istype(tile, /turf/space))
		obj = locate(/obj/structure/lattice) in tile
		if(obj)
			tile_icon = new /icon('icons/obj/structures.dmi', "latticefull", SOUTH)
		obj = locate(/obj/structure/grille) in tile
		if(obj)
			tile_icon = new /icon('icons/obj/structures.dmi', "grille", SOUTH)
		obj = locate(/obj/structure/transit_tube) in tile
		if(obj)
			tile_icon = new /icon('icons/obj/pipes/transit_tube.dmi', obj.icon_state, SOUTH)
	else
		switch(tile.type)
			if(/turf/simulated/wall/r_wall) tile_icon = new /icon('icons/turf/wall_masks.dmi', "rgeneric", SOUTH)
			if(/turf/simulated/wall) tile_icon = new /icon('icons/turf/wall_masks.dmi', "generic", SOUTH)
			else tile_icon = new /icon(tile.icon, tile.icon_state, tile.dir)

		obj_icons = list()

		obj = locate(/obj/structure) in tile
		if(obj)
			obj_icons += new /icon(obj.icon, obj.icon_state, obj.dir, 1, 0)
		obj = locate(/obj/machinery) in tile
		if(obj)
			obj_icons += new /icon(obj.icon, obj.icon_state, obj.dir, 1, 0)
		obj = locate(/obj/structure/window) in tile
		if(obj)
			switch(obj.type)
				if(/obj/structure/window/reinforced/full) obj_icons += new /icon('icons/obj/structures.dmi', "r-wingrille", SOUTH)
				if(/obj/structure/window) obj_icons += new /icon('icons/obj/structures.dmi', "wingrille", SOUTH)
				else obj_icons += new /icon('icons/obj/structures.dmi', obj.icon_state, SOUTH)

		for(var/I in obj_icons)
			var/icon/obj_icon = I
			tile_icon.Blend(obj_icon, ICON_OVERLAY)

	if(tile_icon)
		tile_icon.Scale(TILE_SIZE, TILE_SIZE)

		minimap.Blend(tile_icon, ICON_OVERLAY, ((tile.x - 1) * TILE_SIZE), ((tile.y - 1) * TILE_SIZE))

