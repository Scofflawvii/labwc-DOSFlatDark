#!/usr/bin/env bash

set -euo pipefail

theme_name="DOSFlat-Dark"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
theme_source="${repo_root}/themes/${theme_name}"
theme_target_root="${XDG_DATA_HOME:-$HOME/.local/share}/themes"
theme_target="${theme_target_root}/${theme_name}"
qt5_dir="${XDG_CONFIG_HOME:-$HOME/.config}/qt5ct"
qt6_dir="${XDG_CONFIG_HOME:-$HOME/.config}/qt6ct"
qt5_qss_target="${qt5_dir}/qss/dosflat-dark.qss"
qt6_qss_target="${qt6_dir}/qss/dosflat-dark.qss"
gtk3_settings="${XDG_CONFIG_HOME:-$HOME/.config}/gtk-3.0/settings.ini"
gtk4_settings="${XDG_CONFIG_HOME:-$HOME/.config}/gtk-4.0/settings.ini"
fuzzel_dir="${XDG_CONFIG_HOME:-$HOME/.config}/fuzzel"
fuzzel_config="${fuzzel_dir}/fuzzel.ini"
foot_dir="${XDG_CONFIG_HOME:-$HOME/.config}/foot"
foot_config="${foot_dir}/foot.ini"
labwc_dir="${XDG_CONFIG_HOME:-$HOME/.config}/labwc"
labwc_rc="${labwc_dir}/rc.xml"
labwc_environment="${labwc_dir}/environment"
labwc_autostart="${labwc_dir}/autostart"
configure_qt=0
configure_gtk=0
configure_labwc=0
configure_qt6_session=0
configure_fuzzel=0
configure_foot=0

labwc_theme_block=$(cat <<'EOF'
  <theme>
    <name>DOSFlat-Dark</name>
    <icon>hicolor</icon>
    <titlebar>
      <layout>menu:iconify,max,close</layout>
      <showTitle>yes</showTitle>
    </titlebar>
    <cornerRadius>0</cornerRadius>
    <keepBorder>yes</keepBorder>
    <dropShadows>no</dropShadows>
    <font place="ActiveWindow">
      <name>Terminus</name>
      <size>10</size>
    </font>
    <font place="InactiveWindow">
      <name>Terminus</name>
      <size>10</size>
    </font>
    <font place="MenuItem">
      <name>Terminus</name>
      <size>10</size>
    </font>
    <font place="MenuHeader">
      <name>Terminus</name>
      <size>10</size>
    </font>
    <font place="OnScreenDisplay">
      <name>Terminus</name>
      <size>10</size>
    </font>
  </theme>
EOF
)

backup_file() {
    local path="$1"

    if [[ -f "$path" ]]; then
        cp -f "$path" "${path}.bak.$(date +%Y%m%d%H%M%S)"
    fi
}

write_qt_config() {
    local template_path="$1"
    local target_path="$2"
    local qss_path="$3"

    backup_file "$target_path"
    sed "s|@QSS_PATH@|${qss_path}|g" "$template_path" > "$target_path"
}

  install_config_file() {
    local source_path="$1"
    local target_path="$2"

    mkdir -p "$(dirname "$target_path")"
    backup_file "$target_path"
    cp -f "$source_path" "$target_path"
  }

  set_ini_value() {
    local file="$1"
    local section="$2"
    local key="$3"
    local value="$4"
    local temp_file

    mkdir -p "$(dirname "$file")"

    if [[ ! -f "$file" ]]; then
      printf '[%s]\n%s=%s\n' "$section" "$key" "$value" > "$file"
      return
    fi

    temp_file="$(mktemp)"
    awk -v section="$section" -v key="$key" -v value="$value" '
      BEGIN {
        in_section = 0
        section_found = 0
        key_written = 0
      }

      /^\[/ {
        if (in_section && !key_written) {
          print key "=" value
          key_written = 1
        }

        in_section = ($0 == "[" section "]")
        if (in_section) {
          section_found = 1
        }
      }

      {
        if (in_section && $0 ~ ("^" key "=")) {
          if (!key_written) {
            print key "=" value
            key_written = 1
          }
          next
        }

        print
      }

      END {
        if (!section_found) {
          print "[" section "]"
          print key "=" value
        } else if (in_section && !key_written) {
          print key "=" value
        }
      }
    ' "$file" > "$temp_file"

    mv "$temp_file" "$file"
  }

  configure_gtk_settings() {
    backup_file "$gtk3_settings"
    set_ini_value "$gtk3_settings" "Settings" "gtk-theme-name" "$theme_name"
    set_ini_value "$gtk3_settings" "Settings" "gtk-font-name" "Terminus 10"
    set_ini_value "$gtk3_settings" "Settings" "gtk-application-prefer-dark-theme" "1"
    set_ini_value "$gtk3_settings" "Settings" "gtk-button-images" "1"
    set_ini_value "$gtk3_settings" "Settings" "gtk-menu-images" "1"

    backup_file "$gtk4_settings"
    set_ini_value "$gtk4_settings" "Settings" "gtk-theme-name" "$theme_name"
    set_ini_value "$gtk4_settings" "Settings" "gtk-font-name" "Terminus 10"
    set_ini_value "$gtk4_settings" "Settings" "gtk-application-prefer-dark-theme" "1"
  }

  configure_qt6_session_env() {
    backup_file "$labwc_environment"
    set_ini_value "$labwc_environment" "__flat__" "QT_QPA_PLATFORMTHEME" "qt6ct"
    set_ini_value "$labwc_environment" "__flat__" "QT_STYLE_OVERRIDE" ""

    perl -0pi -e 's/^\[__flat__\]\n//m' "$labwc_environment"

    if [[ -f "$labwc_autostart" ]]; then
      backup_file "$labwc_autostart"

      if ! grep -q 'QT_QPA_PLATFORMTHEME' "$labwc_autostart"; then
        perl -0pi -e 's/(dbus-update-activation-environment --systemd \\\n\s*DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE)/$1 \\\n            QT_QPA_PLATFORMTHEME QT_STYLE_OVERRIDE/s' "$labwc_autostart"

        perl -0pi -e 's/(systemctl --user import-environment \\\n\s*DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE)/$1 \\\n        QT_QPA_PLATFORMTHEME QT_STYLE_OVERRIDE/s' "$labwc_autostart"
      fi
    fi
  }

  configure_labwc_rc() {
    mkdir -p "$labwc_dir"

    if [[ ! -f "$labwc_rc" ]]; then
      cp -f "${repo_root}/examples/labwc/rc.xml" "$labwc_rc"
      return
    fi

    backup_file "$labwc_rc"

    if grep -q '<theme>' "$labwc_rc"; then
      perl -0pi -e 's#\s*<theme>.*?</theme>\s*##sm' "$labwc_rc"
    fi

    if grep -q '</labwc_config>' "$labwc_rc"; then
      LABWC_THEME_BLOCK="$labwc_theme_block" perl -0pi -e 's#</labwc_config>#$ENV{LABWC_THEME_BLOCK}\n</labwc_config>#s' "$labwc_rc"
    else
      printf '\n%s\n' "$labwc_theme_block" >> "$labwc_rc"
    fi
  }

  configure_fuzzel_ini() {
    install_config_file "${repo_root}/dotfiles/fuzzel/fuzzel.ini" "$fuzzel_config"
  }

  configure_foot_ini() {
    install_config_file "${repo_root}/dotfiles/foot/foot.ini" "$foot_config"
  }

for arg in "$@"; do
    case "$arg" in
        --configure-qt)
            configure_qt=1
            ;;
    --configure-gtk)
      configure_gtk=1
      ;;
    --configure-labwc)
      configure_labwc=1
      ;;
    --configure-qt6-session)
      configure_qt6_session=1
      ;;
    --configure-fuzzel)
      configure_fuzzel=1
      ;;
    --configure-foot)
      configure_foot=1
      ;;
    --configure-all)
      configure_qt=1
      configure_gtk=1
      configure_labwc=1
      configure_qt6_session=1
      configure_fuzzel=1
      configure_foot=1
      ;;
        *)
            printf 'Unknown option: %s\n' "$arg" >&2
            exit 1
            ;;
    esac
