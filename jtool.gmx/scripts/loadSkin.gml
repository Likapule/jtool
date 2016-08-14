/// loadSkin(skin_name)
// Load the specified skin from file into the game.

var skin_name = argument0

if not directory_exists('skins') {
    var num = zip_unzip('./stock_skins_zip_included.zip', './')
    if num <= 0 {
        show_message('Failed to unzip stock skins.')
    }
}

var skinFolder = 'skins\'+skin_name+'\'
if not directory_exists(skinFolder) {
    inputOverlay(input_info, false, "Couldn't find skin folder#"+skinFolder)
}
var ini_filename = skinFolder+'skin_config.ini'
var missing_ini_filename = 'skin_config_missing.ini'

if not directory_exists(skinFolder) {
    inputOverlay(input_info,false,"Couldn't find skin folder#"+skinFolder)
    ini_filename = missing_ini_filename
}
else if not file_exists(ini_filename) {
    inputOverlay(input_info,false,'Warning: '+ini_filename+' does not exist.')
}
ini_open(ini_filename)

// meta
var skinver_string = ini_read_string('meta','version','')
if skinver_string == '' {
    //inputOverlay(input_info,false,'Warning: no version provided in skin.')
}
else {
    var skinver_major = real(splitDelimString(skinver_string,'.',0))
    if skinver_major > global.version_major {
        //inputOverlay(input_info,false,'Warning: may not be not compatible with skin;#it has a new major version.')
    }
}

// ui
global.color_button = colorFromHsvDelimString(
    ini_read_string('ui','button_idle_color','0,0,175'),',')
global.color_buttonhover = colorFromHsvDelimString(
    ini_read_string('ui','button_active_color','0,0,255'),',')
global.color_palettepressed = colorFromHsvDelimString(
    ini_read_string('ui','button_palette_pressed_color','0,0,0'),',')
global.buttonhoveralpha = ini_read_real('ui','button_active_alpha',0.5)
global.buttonpalettepressedalpha = ini_read_real('ui','button_palette_pressed_alpha',0.5)
global.buttonhoverborder = ini_read_real('ui','button_active_border',false)

// objects
var colorstring = ini_read_string('objects','killer_idle_color','0,0,255')
global.color_killerhue = real(splitDelimString(colorstring,',',0))
global.color_killersat = real(splitDelimString(colorstring,',',1))
global.color_killerval = real(splitDelimString(colorstring,',',2))
global.color_killer = colorFromHsvDelimString(colorstring,',')
var colorstring = ini_read_string('objects','killer_active_color','0,128,255')
global.color_killer2hue = real(splitDelimString(colorstring,',',0))
global.color_killer2sat = real(splitDelimString(colorstring,',',1))
global.color_killer2val = real(splitDelimString(colorstring,',',2))
global.color_killer2 = colorFromHsvDelimString(colorstring,',')
global.color_warp = colorFromHsvDelimString(
    ini_read_string('objects','warp_color','67,196,239'),',')
global.bulletblockeralpha = ini_read_real('objects','bulletblocker_alpha',0.3)
global.spikeframes = ini_read_real('objects','spike_frames',1)
global.spikeanimspeed = ini_read_real('objects','spike_animspeed',1)
global.minispikeframes = ini_read_real('objects','minispike_frames',1)
global.minispikeanimspeed = ini_read_real('objects','minispike_animspeed',1)

// bg
var bg_type = ini_read_string('bg','type','stretch')
var bg_hspeed = ini_read_real('bg','hspeed',0)
var bg_vspeed = ini_read_real('bg','vspeed',0)
ini_close()
file_delete(missing_ini_filename)



// delete previous skin sprites
var size = ds_map_size(global.skinSpriteMap);
var key = ds_map_find_first(global.skinSpriteMap)
for (var i=0; i<size; i+=1) {
    var subMap = global.skinSpriteMap[? key]
    var spr = subMap[? 'sprite']
    if ds_list_find_index(global.defaultSkinSpriteList, spr) == -1 {
        sprite_delete(spr)
    }
    ds_map_destroy(subMap)
    key = ds_map_find_next(global.skinSpriteMap, key)
}
ds_map_clear(global.skinSpriteMap)


