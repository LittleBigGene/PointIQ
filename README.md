# PointIQ

PointIQ is an iOS app designed for **table tennis players** to track matches, log strokes, and gain meaningful insights into their game. The app focuses on fast, in-game usability while building a rich data set for post-match analysis and long‑term improvement.

---

## 🚀 Features

* 🏓 **Live Match Scoreboard**
  Track points in real time with table‑tennis–specific rules and flows.

* ✍️ **Stroke Logging**
  Log strokes during or after rallies (e.g. loop, push, block, chop) with an intuitive taxonomy.

* 📊 **Match History & Stats**
  Review past matches, stroke distributions, and performance trends.

* ☁️ **Cloud Sync with Supabase**
  Secure authentication and cloud storage for matches and user data.

* 📱 **iOS‑First UX**
  Optimized for quick interactions during real matches.

---

## 🧱 Tech Stack

* **Platform**: iOS (Swift / SwiftUI)
* **Backend**: Supabase

  * Authentication
  * Postgres database
  * Row Level Security (RLS)
* **Architecture**: Client‑driven, API‑light (direct Supabase SDK usage)

---

## 🔐 Backend & Security

* Supabase is used as the primary backend
* All tables enforce **Row Level Security (RLS)**
* Users can only access their own matches and logs
* No sensitive secrets are stored in the client

---

## 🧪 Development & Testing

* Supports local development using Supabase project keys
* TestFlight used for beta distribution
* Manual testing focuses on:

  * Live scoring accuracy
  * Offline / reconnect behavior
  * App background & foreground transitions

---

## 📦 Environment Setup

1. Clone the repository
2. Open the project in Xcode
3. Configure Supabase credentials:

   * Project URL
   * Public anon key
4. Build and run on simulator or device

> ⚠️ Never commit service role keys or secrets.

---

## 🛡 Privacy

PointIQ collects only the data required to provide its core functionality:

* User account information
* Match and stroke data created by the user

See the app’s **Privacy Policy** for full details.

---

## 📈 Roadmap (High Level)

* Advanced match analytics
* Training mode & drills
* Video + stroke tagging
* Club / coach sharing features

---

## 🤝 Contributing

This project is currently developed as a solo product. Contributions, ideas, and feedback are welcome via issues or discussions.

---

## 🏓 Vision

PointIQ aims to become a **personal performance intelligence system** for table tennis—simple enough to use during play, powerful enough to guide long‑term improvement.
