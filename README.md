<p align="center">
  <img src="https://raw.githubusercontent.com/adi1090x/files/master/dynamic-wallpaper/logo.png">
</p>
<p align="center">
  <img src="https://img.shields.io/badge/Maintained%3F-Yes-green?style=for-the-badge">
  <img src="https://img.shields.io/github/license/AinaKANTY/dynamic-wallpaper?style=for-the-badge">
  <img src="https://img.shields.io/github/stars/AinaKANTY/dynamic-wallpaper?style=for-the-badge">
  <img src="https://img.shields.io/badge/Fork%20of-adi1090x%2Fdynamic--wallpaper-orange?style=for-the-badge">
</p>

<p align="center">A simple <code>bash</code> script to set wallpapers according to current time, supporting multiple desktop environments and window managers.</p>

![gif](https://raw.githubusercontent.com/adi1090x/files/master/dynamic-wallpaper/main.gif) 

### Features & Overview

- **Wallpaper setter**: Automatically detected based on your environment.
- **Multi-environment**: Automatically detects and supports your DE/WM (Wayland & X11).
- **Target specific monitors**: Apply a wallpaper to a specific screen using the `-m` or `--monitor` flag (supports Hyprland, Sway, KDE, and XFCE).
- **Random Selection**: Pick a random style from your installed ones using the `-r` or `--random` flag.
- **Manage Styles**: Easily remove an installed style using the `dwall rm <style>` subcommand.
- **Smart Time Fallback**: If an image for the current hour is missing, `dwall` automatically falls back to the previous available hour. You don't need exactly 24 images!
- **Multi-Format Auto-detection**: Seamlessly searches for `.jpg`, `.jpeg`, `.png`, `.webp`, and `.gif` formats simultaneously.
- **Dynamic Theming**: Supports **Matugen** (default) and **Pywal** (via `-p` flag) for automatic color scheme generation.
- **Safety First**: Features a robust `flock` instance locking system to prevent overlapping runs, along with clean exits on system signals.
- **Scheduler**: Compatible with **Systemd Timers** and **Cronie**.

### Supported Environments

#### Wayland
![Hyprland](https://img.shields.io/badge/Hyprland-supported-blue?style=flat-square)
![Sway](https://img.shields.io/badge/Sway-supported-blue?style=flat-square)
![Wayfire](https://img.shields.io/badge/Wayfire-supported-blue?style=flat-square)
![Niri](https://img.shields.io/badge/Niri-supported-blue?style=flat-square)
![Cosmic](https://img.shields.io/badge/Cosmic-supported-blue?style=flat-square)
![River](https://img.shields.io/badge/River-supported-blue?style=flat-square)
![Labwc](https://img.shields.io/badge/Labwc-supported-blue?style=flat-square)
![Wayland](https://img.shields.io/badge/Wayland%20Generic-supported-blue?style=flat-square)

#### X11
![GNOME](https://img.shields.io/badge/GNOME-supported-orange?style=flat-square&logo=gnome)
![KDE](https://img.shields.io/badge/KDE%20Plasma-supported-blue?style=flat-square&logo=kde)
![XFCE](https://img.shields.io/badge/XFCE-supported-lightgrey?style=flat-square)
![MATE](https://img.shields.io/badge/MATE-supported-green?style=flat-square)
![Cinnamon](https://img.shields.io/badge/Cinnamon-supported-red?style=flat-square)
![LXDE](https://img.shields.io/badge/LXDE-supported-yellow?style=flat-square)
![Enlightenment](https://img.shields.io/badge/Enlightenment-supported-lightgrey?style=flat-square)
![X11](https://img.shields.io/badge/X11%20Generic-supported-lightgrey?style=flat-square)

### Color Generation (optional)
![matugen](https://img.shields.io/badge/matugen-supported-8b5cf6?style=flat-square)
![pywal](https://img.shields.io/badge/pywal-supported-8b5cf6?style=flat-square)

The script uses **Matugen** by default if installed. If you prefer to use **Pywal**, you can force it by passing the `-p` or `--pywal` flag.

### Dependencies

- **`systemd`** or **`cronie`**: For the hourly timer.
- **Wallpaper Setters** (install at least one based on your environment if not using a full DE):
  - *Wayland*: `awww`, `hyprpaper`, `swaybg`, or `wbg`. *(Note: `wpaperd` is not supported).*
  - *X11*: `feh`, `nitrogen`, `hsetroot`, or `xwallpaper`.
  - *DEs*: their built-in native tools.
- **`matugen`**: For Material You dynamic colors (optional).
- **`pywal`**: For dynamic color schemes (optional).

### Installation

1. **Clone the repository**:
```bash
git clone https://github.com/AinaKANTY/dynamic-wallpaper.git
cd dynamic-wallpaper
```

2. **Install**
```bash
chmod +x install.sh
./install.sh
```

### Usage Options

```bash
Usage: dwall [OPTION...]
       dwall rm <style>

Options:
   -h, --help            Show help message
   -p, --pywal           Use pywal to set terminal colors instead of matugen
   -s, --style <style>   Name of the style to apply
   -S, --setter <setter> Force a specific wallpaper setter
   -m, --monitor <name>  Target a specific monitor (ex: DP-1, eDP-1)
   -l, --list            List available styles
   -r, --random          Pick a random style
```

### Automation

#### Systemd Timer

1. **Create the service** (`~/.config/systemd/user/dwall@.service`):
```ini
[Unit]
Description=Dynamic Wallpaper

[Service]
ExecStart=/usr/bin/dwall -s %i
```

2. **Create the timer** (`~/.config/systemd/user/dwall.timer`):
```ini
[Unit]
Description=Dynamic Wallpaper Timer

[Timer]
OnCalendar=hourly
Persistent=true
Unit=dwall@lakeside.service

[Install]
WantedBy=timers.target
```

3. **Enable**:
```bash
systemctl --user enable --now dwall.timer
systemctl --user start dwall@<style>.service # replace <style> by yours
```

#### Cronie

1. **Enable and start the cron daemon**:
```bash
# systemd
sudo systemctl enable --now cronie
# runit (Artix/Void)
sudo ln -s /etc/runit/sv/cronie /run/runit/service/
```

2. **Make sure the service is running**:
```bash
systemctl status cronie
```

3. **Get your environment variables**:
```bash
env | grep -E '^(SHELL|DISPLAY|WAYLAND_DISPLAY|XDG_SESSION_TYPE|XDG_CURRENT_DESKTOP|DESKTOP_SESSION|DBUS_SESSION_BUS_ADDRESS|XDG_RUNTIME_DIR|HYPRLAND_INSTANCE_SIGNATURE|SWAYSOCK|NIRI_SOCKET|WAYFIRE_SOCKET|COSMIC_SESSION)='
```

4. **Open crontab and add your values**:
```bash
crontab -e
```

```bash
# Replace <value> and <style> with your own values
# X11
0 * * * * DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus /usr/bin/dwall -s <style>

# Wayland — Hyprland (replaces the value of HYPRLAND_INSTANCE_SIGNATURE with the one obtained in step 3)
0 * * * * XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=wayland-1 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus HYPRLAND_INSTANCE_SIGNATURE=<value> /usr/bin/dwall -s <style>

# Wayland — Sway
0 * * * * XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=wayland-1 SWAYSOCK=<value> /usr/bin/dwall -s <style>
```

5. **Verify** the cron job is registered:
```bash
crontab -l
```

### How to add own wallpapers

1. Download a wallpaper set you like.
2. Rename the wallpapers to match the hours of the day: `0` to `23` (e.g., `0.jpg` for midnight, `12.png` for noon). 
   > **Note:** Thanks to the **Smart Fallback** feature, you don't need exactly 24 images! If you only have images for `6`, `12`, and `18`, the script will automatically keep showing `6.jpg` until noon.
3. Make a new directory in `/usr/share/dynamic-wallpaper/images/` (e.g., `mystyle`) and copy your images into it.
4. Run the program to test: `dwall -s mystyle`.

**`Tips`**
- You can use `dwall` to change between your favorite wallpapers every hour.
- You can use `dwall` as a picture slide, which can set your favorite photos as wallpaper every hour or every 15 minutes. Just create an appropriate timer.

### Use HEIC Images

You may also want to use wallpapers from [Dynamic Wallpaper Club](https://dynamicwallpaper.club/). To do so, you need to convert `.heic` image file to either png or jpg format. Download a `.heic` image and extract it. 

- First install `heif-convert` on your system:
```bash
# Arch/Manjaro
sudo pacman -S libheif
# Debian/Ubuntu
sudo apt install libheif-examples
# RedHat/Fedora
sudo dnf install libheif libheif-tools
```

- Move your `.heic` file in a directory and run following command to convert images.
```bash
# change to directory
cd Downloads/

# convert to jpg images
for file in *.heic; do heif-convert "$file" "${file/%.heic/.jpg}"; done
```

- Now, you have the images, just follow the [above](#how-to-add-own-wallpapers) steps to use these wallpapers with `dwall`.

**More Wallpapers :** The original author also created additional wallpaper sets, which are not added to this repository because of their big size. You can download these wallpapers set from here
<p align="center">
  <a href="https://github.com/adi1090x/files/tree/master/dynamic-wallpaper/wallpapers"><img alt="undefined" src="https://img.shields.io/badge/Download-Here-blue?style=for-the-badge&logo=github"></a>
</p>

### Credits
- **Original Author**: [Aditya Shakya (@adi1090x)](https://github.com/adi1090x).
- **License**: Distributed under the **GPL-3.0 License**.