// load sprite configs
var skinConfigFilename = skinFolder+'skin_config.xml'
if file_exists(skinConfigFilename) {
    var subMap = -1
    var lastValue = ''
    DerpXmlRead_OpenFile(skinConfigFilename)
    while DerpXmlRead_Read() {
        var type = DerpXmlRead_CurType()
        var value = DerpXmlRead_CurValue()
        if type == DerpXmlType_OpenTag and value == 'sprite' {
            subMap = ds_map_create()
        }
        else if type == DerpXmlType_CloseTag {
            // todo: load general skin values (spike color, etc)
            if value == 'name' {
                global.skinSpriteMap[? lastValue] = subMap
            }
            else if value == 'xorig' or value == 'yorig'
            or value = 'xpaloff' or value = 'ypaloff'
            or value == 'animframes' {
                subMap[? value] = real(lastValue)
            }
            else if value == 'animspeed' {
                subMap[? value] = 1/real(lastValue)
            }
            else if value == 'animsync' {
                subMap[? value] = lastValue
            }
        }
        lastValue = value
    }
    DerpXmlRead_CloseFile()
}
else {
    // Todo: handle skin config file not existing
}


// add default sprites
var size = ds_map_size(global.stringToDefaultSkinSprite);
var key = ds_map_find_first(global.stringToDefaultSkinSprite)
for (var i=0; i<size; i+=1) {
    var subMap = global.skinSpriteMap[? key];
    if is_undefined(subMap) {
        // TODO: show an error message if a sprite config isn't supplied!
        subMap = ds_map_create()
        global.skinSpriteMap[? key] = subMap
        subMap[? 'xorig'] = 0
        subMap[? 'yorig'] = 0
        subMap[? 'xpaloff'] = 0
        subMap[? 'ypaloff'] = 0
        subMap[? 'animframes'] = 0
        subMap[? 'animspeed'] = 0
        subMap[? 'animsync'] = 'synced'
    }
    subMap[? 'sprite'] = global.stringToDefaultSkinSprite[? key]
    key = ds_map_find_next(global.stringToDefaultSkinSprite, key)
}


// load png files
var filename = file_find_first(skinFolder+'*.png', 0)
while filename != '' {
    var sprName = string_copy(filename, 1, string_pos('.', filename)-1)
    var subMap = global.skinSpriteMap[? sprName]
    if is_undefined(subMap) {
        // TODO: show an error message if a sprite config isn't supplied!
        subMap = ds_map_create()
        global.skinSpriteMap[? sprName] = subMap
        subMap[? 'xorig'] = 0
        subMap[? 'yorig'] = 0
        subMap[? 'xpaloff'] = 0
        subMap[? 'ypaloff'] = 0
        subMap[? 'animframes'] = 0
        subMap[? 'animspeed'] = 0
        subMap[? 'animsync'] = 'synced'
    }
    var xOrig = subMap[? 'xorig']
    var yOrig = subMap[? 'yorig']
    var animFrames = subMap[? 'animframes']
    var addedSpr = sprite_add(skinFolder+filename, animFrames, false, false, xOrig, yOrig)
    if addedSpr == -1 {
        resource_add_errors += ', '+filename
        addedSpr = sprite_duplicate(sSpikeUpDefault)
    }
    subMap[? 'sprite'] = addedSpr
    filename = file_find_next()
}
file_find_close()


// Hardcoded values (only apple anim speed)
var subMap = global.skinSpriteMap[? 'apple'];
subMap[? 'animspeed'] = 1/15


// Set selected object to first one in palatte
var palItemMap = global.palatteList[| 0]
var spriteConfigMap = global.skinSpriteMap[? palItemMap[? 'spr']]
with oEdit {
    selected_object = global.stringToObjectMap[? palItemMap[? 'obj']]
    selected_sprite = spriteConfigMap[? 'sprite']
    selected_killer = selected_object == oKiller
    selected_animspeed = spriteConfigMap[? 'animspeed']
}


