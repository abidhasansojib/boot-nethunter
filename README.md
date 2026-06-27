# Boot Nethunter

Boots the **Kali Chroot (Nethunter-Rooted)** environment directly inside **Termux**, giving you a fully functional rooted Kali interface with Termux’s flexibility and customizability.No need to flash Nethunter Zip Module
> 🧩 **Rooted Android ONLY**

# Installation 

   ```bash
   pkg install git && git clone https://github.com/abidhasansojib/boot-nethunter.git && cd boot-nethunter && chmod +x install_boot-kali.sh && ./install_boot-kali.sh
   ```
# Fix tmp directory error
I have added fix in installation scripts but if that doesn't work usung this in kali terminal

  ```bash
   echo 'export TMPDIR=/tmp' >> ~/.zshrc
   source ~/.zshrc
```

## Usage

Run `boot-kali` anywhere inside Termux to start the **Kali chroot** environment.I have added `boot-kali` in termux bash.bashrc file.So when you open a new tab it will automatically boot kali.


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

## Delete Chroot

Use this command in your termux terminal not kali terminal(Use Ctrl+d twice to exit kali terminal) 

```bash
boot-kali --remove
```
