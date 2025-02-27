# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2019-present Shanti Gilbert (https://github.com/shantigilbert)
# Copyright (C) 2020-present Fewtarius

PKG_NAME="351elec"
PKG_VERSION=""
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="GPLv3"
PKG_SITE=""
PKG_URL=""
PKG_DEPENDS_TARGET="toolchain $OPENGLES 351elec-emulationstation retroarch retroarch32 retroarch-overlays imagemagick"
PKG_SHORTDESC="351ELEC Meta Package"
PKG_LONGDESC="351ELEC Meta Package"
PKG_IS_ADDON="no"
PKG_AUTORECONF="no"
PKG_TOOLCHAIN="make"

# Thanks to magicseb  Reicast SA now WORKS :D
PKG_EXPERIMENTAL="munt quasi88 xmil np2kai hypseus"
PKG_EMUS="$LIBRETRO_CORES advancemame PPSSPPSDL tgbdual TIC-80 pcsx_rearmed parallel-n64 fba4arm reicastsa amiberry uae4arm puae hatarisa fba4arm openbor mupen64plus mupen64plus-nx scummvmsa residualvm duckstation"
PKG_TOOLS="ffmpeg libjpeg-turbo common-shaders glsl-shaders Skyscraper MC SDL_GameControllerDB linux-utils xmlstarlet CoreELEC-Debug-Scripts sixaxis jslisten evtest mpv bluetool rs97-commander-sdl2 jslisten gnupg gzip patchelf valgrind strace gdb apitrace"
PKG_RETROPIE_DEP="bash pyudev dialog six git dbus-python pygobject coreutils"
PKG_DEPENDS_TARGET+=" $PKG_TOOLS $PKG_RETROPIE_DEP $PKG_EMUS $PKG_EXPERIMENTAL ports moonlight"

# These packages are only meant for S922x, S905x2 and A311D devices as they run poorly on S905, S912, etc"
if [ "$PROJECT" == "Amlogic-ng" ]; then
PKG_DEPENDS_TARGET+=" $LIBRETRO_S922X_CORES mame2016"
fi

if [[ "$DEVICE" =~ RG351 ]]; then
    PKG_DEPENDS_TARGET+=" odroidgoa-utils rs97-commander-sdl2"
    
    #we disable some cores that are not working or work poorly on OGA
    for discore in mesen-s virtualjaguar quicknes reicastsa_old reicastsa MC; do
        PKG_DEPENDS_TARGET=$(echo $PKG_DEPENDS_TARGET | sed "s|$discore||")
    done
    PKG_DEPENDS_TARGET+=" opera yabasanshiro"
else
    PKG_DEPENDS_TARGET+=" fbterm"
fi

make_target() {
if [ "$PROJECT" == "Amlogic-ng" ]; then
    cp -r $PKG_DIR/fbfix* $PKG_BUILD/
    cd $PKG_BUILD/fbfix
    $CC -O2 fbfix.c -o fbfix
fi
}

