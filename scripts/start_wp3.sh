#!/bin/bash

# 1. Fix terminal input mapping for NetHunter/Android environments
stty sane 2>/dev/null

# Default configuration variables
APIFACE="wlan1"
NETIFACE="wlan0"
DEFAULT_SSID="Free Wifi"
DEFAULT_BSSID="00:11:22:33:44:55"
CHANNEL=1
WLAN0TO1=1

# -----------------------------------------------------------------
# Interactive User Inputs (Fixed Keyboard & Carriage Return Bug)
# -----------------------------------------------------------------
echo "--- NetHunter wifipumpkin3 Setup ---"

# Prompt for SSID
echo -n "Enter SSID Name [Default: $DEFAULT_SSID]: "
read -r input_ssid
input_ssid=$(echo "$input_ssid" | tr -d '\r')
SSID=${input_ssid:-$DEFAULT_SSID}

# Prompt for BSSID
echo -n "Enter BSSID/MAC [Default: $DEFAULT_BSSID]: "
read -r input_bssid
input_bssid=$(echo "$input_bssid" | tr -d '\r')
BSSID=${input_bssid:-$DEFAULT_BSSID}

# Prompt for Template
echo -n "Enter Captive Portal Template (Leave blank for no proxy): "
read -r TEMPLATE
TEMPLATE=$(echo "$TEMPLATE" | tr -d '\r')

echo ""
echo "------------------------------------"
echo "Configured SSID: $SSID"
echo "Configured BSSID: $BSSID"
echo "Configured Template: ${TEMPLATE:-None (No Proxy)}"
echo "------------------------------------"

# -----------------------------------------------------------------
# Dependency & Environment Checks
# -----------------------------------------------------------------
command -v wifipumpkin3 >/dev/null 2>&1 || { echo 'wifipumpkin3 is missing, installing..'; apt update && apt install wifipumpkin3 -y; }
command -v dnschef >/dev/null 2>&1 || { echo 'dnschef is missing, installing..'; apt update && apt install dnschef -y; }

echo "Checking if config folder exists.."
if [[ ! -d /root/.config/wifipumpkin3 ]]; then
  wifipumpkin3 -xpulp 'exit'
fi

echo "Checking default rule number.."
table=""
# Suppressing stderr 2>/dev/null to hide the dynamic Android FIB errors
for t in $(ip rule list | awk -F"lookup" '{print $2}'); do
  DEF=$(ip route show table "$t" 2>/dev/null | grep default | grep "$NETIFACE")
  if [[ -n "$DEF" ]]; then
     table="$t"
     break
  fi
done

if [[ -z "$table" ]]; then
  echo "Warning: Could not automatically determine default routing table. Defaulting to main."
  table="main"
else
  echo "Default rule number is $table"
fi

# -----------------------------------------------------------------
# Interface Clean/Setup (Fixes SIOCADDRT / Network Unreachable)
# -----------------------------------------------------------------
echo "Checking for existing $APIFACE interface.."
if ip link show "$APIFACE" >/dev/null 2>&1; then
  echo "$APIFACE exists, flushing old network states..."
  ip link set dev "$APIFACE" down 2>/dev/null
  ip addr flush dev "$APIFACE" 2>/dev/null
  ip link set dev "$APIFACE" up
else
  if [[ $WLAN0TO1 -eq 1 ]]; then
    if iw list | grep -q '\* AP'; then
      echo "wlan0 supports AP mode, creating AP interface ($APIFACE).."
      iw dev wlan0 interface add "$APIFACE" type __ap
      ip addr flush dev "$APIFACE" 2>/dev/null
      ip link set up dev "$APIFACE"
    else
      echo "Error: wlan0 doesn't support AP mode. Exiting.."
      exit 1
    fi
  fi
fi

# -----------------------------------------------------------------
# Network Routing & Execution
# -----------------------------------------------------------------
echo "Adding iptables rules for internet sharing..."
ip rule add from all lookup main pref 1 2> /dev/null
ip rule add from all iif lo oif "$APIFACE" uidrange 0-0 lookup 97 pref 11000 2> /dev/null
ip rule add from all iif lo oif "$NETIFACE" lookup "$table" pref 17000 2> /dev/null
ip rule add from all iif lo oif "$APIFACE" lookup 97 pref 17000 2> /dev/null
ip rule add from all iif "$APIFACE" lookup "$table" pref 21000 2> /dev/null

# Configure Proxy commands based on template input
if [[ -n "$TEMPLATE" ]]; then
  TemplateCMD="set captiveflask.$TEMPLATE true;"
  CaptiveCMD="set proxy captiveflask true;"
else 
  TemplateCMD=""
  CaptiveCMD="set proxy noproxy;"
fi

echo "Starting dnschef in background..."
dnschef --interface 10.0.0.1 >/dev/null 2>&1 &
DNSCHEF_PID=$!

echo "Starting wifipumpkin3..."
# SSID variable wrapped in escaped double quotes to handle configurations with spaces gracefully
wifipumpkin3 --xpulp "set interface $APIFACE; set interface_net $NETIFACE; set ssid \"$SSID\"; set bssid $BSSID; set channel $CHANNEL; $CaptiveCMD $TemplateCMD start; ap"

# -----------------------------------------------------------------
# Cleanup / Teardown
# -----------------------------------------------------------------
echo "Stopping background processes..."
kill $DNSCHEF_PID 2>/dev/null
pkill -f wifipumpkin3

echo "Restoring iptables rules..."
ip rule del from all lookup main pref 1 2> /dev/null
ip rule del from all iif lo oif "$APIFACE" uidrange 0-0 lookup 97 pref 11000 2> /dev/null
ip rule del from all iif lo oif "$NETIFACE" lookup "$table" pref 17000 2> /dev/null
ip rule del from all iif lo oif "$APIFACE" lookup 97 pref 17000 2> /dev/null
ip rule del from all iif "$APIFACE" lookup "$table" pref 21000 2> /dev/null
stty sane 2>/dev/null
echo "Done."
