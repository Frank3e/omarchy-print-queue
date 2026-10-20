#!/usr/bin/env bash
# Cola de impresion de CUPS para el widget de la barra. Salida: una linea JSON.
set -uo pipefail

esc() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

if ! command -v lpstat >/dev/null 2>&1; then
  case "${LC_ALL:-${LC_MESSAGES:-${LANG:-}}}" in
    [eE][sS]*) MSG="lpstat no esta instalado" ;;
    *) MSG="lpstat is not installed" ;;
  esac
  printf '{"ok":false,"count":0,"jobs":[],"error":"%s"}\n' "$MSG"
  exit 0
fi

out=$(lpstat -o 2>/dev/null | tr -s ' ') || out=""

count=0
jobs=""
while IFS= read -r line; do
  line=${line#"${line%%[![:space:]]*}"}
  [ -z "$line" ] && continue

  read -r queue user size _ <<< "$line"
  stamp=${line#"$queue $user $size "}
  [ "$stamp" = "$line" ] && stamp=""

  job=${queue##*-}
  printer=${queue%-*}
  if ! [[ "$job" =~ ^[0-9]+$ ]]; then
    job=""
    printer="$queue"
  fi
  if ! [[ "$size" =~ ^[0-9]+$ ]]; then
    size=0
  fi

  entry=$(printf '{"id":"%s","printer":"%s","job":"%s","user":"%s","size":%s,"stamp":"%s"}' \
    "$(esc "$queue")" "$(esc "$printer")" "$(esc "$job")" "$(esc "$user")" "$size" "$(esc "$stamp")")

  if [ -z "$jobs" ]; then
    jobs="$entry"
  else
    jobs="$jobs,$entry"
  fi
  count=$((count + 1))
done <<< "$out"

printf '{"ok":true,"count":%d,"jobs":[%s]}\n' "$count" "$jobs"
