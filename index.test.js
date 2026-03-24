import { describe, it, expect, beforeEach } from 'vitest'
import { DateTime, Settings } from 'luxon'
import TimeLocalizer from './index.js'

// Pin timezone and "now" so tests are deterministic
// vitest.config.js sets process.env.TZ = 'America/Chicago'
const ZONE = 'America/Chicago'
// 2026-03-23 14:30:00 CDT
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
      expect(tl.localTimezone).toBe('America/Chicago')
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

    it('defaults singleFormat to false', () => {
      expect(localizer.singleFormat).toBe(false)
    })
  })

  describe('parse', () => {
    it('parses unix timestamps', () => {
      const result = localizer.parse('1604337131')
      expect(result.toISO()).toBe('2020-11-02T11:12:11.000-06:00')
    })

    it('parses ISO 8601 strings', () => {
      const result = localizer.parse('2025-06-15T10:30:00Z')
      // Luxon converts to system timezone (CDT = UTC-5 in summer)
      expect(result.toISO()).toBe('2025-06-15T05:30:00.000-05:00')
    })

    it('returns null for null input', () => {
      expect(localizer.parse(null)).toBeNull()
    })

    it('returns invalid DateTime for empty string', () => {
      expect(localizer.parse('').isValid).toBe(false)
    })
  })

  describe('hourFormat', () => {
    const time = DateTime.fromObject(
      { year: 2026, month: 3, day: 23, hour: 14, minute: 5, second: 42 },
      { zone: ZONE }
    )

    it('formats without seconds', () => {
      expect(localizer.hourFormat(time, 'h:mm', false, false)).toBe('2:05pm')
    })

    it('formats with seconds', () => {
      expect(localizer.hourFormat(time, 'h:mm', true, false))
        .toBe('2:05:<small class="less-strong">42</small>pm')
    })

    it('includes preposition when requested', () => {
      expect(localizer.hourFormat(time, 'h:mm', false, true)).toBe(' at 2:05pm')
    })

    it('formats with seconds and preposition', () => {
      expect(localizer.hourFormat(time, 'h:mm', true, true))
        .toBe(' at 2:05:<small class="less-strong">42</small>pm')
    })
  })

  describe('preciseTimeSeconds', () => {
    it('formats with lowercase am/pm and full date', () => {
      const time = DateTime.fromObject(
        { year: 2026, month: 3, day: 23, hour: 9, minute: 30, second: 15 },
        { zone: ZONE }
      )
      expect(localizer.preciseTimeSeconds(time))
        .toBe('March 23, 2026 at 9:30:15am CDT')
    })

    it('formats pm times', () => {
      const time = DateTime.fromObject(
        { year: 2026, month: 3, day: 23, hour: 14, minute: 30, second: 0 },
        { zone: ZONE }
      )
      expect(localizer.preciseTimeSeconds(time))
        .toBe('March 23, 2026 at 2:30:00pm CDT')
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
      const earlyMorning = DateTime.fromObject(
        { year: 2026, month: 3, day: 23, hour: 2, minute: 0 },
        { zone: ZONE }
      )
      Settings.now = () => earlyMorning.toMillis()
      window.localTimezone = ZONE
      window.timeLocalizerSingleFormat = false
      const earlyLocalizer = new TimeLocalizer()
      const lateLastNight = earlyMorning.minus({ hours: 3 })
      expect(earlyLocalizer.renderWithoutDate(lateLastNight)).toBe(true)
    })

    it('returns false for times more than 4 hours ago before today', () => {
      const earlyMorning = DateTime.fromObject(
        { year: 2026, month: 3, day: 23, hour: 2, minute: 0 },
        { zone: ZONE }
      )
      Settings.now = () => earlyMorning.toMillis()
      window.localTimezone = ZONE
      window.timeLocalizerSingleFormat = false
      const earlyLocalizer = new TimeLocalizer()
      const yesterdayEvening = earlyMorning.minus({ hours: 5 })
      expect(earlyLocalizer.renderWithoutDate(yesterdayEvening)).toBe(false)
    })
  })

  describe('localizedDateText', () => {
    it('shows only time for today (variable format)', () => {
      const time = NOW.minus({ hours: 1 })
      expect(localizer.localizedDateText(time, false, false, false, false))
        .toBe(' 1:30pm')
    })

    it('shows only time for today with preposition', () => {
      const time = NOW.minus({ hours: 1 })
      expect(localizer.localizedDateText(time, false, true, false, true))
        .toBe('  at 1:30pm')
    })

    it('shows yyyy-MM-dd with time for today in singleFormat', () => {
      const time = NOW.minus({ hours: 1 })
      expect(localizer.localizedDateText(time, true, false, false, false))
        .toBe('2026-03-23 1:30pm')
    })

    it('shows month and day without year for this year', () => {
      const time = DateTime.fromObject(
        { year: 2026, month: 1, day: 15, hour: 10 },
        { zone: ZONE }
      )
      expect(localizer.localizedDateText(time, false, false, false, false))
        .toBe('Jan 15')
    })

    it('shows month, day, and time for this year with preciseTime', () => {
      const time = DateTime.fromObject(
        { year: 2026, month: 1, day: 15, hour: 10 },
        { zone: ZONE }
      )
      expect(localizer.localizedDateText(time, false, true, false, false))
        .toBe('Jan 15,  10:00am')
    })

    it('shows month, day, and time with preposition for this year', () => {
      const time = DateTime.fromObject(
        { year: 2026, month: 1, day: 15, hour: 10 },
        { zone: ZONE }
      )
      expect(localizer.localizedDateText(time, false, true, false, true))
        .toBe('Jan 15  at 10:00am')
    })

    it('shows date with year for a different year', () => {
      const time = DateTime.fromObject(
        { year: 2024, month: 6, day: 1, hour: 10 },
        { zone: ZONE }
      )
      expect(localizer.localizedDateText(time, false, false, false, false))
        .toBe('Jun 1, 2024')
    })

    it('shows date with year and time for a different year with preciseTime', () => {
      const time = DateTime.fromObject(
        { year: 2024, month: 6, day: 1, hour: 10 },
        { zone: ZONE }
      )
      expect(localizer.localizedDateText(time, false, true, false, false))
        .toBe('Jun 1, 2024,  10:00am')
    })

    it('uses yyyy-MM-dd for singleFormat', () => {
      const time = DateTime.fromObject(
        { year: 2026, month: 1, day: 15, hour: 10 },
        { zone: ZONE }
      )
      expect(localizer.localizedDateText(time, true, false, false, false))
        .toBe('2026-01-15')
    })

    it('uses yyyy-MM-dd with time for singleFormat with preciseTime', () => {
      const time = DateTime.fromObject(
        { year: 2026, month: 1, day: 15, hour: 10 },
        { zone: ZONE }
      )
      expect(localizer.localizedDateText(time, true, true, false, false))
        .toBe('2026-01-15 10:00am')
    })

    describe('with onlyTodayWithoutDate disabled', () => {
      beforeEach(() => {
        localizer.onlyTodayWithoutDate = false
      })

      it('shows Yesterday prefix', () => {
        const time = NOW.minus({ hours: 20 })
        expect(localizer.localizedDateText(time, false, false, false, false))
          .toBe('Yesterday,  6:30pm')
      })

      it('shows Tomorrow prefix', () => {
        const time = NOW.plus({ hours: 20 })
        expect(localizer.localizedDateText(time, false, false, false, false))
          .toBe('Tomorrow,  10:30am')
      })

      it('shows Today prefix', () => {
        const time = NOW.minus({ hours: 1 })
        expect(localizer.localizedDateText(time, false, false, false, false))
          .toBe('Today,  1:30pm')
      })
    })
  })

  describe('localizedTimeHtml', () => {
    it('renders today time as span with title', () => {
      const timestamp = Math.floor(NOW.minus({ hours: 1 }).toSeconds()).toString()
      expect(localizer.localizedTimeHtml(timestamp, {}))
        .toBe('<span title="March 23, 2026 at 1:30:00pm CDT"> 1:30pm</span>')
    })

    it('renders ISO date from this year', () => {
      expect(localizer.localizedTimeHtml('2026-01-15T10:30:00Z', {}))
        .toBe('<span title="January 15, 2026 at 4:30:00am CST">Jan 15</span>')
    })

    it('renders old timestamp with year', () => {
      expect(localizer.localizedTimeHtml('1604337131', {}))
        .toBe('<span title="November 2, 2020 at 11:12:11am CST">Nov 2, 2020</span>')
    })

    it('renders with singleFormat option', () => {
      expect(localizer.localizedTimeHtml('2026-01-15T10:30:00Z', { singleFormat: true }))
        .toBe('<span title="January 15, 2026 at 4:30:00am CST">2026-01-15</span>')
    })

    it('renders with preciseTime option', () => {
      expect(localizer.localizedTimeHtml('2026-01-15T10:30:00Z', { preciseTime: true }))
        .toBe('<span title="January 15, 2026 at 4:30:00am CST">Jan 15,  4:30am</span>')
    })

    it('renders with includeSeconds option', () => {
      expect(localizer.localizedTimeHtml('1604337131', { includeSeconds: true }))
        .toBe('<span title="November 2, 2020 at 11:12:11am CST">Nov 2, 2020,  11:12:<small class="less-strong">11</small>am</span>')
    })

    it('renders with withPreposition (no time shown for non-precise date)', () => {
      expect(localizer.localizedTimeHtml('2026-01-15T10:30:00Z', { withPreposition: true }))
        .toBe('<span title="January 15, 2026 at 4:30:00am CST">Jan 15</span>')
    })

    it('returns Invalid DateTime for empty string', () => {
      expect(localizer.localizedTimeHtml('', {}))
        .toBe('<span title="Invalid DateTime">Invalid DateTime</span>')
    })

    it('returns Invalid DateTime for null input (coerced to string)', () => {
      expect(localizer.localizedTimeHtml(null, {}))
        .toBe('<span title="Invalid DateTime">Invalid DateTime</span>')
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
      expect(el.innerHTML).toBe('Nov 2, 2020')
      expect(el.getAttribute('title')).toBe('November 2, 2020 at 11:12:11am CST')
    })

    it('skips title when element has skipTimeTitle class', () => {
      const el = document.createElement('span')
      el.className = 'localizeTime skipTimeTitle'
      el.textContent = '1604337131'
      document.body.appendChild(el)

      localizer.localize()

      expect(el.innerHTML).toBe('Nov 2, 2020')
      expect(el.getAttribute('title')).toBeNull()
    })

    it('writes abbreviated timezone to localizeTimezone elements', () => {
      const el = document.createElement('span')
      el.className = 'localizeTimezone'
      document.body.appendChild(el)

      localizer.localize()

      expect(el.textContent).toBe('CDT')
      expect(el.classList.contains('localizeTimezone')).toBe(false)
    })

    it('sets hidden timezone field values', () => {
      const el = document.createElement('input')
      el.className = 'hiddenFieldTimezone'
      document.body.appendChild(el)

      localizer.localize()

      expect(el.value).toBe('America/Chicago')
    })

    it('sets date input field from data attribute', () => {
      const el = document.createElement('input')
      el.className = 'dateInputUpdateZone'
      el.setAttribute('data-initialtime', '2026-03-23T10:30:00Z')
      document.body.appendChild(el)

      localizer.localize()

      // fromISO converts to system timezone (CDT = UTC-5)
      expect(el.value).toBe('2026-03-23T05:30')
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

      expect(el.innerHTML).toBe('Nov 2, 2020,  11:12am')
    })

    it('respects preciseTimeSeconds class', () => {
      const el = document.createElement('span')
      el.className = 'localizeTime preciseTimeSeconds'
      el.textContent = '1604337131'
      document.body.appendChild(el)

      localizer.localize()

      expect(el.innerHTML)
        .toBe('Nov 2, 2020,  11:12:<small class="less-strong">11</small>am')
    })

    it('respects withPreposition class', () => {
      const el = document.createElement('span')
      el.className = 'localizeTime preciseTime withPreposition'
      el.textContent = '1604337131'
      document.body.appendChild(el)

      localizer.localize()

      expect(el.innerHTML).toBe('Nov 2, 2020  at 11:12am')
    })

    it('uses singleFormat but variableFormat overrides', () => {
      window.timeLocalizerSingleFormat = true
      window.localTimezone = ZONE
      const singleLocalizer = new TimeLocalizer()

      const fixedEl = document.createElement('span')
      fixedEl.className = 'localizeTime'
      fixedEl.textContent = '1604337131'
      document.body.appendChild(fixedEl)

      const variableEl = document.createElement('span')
      variableEl.className = 'localizeTime variableFormat'
      variableEl.textContent = '1604337131'
      document.body.appendChild(variableEl)

      singleLocalizer.localize()

      expect(fixedEl.innerHTML).toBe('2020-11-02')
      expect(variableEl.innerHTML).toBe('Nov 2, 2020')
    })
  })
})
