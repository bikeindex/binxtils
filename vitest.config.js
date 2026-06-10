import { defineConfig } from 'vitest/config'

// Pin system timezone so tests produce identical output on all machines
process.env.TZ = 'America/Chicago'

export default defineConfig({
  test: {
    environment: 'jsdom',
    // Use an https origin so the Secure timezone cookie is readable in tests
    environmentOptions: {
      jsdom: { url: 'https://localhost/' }
    }
  }
})
