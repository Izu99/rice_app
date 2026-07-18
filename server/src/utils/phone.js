/**
 * Normalize a Sri Lankan phone number to a canonical "0XXXXXXXXX" form so
 * that "0771234567", "771234567", and "+94771234567" all compare equal.
 * Without this, duplicate-phone detection misses numbers that differ only
 * by leading zero / country code.
 */
function normalizePhone (phone) {
  if (!phone) return phone

  let digits = String(phone).replace(/\D/g, '')

  if (digits.startsWith('94') && digits.length === 11) {
    digits = `0${digits.slice(2)}`
  } else if (digits.length === 9 && !digits.startsWith('0')) {
    digits = `0${digits}`
  }

  return digits
}

module.exports = { normalizePhone }
