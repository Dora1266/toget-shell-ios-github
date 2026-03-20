# ToGet iOS GitHub Actions Context

This directory is a minimal export for iOS GitHub Actions builds.

Included:
- iOS Xcode project
- Capacitor iOS dependencies and sync script
- offline shell template
- GitHub Actions workflow

Not included:
- Android source
- desktop source
- unrelated app shell code

Usage:
```bash
npm install
npm run sync:config
npx cap sync ios
cd ios/App
pod install
```
