#!/data/data/com.termux/files/usr/bin/bash
# Code Begins here ->

red='\033[1;31m'
green='\033[1;32m'
yellow='\033[1;33m'
blue='\033[1;34m'
light_cyan='\033[1;96m'
reset='\033[0m'

function print_banner() {
    clear
    printf "${blue}##################################################\n"
    printf "${blue}##                                              ##\n"
    printf "${blue}##  88      a8P         db        88        88  ##\n"
    printf "${blue}##  88    .88'         d88b       88        88  ##\n"
    printf "${blue}##  88   88'          d8''8b      88        88  ##\n"
    printf "${blue}##  88 d88           d8'  '8b     88        88  ##\n"
    printf "${blue}##  8888'88.        d8YaaaaY8b    88        88  ##\n"
    printf "${blue}##  88P   Y8b      d8''''''''8b   88        88  ##\n"
    printf "${blue}##  88     '88.   d8'        '8b  88        88  ##\n"
    printf "${blue}##  88       Y8b d8'          '8b 888888888 88  ##\n"
    printf "${blue}##                                              ##\n"
    printf "${blue}####  ############# NetHunter ####################${reset}\n\n"
}

function check_update()
{
    # Check if we are running in Termux
    if [ ! -d ~/.termux ]; then
        clear
        echo " "
        echo -e "${red}[!] You may be on an older version of Termux !!!${reset}"
        echo -e "${yellow}    Updating Termux....${reset}"
        sleep 2
        pkg update -y
        clear
        echo -e "${yellow}[!] Upgrading packages...${reset}"
        sleep 2
        pkg upgrade -y
        pkg install wget tar xz-utils -y
        clear
        echo " "
        echo -e "${red}[*] You need to completely restart Termux,${reset}"
        echo -e "${red}    And start the installation again !!!${reset}"
        echo " "
        exit
    else
        echo -e "${light_cyan}[*] Checking and installing package dependencies...${reset}"
        pkg install wget tar xz-utils -y
    fi
}

# 1. Architecture detection
ARCH="$([ "$(uname -m)" = "aarch64" ] && echo "arm64" || echo "armhf")"
MNT="/data/local/nhsystem/kali-${ARCH}"

# 2. Check for existing chroot
function check_existing_chroot()
{
    if su -c "test -d $MNT"; then
        echo -e "${yellow}⚠️ An existing chroot was found at: $MNT${reset}"
        read -p "Do you want to delete it and reinstall Kali chroot? (y/n): " choice
        choice=$(echo "$choice" | tr '[:upper:]' '[:lower:]')
        if [[ "$choice" != "y" && "$choice" != "yes" ]]; then
            echo -e "${red}[-] Closing installation script.${reset}"
            exit 0
        else
            echo -e "${yellow}[*] Cleaning up and removing old chroot environment...${reset}"
            # Execute the specified removal command
            export MNT="/data/local/nhsystem/kali-$([ "$(uname -m)" = "aarch64" ] && echo "arm64" || echo "armhf")"
            su -c "pids=\$(lsof | grep '$MNT' | awk '{print \$2}' | uniq) && [ -n '\$pids' ] && kill -9 \$pids; for m in dev/pts dev/shm dev proc sys system sdcard; do umount -l $MNT/\$m 2>/dev/null; done; rm -rf /data/local/nhsystem"
            echo -e "${green}✓ Old chroot removed successfully.${reset}"
        fi
    fi
}

# 3. Choose version
function choose_rootfs_version()
{
    echo -e "${blue}=========================================${reset}"
    echo -e "${light_cyan} Choose Kali NetHunter Rootfs version:${reset}"
    echo -e "${green} 1) Full${reset} (Recommended, complete suite of tools)"
    echo -e "${green} 2) Minimal${reset} (Lightweight command-line only)"
    echo -e "${blue}=========================================${reset}"
    read -p "Enter choice [1 or 2]: " choice
    if [ "$choice" = "2" ]; then
        ROOTFS_URL="https://kali.download/nethunter-images/current/rootfs/kali-nethunter-rootfs-minimal-${ARCH}.tar.xz"
        echo -e "${green}[*] Selected Minimal rootfs.${reset}"
    else
        ROOTFS_URL="https://kali.download/nethunter-images/current/rootfs/kali-nethunter-rootfs-full-${ARCH}.tar.xz"
        echo -e "${green}[*] Selected Full rootfs.${reset}"
    fi
}

