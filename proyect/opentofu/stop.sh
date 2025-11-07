#!/bin/bash
set -e

URI="qemu:///system"
STATE_FILE="terraform.tfstate"

if [[ ! -f "$STATE_FILE" ]]; then
  echo "❌ No se encuentra $STATE_FILE"
  exit 1
fi

# ¿Existe sección resources?
if ! grep -q '"resources"[[:space:]]*:[[:space:]]*\[' "$STATE_FILE"; then
  echo "❌ El estado no contiene sección resources"
  exit 1
fi

# ¿Hay algún recurso libvirt?
if ! grep -qP '"type"\s*:\s*"libvirt_' "$STATE_FILE"; then
  echo "⚠️ No hay recursos libvirt que gestionar"
  exit 0
fi

# Extraer nombres dentro de attributes.name por tipo (PCRE; sin depender de saltos de línea)
VMs=$(
  grep -oP '"type"\s*:\s*"libvirt_domain".*?"attributes"\s*:\s*{.*?"name"\s*:\s*"\K[^"]+' "$STATE_FILE" \
  | sort -u
)

NETS=$(
  grep -oP '"type"\s*:\s*"libvirt_network".*?"attributes"\s*:\s*{.*?"name"\s*:\s*"\K[^"]+' "$STATE_FILE" \
  | sort -u
)

# Apagar VMs
if [[ -n "$VMs" ]]; then
  echo "🛑 Apagando VMs…"
  while IFS= read -r NAME; do
    [[ -z "$NAME" ]] && continue
    if virsh -c "$URI" dominfo "$NAME" &>/dev/null; then
      echo "→ shutdown $NAME"
      virsh -c "$URI" shutdown "$NAME" || true
    fi
  done <<< "$VMs"

  echo "⏳ Esperando a que se apaguen…"
  while IFS= read -r NAME; do
    [[ -z "$NAME" ]] && continue
    for i in {1..10}; do
      if ! virsh -c "$URI" dominfo "$NAME" | grep -q "running"; then
        break
      fi
      sleep 2
    done
  done <<< "$VMs"
fi

# Desactivar redes (solo si están activas)
if [[ -n "$NETS" ]]; then
  echo "📴 Desactivando redes…"
  while IFS= read -r NET; do
    [[ -z "$NET" ]] && continue
    if virsh -c "$URI" net-info "$NET" &>/dev/null; then
      if virsh -c "$URI" net-info "$NET" | grep -q "Active: yes"; then
        echo "→ net-destroy $NET"
        virsh -c "$URI" net-destroy "$NET" || true
      else
        echo "✔ $NET ya inactiva"
      fi
    fi
  done <<< "$NETS"
fi

echo "✅ Escenario detenido correctamente"
