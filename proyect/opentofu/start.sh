#!/bin/bash
set -e

URI="qemu:///system"
STATE_FILE="terraform.tfstate"

if [[ ! -f "$STATE_FILE" ]]; then
  echo "❌ No se encuentra $STATE_FILE"
  exit 1
fi

# ¿Hay algún recurso libvirt?
if ! grep -qP '"type"\s*:\s*"libvirt_' "$STATE_FILE"; then
  echo "⚠️ No hay recursos libvirt que gestionar"
  exit 0
fi

# Extraer redes y VMs (desde attributes.name)
NETS=$(
  grep -oP '"type"\s*:\s*"libvirt_network".*?"attributes"\s*:\s*{.*?"name"\s*:\s*"\K[^"]+' "$STATE_FILE" \
  | sort -u
)

VMs=$(
  grep -oP '"type"\s*:\s*"libvirt_domain".*?"attributes"\s*:\s*{.*?"name"\s*:\s*"\K[^"]+' "$STATE_FILE" \
  | sort -u
)

# Activar redes primero
if [[ -n "$NETS" ]]; then
  echo "🌐 Activando redes…"
  while IFS= read -r NET; do
    [[ -z "$NET" ]] && continue
    if virsh -c "$URI" net-info "$NET" &>/dev/null; then
      if virsh -c "$URI" net-info "$NET" | grep -q "Active: no"; then
        echo "→ net-start $NET"
        virsh -c "$URI" net-start "$NET" || true
      else
        echo "✔ $NET ya activa"
      fi
    fi
  done <<< "$NETS"
fi

# Arrancar VMs
if [[ -n "$VMs" ]]; then
  echo "💻 Arrancando VMs…"
  while IFS= read -r NAME; do
    [[ -z "$NAME" ]] && continue
    if virsh -c "$URI" dominfo "$NAME" &>/dev/null; then
      if virsh -c "$URI" dominfo "$NAME" | grep -q "State:.*shut off"; then
        echo "→ start $NAME"
        virsh -c "$URI" start "$NAME"
      else
        echo "✔ $NAME ya está encendida"
      fi
    fi
  done <<< "$VMs"
fi

echo "✅ Escenario iniciado correctamente"
tofu output