makeinstall_target() {
   
  mkdir -p $INSTALL/usr/config/
  rsync -av $PKG_DIR/config/* $INSTALL/usr/config/
  #cp -rf $PKG_DIR/config/* $INSTALL/usr/config/
  ln -sf /storage/.config/distribution $INSTALL/distribution
  find $INSTALL/usr/config/distribution/ -type f -exec chmod o+x {} \;

  echo "${LIBREELEC_VERSION}" > $INSTALL/usr/config/.OS_VERSION

  if [[ "${DEVICE}" =~ RG351 ]]; then
      echo "${DEVICE}" > $INSTALL/usr/config/.OS_ARCH
  else
      echo "${PROJECT}" > $INSTALL/usr/config/.OS_ARCH
  fi

  echo "$(date)" > $INSTALL/usr/config/.OS_BUILD_DATE
 
  mkdir -p $INSTALL/usr/bin/
  
  ## Compatibility links for ports
  ln -s /storage/roms $INSTALL/roms
  ln -sf /storage/roms/opt $INSTALL/opt

  mkdir -p $INSTALL/usr/lib
  ln -s /usr/lib32/ld-2.32.so $INSTALL/usr/lib/ld-linux-armhf.so.3

  mkdir -p $INSTALL/usr/share/retroarch-overlays
    cp -r $PKG_DIR/overlay/* $INSTALL/usr/share/retroarch-overlays
  
  mkdir -p $INSTALL/usr/share/libretro-database
     touch $INSTALL/usr/share/libretro-database/dummy

  # Move plymouth-lite bin to show splash screen
  cp $(get_build_dir plymouth-lite)/.install_init/usr/bin/ply-image $INSTALL/usr/bin

  mkdir -p $INSTALL/usr/config/splash

  find_file_path "splash/splash-*.png" && cp ${FOUND_PATH} $INSTALL/usr/config/splash

  mkdir -p $INSTALL/usr/share/bootloader
  if [ "$DEVICE" == "RG351P" ]; then
    find_file_path "splash/splash-480.bmp" && cp ${FOUND_PATH} $INSTALL//usr/share/bootloader/logo.bmp
  elif [ "$DEVICE" == "RG351V" ]; then
    find_file_path "splash/splash-640.bmp" && cp ${FOUND_PATH} $INSTALL//usr/share/bootloader/logo.bmp
  fi

}

post_install() {
# Remove unnecesary Retroarch Assets and overlays
  for i in branding glui nuklear nxrgui pkg switch wallpapers zarch COPYING; do
    rm -rf "$INSTALL/usr/share/retroarch-assets/$i"
  done
  
  for i in automatic dot-art flatui neoactive pixel retroactive retrosystem systematic convert.sh NPMApng2PMApng.py; do
  rm -rf "$INSTALL/usr/share/retroarch-assets/xmb/$i"
  done
  
  for i in borders effects gamepads ipad keyboards misc; do
    rm -rf "$INSTALL/usr/share/retroarch-overlays/$i"
  done
  mkdir -p $INSTALL/etc/retroarch-joypad-autoconfig
  cp -r $PKG_DIR/gamepads/* $INSTALL/etc/retroarch-joypad-autoconfig
  ln -sf 351elec.target $INSTALL/usr/lib/systemd/system/default.target
  enable_service 351elec-autostart.service

  echo "" >$INSTALL/etc/issue
  echo "  _________  _ _____ _     _____ ____ " >>$INSTALL/etc/issue
  echo " |___ / ___|/ | ____| |   | ____/ ___| V${LIBREELEC_VERSION}" >>$INSTALL/etc/issue
  echo "   |_ \___ \| |  _| | |   |  _|| |    " >>$INSTALL/etc/issue
  echo "  ___) |__) | | |___| |___| |__| |___ " >>$INSTALL/etc/issue
  echo " |____/____/|_|_____|_____|_____\____|" >>$INSTALL/etc/issue
  echo "" >>$INSTALL/etc/issue
  echo "" >>$INSTALL/etc/issue

  ln -s /etc/issue $INSTALL/etc/motd

  cp $PKG_DIR/sources/autostart.sh $INSTALL/usr/bin
  cp $PKG_DIR/sources/shutdown.sh $INSTALL/usr/bin
  cp $PKG_DIR/sources/pico-8.sh $INSTALL/usr/bin
  cp ${PKG_DIR}/sources/scripts/* $INSTALL/usr/bin

  rm -f $INSTALL/usr/bin/{sh,bash,busybox,sort}
  cp $(get_build_dir busybox)/.install_pkg/usr/bin/busybox $INSTALL/usr/bin
  cp $(get_build_dir bash)/.install_pkg/usr/bin/bash $INSTALL/usr/bin
  cp $(get_build_dir coreutils)/.install_pkg/usr/bin/sort $INSTALL/usr/bin

  ln -sf bash $INSTALL/usr/bin/sh
  mkdir -p $INSTALL/etc
  echo "/usr/bin/bash" >>$INSTALL/etc/shells
  echo "/usr/bin/sh" >>$INSTALL/etc/shells

  echo "chmod 4755 $INSTALL/usr/bin/bash" >> $FAKEROOT_SCRIPT
  echo "chmod 4755 $INSTALL/usr/bin/busybox" >> $FAKEROOT_SCRIPT
  find $INSTALL/usr/ -type f -iname "*.sh" -exec chmod +x {} \;
  
CORESFILE="$INSTALL/usr/config/emulationstation/es_systems.cfg"

if [ "${PROJECT}" != "Amlogic-ng" ]; then
    if [[ ${DEVICE} =~ RG351 ]]; then
        remove_cores="mesen-s quicknes REICASTSA_OLD REICASTSA mame2016"
    elif [ "${PROJECT}" == "Amlogic" ]; then
        remove_cores="mesen-s quicknes mame2016"
        xmlstarlet ed -L -P -d "/systemList/system[name='3do']" $CORESFILE
        xmlstarlet ed -L -P -d "/systemList/system[name='saturn']" $CORESFILE
    fi
    
    # remove unused cores
    for discore in ${remove_cores}; do
        sed -i "s|<core>$discore</core>||g" $CORESFILE
        sed -i '/^[[:space:]]*$/d' $CORESFILE
    done
fi
  # Remove scripts from OdroidGoAdvance build
	if [[ ${DEVICE} =~ RG351 ]]; then 
	for i in "01 - Get ES Themes" "03 - wifi" "10 - Force Update" "04 - Configure Reicast" "07 - Skyscraper" "09 - system info"; do 
xmlstarlet ed -L -P -d "/gameList/game[name='${i}']" $INSTALL/usr/config/usr/bin/modules/gamelist.xml 2>/dev/null ||:
	rm "$INSTALL/usr/config/usr/bin/modules/${i}.sh" 2>/dev/null ||:
	done
	fi 
  
} 
