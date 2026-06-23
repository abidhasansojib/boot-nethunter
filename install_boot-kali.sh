#! /data/data/com.termux/files/usr/bin/bash
#  CODE Begins here ->

function banner_boot-nethunter()
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
        echo " [!] Your are on older version of Termux !!!"
        echo "     Updating Termux...."
        sleep 4
        apt update
        clear
        echo " [!] if prompted any, hit -> y"
        sleep 5
        apt upgrade -y
        apt install wget -y
        clear
        echo " "
        echo " [*] You need to completly restart the termux, "
        echo "     And start the installation again !!!"
        echo " "
        exit;
    fi
}

setup_nh_files() {
    # Define target directories
    local BIN_DIR="/data/local/nhsystem/kali-arm64/bin"
    local ROOT_DIR="/data/local/nhsystem/kali-arm64/root"
    local SCRIPTS_SRC="scripts"

    # Check if the scripts folder exists
    if [ ! -d "$SCRIPTS_SRC" ]; then
        echo "⚠️ Error: '$SCRIPTS_SRC' folder not found in the current directory."
        return 1
    fi

    # 1. Handle 'kex' from the scripts folder
    if [ -f "$SCRIPTS_SRC/kex" ]; then
        echo "Moving 'kex' to $BIN_DIR..."
        sudo mv "$SCRIPTS_SRC/kex" "$BIN_DIR/" && sudo chmod +x "$BIN_DIR/kex"
        echo "✓ 'kex' moved and made executable."
    else
        echo "⚠️ Warning: 'kex' not found inside '$SCRIPTS_SRC/'"
    fi

    # 2. Move everything else remaining in the scripts folder to root
    # This safely checks if there are any files left in the directory
    if [ "$(shopt -s nullglob; echo "$SCRIPTS_SRC"/*)" ]; then
        echo "Moving remaining scripts to $ROOT_DIR..."
        sudo mv "$SCRIPTS_SRC"/* "$ROOT_DIR/"
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
function install_boot-nethunter()
{
    echo " [*] Installing Boot Nethunter ..."
    echo " "

    su -c 'cp -r /data/data/com.offsec.nethunter/scripts /data/local/'
    echo "#! /data/data/com.termux/files/usr/bin/bash" > /data/data/com.termux/files/usr/bin/boot-kali
    echo "# This scrpit boots nethunter in termux" >> /data/data/com.termux/files/usr/bin/boot-kali
    echo >> ~/.termux/bin/boot-kali
    echo "su -c '" >> ~/.termux/bin/boot-kali
    echo "nethunter_env=\$PATH:/system/sbin" >> /data/data/com.termux/files/usr/bin/boot-kali
    echo "nethunter_env=\$nethunter_env:/product/bin" >> /data/data/com.termux/files/usr/bin/boot-kali
    echo "nethunter_env=\$nethunter_env:/apex/com.android.runtime/bin" >> /data/data/com.termux/files/usr/bin/boot-kali
    echo "nethunter_env=\$nethunter_env:/odm/bin" >> /data/data/com.termux/files/usr/bin/boot-kali
    echo "nethunter_env=\$nethunter_env:/vendor/bin" >> /data/data/com.termux/files/usr/bin/boot-kali
    echo "nethunter_env=\$nethunter_env:/vendor/xbin" >> /data/data/com.termux/files/usr/bin/boot-kali
    echo "nethunter_env=\$nethunter_env:/data/local/scripts" >> /data/data/com.termux/files/usr/bin/boot-kali
    echo "nethunter_env=\$nethunter_env:/data/local/scripts/bin" >> /data/data/com.termux/files/usr/bin/boot-kali
    echo "export PATH=\$nethunter_env; exec bootkali'" >> /data/data/com.termux/files/usr/bin/boot-kali
    echo >> /data/data/com.termux/files/usr/bin/boot-kali
    chmod +x /data/data/com.termux/files/usr/bin/boot-kali
    echo " "
    echo " [*] Installation successful !!!"
    echo " "
    echo "> Run 'boot-kali' anywhere to start Kali Chroot."
    echo " "
    echo " [*] Termux needs to be restarted to work properly,"
    echo "     Please restart !"
    echo " "
    read
    exit
}

############ Main #############

banner_boot-nethunter

check_update
setup_nh_files

install_boot-nethunter

clean_temp

##############################
