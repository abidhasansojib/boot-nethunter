# Boot Nethunter

Boots the **Kali Chroot (Nethunter-Rooted)** environment directly inside **Termux**, giving you a fully functional rooted Kali interface with Termux’s flexibility and customizability.

> 🧩 **Rooted Android ONLY**

# Installation 

   ```bash
   pkg install git && git clone https://github.com/abidhasansojib/boot-nethunter.git && cd boot-nethunter && chmod +x install_boot-kali.sh && ./install_boot-kali.sh
   ```

## Usage

Run `boot-kali` anywhere inside Termux to start the **Kali chroot** environment.

## Additional Info

- Installation creates a `bin` folder under `$HOME/.termux/`, which is automatically added to your `PATH`.
- You can drop any binaries or executables into that folder and call them globally from Termux.
