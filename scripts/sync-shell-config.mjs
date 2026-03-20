import fs from 'node:fs/promises'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const defaultAppUrl = 'https://toget.chat'

function normalizeUrl(raw) {
  const text = typeof raw === 'string' ? raw.trim() : ''
  if (!text) return ''
  try {
    const url = new URL(text)
    if (url.protocol !== 'http:' && url.protocol !== 'https:') return ''
    url.hash = ''
    return url.toString().replace(/\/$/, '')
  } catch {
    return ''
  }
}

async function readJson(file) {
  try {
    const raw = await fs.readFile(file, 'utf8')
    const parsed = JSON.parse(raw)
    return parsed && typeof parsed === 'object' ? parsed : null
  } catch {
    return null
  }
}

async function exists(file) {
  try {
    await fs.access(file)
    return true
  } catch {
    return false
  }
}

async function resolveAppUrl() {
  const fromEnv = normalizeUrl(process.env.TOGET_APP_URL)
  if (fromEnv) return fromEnv

  const candidates = []
  if (process.env.TOGET_SHELL_CONFIG) candidates.push(path.resolve(process.env.TOGET_SHELL_CONFIG))
  candidates.push(path.join(root, 'toget-shell.json'))

  for (const file of candidates) {
    if (!await exists(file)) continue
    const parsed = await readJson(file)
    const value = normalizeUrl(parsed?.appUrl)
    if (value) return value
  }

  return defaultAppUrl
}

async function writeFile(file, text) {
  await fs.mkdir(path.dirname(file), { recursive: true })
  await fs.writeFile(file, text, 'utf8')
}

async function main() {
  const appUrl = await resolveAppUrl()
  const capacitorConfig = {
    appId: 'com.togetai.toget',
    appName: 'ToGet',
    webDir: 'www',
    server: {
      url: appUrl,
      cleartext: appUrl.startsWith('http://'),
      errorPath: 'offline.html',
    },
  }

  await writeFile(
    path.join(root, 'capacitor.config.json'),
    `${JSON.stringify(capacitorConfig, null, 2)}\n`,
  )

  await writeFile(
    path.join(root, 'android/app/src/main/assets/capacitor.config.json'),
    `${JSON.stringify(capacitorConfig, null, 2)}\n`,
  )

  const iosCapConfig = path.join(root, 'ios/App/App/capacitor.config.json')
  if (await exists(path.dirname(iosCapConfig))) {
    await writeFile(
      iosCapConfig,
      `${JSON.stringify(capacitorConfig, null, 2)}\n`,
    )
  }

  const offlineTemplatePath = path.join(root, 'www/offline.html')
  const offlineTemplate = await fs.readFile(offlineTemplatePath, 'utf8')
  const offlineHtml = offlineTemplate.replace('__TOGET_APP_URL__', appUrl)
  await writeFile(path.join(root, 'android/app/src/main/assets/public/offline.html'), offlineHtml)

  const iosOffline = path.join(root, 'ios/App/App/public/offline.html')
  if (await exists(path.dirname(iosOffline))) {
    await writeFile(iosOffline, offlineHtml)
  }

  process.stdout.write(`ToGet shell config synced: appUrl=${appUrl}\n`)
}

main().catch((error) => {
  process.stderr.write(`${String(error?.stack || error)}\n`)
  process.exitCode = 1
})
