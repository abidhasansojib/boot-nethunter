#! /data/data/com.termux/files/usr/bin/bash
#  CODE Begins here ->

function banner_boot_nethunter()
{
    blue='\033[1;34m'
    light_cyan='\033[1;96m'
    reset='\033[0m'
    clear
    printf "  ${blue}##############################\n"
    printf "  ${blue}##                          ##\n"
    printf "  ${blue}##     Boot-Nethunter       ##\n"
    printf "  ${blue}##                          ##\n"
    printf "  ${blue}##############################\n"
    printf "  ${blue}|||||| ${light_cyan}abidhasansojib${blue}||||||||\n"
    printf "  ${blue}--------------------------------------${reset}"
    echo "  "
    echo "  "
}

function check_update()
{
    if [ ! -d ~/.termux ]; then
        clear
        echo " "
        echo " [!] You may be on an older version of Termux !!!"
        echo "     Updating Termux...."
        sleep 2
        pkg update -y
        clear
        echo " [!] Upgrading packages..."
        sleep 2
        pkg upgrade -y
        pkg install wget -y
        clear
        echo " "
        echo " [*] You need to completely restart Termux, "
        echo "     And start the installation again !!!"
        echo " "
        exit
    fi
}

setup_nh_files() {
    local BIN_DIR="/data/local/nhsystem/kali-arm64/bin"
    local ROOT_DIR="/data/local/nhsystem/kali-arm64/root"
    local SCRIPTS_SRC="scripts"

    if [ ! -d "$SCRIPTS_SRC" ]; then
        echo "⚠️ Error: '$SCRIPTS_SRC' folder not found in the current directory."
        return 1
    fi

    if [ -f "$SCRIPTS_SRC/kex" ]; then
        echo "Moving 'kex' to $BIN_DIR..."
        su -c "mv '$SCRIPTS_SRC/kex' '$BIN_DIR/' && chmod +x '$BIN_DIR/kex'"
        echo "✓ 'kex' moved and made executable."
    else
        echo "⚠️ Warning: 'kex' not found inside '$SCRIPTS_SRC/'"
    fi

    if [ "$(shopt -s nullglob; echo "$SCRIPTS_SRC"/*)" ]; then
        echo "Moving remaining scripts to $ROOT_DIR..."
        su -c "mkdir -p '$ROOT_DIR/scripts'"
        su -c "mv '$SCRIPTS_SRC'/* '$ROOT_DIR/scripts/'"
        echo "✓ All remaining scripts moved to root."
    else
        echo "ℹ️ No extra scripts left in '$SCRIPTS_SRC/' to move."
    fi
}

function clean_temp()
{
    if [ -f ~/.wget-hsts ]; then
        rm ~/.wget-hsts
    fi
}

function install_boot_nethunter()
{
    echo " [*] Installing Boot Nethunter ..."
    echo " "

    su -c 'cp -r /data/data/com.offsec.nethunter/scripts /data/local/'
    
    # 1. Create the boot-kali script locally in Termux user space first
    cat << 'EOF' > boot-kali.tmp
#! /data/data/com.termux/files/usr/bin/bash
# This script boots nethunter in termux

su -c '
nethunter_env=$PATH:/system/sbin
nethunter_env=$nethunter_env:/product/bin
nethunter_env=$nethunter_env:/apex/com.android.runtime/bin
nethunter_env=$nethunter_env:/odm/bin
nethunter_env=$nethunter_env:/vendor/bin
nethunter_env=$nethunter_env:/vendor/xbin
nethunter_env=$nethunter_env:/data/local/scripts
nethunter_env=$nethunter_env:/data/local/scripts/bin
export PATH=$nethunter_env; exec bootkali'
EOF

    # 2. Safely move it to the system destination, fix permissions using root, and clean up
    TARGET_PATH="/data/data/com.termux/files/usr/bin/boot-kali"
    su -c "mv boot-kali.tmp $TARGET_PATH && chmod +x $TARGET_PATH"

    echo " "
    echo " [*] Installation successful !!!"
    echo " "
    echo "> Run 'boot-kali' anywhere to start Kali Chroot."
    echo " "
    echo " [*] Termux needs to be restarted to work properly,"
    echo "     Please restart !"
    echo " "
    read -p "Press [Enter] to exit..."
    exit
}

############ Main #############

banner_boot_nethunter
check_update
setup_nh_files
install_boot_nethunter
clean_temp