done

mkdir -p "$theme_target_root"
mkdir -p "$theme_target"
cp -a "${theme_source}/." "$theme_target/"

mkdir -p "${qt5_dir}/qss" "${qt6_dir}/qss"
cp -f "${repo_root}/qt/dosflat-dark.qss" "$qt5_qss_target"
cp -f "${repo_root}/qt/dosflat-dark.qss" "$qt6_qss_target"

if [[ "$configure_qt" -eq 1 ]]; then
    mkdir -p "$qt5_dir" "$qt6_dir"
    write_qt_config "${repo_root}/qt/qt5ct.conf.template" "${qt5_dir}/qt5ct.conf" "$qt5_qss_target"
    write_qt_config "${repo_root}/qt/qt6ct.conf.template" "${qt6_dir}/qt6ct.conf" "$qt6_qss_target"
fi

if [[ "$configure_gtk" -eq 1 ]]; then
  configure_gtk_settings
fi

if [[ "$configure_labwc" -eq 1 ]]; then
  configure_labwc_rc
fi

if [[ "$configure_qt6_session" -eq 1 ]]; then
  configure_qt6_session_env
fi

if [[ "$configure_fuzzel" -eq 1 ]]; then
  configure_fuzzel_ini
fi

if [[ "$configure_foot" -eq 1 ]]; then
  configure_foot_ini
fi

cat <<EOF
Installed ${theme_name} to:
  ${theme_target}

Installed Qt stylesheet to:
  ${qt5_qss_target}
  ${qt6_qss_target}

Configured:
  Qt stylesheet files: yes
  qt5ct.conf / qt6ct.conf: $([[ "$configure_qt" -eq 1 ]] && printf yes || printf no)
  GTK settings.ini: $([[ "$configure_gtk" -eq 1 ]] && printf yes || printf no)
  Labwc rc.xml theme block: $([[ "$configure_labwc" -eq 1 ]] && printf yes || printf no)
  Labwc qt6ct session env: $([[ "$configure_qt6_session" -eq 1 ]] && printf yes || printf no)
  fuzzel.ini: $([[ "$configure_fuzzel" -eq 1 ]] && printf yes || printf no)
  foot.ini: $([[ "$configure_foot" -eq 1 ]] && printf yes || printf no)
EOF

if [[ "$configure_qt" -eq 0 || "$configure_gtk" -eq 0 || "$configure_labwc" -eq 0 || "$configure_qt6_session" -eq 0 || "$configure_fuzzel" -eq 0 || "$configure_foot" -eq 0 ]]; then
    cat <<EOF
Remaining optional automation:
  ./scripts/install.sh --configure-qt
  ./scripts/install.sh --configure-gtk
  ./scripts/install.sh --configure-labwc
  ./scripts/install.sh --configure-qt6-session
  ./scripts/install.sh --configure-fuzzel
  ./scripts/install.sh --configure-foot
  ./scripts/install.sh --configure-all
EOF
fi

cat <<EOF

Session note:
  qt6ct is configured through ${labwc_environment} when --configure-qt6-session is used.
  Reload Labwc or log in again for session environment changes to take effect.
EOF