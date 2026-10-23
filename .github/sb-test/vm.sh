#!/usr/bin/env bash
# Runner-side driver for a Secure Boot VM: QEMU (OVMF secboot, SMM), SSH,
# monitor, screenshots, and the shim MokManager confirmation.
set -uo pipefail
D=${VM_DIR:?}
KEY=$D/key
SSH=(ssh -i "$KEY" -p 2222 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=5 -o LogLevel=ERROR tester@127.0.0.1)

mon() { python3 - "$D/mon.sock" "$*" <<'PY'
import socket, sys, time
s = socket.socket(socket.AF_UNIX); s.connect(sys.argv[1]); s.settimeout(3)
try: s.recv(4096)
except Exception: pass
s.sendall((sys.argv[2] + "\n").encode()); time.sleep(0.7)
try: print(s.recv(65536).decode(errors="replace").split("\n", 1)[-1].strip())
except Exception: pass
PY
}
running() { sudo test -f "$D/qemu.pid" && sudo kill -0 "$(sudo cat "$D/qemu.pid")" 2>/dev/null; }
serial() { ls -t "$D"/serial-*.log 2>/dev/null | head -1; }
grab() { # name -> ppm and png
    mon "screendump $D/$1.ppm" >/dev/null; sleep 0.5
    sudo chmod 644 "$D/$1.ppm" 2>/dev/null
    convert "$D/$1.ppm" "$D/$1.png" 2>/dev/null
}
shot() {
    grab "$1"
    echo "SCREENSHOT $1 $(identify -format '%wx%h mean=%[fx:mean] blue=%[fx:mean.b] red=%[fx:mean.r]' "$D/$1.png")"
    echo "BEGIN-B64 $1"; convert "$D/$1.png" -resize 960x -quality 70 jpg:- | base64 -w 0; echo; echo "END-B64 $1"
}
keys() { for k in "$@"; do mon "sendkey $k" >/dev/null; sleep 0.4; done; }

case "$1" in
boot)
    sudo rm -f "$D/mon.sock" "$D/qemu.pid"
    sudo qemu-system-x86_64 -name sbtest -machine q35,smm=on,accel=kvm -cpu host -smp 4 -m 4G \
        -global driver=cfi.pflash01,property=secure,value=on \
        -drive if=pflash,format=raw,unit=0,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.secboot.fd \
        -drive if=pflash,format=raw,unit=1,file="$D/vars.fd" \
        -drive file="$D/qcow2/disk.qcow2",if=virtio,format=qcow2 \
        -netdev user,id=n0,hostfwd=tcp:127.0.0.1:2222-:22 -device virtio-net-pci,netdev=n0 \
        -device virtio-vga -display none \
        -serial file:"$D/serial-$2.log" -monitor unix:"$D/mon.sock",server,nowait \
        -daemonize -pidfile "$D/qemu.pid"
    sudo chmod 666 "$D/mon.sock" "$D/serial-$2.log"
    ;;
wait-ssh)
    for _ in $(seq "$2"); do "${SSH[@]}" true 2>/dev/null && { echo "ssh up"; exit 0; }; sleep 1; done
    echo "ssh not up after $2 s"; tail -c 3000 "$(serial)" | tr -cd '\11\12\15\40-\176'; shot no-ssh; exit 1
    ;;
wait-off)
    for i in $(seq "$2"); do running || { echo "VM powered off after ${i}s"; exit 0; }; sleep 1; done
    echo "VM still running after $2 s"; exit 1
    ;;
mok-confirm)
    # Wait for the reboot (a dark frame, or OVMF's boot manager on the serial
    # console), then for shim's MokManager ("Press any key to perform MOK
    # management", 10 s timeout): its text on serial, or its blue screen.
    log=$(serial); from=$(( $(stat -c %s "$log") + 1 ))
    newtext() { tail -c "+$from" "$log" | tr -cd '\11\12\15\40-\176'; }
    frame() { grab poll; convert "$D/poll.png" -format '%[fx:mean] %[fx:mean.b] %[fx:mean.r]' info: 2>/dev/null; }
    rebooted=""
    for i in $(seq 120); do
        if newtext | grep -q 'BdsDxe'; then rebooted="serial"; break; fi
        read -r m _ _ < <(frame)
        if awk -v m="${m:-1}" 'BEGIN { exit !(m < 0.03) }'; then rebooted="dark frame"; break; fi
        sleep 0.5
    done
    echo "reboot seen: ${rebooted:-no (continuing)} "
    found=""
    for i in $(seq 240); do
        if newtext | grep -q 'MOK management'; then found="serial after ${i} polls"; break; fi
        read -r _ b r < <(frame)
        if awk -v b="${b:-0}" -v r="${r:-1}" 'BEGIN { exit !(b > 0.3 && r < 0.25) }'; then found="blue screen after ${i} polls"; break; fi
        sleep 0.3
    done
    [[ -n "$found" ]] || { echo "no MokManager prompt"; shot no-mok; exit 1; }
    echo "MokManager: $found"
    keys ret; sleep 2; shot mok-menu
    keys down ret; sleep 2; shot mok-password
    for _ in 1 2 3; do keys a ret; sleep 1; done
    sleep 1; shot mok-confirm
    keys down ret; sleep 2; shot mok-done
    keys ret
    ;;
run)  "${SSH[@]}" sudo bash /var/tmp/checks.sh "$2" ;;
user) shift; "${SSH[@]}" "$@" ;;
push) scp -i "$KEY" -P 2222 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR "$2" tester@127.0.0.1:/var/tmp/ ;;
shot) shot "$2" ;;
monitor) shift; mon "$*" ;;
stop) running && sudo kill "$(sudo cat "$D/qemu.pid")" ;;
esac
