#!/bin/bash
# @See https://felixc.at/2012/09/one-line-bash-check-if-aur-packages-in-your-arch-sync-with-community/

. helpers.sh

echo_info "Arch 里没有和社区同步的 AUR 包："
pacman -Qmq | parallel 'result=$(package-query -AQ -f "%v" "{}" | uniq -d | wc -l); [ $result -eq 0 ] && echo "{}"'
