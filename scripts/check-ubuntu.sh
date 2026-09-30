#!/usr/bin/env bash
# How-to-SSH: read-only status check for an Ubuntu machine.
# It makes NO changes and never asks for a password.
#
# Run from the repository folder:
#   bash scripts/check-ubuntu.sh
#
# Output legend:  [OK] done   [--] missing / needs action   [??] cannot tell, ask the user

ok()   { printf '[OK] %s\n' "$*"; }
miss() { printf '[--] %s\n' "$*"; }
unk()  { printf '[??] %s\n' "$*"; }
info() { printf '     %s\n' "$*"; }

echo "== How-to-SSH check (Ubuntu) =="

# ---------- System ----------
if [ -r /etc/os-release ]; then . /etc/os-release; info "OS: ${PRETTY_NAME:-unknown}"; fi
info "User: $(whoami)   Host: $(hostname)"
session_type="${XDG_SESSION_TYPE:-}"
if [ -z "$session_type" ] && command -v loginctl >/dev/null 2>&1; then
    sid="$(loginctl list-sessions --no-legend 2>/dev/null | awk -v u="$(whoami)" '$3==u {print $1; exit}')"
    [ -n "$sid" ] && session_type="$(loginctl show-session "$sid" -p Type --value 2>/dev/null)"
fi
info "Desktop session type: ${session_type:-unknown}"

echo "-- Privileges"
if sudo -n true 2>/dev/null; then
    ok "sudo works without a password prompt (agent can run sudo commands itself)"
else
    miss "sudo needs a password -> the user must run sudo commands in their own terminal"
fi

# ---------- Tailscale ----------
echo "-- Tailscale"
if command -v curl >/dev/null 2>&1; then ok "curl installed"; else miss "curl not installed (needed for the Tailscale installer)"; fi
if command -v tailscale >/dev/null 2>&1; then
    ok "tailscale installed"
    ip4="$(tailscale ip -4 2>/dev/null | head -n1)"
    if [ -n "$ip4" ]; then ok "tailscale logged in, IP: $ip4"; else miss "tailscale not logged in (sudo tailscale up)"; fi
else
    miss "tailscale not installed"
fi
info "Tailscale key expiry: check at https://login.tailscale.com/admin/machines (lab PC should be 'Expiry disabled')"

# ---------- SSH ----------
echo "-- SSH"
if command -v ssh >/dev/null 2>&1; then ok "ssh client available"; else miss "ssh client not found"; fi
if dpkg -s openssh-server >/dev/null 2>&1; then
    ok "openssh-server installed"
    st="$(systemctl is-active ssh 2>/dev/null)"
    en="$(systemctl is-enabled ssh 2>/dev/null)"
    sock="$(systemctl is-active ssh.socket 2>/dev/null)"
    if [ "$st" = active ] || [ "$sock" = active ]; then ok "SSH server active"; else miss "SSH server not active (ssh: ${st:-unknown})"; fi
    if [ "$en" = enabled ] || [ "$sock" = active ]; then ok "SSH server starts at boot"; else miss "SSH server at boot: ${en:-unknown}"; fi
else
    miss "openssh-server not installed (only needed on the lab PC)"
fi
if [ -r /etc/ufw/ufw.conf ] && grep -qi '^ENABLED=yes' /etc/ufw/ufw.conf; then
    unk "ufw firewall is ON -> 'sudo ufw allow ssh' must have been run (cannot verify without sudo)"
else
    ok "ufw firewall is off"
fi

# ---------- Sleep / lock ----------
echo "-- Sleep / screen lock"
sl="$(systemctl is-enabled sleep.target 2>/dev/null)"
if [ "$sl" = masked ]; then ok "system sleep disabled (sleep.target masked)"; else miss "system sleep NOT disabled (sleep.target: ${sl:-unknown})"; fi
if command -v gsettings >/dev/null 2>&1; then
    idle="$(gsettings get org.gnome.desktop.session idle-delay 2>/dev/null)"
    lock="$(gsettings get org.gnome.desktop.screensaver lock-enabled 2>/dev/null)"
    if [ "$idle" = "uint32 0" ]; then ok "screen blanking disabled"; else miss "screen blanks after: ${idle:-unknown}"; fi
    if [ "$lock" = "false" ]; then ok "automatic screen lock off"; else miss "automatic screen lock: ${lock:-unknown}"; fi
else
    unk "gsettings not available (no GNOME desktop?)"
fi

# ---------- Remote desktop ----------
echo "-- Remote desktop (RustDesk)"
conf=/etc/gdm3/custom.conf
if [ -r "$conf" ]; then
    if grep -Eq '^[[:space:]]*WaylandEnable[[:space:]]*=[[:space:]]*false' "$conf"; then
        ok "Wayland disabled in $conf (Xorg is used after reboot)"
    else
        miss "Wayland still enabled in $conf"
    fi
    if grep -Eqi '^[[:space:]]*AutomaticLoginEnable[[:space:]]*=[[:space:]]*true' "$conf"; then
        who="$(grep -Ei '^[[:space:]]*AutomaticLogin[[:space:]]*=' "$conf" | head -n1 | cut -d= -f2 | tr -d '[:space:]')"
        ok "automatic login enabled (user: ${who:-?})"
    else
        miss "automatic login not enabled"
    fi
else
    unk "$conf not found (not using GDM?)"
fi
if [ "$session_type" = x11 ]; then ok "current session is x11"; else miss "current session is ${session_type:-unknown} (must be x11 for RustDesk; reboot after disabling Wayland)"; fi
if command -v rustdesk >/dev/null 2>&1; then ok "rustdesk installed"; else miss "rustdesk not installed"; fi
rs="$(systemctl is-active rustdesk 2>/dev/null)"
if [ "$rs" = active ]; then ok "rustdesk service active"; else miss "rustdesk service: ${rs:-not found}"; fi
cfg="$HOME/.config/rustdesk/RustDesk2.toml"
if [ -r "$cfg" ] && grep -Eq "direct-server[[:space:]]*=[[:space:]]*'Y'" "$cfg"; then
    ok "RustDesk direct IP access enabled"
else
    unk "RustDesk direct IP access: cannot confirm -> ask the user to check Settings > Security"
fi
info "RustDesk permanent password: cannot be checked by a script -> ask the user"

echo "== done =="