/*

// assign sprites from file
var resource_add_errors = ''
for (var i=0; i<100; i+=1) {
    // spr_index - sprite index to replace
    // spr_default - default sprite to use if png not found
    // file - name of png file
    // xo - sprite x origin to set (default 0)
    // yo - sprite y origin to set (default 0)
    // frames - number of frames the sprite png has (default 1)
    var spr_index,spr_default,file,xo,yo,frames
    xo = 0
    yo = 0
    frames = 1
    switch i {
        case 0:  spr_index=sSpikeUp spr_default=sSpikeUpDefault file='spikeup.png' frames = global.spikeframes break
        case 1:  spr_index=sSpikeRight spr_default=sSpikeRightDefault file='spikeright.png' frames = global.spikeframes break
        case 2:  spr_index=sSpikeLeft spr_default=sSpikeLeftDefault file='spikeleft.png' frames = global.spikeframes break
        case 3:  spr_index=sSpikeDown spr_default=sSpikeDownDefault file='spikedown.png' frames = global.spikeframes break
        case 4:  spr_index=sMiniSpikeUp spr_default=sMiniSpikeUpDefault file='miniup.png' frames = global.minispikeframes break
        case 5:  spr_index=sMiniSpikeRight spr_default=sMiniSpikeRightDefault file='miniright.png' frames = global.minispikeframes break
        case 6:  spr_index=sMiniSpikeLeft spr_default=sMiniSpikeLeftDefault file='minileft.png' frames = global.minispikeframes break
        case 7:  spr_index=sMiniSpikeDown spr_default=sMiniSpikeDownDefault file='minidown.png' frames = global.minispikeframes break
        case 8:  spr_index=sEditBlock spr_default=sEditBlockDefault file='block.png' break
        case 9:  spr_index=sEditMiniBlock spr_default=sEditMiniBlockDefault file='miniblock.png' break
        case 10: spr_index=sPlatform spr_default=sPlatformDefault file='platform.png' break
        case 11: spr_index=sSave spr_default=sSaveDefault file='save.png' frames = 2 break
        case 12: spr_index=sApple spr_default=sAppleDefault file='apple.png' xo=10 yo=12 frames = 2 break
        case 13: spr_index=sWater1 spr_default=sWater1Default file='water1.png' break
        case 14: spr_index=sWater2 spr_default=sWater2Default file='water2.png' break
        case 15: spr_index=sWalljumpL spr_default=sWalljumpLDefault file='walljumpL.png' break
        case 16: spr_index=sWalljumpR spr_default=sWalljumpRDefault file='walljumpR.png' break
        case 17: spr_index=sKillerBlock spr_default=sKillerBlockDefault file='killerblock.png' break
        case 18: spr_index=sSidebar spr_default=sSidebarDefault file='sidebar.png' break
        case 19: spr_index=sMenu spr_default=sMenuDefault file='menu.png' break
        case 20: spr_index=sBulletBlocker spr_default=sBulletBlockerDefault file='bulletblocker.png' break
        case 21: spr_index=sPlayerStart spr_default=sPlayerStartDefault file='playerstart.png' break
        case 22: spr_index=sWarp spr_default=sWarpDefault file='warp.png' break
        case 23: spr_index=sJumpRefresher spr_default=sJumpRefresherDefault file='jumprefresher.png' xo=15 yo=15 break
        case 24: spr_index=sWater3 spr_default=sWater3Default file='water3.png' break
        case 25: spr_index=sPopup spr_default=sPopupDefault file='popup.png' break
        default: continue
    }
    
    if file_exists(skinfolder+file) {
        var spr = sprite_add(skinfolder+file,frames,false,false,xo,yo)
        if spr != -1 {
            sprite_assign(spr_index,spr)
            sprite_delete(spr)
        }
        else {
            resource_add_errors += ', '+file
            sprite_assign(spr_index,spr_default)
        }
    }
    else {
        sprite_assign(spr_index,spr_default)
    }
}

// assign background from file
file = 'bg.png'
if file_exists(skinfolder+file) {
    var bg = background_add(skinfolder+file,false,false)
    if bg != -1 {
        background_assign(bgBackground,bg)
        background_delete(bg)
    }
    else {
        resource_add_errors += ', '+file
        background_assign(bgBackground,bgBackgroundDefault)
    }
}
else {
    background_assign(bgBackground,bgBackgroundDefault)
}
if bg_type == 'stretch' {
    background_xscale = room_width/background_width
    background_yscale = room_height/background_height
    background_htiled = false
    background_vtiled = false
}
else if bg_type == 'tile' {
    background_xscale = 1
    background_yscale = 1
    background_htiled = true
    background_vtiled = true
}
background_hspeed = bg_hspeed
background_vspeed = bg_vspeed
background_x = 0
background_y = 0

if resource_add_errors != '' {
    inputOverlay(input_info,false,'Error when adding resources:#'+resource_add_errors+'#Try double checking everything.')
}
