import { describe, it, expect, beforeEach } from 'vitest'
import { DateTime, Settings } from 'luxon'
import TimeLocalizer from './index.js'

// Pin timezone and "now" so tests are deterministic
const ZONE = 'America/Chicago'
// 2026-03-23 14:30:00 CST
const NOW = DateTime.fromObject(
  { year: 2026, month: 3, day: 23, hour: 14, minute: 30 },
  { zone: ZONE }
)

function buildLocalizer () {
  window.localTimezone = ZONE
  window.timeLocalizerSingleFormat = false
  Settings.now = () => NOW.toMillis()
  return new TimeLocalizer()
}

describe('TimeLocalizer', () => {
  let localizer

  beforeEach(() => {
    window.localTimezone = undefined
    window.timeLocalizerSingleFormat = undefined
    Settings.now = () => NOW.toMillis()
    localizer = buildLocalizer()
  })

  describe('constructor', () => {
    it('detects timezone from Intl when window.localTimezone is not set', () => {
      delete window.localTimezone
      const tl = new TimeLocalizer()
      expect(tl.localTimezone).toBeTruthy()
    })

    it('uses window.localTimezone when set', () => {
      window.localTimezone = 'Europe/London'
      const tl = new TimeLocalizer()
      expect(tl.localTimezone).toBe('Europe/London')
    })

    it('sets singleFormat from window', () => {
      window.timeLocalizerSingleFormat = true
      const tl = new TimeLocalizer()
      expect(tl.singleFormat).toBe(true)
    })
  })

  describe('parse', () => {
    it('parses unix timestamps', () => {
      const result = localizer.parse('1604337131')
      expect(result).toBeInstanceOf(DateTime)
      expect(result.year).toBe(2020)
    })

    it('parses ISO 8601 strings', () => {
      const result = localizer.parse('2025-06-15T10:30:00Z')
      expect(result.year).toBe(2025)
      expect(result.month).toBe(6)
    })

    it('returns null for null input', () => {
      expect(localizer.parse(null)).toBeNull()
    })
  })

  describe('hourFormat', () => {
    const time = DateTime.fromObject(
      { year: 2026, month: 3, day: 23, hour: 14, minute: 5, second: 42 },
      { zone: ZONE }
    )

    it('formats without seconds', () => {
      const result = localizer.hourFormat(time, 'h:mm', false, false)
      expect(result).toBe('2:05pm')
    })

    it('formats with seconds', () => {
      const result = localizer.hourFormat(time, 'h:mm', true, false)
      expect(result).toContain('2:05')
      expect(result).toContain('42')
      expect(result).toContain('pm')
    })

    it('includes preposition when requested', () => {
      const result = localizer.hourFormat(time, 'h:mm', false, true)
      expect(result).toMatch(/^ at /)
    })
  })

  describe('preciseTimeSeconds', () => {
    it('formats with lowercase am/pm', () => {
      const time = DateTime.fromObject(
        { year: 2026, month: 3, day: 23, hour: 9, minute: 30, second: 15 },
        { zone: ZONE }
      )
      const result = localizer.preciseTimeSeconds(time)
      expect(result).toMatch(/9:30:15/)
      expect(result).toMatch(/am/)
      expect(result).not.toMatch(/ AM/)
    })
  })

  describe('renderWithoutDate', () => {
    it('returns true for times today', () => {
      const time = NOW.minus({ hours: 1 }).setZone(ZONE)
      expect(localizer.renderWithoutDate(time)).toBe(true)
    })

    it('returns false for times yesterday', () => {
      const time = NOW.minus({ days: 1, hours: 5 }).setZone(ZONE)
      expect(localizer.renderWithoutDate(time)).toBe(false)
    })

    it('returns true for times within past 4 hours even if before today', () => {
      // 2am today minus 3 hours = 11pm yesterday, but within 4 hour window
      const earlyMorning = DateTime.fromObject(
        { year: 2026, month: 3, day: 23, hour: 2, minute: 0 },
        { zone: ZONE }
      )
      Settings.now = () => earlyMorning.toMillis()
      const earlyLocalizer = buildLocalizer()
      const lateLastNight = earlyMorning.minus({ hours: 3 })
      expect(earlyLocalizer.renderWithoutDate(lateLastNight)).toBe(true)
    })
  })

  describe('localizedDateText', () => {
    it('shows only time for today (variable format)', () => {
      const time = NOW.minus({ hours: 1 })
      const result = localizer.localizedDateText(time, false, false, false, false)
      expect(result).toMatch(/\d+:\d+[ap]m/)
      expect(result).not.toMatch(/Mar/)
    })

    it('shows date without year for this year', () => {
      const time = DateTime.fromObject(
        { year: 2026, month: 1, day: 15, hour: 10 },
        { zone: ZONE }
      )
      const result = localizer.localizedDateText(time, false, false, false, false)
      expect(result).toMatch(/Jan/)
      expect(result).toMatch(/15/)
      expect(result).not.toMatch(/2026/)
    })

    it('shows date with year for a different year', () => {
      const time = DateTime.fromObject(
        { year: 2024, month: 6, day: 1, hour: 10 },
        { zone: ZONE }
      )
      const result = localizer.localizedDateText(time, false, false, false, false)
      expect(result).toMatch(/Jun/)
      expect(result).toMatch(/2024/)
    })

    it('uses yyyy-MM-dd format when singleFormat is true', () => {
      const time = DateTime.fromObject(
        { year: 2026, month: 1, day: 5, hour: 10 },
        { zone: ZONE }
      )
      const result = localizer.localizedDateText(time, true, false, false, false)
      expect(result).toMatch(/2026-01-05/)
    })

    it('includes hours when preciseTime is set', () => {
      const time = DateTime.fromObject(
        { year: 2026, month: 1, day: 15, hour: 10, minute: 30 },
        { zone: ZONE }
      )
      const result = localizer.localizedDateText(time, false, true, false, false)
      expect(result).toMatch(/10:30am/)
    })
  })

  describe('localizedTimeHtml', () => {
    it('returns a span with title and formatted text', () => {
      const timestamp = Math.floor(NOW.minus({ hours: 1 }).toSeconds()).toString()
      const result = localizer.localizedTimeHtml(timestamp, {})
      expect(result).toMatch(/^<span title=".*">.*<\/span>$/)
    })

    it('returns empty span for unparseable input', () => {
      expect(localizer.localizedTimeHtml('', {})).toBe('<span></span>')
    })

    it('accepts ISO string input', () => {
      const result = localizer.localizedTimeHtml('2026-01-15T10:30:00Z', {})
      expect(result).toMatch(/Jan/)
    })
  })

  describe('localize (DOM)', () => {
    beforeEach(() => {
      document.body.innerHTML = ''
    })

    it('localizes time elements', () => {
      const el = document.createElement('span')
      el.className = 'localizeTime'
      el.textContent = '1604337131'
      document.body.appendChild(el)

      localizer.localize()

      expect(el.classList.contains('localizeTime')).toBe(false)
      expect(el.classList.contains('localizedTime')).toBe(true)
      expect(el.innerHTML).toMatch(/Nov/)
      expect(el.getAttribute('title')).toBeTruthy()
    })

    it('skips title when element has skipTimeTitle class', () => {
      const el = document.createElement('span')
      el.className = 'localizeTime skipTimeTitle'
      el.textContent = '1604337131'
      document.body.appendChild(el)

      localizer.localize()

      expect(el.getAttribute('title')).toBeNull()
    })

    it('writes timezone to localizeTimezone elements', () => {
      const el = document.createElement('span')
      el.className = 'localizeTimezone'
      document.body.appendChild(el)

      localizer.localize()

      expect(el.textContent).toBeTruthy()
      expect(el.classList.contains('localizeTimezone')).toBe(false)
    })

    it('sets hidden timezone field values', () => {
      const el = document.createElement('input')
      el.className = 'hiddenFieldTimezone'
      document.body.appendChild(el)

      localizer.localize()

      expect(el.value).toBe(ZONE)
    })

    it('sets date input field from data attribute', () => {
      const el = document.createElement('input')
      el.className = 'dateInputUpdateZone'
      el.setAttribute('data-initialtime', '2026-03-23T10:30:00Z')
      document.body.appendChild(el)

      localizer.localize()

      expect(el.value).toMatch(/2026-03-23T/)
    })
  })

  describe('writeTime with class options', () => {
    beforeEach(() => {
      document.body.innerHTML = ''
    })

    it('respects preciseTime class', () => {
      const el = document.createElement('span')
      el.className = 'localizeTime preciseTime'
      el.textContent = '1604337131'
      document.body.appendChild(el)

      localizer.localize()

      expect(el.innerHTML).toMatch(/:\d{2}[ap]m/)
    })

    it('respects preciseTimeSeconds class', () => {
      const el = document.createElement('span')
      el.className = 'localizeTime preciseTimeSeconds'
      el.textContent = '1604337131'
      document.body.appendChild(el)

      localizer.localize()

      expect(el.innerHTML).toMatch(/small/)
    })

    it('respects withPreposition class', () => {
      const el = document.createElement('span')
      el.className = 'localizeTime preciseTime withPreposition'
      el.textContent = '1604337131'
      document.body.appendChild(el)

      localizer.localize()

      expect(el.innerHTML).toMatch(/ at /)
    })

    it('uses singleFormat but variableFormat overrides', () => {
      window.timeLocalizerSingleFormat = true
      const singleLocalizer = buildLocalizer()

      const fixedEl = document.createElement('span')
      fixedEl.className = 'localizeTime'
      fixedEl.textContent = '1604337131'
      document.body.appendChild(fixedEl)

      const variableEl = document.createElement('span')
      variableEl.className = 'localizeTime variableFormat'
      variableEl.textContent = '1604337131'
      document.body.appendChild(variableEl)

      singleLocalizer.localize()

      expect(fixedEl.innerHTML).toMatch(/^\d{4}-\d{2}-\d{2}/)
      expect(variableEl.innerHTML).not.toMatch(/^\d{4}-\d{2}-\d{2}/)
    })

    it('handles empty text content gracefully', () => {
      const el = document.createElement('span')
      el.className = 'localizeTime'
      el.textContent = ''
      document.body.appendChild(el)

      localizer.localize()

      expect(el.classList.contains('localizedTime')).toBe(true)
      expect(el.innerHTML).toBe('')
    })
  })
})
