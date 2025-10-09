#! /data/data/com.termux/files/usr/bin/bash
########## INFO ############

# This is boot-nethunter installer, you can delete this file safely after installation.

## File Name:    install_bootkali.sh v1.1
# Author:       Aravind Potluri (CIPH3R) <aravindswami135@gmail.com>
# Description:  Installs boot-kali script that can start nethunter's chroot in other 
#               terminal like termux.

## Msg for Devs:
# If you alter the number of lines in boot-kali script please count the final number of
# lines that would be created and update the argument passed to ibar integrity checker in
# install_boot-nethunter() function.

############################
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
    printf "  ${blue}|||||| ${light_cyan}name-is-cipher ${blue}||||||||\n"
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

function check_tbin()
{
    if [ ! -d ~/.termux/bin ]; then
        mkdir ~/.termux/bin
        echo >> ~/.bashrc
        echo "# This PATH is for Termux superuser bin folder" >> ~/.bashrc
        echo "export PATH=\$PATH:/data/data/com.termux/files/home/.termux/bin" >> ~/.bashrc
        echo " [*] Created Termux bin"
        echo " "
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
    echo "#! /data/data/com.termux/files/usr/bin/bash" > ~/.termux/bin/boot-kali
    echo "# This scrpit boots nethunter in termux" >> ~/.termux/bin/boot-kali
    echo >> ~/.termux/bin/boot-kali
    echo "su -c '" >> ~/.termux/bin/boot-kali
    echo "nethunter_env=\$PATH:/system/sbin" >> ~/.termux/bin/boot-kali
    echo "nethunter_env=\$nethunter_env:/product/bin" >> ~/.termux/bin/boot-kali
    echo "nethunter_env=\$nethunter_env:/apex/com.android.runtime/bin" >> ~/.termux/bin/boot-kali
    echo "nethunter_env=\$nethunter_env:/odm/bin" >> ~/.termux/bin/boot-kali
    echo "nethunter_env=\$nethunter_env:/vendor/bin" >> ~/.termux/bin/boot-kali
    echo "nethunter_env=\$nethunter_env:/vendor/xbin" >> ~/.termux/bin/boot-kali
    echo "nethunter_env=\$nethunter_env:/data/local/scripts" >> ~/.termux/bin/boot-kali
    echo "nethunter_env=\$nethunter_env:/data/local/scripts" >> ~/.termux/bin/boot-kali
    echo "nethunter_env=\$nethunter_env:/data/local/scripts/bin" >> ~/.termux/bin/boot-kali
    echo "export PATH=\$nethunter_env; exec bootkali'" >> ~/.termux/bin/boot-kali
    echo >> ~/.termux/bin/boot-kali
    chmod +x ~/.termux/bin/boot-kali
     # Integrity checker, the number argument to ibar is number of lines in boot-kali script.
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

check_tbin

install_boot-nethunter

clean_temp

##############################
