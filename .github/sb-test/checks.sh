#!/usr/bin/env bash
# Hibernate test, run as root inside the VM: checks.sh <phase>
set -uo pipefail
fails=0
pass() { echo "PASS  $*"; }
fail() { echo "FAIL  $*"; fails=$((fails + 1)); }
info() { echo "INFO  $*"; }
indent() { sed 's/^/      /' | head -"${1:-30}"; }
U=tester; uid=$(id -u "$U")
export XDG_RUNTIME_DIR=/run/user/$uid
sig() { ls -t "$XDG_RUNTIME_DIR/hypr" 2>/dev/null | head -1; }
hctl() { setpriv --reuid="$U" --regid="$U" --init-groups env XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" HYPRLAND_INSTANCE_SIGNATURE="$(sig)" hyprctl "$@"; }
wait_for() { local t=$1; shift; for _ in $(seq "$t"); do "$@" && return 0; sleep 1; done; return 1; }
boot_id() { cat /proc/sys/kernel/random/boot_id; }
hypr_pid() { pgrep -u "$U" -x Hyprland | head -1; }
proof_mapped() { [[ $(hctl -j clients 2>/dev/null | jq '[.[] | select(.class == "hbproof")] | length') -ge 1 ]]; }

case "$1" in
first-boot)
    info "system: $(timeout 900 systemctl is-system-running --wait)"
    journalctl -b -u tblue-hibernate-setup -o cat --no-pager | indent
    swapon --show | indent
    ;;

ready)
    info "system: $(timeout 900 systemctl is-system-running --wait)"
    cmd=$(cat /proc/cmdline)
    info "resume kargs: $(tr ' ' '\n' <<<"$cmd" | grep -E '^(resume|resume_offset|nohibernate)' | paste -sd' ')"
    [[ "$cmd" == *resume=* && "$cmd" == *resume_offset=* ]] && pass "resume= and resume_offset= on the kernel command line" || fail "resume kargs missing"
    [[ " $cmd " != *" nohibernate "* ]] && pass "nohibernate removed" || fail "nohibernate still set"
    info "lockdown: $(cat /sys/kernel/security/lockdown 2>/dev/null)"
    info "/sys/power/state: $(cat /sys/power/state)   /sys/power/disk: $(cat /sys/power/disk)"
    swapon --show | indent
    swapon --show=NAME --noheadings | grep -q /var/swap/swapfile && pass "swapfile active" || fail "swapfile not active"
    lbl=$(stat -c %C /var/swap/swapfile)
    [[ "$lbl" == *:swapfile_t:* ]] && pass "swapfile SELinux label: $lbl" || fail "swapfile SELinux label: $lbl"
    info "SELinux: $(getenforce)"
    info "memory: $(free -m | awk '/Mem:/ {print "used " $3 " MiB of " $2}')"
    for m in CanHibernate CanSuspendThenHibernate; do
        r=$(busctl call org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager "$m" 2>&1 | sed 's/^s "\(.*\)"$/\1/')
        [[ "$r" == yes ]] && pass "logind $m: $r" || fail "logind $m: $r"
    done
    info "initramfs resume support: $(lsinitrd "/usr/lib/modules/$(uname -r)/initramfs.img" 2>/dev/null | grep -oE '[^ ]*hibernate-resume[^ ]*' | sort -u | paste -sd' ')"
    wait_for 180 hypr_pid >/dev/null && pass "Hyprland session up (pid $(hypr_pid))" || fail "no Hyprland session"
    ;;

prepare)
    # A live clock in a terminal: after resume it should still be running.
    cat > /var/tmp/hb-clock.sh <<'CLOCK'
