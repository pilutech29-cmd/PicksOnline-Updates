#!/usr/bin/env bash
# Lo llama nginx-rtmp cuando OBS empieza (on) o termina (off) de transmitir.
case "$1" in
  on)  /usr/bin/sudo -n /usr/bin/systemctl start simititv-vivo ;;
  off) /usr/bin/sudo -n /usr/bin/systemctl stop simititv-vivo ;;
esac
