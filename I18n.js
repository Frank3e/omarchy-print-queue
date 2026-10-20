// Cadenas del widget de cola de impresion, adaptadas al idioma del sistema.
// Locale: LC_ALL > LC_MESSAGES > LANG (el nombre que Qt.locale().name ya trae).

var strings = {
  en: {
    "queue.title": "Print queue",
    "queue.empty": "Queue empty",
    "queue.pendingOne": "1 job pending",
    "queue.pendingMany": "%n jobs pending",
    "queue.noJobs": "No jobs in the queue",
    "job.cancel": "Cancel",
    "job.cancelAll": "Cancel all",
    "job.refresh": "Refresh",
    "job.cancelTip": "Cancels this job from the queue",
    "job.cancelAllTip": "Empties the print queue",
    "status.cancellingJob": "Cancelling job\u2026",
    "status.cancellingAll": "Cancelling all jobs\u2026",
    "err.readQueue": "Could not read the print queue",
    "err.cancelFailed": "Failed to cancel the job"
  },
  es: {
    "queue.title": "Cola de impresion",
    "queue.empty": "Cola vacia",
    "queue.pendingOne": "1 trabajo pendiente",
    "queue.pendingMany": "%n trabajos pendientes",
    "queue.noJobs": "No hay trabajos en la cola",
    "job.cancel": "Cancelar",
    "job.cancelAll": "Cancelar todo",
    "job.refresh": "Refrescar",
    "job.cancelTip": "Cancela este trabajo de la cola",
    "job.cancelAllTip": "Vacia la cola de impresion",
    "status.cancellingJob": "Cancelando trabajo\u2026",
    "status.cancellingAll": "Cancelando todos los trabajos\u2026",
    "err.readQueue": "No se pudo leer la cola de impresion",
    "err.cancelFailed": "Fallo al cancelar el trabajo"
  }
}

function langOf(localeName) {
  var base = String(localeName || "").toLowerCase().split(/[-_.@]/)[0]
  return strings[base] ? base : "en"
}

function t(key, localeName) {
  var table = strings[langOf(localeName)]
  var value = table[key]
  if (value === undefined) value = strings.en[key]
  return value === undefined ? String(key) : value
}

function tn(oneKey, manyKey, count, localeName) {
  var n = Number(count || 0)
  return t(n === 1 ? oneKey : manyKey, localeName).replace(/%n/g, String(n))
}