#!/bin/bash
echo "Session started: $(date '+%F %T')"
echo "Boot ID:         $(cat /proc/sys/kernel/random/boot_id)"
echo
while :; do printf '\rClock:           %s ' "$(date +%T)"; sleep 1; done
CLOCK
    chmod 755 /var/tmp/hb-clock.sh
    sleep 10
    hctl eval 'hl.exec_cmd("kitty --class hbproof -T Hibernate-proof /var/tmp/hb-clock.sh")' >/dev/null
    wait_for 30 proof_mapped && pass "clock window open" || fail "clock window did not open"
    # Another user's session, so logind checks hibernate-multiple-sessions.
    id second >/dev/null 2>&1 || useradd -m second
    systemd-run --quiet --unit=other-session -p PAMName=login -p User=second sleep infinity
    sleep 3
    loginctl list-sessions --no-legend | indent
    hp=$(hypr_pid)
    r=$(pkcheck --action-id org.freedesktop.login1.hibernate-multiple-sessions --process "$hp" >/dev/null 2>&1; echo $?)
    [[ "$r" == 0 ]] && pass "polkit: hibernate-multiple-sessions allowed for the session without a prompt" || fail "polkit: hibernate-multiple-sessions -> $r"
    { echo "boot_id=$(boot_id)"; echo "hypr=$hp"; echo "kitty=$(pgrep -u "$U" -f 'kitty --class hbproof' | head -1)"; echo "epoch=$(date +%s)"; } > /var/tmp/hb-before
    cat /var/tmp/hb-before | indent
    ;;

hibernate)
    # From inside the session, like a keybind or the power menu would.
    journalctl --rotate >/dev/null 2>&1
    hctl eval 'hl.exec_cmd("systemctl hibernate > /tmp/hb-hibernate.log 2>&1")' >/dev/null
    pass "systemctl hibernate started from the Hyprland session"
    ;;

verify)
    # shellcheck disable=SC1091
    . /var/tmp/hb-before
    now=$(boot_id)
    [[ "$now" == "$boot_id" ]] && pass "same boot ID as before hibernating ($now): resumed, not rebooted" || fail "new boot ID $now (was $boot_id): this was a fresh boot"
    info "boots in the journal: $(journalctl --list-boots -q | wc -l)"
    journalctl -b -k -o short-monotonic --no-pager | grep -E 'PM: (hibernation|Image|Restoring|Basic memory|Using [0-9]+ thread|resume)|hibernation (entry|exit)|Image (loading|successfully)' | tail -20 | indent 20
    journalctl -b --no-pager -o short-monotonic | grep -E 'systemd-sleep|Performing sleep operation|returned from sleep' | tail -6 | indent 6
    kill -0 "$hypr" 2>/dev/null && pass "the same Hyprland process ($hypr) is still running" || fail "Hyprland $hypr is gone"
    [[ -n "$kitty" ]] && kill -0 "$kitty" 2>/dev/null && pass "the clock terminal ($kitty) survived" || fail "clock terminal gone"
    wait_for 20 proof_mapped && pass "its window is still mapped" || fail "clock window not mapped"
    info "wall-clock time since the snapshot: $(( $(date +%s) - epoch )) s; uptime $(cut -d. -f1 /proc/uptime) s"
    st=$(systemctl --user -M "$U@" show graphical-session.target -p ActiveState --value 2>&1)
    [[ "$st" == active ]] && pass "graphical-session.target still active" || fail "graphical-session.target: $st"
    info "systemctl hibernate output: $(cat /tmp/hb-hibernate.log 2>&1 | paste -sd' ')"
    ;;

sth-prepare)
    # suspend-then-hibernate, as the lid uses: suspend, then hibernate after
    # HibernateDelaySec (shortened for the test).
    mkdir -p /etc/systemd/sleep.conf.d
    printf '[Sleep]\nHibernateDelaySec=45s\n' > /etc/systemd/sleep.conf.d/zz-test.conf
    { echo "boot_id=$(boot_id)"; echo "hypr=$(hypr_pid)"; echo "kitty=$(pgrep -u "$U" -f 'kitty --class hbproof' | head -1)"; echo "epoch=$(date +%s)"; } > /var/tmp/hb-before
    journalctl --rotate >/dev/null 2>&1
    hctl eval 'hl.exec_cmd("systemctl suspend-then-hibernate > /tmp/hb-hibernate.log 2>&1")' >/dev/null
    pass "systemctl suspend-then-hibernate started from the Hyprland session"
    ;;
