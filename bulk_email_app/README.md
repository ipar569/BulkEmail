# Bulk Email App

A Flutter app that sends **bulk, personalized emails** from CSV or Excel spreadsheets. You choose a file, map its columns to recipient, subject, body, and optional attachments, then send all emails through your own SMTP account (e.g. Gmail).

## Features

- **CSV & Excel** — Upload `.csv` or `.xlsx` files; first sheet is used for Excel
- **Column mapping** — Map your spreadsheet columns to:
  - **Recipient Email** (required)
  - **Subject** (required)
  - **Body** (required)
  - **Attachments** (optional) — file path per row
- **Sender settings** — Store sender email and app password (or API key) in app; saved on device
- **SMTP sending** — Sends via SMTP (default example: Gmail on port 587)
- **Progress feedback** — Shows how many emails were sent and how many failed

## Getting started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed and on your PATH

### Run the app

```bash
flutter pub get
flutter run
```

Pick your platform (e.g. Windows, Android) when prompted or use `flutter run -d windows`, etc.

### Build for release

```bash
flutter build windows   # or apk, ios, macos, web, etc.
```

## File format

Your CSV or Excel file should have a **header row**. Example:

| email             | subject        | message        | attachment_path   |
|-------------------|----------------|----------------|-------------------|
| user1@example.com | Hello User 1   | Hi, this is…   |                   |
| user2@example.com | Hello User 2   | Hi, this is…   | C:\files\doc.pdf  |

After you upload, the app shows a **Map Columns** dialog so you assign:
- Which column = Recipient Email  
- Which column = Subject  
- Which column = Body  
- Which column = Attachments (optional)

Column names in the file don’t have to match; you choose the mapping once per file.

## Email settings (Gmail example)

1. In the app, open **Settings** (gear icon).
2. Enter your **sender email** (e.g. your Gmail address).
3. Enter an **App Password**, not your normal Gmail password:
   - Turn on 2-Step Verification for your Google account.
   - Go to [Google Account → Security → App passwords](https://myaccount.google.com/apppasswords).
   - Create an app password and paste it into the app.

The app uses **SMTP** (e.g. `smtp.gmail.com`, port 587). Other providers (Outlook, custom SMTP) would require changing the SMTP host/port in the code (see `lib/main.dart` → `SmtpServer`).

## Project structure

- `lib/main.dart` — App entry, home screen, file picker, column mapping, and bulk send logic
- `lib/splash_screen.dart` — Splash screen
- `pubspec.yaml` — Dependencies (file_picker, excel, csv, mailer, provider, shared_preferences, etc.)

## Resources

- [Flutter documentation](https://docs.flutter.dev/)
- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)
