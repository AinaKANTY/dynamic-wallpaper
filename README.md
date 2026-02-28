<p align="center">
  <img src="https://raw.githubusercontent.com/adi1090x/files/master/dynamic-wallpaper/logo.png">
</p>
<p align="center">
  <img src="https://img.shields.io/badge/Maintained%3F-Yes-green?style=for-the-badge">
  <img src="https://img.shields.io/github/license/Philippien-AT99/dynamic-wallpaper?style=for-the-badge">
  <img src="https://img.shields.io/github/stars/Philippien-AT99/dynamic-wallpaper?style=for-the-badge">
</p>

<p align="center">A simple <code>bash</code> script to set wallpapers according to current time, supporting multiple desktop environments and window managers.</p>

## Testing
This script has been tested on **Hyprland/Arch**. 
If you use another environment, please report your experience by opening an issue.

![gif](https://raw.githubusercontent.com/adi1090x/files/master/dynamic-wallpaper/main.gif) 

### Overview

- **Wallpaper setter**: Automatically detected based on your environment (`swww`, `hyprpaper`, `swaybg`, `hyprctl`, `gsettings`, `plasma-apply-wallpaperimage`, `xfconf-query`)
- **Multi-environment**: Automatically detects and supports Hyprland, Sway, GNOME, KDE, XFCE and more.
- **Dynamic Theming**: Supports **Matugen** and **Pywal** for automatic color scheme generation (optional).
- **Format Support**: Automatically detects `.jpg`, `.png`, `.webp`, and `.gif`.
- **Scheduler**: Compatible with **Systemd Timers** and **Cronie**.

### Dependencies

Install these programs before using `dwall`:
- **`systemd`** or **`cronie`**: For the hourly timer (recommended).
- **`matugen`**: For Material You dynamic colors (optional).
- **`pywal`**: For dynamic color schemes (optional).

### Installation

1. **Clone and install**:
```bash
$ git clone https://github.com/Philippien-AT99/dynamic-wallpaper.git
$ cd dynamic-wallpaper
$ chmod +x install.sh
$ ./install.sh
```

### Automation (Systemd Timer)

This version uses **Systemd Timers** for better integration with Wayland.

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

[Install]
WantedBy=timers.target
```

3. **Enable**:
```ini
systemctl --user enable --now dwall@<style>.timer
# exemple :
systemctl --user enable --now dwall@beach.timer
```

### Previews

|Aurora|Beach|Bitday|Chihuahuan|
|--|--|--|--|
|![gif](https://raw.githubusercontent.com/adi1090x/files/master/dynamic-wallpaper/aurora.gif)|![gif](https://raw.githubusercontent.com/adi1090x/files/master/dynamic-wallpaper/beach.gif)|![gif](https://raw.githubusercontent.com/adi1090x/files/master/dynamic-wallpaper/bitday.gif)|![gif](https://raw.githubusercontent.com/adi1090x/files/master/dynamic-wallpaper/chihuahuan.gif)|

|Cliffs|Colony|Desert|Earth|
|--|--|--|--|
|![gif](https://raw.githubusercontent.com/adi1090x/files/master/dynamic-wallpaper/cliffs.gif)|![gif](https://raw.githubusercontent.com/adi1090x/files/master/dynamic-wallpaper/colony.gif)|![gif](https://raw.githubusercontent.com/adi1090x/files/master/dynamic-wallpaper/desert.gif)|![gif](https://raw.githubusercontent.com/adi1090x/files/master/dynamic-wallpaper/earth.gif)|

|Exodus|Factory|Forest|Gradient|
|--|--|--|--|
|![gif](https://raw.githubusercontent.com/adi1090x/files/master/dynamic-wallpaper/exodus.gif)|![gif](https://raw.githubusercontent.com/adi1090x/files/master/dynamic-wallpaper/factory.gif)|![gif](https://raw.githubusercontent.com/adi1090x/files/master/dynamic-wallpaper/forest.gif)|![gif](https://raw.githubusercontent.com/adi1090x/files/master/dynamic-wallpaper/gradient.gif)|

|Home|Island|Lake|Lakeside|
|--|--|--|--|
|![gif](https://raw.githubusercontent.com/adi1090x/files/master/dynamic-wallpaper/home.gif)|![gif](https://raw.githubusercontent.com/adi1090x/files/master/dynamic-wallpaper/island.gif)|![gif](https://raw.githubusercontent.com/adi1090x/files/master/dynamic-wallpaper/lake.gif)|![gif](https://raw.githubusercontent.com/adi1090x/files/master/dynamic-wallpaper/lakeside.gif)|

|Market|Mojave|Moon|Mountains|
|--|--|--|--|
|![gif](https://raw.githubusercontent.com/adi1090x/files/master/dynamic-wallpaper/market.gif)|![gif](https://raw.githubusercontent.com/adi1090x/files/master/dynamic-wallpaper/mojave.gif)|![gif](https://raw.githubusercontent.com/adi1090x/files/master/dynamic-wallpaper/moon.gif)|![gif](https://raw.githubusercontent.com/adi1090x/files/master/dynamic-wallpaper/mountains.gif)|

|Room|Sahara|Street|Tokyo|
|--|--|--|--|
|![gif](https://raw.githubusercontent.com/adi1090x/files/master/dynamic-wallpaper/room.gif)|![gif](https://raw.githubusercontent.com/adi1090x/files/master/dynamic-wallpaper/sahara.gif)|![gif](https://raw.githubusercontent.com/adi1090x/files/master/dynamic-wallpaper/street.gif)|![gif](https://raw.githubusercontent.com/adi1090x/files/master/dynamic-wallpaper/tokyo.gif)|

 ### Integration with Matugen
 
 To make your window borders and UI match the wallpaper automatically with **Matugen**:

1. **Update your Hyprland config**: Add this line to your `~/.config/hypr/hyprland.conf`:
```ini
source = ~/.config/hypr/colors.conf
```

2. **Configure Matugen output**: Create `~/.config/matugen/config.toml`:
```ini
[config.outputs.hyprland]
path = "~/.config/hypr/colors.conf"
template = "hyprland.desktop"
```

3. **Use the variables:**
```ini
general {
    col.active_border = $primary
    col.inactive_border = $surface_variant
}
```

### How to add own wallpapers

+ Download a wallpaper set you like.
+ Rename the wallpapers (must be **jpg/png**) to `0-23`. If you don't have enough images, symlink them.
+ Make a directory in `/usr/share/dynamic-wallpaper/images` and copy your wallpapers in that. 
+ Run the program, select the style and apply it.

**`Tips`**
- You can use `dwall` to change between your favorite wallpapers every hour.
- You can use `dwall` as picture slide, which can set your favorite photos as wallpaper every hour or every 15 minutes. Just create an appropriate timer.

### Use HEIC Images

You may also want to use wallpapers from [Dynamic Wallpaper Club](https://dynamicwallpaper.club/). To do so, you need to convert `.heic` image file to either png or jpg format. Download a `.heic` wallpaper file you like and follow the steps below to convert images.

- First install `heif-convert` on your system - 
```bash
# On Archlinux
$ sudo pacman -S libheif
# or
$ yay -S libheif
```

- Move your `.heic` file in a directory and run following command to convert images - 
```bash
# change to directory
$ cd Downloads/heic_images

# convert to jpg images
$ for file in *.heic; do heif-convert $file ${file/%.heic/.jpg}; done
```

- Now, you have the images, just follow the [above](https://github.com/adi1090x/dynamic-wallpaper#How-to-add-own-wallpapers) steps to use these wallpapers with `dwall`.

**More Wallpapers :** I've also created a few more wallpaper sets, which are not added to this repository because of their big size. You can download these wallpapers set from here - 
<p align="center">
  <a href="https://github.com/adi1090x/files/tree/master/dynamic-wallpaper/wallpapers"><img alt="undefined" src="https://img.shields.io/badge/Download-Here-blue?style=for-the-badge&logo=github"></a>
</p>

**`Available Sets`** : `Catalina`, `London`, `Maldives`, `Mojave HD`, `Mount Fuji`, `Seoul`, and more...

#### Roadmap (TODO)

**Wayland (Priority)**
- [x] **Hyprland**
- [x] **Sway**
- [ ] **Cosmic Desktop**
- [ ] **River / Wayfire**

**X11/Mixed**
- [x] **XFCE**
- [x] **KDE Plasma**
- [x] **GNOME**
- [ ] **LXQt / Cinnamon**

### Credits
- **Original Author**: [Aditya Shakya (@adi1090x)](https://github.com/adi1090x).
- **Optimization**: Forked for modern sessions by [Aina KANTY (@ainaKANTY)](https://github.com/AinaKANTY).
- **License**: Distributed under the **GPL-3.0 License**.