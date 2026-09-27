.pragma library

// Pure helpers for the Spacefast panel. Kept free of QML so they are easy to
// reason about (and to test with plain node if you ever want to).

function parseSpaces(text) {
  var empty = { account: { authenticated: false, user: null }, engine: "", dashboardUrl: "https://my.spacefast.com", spaces: [] }
  var raw = String(text || "").trim()
  if (!raw) return empty
  try {
    var parsed = JSON.parse(raw)
    if (!parsed || typeof parsed !== "object") return empty
    if (!Array.isArray(parsed.spaces)) parsed.spaces = []
    if (!parsed.account) parsed.account = empty.account
    return parsed
  } catch (e) {
    return empty
  }
}

function accountLabel(data) {
  if (!data || !data.account) return ""
  if (!data.account.authenticated) return "Not signed in"
  var user = data.account.user
  if (user && typeof user === "object")
    return user.email || user.username || user.name || user.login || "Signed in"
  if (typeof user === "string" && user !== "") return user
  return "Signed in"
}

function hostOf(url) {
  var s = String(url || "")
  s = s.replace(/^https?:\/\//, "")
  s = s.replace(/\/$/, "")
  return s
}

function secondsBetween(fromIso, toDate) {
  var t = Date.parse(fromIso || "")
  if (isNaN(t)) return NaN
  return Math.round((t - toDate.getTime()) / 1000)
}

function humanSpan(seconds) {
  var s = Math.abs(seconds)
  if (s < 60) return "moments"
  if (s < 3600) return Math.round(s / 60) + "m"
  if (s < 86400) return Math.round(s / 3600) + "h"
  return Math.round(s / 86400) + "d"
}

function ago(iso, now) {
  var d = secondsBetween(iso, now || new Date())
  if (isNaN(d)) return ""
  if (Math.abs(d) < 60) return "just now"
  return humanSpan(d) + " ago"
}

// Right-hand status text for one space row.
function detail(space, now) {
  if (!space) return ""
  now = now || new Date()
  if (space.anonymous && space.expiresAt) {
    var left = secondsBetween(space.expiresAt, now)
    if (!isNaN(left)) return left > 0 ? "claim in " + humanSpan(left) : "expired"
  }
  var parts = []
  if (space.version) parts.push(space.version)
  var when = ago(space.updatedAt, now)
  if (when) parts.push(when)
  return parts.join(" · ")
}

// Anonymous spaces about to expire deserve the warning color.
function urgent(space, now) {
  if (!space || !space.anonymous || !space.expiresAt) return false
  var left = secondsBetween(space.expiresAt, now || new Date())
  return !isNaN(left) && left < 6 * 3600
}

function glyph(space) {
  if (!space) return "󰖟"
  return space.anonymous ? "󰌾" : "󰖟"
}

function clampIndex(index, count) {
  if (count <= 0) return -1
  if (index < 0) return 0
  if (index >= count) return count - 1
  return index
}
