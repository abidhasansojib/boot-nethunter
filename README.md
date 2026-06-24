# Boot Nethunter

Boots the **Kali Chroot (Nethunter-Rooted)** environment directly inside **Termux**, giving you a fully functional rooted Kali interface with Termux’s flexibility and customizability.This doesn't install the chroot you have to flash nethunter flashable zip using root manager and then open nethunter app then you can do this setup to completely overcome dependency on Nethunter apps

> 🧩 **Rooted Android ONLY**

# Installation 

   ```bash
   pkg install git && git clone https://github.com/abidhasansojib/boot-nethunter.git && cd boot-nethunter && chmod +x install_boot-kali.sh && ./install_boot-kali.sh
   ```
# Fix tmp directory error

  ```bash
   echo 'export TMPDIR=/tmp' >> ~/.zshrc
   source ~/.zshrc
```

## Usage

Run `boot-kali` anywhere inside Termux to start the **Kali chroot** environment.Or you can add the command in bash.bashrc to make it automatic exicute while opening a new tab.For that run this command below

```bash
rm /data/data/com.termux/files/usr/etc/motd && echo "boot-kali" | tee -a /data/data/com.termux/files/usr/etc/bash.bashrc
```


# Additional Info

## Sound Fix

To start audio server user this command in nethunter terminal

```bash
audio start
```
and use this app to get sound output no need Nethunter app.[Download App](https://drive.google.com/file/d/1fXFMu-oTDUM-u4nD403raVjoM8IGYDJq/view?usp=drivesdk)


## Keyboard Fix

If keyboard is working but giving some problem like ^M or something else run this in terminal

```bash
stty sane
```



