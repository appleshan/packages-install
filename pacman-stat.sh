#!/bin/bash
# by Felix Yan <https://github.com/felixonmars>
# stat of system update

# 查询archlinux滚了多少次
echo $(head -n1 /var/log/pacman.log | cut -d " " -f 1,2) 以来一共滚了 $(grep -c "full system upgrade" /var/log/pacman.log) 次﻿