sb-locked)
    info "$(mokutil --sb-state 2>&1 | paste -sd' ')"
    info "lockdown: $(cat /sys/kernel/security/lockdown)"
    grep -q '\[integrity\]\|\[confidentiality\]' /sys/kernel/security/lockdown && pass "kernel locked down by Secure Boot" || fail "kernel not locked down"
    r=$(busctl call org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager CanHibernate 2>&1 | sed 's/^s "\(.*\)"$/\1/')
    [[ "$r" == na ]] && pass "logind CanHibernate: na (as expected while locked down)" || fail "logind CanHibernate: $r"
    journalctl -b -u tblue-hibernate-setup -o cat --no-pager | indent 6
    [[ ! -e /var/lib/tblue/hibernate-setup-v2.done ]] && pass "hibernate setup not marked done: it re-checks every boot" || fail "hibernate setup marked done while locked down"
    info "justfile imports: $(grep -h '^import\|^!include' /usr/share/ublue-os/justfile 2>/dev/null | paste -sd' ' | cut -c1-400)"
    n=$(runuser -u "$U" -- ujust --list 2>/dev/null | grep -cE 'hypr-(hibernate-on-secureboot|secureboot-verify-linux)')
    [[ "$n" == 2 ]] && pass "ujust lists both recipes" || fail "ujust lists $n of the 2 recipes"
    wait_for 180 hypr_pid >/dev/null && pass "Hyprland session up with Secure Boot enforcing" || fail "no Hyprland session"
    ;;

sb-optin-check)
    [[ -f /var/lib/tblue/hibernate-setup-v2.done ]] && pass "hibernate setup done ahead of the reboot" || fail "hibernate setup not done"
    lbl=$(stat -c %C /var/swap/swapfile 2>&1)
    [[ "$lbl" == *:swapfile_t:* ]] && pass "swapfile created and labelled ($lbl)" || fail "swapfile: $lbl"
    rpm-ostree status 2>/dev/null | head -12 | indent 12
    ;;

sb-unlocked)
    st=$(mokutil --sb-state 2>&1 | paste -sd' ')
    info "$st"
    [[ "$st" == *"SecureBoot enabled"* ]] && pass "firmware Secure Boot still enabled" || fail "Secure Boot state: $st"
    [[ "$st" == *"validation is disabled"* ]] && pass "shim validation disabled" || fail "shim validation still on"
    info "lockdown: $(cat /sys/kernel/security/lockdown)"
    grep -q '\[none\]' /sys/kernel/security/lockdown && pass "kernel no longer locked down" || fail "kernel still locked down"
    cmd=$(cat /proc/cmdline)
    [[ "$cmd" == *resume=* && "$cmd" == *resume_offset=* && " $cmd " != *" nohibernate "* ]] && pass "resume kargs in effect, nohibernate gone" || fail "kargs: $cmd"
    for m in CanHibernate CanSuspendThenHibernate; do
        r=$(busctl call org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager "$m" 2>&1 | sed 's/^s "\(.*\)"$/\1/')
        [[ "$r" == yes ]] && pass "logind $m: $r" || fail "logind $m: $r"
    done
    wait_for 180 hypr_pid >/dev/null && pass "Hyprland session up" || fail "no Hyprland session"
    ;;

sb-relocked)
    st=$(mokutil --sb-state 2>&1 | paste -sd' ')
    info "$st"
    [[ "$st" == *"SecureBoot enabled"* && "$st" != *"validation is disabled"* ]] && pass "shim validates Linux again" || fail "Secure Boot state: $st"
    info "lockdown: $(cat /sys/kernel/security/lockdown)"
    grep -q '\[integrity\]\|\[confidentiality\]' /sys/kernel/security/lockdown && pass "kernel locked down again" || fail "kernel not locked down"
    r=$(busctl call org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager CanHibernate 2>&1 | sed 's/^s "\(.*\)"$/\1/')
    [[ "$r" == na ]] && pass "logind CanHibernate: na" || fail "logind CanHibernate: $r"
    r=$(busctl call org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager CanSuspend 2>&1 | sed 's/^s "\(.*\)"$/\1/')
    [[ "$r" == yes ]] && pass "logind CanSuspend: yes (sleep falls back to suspend)" || fail "logind CanSuspend: $r"
    wait_for 180 hypr_pid >/dev/null && pass "Hyprland session up" || fail "no Hyprland session"
    ;;
esac
echo "phase $1: $fails failure(s)"
exit "$fails"