# 4. Download and extract rootfs
function download_and_extract()
{
    echo -e "${light_cyan}[*] Downloading Kali NetHunter rootfs...${reset}"
    echo -e "${light_cyan}URL: $ROOTFS_URL${reset}"

    # Check if local file already exists to save download time/bandwidth
    if [ -f "nethunter-rootfs.tar.xz" ]; then
        echo -e "${yellow}Found existing nethunter-rootfs.tar.xz in current directory.${reset}"
        read -p "Do you want to use the existing archive instead of downloading again? (y/n): " use_existing
        use_existing=$(echo "$use_existing" | tr '[:upper:]' '[:lower:]')
        if [[ "$use_existing" != "y" && "$use_existing" != "yes" ]]; then
            echo -e "${light_cyan}[*] Downloading fresh archive...${reset}"
            rm -f nethunter-rootfs.tar.xz
            wget -O nethunter-rootfs.tar.xz --show-progress "$ROOTFS_URL"
        else
            echo -e "${green}[*] Using existing archive.${reset}"
        fi
    else
        wget -O nethunter-rootfs.tar.xz --show-progress "$ROOTFS_URL"
    fi

    if [ ! -f nethunter-rootfs.tar.xz ]; then
        echo -e "${red}❌ Error: nethunter-rootfs.tar.xz not found!${reset}"
        exit 1
    fi

    echo -e "${light_cyan}[*] Creating target directory /data/local/nhsystem...${reset}"
    su -c "mkdir -p /data/local/nhsystem"

    echo -e "${light_cyan}[*] Extracting Kali rootfs (this may take a few minutes)...${reset}"
    su -c "PATH=$PATH LD_LIBRARY_PATH=$LD_LIBRARY_PATH tar -xJf nethunter-rootfs.tar.xz -C /data/local/nhsystem"
    if [ $? -ne 0 ]; then
        echo -e "${red}❌ Error: Failed to extract rootfs.${reset}"
        exit 1
    fi
    echo -e "${green}✓ Extraction completed successfully.${reset}"

    echo -e "${light_cyan}[*] Creating kalifs symlink...${reset}"
    su -c "ln -sf /data/local/nhsystem/kali-${ARCH} /data/local/nhsystem/kalifs"
}

