# Bulk Email

Send personalized bulk emails from CSV or Excel spreadsheets. A cross-platform Flutter app that lets you upload a file, map columns to recipient, subject, body, and optional attachments, then send emails via your SMTP account (e.g. Gmail).

## What it does

- **Upload** CSV or Excel (`.xlsx`) files with your recipient list and email content
- **Map columns** to Recipient Email, Subject, Body, and optional Attachments
- **Configure** sender email and app password once (saved securely on device)
- **Send** bulk emails with optional per-row attachments via SMTP

## Project structure

| Path | Description |
|------|-------------|
| **[bulk_email_app/](bulk_email_app/)** | Flutter app — run and build from here |

## Quick start

1. Open the Flutter project: `bulk_email_app/`
2. Install dependencies: `flutter pub get`
3. Run: `flutter run` (or build for Windows, Android, etc.)
4. In the app: set **Settings** (sender email + app password), then **Browse Files** to pick a CSV/Excel file, map columns, and **Send Emails**

See **[bulk_email_app/README.md](bulk_email_app/README.md)** for detailed setup, file format, and Gmail app password instructions.

## Tech

- **Flutter** (Dart) — UI and logic  
- **mailer** — SMTP sending  
- **excel** / **csv** — spreadsheet parsing  
- **file_picker** — file selection  
- **provider** + **shared_preferences** — settings and state  

## License

See the app folder for license details.
