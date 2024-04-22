#!/bin/bash

XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}

if [ -d "/opt/system/Tools/PortMaster/" ]; then
  controlfolder="/opt/system/Tools/PortMaster"
elif [ -d "/opt/tools/PortMaster/" ]; then
  controlfolder="/opt/tools/PortMaster"
elif [ -d "$XDG_DATA_HOME/PortMaster/" ]; then
  controlfolder="$XDG_DATA_HOME/PortMaster"
else
  controlfolder="/roms/ports/PortMaster"
fi

source $controlfolder/control.txt
source $controlfolder/device_info.txt

get_controls

GAMEDIR="/$directory/ports/bstone-ps"

$ESUDO chmod 777 -R $GAMEDIR/*

if [[ "$CFW_NAME" == "muOS" ]]; then
    sed -i 's/^\(vid_renderer\s*\)"[^"]*"/\1"software"/' "$GAMEDIR/conf/bibendovsky/bstone/bstone_config.txt"
    ADDLPARAMS="--no_screens"
else
    sed -i 's/^\(vid_renderer\s*\)"[^"]*"/\1"gles_2_0"/' "$GAMEDIR/conf/bibendovsky/bstone/bstone_config.txt"
    ADDLPARAMS=""
fi

cd $GAMEDIR

> "$GAMEDIR/log.txt" && exec > >(tee "$GAMEDIR/log.txt") 2>&1

$ESUDO rm -rf ~/.local/share/bibendovsky
ln -sfv $GAMEDIR/conf/bibendovsky ~/.local/share/

$ESUDO chmod 666 /dev/tty0
$ESUDO chmod 666 /dev/tty1
$ESUDO chmod 666 /dev/uinput

export DEVICE_ARCH="${DEVICE_ARCH:-aarch64}"
export LD_LIBRARY_PATH="$GAMEDIR/libs.${DEVICE_ARCH}:$LD_LIBRARY_PATH"
export SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig"

if [[ $ANALOGSTICKS == '1' ]]; then
    GPTOKEYB_CONFIG="$GAMEDIR/bstone1joy.gptk"
elif [[ $DEVICE_NAME == 'x55' ]] || [[ $DEVICE_NAME == 'RG353P' ]]; then
    GPTOKEYB_CONFIG="$GAMEDIR/bstonetriggers.gptk"
else
    GPTOKEYB_CONFIG="$GAMEDIR/bstone.gptk"
fi

$GPTOKEYB "bstone.${DEVICE_ARCH}" -c "$GPTOKEYB_CONFIG" &
./bstone.${DEVICE_ARCH} --vid_windowed_width $DISPLAY_WIDTH --vid_windowed_height $DISPLAY_HEIGHT --vid_is_ui_stretched 1 $ADDLPARAMS --data_dir $GAMEDIR/gamedata/planet_strike

$ESUDO kill -9 $(pidof gptokeyb)
$ESUDO systemctl restart oga_events &
printf "\033c" > /dev/tty0
printf "\033c" > /dev/tty1
