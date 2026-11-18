<p align="center">
  <img src="assets/app_icon.png" alt="PDF Toolkit app icon" width="112" />
</p>

<h1 align="center">PDF Toolkit</h1>

<p align="center">
  A clean, on-device workspace for the PDF tasks you do every day.
</p>

<p align="center">
  <a href="https://github.com/shivubuilds-mikasa/pdf-toolkit/releases/latest">
    <img src="https://img.shields.io/github/v/release/shivubuilds-mikasa/pdf-toolkit?label=latest%20release&color=8b7bff" alt="Latest release" />
  </a>
  <img src="https://img.shields.io/badge/Flutter-3.44.9-02569B?logo=flutter&logoColor=white" alt="Built with Flutter" />
  <img src="https://img.shields.io/badge/platform-Android-3DDC84?logo=android&logoColor=white" alt="Android app" />
  <img src="https://img.shields.io/badge/ads-none-18a999" alt="No ads" />
</p>

<p align="center">
  <a href="https://github.com/shivubuilds-mikasa/pdf-toolkit/releases/latest/download/app-release.apk"><strong>⬇ Download the latest APK</strong></a>
  &nbsp; · &nbsp;
  <a href="https://github.com/shivubuilds-mikasa/pdf-toolkit/releases">All releases</a>
</p>

<p align="center">
  <img src="docs/screenshots/app-tour.gif" alt="Animated tour: dashboard, saved PDFs, and the PDF reader" width="270" />
</p>

## Your PDFs, one place

Convert, organize, and work with PDFs from a single app. The interface keeps your tools close, your recent work easy to find, and your saved documents accessible all the way to the bottom of the list.

## ✨ What you can do

| Tool | What it does |
| --- | --- |
| 🖼️ **Image to PDF** | Turn one or more images into a PDF. |
| 📷 **Document Scanner** | Capture paper documents with your camera and save them as PDFs. |
| 🔗 **PDF Merger** | Combine multiple PDFs into one file. |
| ✂️ **PDF Splitter** | Extract page ranges or split a document into separate pages. |
| 📦 **PDF Compressor** | Reduce file size with adjustable compression. |
| 🔄 **Page Rotation** | Rotate selected pages or an entire document. |
| 🔐 **Password Protect** | Add or remove PDF passwords. |
| 📁 **Saved Files** | Search, sort, favorite, rename, share, and open your PDFs. |

## 📱 Screenshots

<table>
  <tr>
    <th align="center">Dashboard</th>
    <th align="center">Saved files</th>
    <th align="center">PDF reader</th>
  </tr>
  <tr>
    <td align="center"><img src="docs/screenshots/dashboard.png" alt="Dashboard showing storage, totals, and quick actions" width="240" /></td>
    <td align="center"><img src="docs/screenshots/saved-files-bottom.png" alt="Saved files list with the last PDF above the navigation bar" width="240" /></td>
    <td align="center"><img src="docs/screenshots/last-pdf-opened.png" alt="The last PDF opened in the reader" width="240" /></td>
  </tr>
</table>

The animated tour above cycles through these screens with a soft crossfade.

## 📦 Install

Download **PDF Toolkit v1.0.5** from the latest GitHub release:

<p align="center">
  <a href="https://github.com/shivubuilds-mikasa/pdf-toolkit/releases/latest/download/app-release.apk">
    <img src="https://img.shields.io/badge/Download-Android%20APK-6f5bff?style=for-the-badge&logo=android&logoColor=white" alt="Download Android APK" />
  </a>
</p>

Open the downloaded APK on your Android device and follow Android’s install prompt. The release page also contains previous versions and release notes.

## 🧑‍💻 Run from source

### Requirements

- Flutter SDK
- Android Studio or Android SDK
- An Android device or emulator

### Start the app

```bash
git clone https://github.com/shivubuilds-mikasa/pdf-toolkit.git
cd pdf-toolkit
flutter pub get
flutter run
```

### Build a release APK

```bash
flutter build apk --release
```

The APK is written to `build/app/outputs/flutter-apk/app-release.apk`.

## 🧱 Built with

- **Flutter & Dart** for the app and interface
- **Material 3** components with a glass-inspired theme
- **Riverpod** for app state
- Native Android document scanning and local file storage

## 🔒 Your documents

PDF Toolkit is built around local document workflows. Camera access is used by the document scanner; your PDFs remain in the app’s chosen storage location so you can manage them from Saved Files.

## 🤝 Contributing

Bug reports and improvements are welcome. When opening an issue, include your device and Android version, steps to reproduce, and what you expected to happen.

---

<p align="center">
  <strong>PDF Toolkit</strong><br />
  Make PDFs. Keep moving.
</p>
