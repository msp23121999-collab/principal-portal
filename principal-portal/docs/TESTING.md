# Principal Portal Testing Guide

## 1. Static Analysis

Validate Dart syntax, lint rules, and type safety:
```bash
flutter analyze
```

---

## 2. Unit & Widget Testing

Run unit tests, provider tests, widget tests, and accessibility checks:
```bash
flutter test
```

---

## 3. End-to-End (E2E) Visual Testing

Run Playwright automated visual verification across viewports (Desktop, Tablet, Mobile):
```bash
cd ../finalcode-worktree/backend
node verify_3_fixes_e2e.js
```
