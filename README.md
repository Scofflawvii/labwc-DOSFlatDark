# DOSFlat Dark

Small Labwc theming project for a dark, flat, VGA-inspired desktop.

The theme is split into three parts:

- `themes/DOSFlat-Dark/labwc/` for Labwc server-side decorations and menus
- `themes/DOSFlat-Dark/gtk-3.0/` and `themes/DOSFlat-Dark/gtk-4.0/` for GTK apps
- `qt/` for qt5ct and qt6ct stylesheet-based Qt theming
- `dotfiles/fuzzel/` and `dotfiles/foot/` for matching launcher and terminal configs

## Visual direction

- Dark blue-black base surfaces
- Flat solid VGA-blue titlebars
- Squared edges everywhere
- Pixel-style titlebar buttons
- Amber selection with green focus accents

## Install

```bash
./scripts/install.sh
```

That installs the theme into `${XDG_DATA_HOME:-$HOME/.local/share}/themes/DOSFlat-Dark` and copies the Qt stylesheet into `~/.config/qt5ct/qss/` and `~/.config/qt6ct/qss/`.

To also generate `qt5ct.conf` and `qt6ct.conf` that point at the installed stylesheet:

```bash
./scripts/install.sh --configure-qt
```

To also update your user GTK and Labwc config files automatically:

```bash
./scripts/install.sh --configure-all
```

Available automation flags:

- `--configure-qt` writes `qt5ct.conf` and `qt6ct.conf`
- `--configure-gtk` writes or updates GTK `settings.ini`
- `--configure-labwc` writes or updates the `<theme>` block in `~/.config/labwc/rc.xml`
- `--configure-qt6-session` sets `QT_QPA_PLATFORMTHEME=qt6ct` in `~/.config/labwc/environment`
- `--configure-fuzzel` installs `~/.config/fuzzel/fuzzel.ini`
- `--configure-foot` installs `~/.config/foot/foot.ini`
- `--configure-all` runs all of the above

## Enable In Labwc

Set your theme name in `~/.config/labwc/rc.xml`:

```xml
<theme>
  <name>DOSFlat-Dark</name>
  <titlebar>
    <layout>menu:iconify,max,close</layout>
    <showTitle>yes</showTitle>
  </titlebar>
  <cornerRadius>0</cornerRadius>
  <dropShadows>no</dropShadows>
</theme>
```

There is also a ready-made example snippet in `examples/labwc/rc.xml`, and `./scripts/install.sh --configure-labwc` can insert or replace the theme block automatically.

For the stronger DOS look, use a bitmap-ish font in your Labwc and toolkit settings. The bundled configs now default to Terminus across Labwc, GTK, Qt, fuzzel, and foot. Good starting points:

- Terminus
- PxPlus IBM VGA 8x16
- Perfect DOS VGA 437
- Fixed

The bundled configs and stylesheets default to Terminus so you have a consistent baseline.

## Enable GTK

The theme installs as a regular GTK theme alongside the Labwc theme data. Use your usual theme switcher, or set:

```ini
[Settings]
gtk-theme-name=DOSFlat-Dark
gtk-application-prefer-dark-theme=1
```

`./scripts/install.sh --configure-gtk` will write those settings for you.
It also writes `gtk-font-name=Terminus 10`.

## Enable Qt

Use `qt5ct` or `qt6ct` with the `Fusion` style. If you ran `./scripts/install.sh --configure-qt`, the config files are already written.

If you prefer setting Qt manually, point the stylesheet list at the installed `dosflat-dark.qss` file in the matching `qt5ct` or `qt6ct` config directory.

You also need the relevant environment variables in your session:

```bash
export QT_QPA_PLATFORMTHEME=qt6ct
export QT_STYLE_OVERRIDE=
```

`./scripts/install.sh --configure-qt6-session` can write that into your Labwc session environment automatically.

## Enable Fuzzel

The repo now includes a matching `fuzzel` config at `dotfiles/fuzzel/fuzzel.ini`.

Install it automatically with:

```bash
./scripts/install.sh --configure-fuzzel
```

That writes `~/.config/fuzzel/fuzzel.ini` with the same DOSFlat-Dark palette and defaults `terminal=foot` so launcher actions land in the matching terminal.

## Enable Foot

The repo also includes a matching `foot` config at `dotfiles/foot/foot.ini`.

Install it automatically with:

```bash
./scripts/install.sh --configure-foot
```

That writes `~/.config/foot/foot.ini` with the same dark VGA-ish palette, square padding, and a bright amber cursor.

## Tuning

If you want to iterate fast, edit these first:

- `themes/DOSFlat-Dark/labwc/themerc`
- `themes/DOSFlat-Dark/gtk-3.0/gtk.css`
- `themes/DOSFlat-Dark/gtk-4.0/gtk.css`
- `qt/dosflat-dark.qss`
- `dotfiles/fuzzel/fuzzel.ini`
- `dotfiles/foot/foot.ini`

If you want an even harsher monochrome DOS look later, the quickest path is:

- reduce the amber usage to only active selections
- make inactive surfaces closer to `#000000` and `#0000aa`
- switch all UI fonts to a bitmap VGA font