# 5. Setup NetHunter boot scripts and binaries
function setup_boot_scripts()
{
    echo -e "${light_cyan}[*] Setting up NetHunter boot scripts under /data/local/nhsystem/boot_scripts...${reset}"
    su -c "mkdir -p /data/local/nhsystem/boot_scripts"

    # Write bootkali_log
    cat << 'EOF' > bootkali_log.tmp
#!/system/bin/sh
bklog() {
    echo "$@"
    log -t "bklog" "$(basename $0) -> $*"
}
EOF
    su -c "cp bootkali_log.tmp /data/local/nhsystem/boot_scripts/bootkali_log"
    rm -f bootkali_log.tmp

    # Write bootkali_env
    cat << 'EOF' > bootkali_env.tmp
#!/system/bin/sh
unset LD_PRELOAD
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:"$PATH"
NHSYSTEM_PATH=/data/local/nhsystem
CHROOT_EXEC=/usr/bin/sudo
MNT=$(readlink -e $NHSYSTEM_PATH/kalifs)
EOF
    su -c "cp bootkali_env.tmp /data/local/nhsystem/boot_scripts/bootkali_env"
    rm -f bootkali_env.tmp

    # Write bootkali_init
    cat << 'EOF' > bootkali_init.tmp
#!/system/bin/sh
SCRIPT_PATH=$(readlink -f "$0")
. "${SCRIPT_PATH%/*}"/bootkali_log
. "${SCRIPT_PATH%/*}"/bootkali_env

mount_fs() {
    local src="$1"
    local dest="$2"
    local type="$3"
    local opts="$4"

    if ! grep -q " $dest " /proc/mounts; then
        mkdir -p "$dest"
        if [ -n "$type" ] && [ -n "$opts" ]; then
            mount -t "$type" -o "$opts" "$src" "$dest"
        elif [ -n "$type" ]; then
            mount -t "$type" "$src" "$dest"
        elif [ -n "$opts" ]; then
            mount -o "$opts" "$src" "$dest"
        else
            mount "$src" "$dest"
        fi
    fi
}

if [ ! -d "$MNT" ]; then
    bklog "[-] Error: $MNT does not exist!"
    exit 2
fi

mount -o remount,suid /data
chmod +s "$MNT$CHROOT_EXEC" 2>/dev/null || true

if [ ! -e "$MNT/dev/fd" ] || [ ! -e "$MNT/dev/stdin" ] || [ ! -e "$MNT/dev/stdout" ] || [ ! -e "$MNT/dev/stderr" ]; then
    ln -sf /proc/self/fd "$MNT/dev/fd"
    ln -sf /proc/self/fd/0 "$MNT/dev/stdin"
    ln -sf /proc/self/fd/1 "$MNT/dev/stdout"
    ln -sf /proc/self/fd/2 "$MNT/dev/stderr"
fi

mount_fs /dev "$MNT/dev" "" "bind"
mount_fs devpts "$MNT/dev/pts" "devpts" ""
mount_fs tmpfs "$MNT/dev/shm" "tmpfs" "rw,nosuid,nodev,mode=1777"
mount_fs proc "$MNT/proc" "proc" ""
mount_fs sysfs "$MNT/sys" "sysfs" ""
mount_fs /system "$MNT/system" "" "bind"
mount_fs /dev/binderfs "$MNT/dev/binderfs" "" "bind,ro" 2>/dev/null || true

if [ -d "$MNT/sdcard" ] || mkdir -p "$MNT/sdcard"; then
    if ! grep -q " $MNT/sdcard " /proc/mounts; then
        for sdcard in /storage/emulated/0 /sdcard; do
            if [ -d "$sdcard" ]; then
                mount -o bind "$sdcard" "$MNT/sdcard" && break
            fi
        done
    fi
fi

sysctl -w net.ipv4.ip_forward=1 >/dev/null 2>&1
echo "127.0.0.1 localhost kali" > "$MNT/etc/hosts"
echo "::1 localhost ip6-localhost ip6-loopback" >> "$MNT/etc/hosts"
echo "kali" > /proc/sys/kernel/hostname 2>/dev/null || true
EOF
    su -c "cp bootkali_init.tmp /data/local/nhsystem/boot_scripts/bootkali_init"
    rm -f bootkali_init.tmp

    # Write bootkali_bash
    cat << 'EOF' > bootkali_bash.tmp
#!/system/bin/sh
SCRIPT_PATH=$(readlink -f "$0")
. "${SCRIPT_PATH%/*}"/bootkali_init

[ ! -f "$MNT/root/.hushlogin" ] && touch "$MNT/root/.hushlogin"
[ ! -d "$MNT/root/.ssh" ] && mkdir -p "$MNT/root/.ssh"

clear
if [ -x "$MNT/usr/bin/sudo" ]; then
    chroot "$MNT" /usr/bin/sudo -E PATH="$PATH" su
else
    chroot "$MNT" /bin/su
fi
EOF
    su -c "cp bootkali_bash.tmp /data/local/nhsystem/boot_scripts/bootkali_bash"
    rm -f bootkali_bash.tmp

    # Write bootkali_login
    cat << 'EOF' > bootkali_login.tmp
#!/system/bin/sh
SCRIPT_PATH=$(readlink -f "$0")
. "${SCRIPT_PATH%/*}"/bootkali_init

[ ! -f "$MNT/root/.hushlogin" ] && touch "$MNT/root/.hushlogin"
[ ! -d "$MNT/root/.ssh" ] && mkdir -p "$MNT/root/.ssh"

clear
if [ -x "$MNT/usr/bin/sudo" ]; then
    chroot "$MNT" /usr/bin/sudo -E PATH="$PATH" su -l
else
    chroot "$MNT" /bin/su -l
fi
EOF
    su -c "cp bootkali_login.tmp /data/local/nhsystem/boot_scripts/bootkali_login"
    rm -f bootkali_login.tmp

    # Write killkali
    cat << 'EOF' > killkali.tmp
#!/system/bin/sh
SCRIPT_PATH=$(readlink -f "$0")
. "${SCRIPT_PATH%/*}"/bootkali_log
. "${SCRIPT_PATH%/*}"/bootkali_env

kill_chroot_processes() {
    bklog "[!] Killing processes running in chroot..."
    local pids=$(lsof | grep "$MNT" | awk '{print $2}' | uniq)
    if [ -n "$pids" ]; then
        kill -9 $pids 2>/dev/null
    fi
}

unmount_fs() {
    local dest="$1"
    if grep -q " $dest " /proc/mounts; then
        umount -l "$dest" || umount -f "$dest"
        bklog "[+] Unmounted $dest"
    fi
}

kill_chroot_processes
bklog "[!] Unmounting filesystems..."
unmount_fs "$MNT/dev/pts"
unmount_fs "$MNT/dev/shm"
unmount_fs "$MNT/dev/binderfs"
unmount_fs "$MNT/dev"
unmount_fs "$MNT/proc"
unmount_fs "$MNT/sys"
unmount_fs "$MNT/system"
unmount_fs "$MNT/sdcard"
bklog "[+] All done."
EOF
    su -c "cp killkali.tmp /data/local/nhsystem/boot_scripts/killkali"
    rm -f killkali.tmp

    # Write bootkali
    cat << 'EOF' > bootkali.tmp
#!/system/bin/sh
SCRIPT_PATH=$(readlink -f "$0")
. "${SCRIPT_PATH%/*}"/bootkali_init

if [ $# -eq 0 ]; then
    . "${SCRIPT_PATH%/*}"/bootkali_login
else
    if [ "$1" = "ssh" ] || [ "$1" = "apache" ] || [ "$1" = "openvpn" ] || [ "$1" = "dhcp" ] || [ "$1" = "dnsmasq" ] || [ "$1" = "hostapd" ]; then
        svc="$1"
        if [ "$svc" = "apache" ]; then svc="apache2"; fi
        if [ -x "$MNT/usr/bin/sudo" ]; then
            chroot "$MNT" /usr/bin/sudo -E PATH="$PATH" service "$svc" "$2"
        else
            chroot "$MNT" service "$svc" "$2"
        fi
    elif [ "$1" = "custom_cmd" ]; then
        shift
        if [ -x "$MNT/usr/bin/sudo" ]; then
            chroot "$MNT" /usr/bin/sudo -E PATH="$PATH" "$@"
        else
            chroot "$MNT" "$@"
        fi
    else
        if [ -x "$MNT/usr/bin/sudo" ]; then
            chroot "$MNT" /usr/bin/sudo -E PATH="$PATH" "$@"
        else
            chroot "$MNT" "$@"
        fi
    fi
fi
EOF
    su -c "cp bootkali.tmp /data/local/nhsystem/boot_scripts/bootkali"
    rm -f bootkali.tmp

    # Make all boot scripts and directories searchable and executable
    su -c "chmod 755 /data/local"
    su -c "chmod 755 /data/local/nhsystem"
    su -c "chmod 755 /data/local/nhsystem/boot_scripts"
    su -c "chmod 755 /data/local/nhsystem/boot_scripts/*"
    echo -e "${green}✓ NetHunter boot scripts setup complete.${reset}"
}

# 6. Legacy: Move user's custom scripts to chroot
function setup_nh_files()
{
    local BIN_DIR="/data/local/nhsystem/kali-${ARCH}/bin"
    local ROOT_DIR="/data/local/nhsystem/kali-${ARCH}/root"
    local SCRIPTS_SRC="scripts"

    if [ ! -d "$SCRIPTS_SRC" ]; then
        echo -e "${yellow}⚠️ Warning: '$SCRIPTS_SRC' folder not found in current directory. Skipping legacy script setup.${reset}"
        return 0
    fi

    if [ -f "$SCRIPTS_SRC/kex" ]; then
        echo -e "${light_cyan}[*] Copying 'kex' to $BIN_DIR...${reset}"
        su -c "mkdir -p '$BIN_DIR' && cp '$SCRIPTS_SRC/kex' '$BIN_DIR/' && chmod +x '$BIN_DIR/kex'"
        echo -e "${green}✓ 'kex' moved and made executable.${reset}"
    else
        echo -e "${yellow}⚠️ Warning: 'kex' not found inside '$SCRIPTS_SRC/'${reset}"
    fi

    if [ "$(shopt -s nullglob; echo "$SCRIPTS_SRC"/*)" ]; then
        echo -e "${light_cyan}[*] Copying remaining scripts to $ROOT_DIR...${reset}"
        su -c "mkdir -p '$ROOT_DIR/scripts'"
        for f in "$SCRIPTS_SRC"/*; do
            if [ "$(basename "$f")" != "kex" ]; then
                su -c "cp '$f' '$ROOT_DIR/scripts/' && chmod +x '$ROOT_DIR/scripts/\$(basename \"$f\")'"
            fi
        done
        echo -e "${green}✓ All remaining scripts moved to root and made executable.${reset}"
    else
        echo -e "${yellow}ℹ️ No extra scripts left in '$SCRIPTS_SRC/' to copy.${reset}"
    fi
}

# 7. Setup system permissions, tmp directories and audio support
function apply_chroot_compatibility_fixes()
{
    echo -e "${light_cyan}[*] Applying Android/Termux compatibility fixes inside chroot...${reset}"
    local CHROOT_PATH="/data/local/nhsystem/kali-${ARCH}"

    # 1. Add aid_inet group (GID 3003) and assign _apt user to it for internet permissions under Android
    su -c "env -i PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin TERM=xterm /system/bin/chroot $CHROOT_PATH sh -c '
        GN=\$(getent group 3003 | cut -d: -f1 || true)
        if [ -z \"\$GN\" ]; then
            if getent group aid_inet >/dev/null 2>&1; then
                GN=aid_inet
            else
                groupadd -g 3003 -o aid_inet || true
                GN=aid_inet
            fi
        fi
        if id -u _apt >/dev/null 2>&1; then
            usermod -a -G \"\$GN\" _apt || true
        fi
    '"

    # 2. Comment out pam_keyinit.so inside chroot pam configurations as it causes issues on Android
    su -c "env -i PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin TERM=xterm /system/bin/chroot $CHROOT_PATH sh -c '
        if [ -d /etc/pam.d ]; then
            sed -i \"s/pam_keyinit\\.so/& # disabled on Android/\" /etc/pam.d/* 2>/dev/null || true
        fi
    '"

    # 3. Fix TMPDIR environment variable for zsh/bash configurations to prevent /tmp directory errors
    echo -e "${light_cyan}[*] Configuring TMPDIR=/tmp for bash and zsh shells inside chroot...${reset}"
    su -c "env -i PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin TERM=xterm /system/bin/chroot $CHROOT_PATH sh -c '
        # Global zshrc
        mkdir -p /etc/zsh
        if [ ! -f /etc/zsh/zshrc ] || ! grep -q \"export TMPDIR=/tmp\" /etc/zsh/zshrc; then
            echo \"export TMPDIR=/tmp\" >> /etc/zsh/zshrc
        fi

        # Global bashrc
        if [ ! -f /etc/bash.bashrc ] || ! grep -q \"export TMPDIR=/tmp\" /etc/bash.bashrc; then
            echo \"export TMPDIR=/tmp\" >> /etc/bash.bashrc
        fi

        # User-specific zshrc & bashrc for root and kali users if they exist
        for user_home in /root /home/kali; do
            if [ -d \"\$user_home\" ]; then
                for rcfile in .zshrc .bashrc; do
                    # Create the file if it does not exist, or append if not already present
                    if [ ! -f \"\$user_home/\$rcfile\" ]; then
                        echo \"export TMPDIR=/tmp\" > \"\$user_home/\$rcfile\"
                    elif ! grep -q \"export TMPDIR=/tmp\" \"\$user_home/\$rcfile\"; then
                        echo \"export TMPDIR=/tmp\" >> \"\$user_home/\$rcfile\"
                    fi
                    # Match home folder owner/group
                    owner=\$(stat -c \"%u:%g\" \"\$user_home\" 2>/dev/null || echo \"root:root\")
                    chown \"\$owner\" \"\$user_home/\$rcfile\" 2>/dev/null || true
                    chmod 644 \"\$user_home/\$rcfile\" 2>/dev/null || true
                done
            fi
        done
    '"
}

function setup_permissions_and_audio()
{
    echo -e "${light_cyan}[*] Setting system mount and sudo permissions...${reset}"
    # Remount /data to enable suid execution (needed for chroot sudo)
    su -c "mount -o remount,suid /data"
    su -c "chmod +s /data/local/nhsystem/kali-${ARCH}/usr/bin/sudo"

    # Ensure /tmp and /var/tmp directories exist and have proper sticky permissions (1777)
    su -c "env -i PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin TERM=xterm /system/bin/chroot /data/local/nhsystem/kali-${ARCH} chmod 1777 /tmp /var/tmp 2>/dev/null" || true

    # Create android tmpdir redirector script in /etc/profile.d/
    su -c "env -i PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin TERM=xterm /system/bin/chroot /data/local/nhsystem/kali-${ARCH} mkdir -p /etc/profile.d"
    su -c "env -i PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin TERM=xterm /system/bin/chroot /data/local/nhsystem/kali-${ARCH} sh -c \"echo 'export TMPDIR=/tmp' > /etc/profile.d/99-android-tmpdir.sh\""
    su -c "env -i PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin TERM=xterm /system/bin/chroot /data/local/nhsystem/kali-${ARCH} chmod 644 /etc/profile.d/99-android-tmpdir.sh"

    # Initialize namespaces and mount proc, sys, dev etc.
    echo -e "${light_cyan}[*] Initializing mounts for the chroot environment...${reset}"
    su -c "env -i PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin TERM=xterm /data/local/nhsystem/boot_scripts/bootkali_init"

    # Apply Termux-chroot compatibility fixes
    apply_chroot_compatibility_fixes

    # Install nethunter-utils to get the audio binary /usr/bin/audio
    echo -e "${light_cyan}[*] Installing nethunter-utils inside chroot for audio support...${reset}"
    su -c "env -i PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin TERM=xterm /system/bin/chroot /data/local/nhsystem/kali-${ARCH} apt-get update"
    su -c "env -i PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin TERM=xterm DEBIAN_FRONTEND=noninteractive /system/bin/chroot /data/local/nhsystem/kali-${ARCH} apt-get install -y nethunter-utils"

    # Ensure audio binary has execution permissions
    su -c "env -i PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin TERM=xterm /system/bin/chroot /data/local/nhsystem/kali-${ARCH} chmod +x /usr/bin/audio 2>/dev/null" || true
    echo -e "${green}✓ Permissions and audio configuration complete.${reset}"
}

# 8. Create the Termux-side boot-kali runner script
function install_boot_nethunter()
{
    echo -e "${light_cyan}[*] Installing Termux boot-kali utility...${reset}"
    
    # 1. Create the boot-kali script locally in Termux user space first
    cat << 'EOF' > boot-kali.tmp
#!/data/data/com.termux/files/usr/bin/bash
# This script boots nethunter in termux

if [ "$1" = "--remove" ]; then
    echo -e "\033[1;33m[*] Unmounting and removing Kali NetHunter chroot...\033[0m"
    # Kill any processes running in the chroot and unmount filesystems
    if su -c "test -f /data/local/nhsystem/boot_scripts/killkali"; then
        su -c "env -i PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/data/local/nhsystem/boot_scripts TERM=xterm sh /data/local/nhsystem/boot_scripts/killkali"
    else
        ARCH="$([ "$(uname -m)" = "aarch64" ] && echo "arm64" || echo "armhf")"
        MNT="/data/local/nhsystem/kali-${ARCH}"
        su -c "pids=\$(lsof | grep '$MNT' | awk '{print \$2}' | uniq) && [ -n '\$pids' ] && kill -9 \$pids; for m in dev/pts dev/shm dev/binderfs dev proc sys system sdcard; do umount -l $MNT/\$m 2>/dev/null; done"
    fi
    
    # Remove the chroot directories
    su -c "rm -rf /data/local/nhsystem"
    
    # Remove from Termux auto-boot (bash.bashrc)
    bashrc_path="/data/data/com.termux/files/usr/etc/bash.bashrc"
    if [ -f "$bashrc_path" ]; then
        sed -i '/^boot-kali$/d' "$bashrc_path"
    fi
    
    # Remove the boot-kali command itself
    rm -f "/data/data/com.termux/files/usr/bin/boot-kali"
    
    echo -e "\033[1;32m✓ Kali NetHunter chroot and boot-kali utility successfully removed.\033[0m"
    exit 0
fi

# Construct safe arguments string to pass cleanly through su -c
ARGS=""
for arg in "$@"; do
    # Escape single quotes and wrap in single quotes
    escaped_arg=$(echo "$arg" | sed "s/'/'\\\\''/g")
    ARGS="$ARGS '$escaped_arg'"
done

# Run bootkali using env -i to clear the Termux host environment variables (prevents LD_PRELOAD crashes)
su -c "env -i PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/data/local/nhsystem/boot_scripts TERM=xterm sh /data/local/nhsystem/boot_scripts/bootkali $ARGS"
EOF

    # 2. Move it to the system destination, make it executable
    TARGET_PATH="/data/data/com.termux/files/usr/bin/boot-kali"
    mv boot-kali.tmp "$TARGET_PATH"
    chmod +x "$TARGET_PATH"

    echo " "
    echo -e "${green} [*] Installation successful !!!${reset}"
    echo " "
    echo -e "${light_cyan}> Run 'boot-kali' anywhere in Termux to start Kali Chroot.${reset}"
    echo " "
    echo -e "${yellow} [*] Termux needs to be restarted to work properly,${reset}"
    echo -e "${yellow}     Please restart !${reset}"
    echo " "
    read -p "Press [Enter] to exit..."
    exit
}

setup_kali_boot() {
    local motd_path="/data/data/com.termux/files/usr/etc/motd"
    local bashrc_path="/data/data/com.termux/files/usr/etc/bash.bashrc"

    # Remove the MOTD file if it exists
    if [ -f "$motd_path" ]; then
        rm "$motd_path" && echo "Removed MOTD."
    fi

    # Append 'boot-kali' only if it isn't already in the bash.bashrc
    if ! grep -qxF "boot-kali" "$bashrc_path" 2>/dev/null; then
        echo "boot-kali" | tee -a "$bashrc_path"
        echo "Added 'boot-kali' to bash.bashrc."
    else
        echo "'boot-kali' is already configured in bash.bashrc."
    fi
}


function clean_temp()
{
    echo -e "${light_cyan}[*] Cleaning up temporary files...${reset}"
    
    # Ask the user before deleting the rootfs archive
    if [ -f "nethunter-rootfs.tar.xz" ]; then
        read -p "Do you want to delete the downloaded rootfs archive to free up space? (y/n): " clean_choice
        clean_choice=$(echo "$clean_choice" | tr '[:upper:]' '[:lower:]')
        if [[ "$clean_choice" == "y" || "$clean_choice" == "yes" ]]; then
            rm -f nethunter-rootfs.tar.xz
            echo -e "${green}✓ Rootfs archive removed.${reset}"
        else
            echo -e "${yellow}ℹ️ Rootfs archive kept for future reinstalls.${reset}"
        fi
    fi

    # Clean up wget history file if it exists
    if [ -f ~/.wget-hsts ]; then
        rm -f ~/.wget-hsts
    fi
    
    echo -e "${green}✓ Clean up done.${reset}"
}



############ Main #############

print_banner
check_update
check_existing_chroot
choose_rootfs_version
download_and_extract
setup_boot_scripts
setup_nh_files
setup_kali_boot
setup_permissions_and_audio
clean_temp
install_boot_nethunter
