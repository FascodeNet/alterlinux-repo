# Autostart X on the first console. Skipped for root, other ttys, ssh, and
# systems without xorg-xinit installed.
[ -z "$DISPLAY" ] && [ "$(tty)" = /dev/tty1 ] && [ "$(id -u)" -ne 0 ] \
    && command -v startx >/dev/null 2>&1 && exec startx
