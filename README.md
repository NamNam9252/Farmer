<h1 align="center">
  🌾 Kisan Saathi — किसान साथी
</h1>

<p align="center">
  <strong>India's AI-Powered Farmer Companion App (Android APK)</strong><br/>
  Talk to it. Photograph your crop. Let AI do the rest.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Android%20APK-green?logo=android" />
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white" />
  <img src="https://img.shields.io/badge/AI-Gemini%20%7C%20Groq%20%7C%20OpenAI-blueviolet" />
  <img src="https://img.shields.io/badge/Language-Hindi%20%7C%20English-orange" />
  <img src="https://img.shields.io/badge/Voice-NLP%20%2B%20STT%20%2B%20TTS-red" />
</p>

---

## 🎯 What Makes This App Different?

Most apps assume you can read and type. **Kisan Saathi does not.**

> **You don't need to type a single word.** Hold the mic button, speak your question in Hindi or English, and the AI answers — out loud, back to you in your language.

This app is built ground-up for Indian farmers who may not be comfortable with keyboards or English interfaces. The **core innovation is the voice-first AI assistant** combined with **photo-based crop disease detection** — you point your phone at a sick plant, tap one button, and get a full diagnosis and treatment plan in seconds.

---

## AI Crop Disease Detection

> **Point → Tap → Healed.**  
> Take a photo of your diseased crop, tap Analyse, and get an instant AI diagnosis — disease name, causes, treatment steps, and where to buy medicine — all in Hindi or English.

This is the **#1 problem this app solves**: farmers losing crops to diseases they can't identify, spending days finding an expert, and losing money because they acted too late. Kisan Saathi puts an expert in every farmer's pocket.

**Full walkthrough →** [Disease Detection guide below ↓](#6-disease-detection)

---

## 📖 Table of Contents

1. [Tech Stack](#tech-stack)
2. [Project Structure](#project-structure)
3. [Installation — Getting the APK](#installation--getting-the-apk)
4. [Backend Setup (Developers)](#backend-setup-developers)
5. [Using the App — Complete Guide](#using-the-app--complete-guide)
   - [Onboarding & Authentication](#1-onboarding--authentication)
   - [Home Dashboard](#2-home-dashboard)
   - [AI Agri Friend — Voice Chatbot](#3-ai-agri-friend--voice-chatbot)
   - [Disease Detection (Hero Feature)](#6-disease-detection)
   - [AI Crop Recommendation](#5-ai-crop-recommendation-smart-farming)
   - [Crop Advisory](#4-crop-advisory)
   - [Market Prices (Mandi Bhav)](#7-market-prices-mandi-bhav)
   - [Marketplace](#8-marketplace)
   - [Equipment Rental](#9-equipment-rental)
   - [Farmer Communities](#10-farmer-communities)
   - [Government Schemes & News](#11-government-schemes--news)
   - [Weather Details](#12-weather-details)
   - [Notifications](#13-notifications)
   - [Profile & Settings](#14-profile--settings)
6. [User Roles](#user-roles)
7. [Language Support](#language-support)
8. [Offline Mode](#offline-mode)
9. [Environment Variables](#environment-variables)

---

## Tech Stack

### Mobile App — Android APK (Flutter)

| Category | Package / Tool |
|---|---|
| Framework | Flutter 3.x (Dart) |
| State Management | Riverpod 2.x |
| Navigation | GoRouter |
| Networking | Dio + HTTP |
| Real-time | Socket.IO client |
| **Voice Input (STT)** | **`speech_to_text`** |
| **Voice Output (TTS)** | **`flutter_tts`** |
| Camera / Gallery | `image_picker` |
| On-device ML | `tflite_flutter` |
| Location | `geolocator` |
| Maps | `flutter_map` (OpenStreetMap) |
| Local Storage | `shared_preferences`, `flutter_secure_storage` |
| SMS (offline) | `telephony` |
| UI | `flutter_svg`, `shimmer`, `lottie`, `google_fonts`, `flutter_markdown` |
| Localization | `flutter_localizations` + `intl` |

### Backend Server (Node.js + TypeScript)

| Category | Tool |
|---|---|
| Framework | Express.js |
| Database ORM | Prisma (PostgreSQL) |
| **AI / LLM** | **Google Gemini, Groq, OpenAI** |
| Real-time | Socket.IO |
| Auth | JWT + bcryptjs |
| File Uploads | Multer |
| Scheduler | node-cron (news/scheme crawling) |
| Validation | Zod |

---

## Project Structure

```
Farmer/
├── client/               # Flutter Android APK source
│   ├── lib/
│   │   ├── features/     # advisory, auth, chatbot, community, crop_recommendation,
│   │   │                 # disease, home, market, marketplace_new, rental, schemes, weather …
│   │   ├── core/         # Theme, constants, AI services, voice/TTS providers
│   │   ├── shared/       # Reusable widgets
│   │   └── router/       # GoRouter + route names
│   ├── assets/           # Images, icons, onboarding, TFLite models, data
│   └── pubspec.yaml
│
└── server/               # Node.js TypeScript REST + WebSocket backend
    ├── src/
    │   ├── modules/      # advisory, auth, community, disease, market, …
    │   └── socket.ts     # Real-time events
    └── prisma/           # DB schema & migrations
```

---

## Installation — Getting the APK

### Option 1 — Direct Install (Recommended for Farmers)

1. On your Android phone, go to **Settings → Security** and enable **"Install from Unknown Sources"** (or "Install Unknown Apps" for Android 8+).
2. Download the APK file: `app-release.apk`.
3. Tap the downloaded file in your notification bar or file manager.
4. Tap **Install** when prompted.
5. Open **Kisan Saathi** from your app drawer.

> **Minimum Android version:** Android 6.0 (Marshmallow) or higher.  
> **Storage required:** ~80 MB (including on-device AI model).  
> **Permissions needed:** Camera, Microphone, Location, Storage.

### Option 2 — Build from Source (Developers)

```bash
git clone https://github.com/your-username/Farmer.git
cd Farmer/client
flutter pub get
flutter build apk --release
# APK at: build/app/outputs/flutter-apk/app-release.apk
```

---

## Backend Setup (Developers)

```bash
cd server
npm install
cp .env.example .env       # Fill in API keys and DB URL
npx prisma migrate dev
npm run dev                # Server starts on http://localhost:3000
```

Update `client/.env` to point `BASE_URL` to your server's IP/URL.

---

## Using the App — Complete Guide

---

### 1. Onboarding & Authentication

#### First Launch — Onboarding Slides
- On very first open you see a full-screen multislide onboarding carousel.
- Each slide highlights a key feature with an illustration and headline.
- Swipe left to advance or tap **Skip** to go directly to login.

#### Login Screen
- Enter your **Phone Number** (or registered email) and **Password**.
- Tap the **eye icon** to toggle password visibility.
- Check **Remember Me** to stay logged in across sessions.
- Tap **Forgot Password?** to reset credentials.
- Tap **Sign In** — a spinner animates while logging you in.
- If credentials are incorrect, a red snackbar appears at the bottom.
- **Language toggle (EN / HI)** pill button at the top-right changes the app language from the very first screen.

#### Sign Up
- Tap **Create Account** on the login screen.
- Fill in: Full Name, Phone Number, Email, Password (and confirm).
- Select your **role**
- Tap **Register**. An OTP is sent to your mobile number via SMS.
---

### 2. Home Dashboard

The Home screen loads immediately after login and is the central hub.

#### Header / App Bar
- Greets you: *"Namaste, [Your Name] 🙏"* with your live GPS location (district, state) beneath.
- **Profile avatar** (top-left) → opens Profile screen.
- **Bell icon** (top-right) → opens Notifications sheet. A red dot badges unread notifications.
- **Pull down** anywhere on screen to refresh location, weather, and notifications.

#### Live Weather Card
- Large dynamic card with current temperature, condition text (Clear / Rainy / Sunny & Hot / Night), humidity %, rain probability %.
- The background gradient changes automatically: blue for clear day, orange-red for hot, grey for rain, dark indigo for night. A sun or moon icon appears in the corner.
- Tap the card → full **Weather Details** screen.
- If a weather alert is active (cyclone, storm, frost warning), a **red alert banner** appears above the card with an event description and a **View** button.

#### Agriculture Services Grid
- 3-column grid below the weather card: **Crop Price, Crop Advisory, Disease Detection, Schemes, Community, Smart Farming**.
- Tap any tile to navigate directly to that feature.
- Tap **See All** → full-screen draggable bottom sheet listing every service: Marketplace (New), Get Helper (Labour), Warehouse Storage (coming soon).

---

### 3. AI Agri Friend — Voice Chatbot

> **This is a voice-first AI assistant. You never have to type if you don't want to.**  
> Long-press the mic → speak in Hindi or English → AI responds in your language and reads the answer aloud to you.

**Accessing:** Home → See All → AI Agri Friend (or via the Chatbot tile).

#### How to Use — Voice (Recommended)

1. Open the Chatbot screen (header: "Agri Friend / खेती मित्र").
2. **Long-press the microphone button** (bottom-right, green circle). It turns red and pulses — you are now being heard.
3. Speak your question naturally in Hindi or English:
   - *"गेहूं में कौन सी खाद डालूं?"*
   - *"What is the price of onion in Rajasthan today?"*
   - *"मेरी फसल पीली हो रही है, क्या करूं?"*
4. Release the button (or it auto-detects silence). Your words are transcribed and sent automatically.
5. The AI response bubble appears. The app **reads the answer aloud** using Text-to-Speech in the correct language — so low-literacy farmers can use this entirely hands-free.
6. Tap the mic again to ask a follow-up question. TTS is automatically stopped when you start speaking.

> **Tip:** You can also tap (single tap) the mic button to start/stop listening without holding.

#### How to Use — Typing

1. Tap the text input field.
2. Type your question in English or Hindi (Devanagari or Hinglish both work).
3. Tap the **green send arrow** or press Enter.

#### Sending a Photo with Your Question

1. Tap the **paperclip attachment icon** (left of the text field).
2. Choose **Camera** (take a live photo) or **Gallery** (pick existing).
3. A thumbnail preview appears above the input bar. Tap **×** to clear it.
4. Optionally type/speak a message: *"This plant looks sick — what is wrong?"*
5. Send. The AI analyses the image + your text together and responds.

#### Smart Agentic Actions
The AI doesn't just answer — it acts. Examples:
- *"Post my wheat listing"* → AI collects details, shows a confirmation dialog, and posts it to the Marketplace for you.
- *"Open the market prices screen"* → the app navigates there automatically.
- Whenever an action needs confirmation, a popup dialog appears: **Confirm** to execute, **Cancel** to abort.

#### Chat Management
- Tap the **three-dot menu** (top-right) → **Clear Chat** to wipe the conversation.

#### Offline Mode — Online Chat
- A yellow top banner: *"Offline mode — Basic commands available"* appears when there is no internet.
- Basic on-device commands still work. For full AI responses without internet → use **Offline SMS Chat** (see [Offline Mode section](#offline-mode)).

---

### 6. Disease Detection

> **The star feature — the reason this app was built.**  
> Farmers lose crores of rupees because they can't identify crop diseases fast enough. This feature puts an AI crop doctor in every farmer's pocket — even without internet.

**Accessing:** Home Grid → Disease Detection / Home → See All → Disease Detection.

#### How It Works — Two Detection Modes

| Mode | When | Engine | Accuracy |
|---|---|---|---|
| **Cloud AI (Online)** | Phone has internet | Multi-modal LLM (Gemini/Groq) — full diagnosis across all crops | High — full treatment plan, medicine links |
| **On-Device TFLite (Offline)** | No internet | 9 per-crop TFLite models bundled in the APK | **~55–60%** — disease name only, no treatment text |

> **Important:** The on-device offline model supports **9 specific crops** (listed below). For all other crops, or for full treatment advice, an internet connection is required to use the cloud AI.

#### Supported Crops — On-Device Offline Model

The APK ships with **9 dedicated TFLite models**, one per crop, covering **38 disease classes** total:

| Crop | Diseases Detected |
|---|---|
| 🍎 **Apple** | Apple Scab, Black Rot, Cedar Apple Rust, Healthy |
| 🍒 **Cherry** | Powdery Mildew, Healthy |
| 🌽 **Corn / Maize** | Cercospora Leaf Spot (Gray Leaf Spot), Common Rust, Northern Leaf Blight, Healthy |
| 🍇 **Grape** | Black Rot, Esca (Black Measles), Leaf Blight (Isariopsis), Healthy |
| 🍑 **Peach** | Bacterial Spot, Healthy |
| 🫑 **Pepper (Bell)** | Bacterial Spot, Healthy |
| 🥔 **Potato** | Early Blight, Late Blight, Healthy |
| 🍓 **Strawberry** | Leaf Scorch, Healthy |
| 🍅 **Tomato** | Bacterial Spot, Early Blight, Late Blight, Leaf Mold, Septoria Leaf Spot, Spider Mites (Two-spotted), Target Spot, Yellow Leaf Curl Virus, Mosaic Virus, Healthy |

> **Accuracy disclaimer:** The offline on-device model achieves approximately **55–60% accuracy** on field photos. Accuracy improves significantly with clear, close-up photos in good lighting. Cloud AI mode is always recommended when internet is available for a more reliable diagnosis.

#### Step 1 — Open the Screen

The screen opens with a large central illustration, a headline, and two big action buttons. No navigation menus needed.

#### Step 2 — Take or Upload a Photo

| Button | What it does |
|---|---|
| 📷 **Take Photo** (blue) | Opens your camera directly |
| 🖼️ **Upload from Gallery** (pink) | Pick an existing photo from your phone |

**Photography Tips (shown in the rotating Tip Banner):**
- Get close to the affected leaf, stem, or root — fill the frame.
- Use natural daylight — avoid harsh shadows or flash glare.
- Capture the most obvious / worst-affected part of the plant.
- Take multiple photos from different angles if unsure.

#### Step 3 — Select Your Crop (Optional but Recommended)

After the photo is loaded, a **Crop Selector** dropdown appears:
- Tap it → a bottom sheet opens with a searchable list of all crops.
- Tap your crop name.
- **Selecting the correct crop routes the image to the right model** (online or offline) for better accuracy.

#### Step 4 — Analyse

Tap the large green **Analyse** button (brain icon). A full-screen animated **"Analysing your crop…"** overlay appears while the AI works:
- **Online mode:** image + crop type + language → sent to cloud AI → full multi-modal diagnosis.
- **Offline mode:** image → run through on-device TFLite model for the selected crop → instant local result.
- Cloud processing takes 5–15 seconds. On-device is near-instant.

#### Step 5 — Read the Disease Result Card

The result card appears with complete diagnosis:

| Section | What it contains |
|---|---|
| **Disease Name** | In both English and Hindi (e.g., "Late Blight / पछेती झुलसा") |
| **Confidence** | AI confidence as a percentage |
| **Severity** | Low / Moderate / Severe — color-coded badge |
| **Causes** | Root causes (fungal, bacterial, pest, weather, etc.) |
| **Symptoms** | Visual signs to confirm the diagnosis |
| **Treatment Plan** | Numbered step-by-step treatment (spray name, dosage, schedule) |
| **Preventive Measures** | How to prevent recurrence next season |
| **Buy Medicine** | Tappable cards → browser links to purchase exact medicines/pesticides |

> All text is rendered in your selected language — Hindi or English.

#### Step 6 — Retake or View Past Reports

- Tap **Retake** on the result card to clear and analyse a new photo.
- Scroll below the result to see **Past Reports** — all your previous analyses with date, crop, disease, and severity. Tap any past report to review it in full.

---

### 5. AI Crop Recommendation (Smart Farming)

**Accessing:** Home Grid → Smart Farming.

**What it does:** Combines live GPS-based weather, your soil type, and real-time mandi prices to tell you **exactly which crop will give you the most profit right now** — ranked by the AI.

#### How to Use

1. Open the screen (header: "AI Crop Advisor / AI फसल सलाहकार").
2. **(Optional)** Tap **Select Crops** → pick up to **8 crops** you're interested in from the visual emoji grid picker. The AI uses your preference to bias its recommendations.
3. Tap **Get AI Recommendation** (large green button). The AI:
   - Fetches your GPS location and identifies your district/state.
   - Pulls live weather data (temperature, humidity, rain chance).
   - Queries current mandi prices for your area.
   - Runs all of this through the AI to generate ranked recommendations.

#### Understanding the Results

**Location & Soil Card**
- Your district + state auto-detected from GPS.
- Soil type detected for your region.
- Current season badge (Kharif / Rabi / Zaid).

**Weather Strip**
- Three pill chips: Temperature, Humidity %, Rain % — showing the conditions the AI used.

**Ranked Crop Cards** (one card per recommended crop)
- **#1, #2, #3 …** rank badge.
- **Demand Level** tag (High / Moderate / Low demand in market).
- Current **Mandi Price** for that crop.
- **Risk Level** chip — green (Low), orange (Medium), red (High).
- **Reason** — why this crop matches your soil, weather, and market this season.
- **Cost vs Profit per acre** — estimated input cost and expected gross profit.

**AI Guidance Summary**
- A soft green card at the bottom with an overall AI narrative summary covering all recommendations together.

---

### 4. Crop Advisory

**Accessing:** Home Grid → Crop Advisory.

**What it does:** Provides textbook-quality crop advisory answers powered by AI — tailored to your specific inputs.

#### How to Use

1. Fill in the **Advisory Form**:
   - **Crop Name** — the crop you are growing.
   - **Soil Type** — Loamy, Sandy, Clay, Black Cotton, Red, etc.
   - **Season** — Kharif / Rabi / Zaid.
   - **Problem / Query** — describe your issue in Hindi or English (e.g., *"मेरी गेहूं की पत्ती पीली क्यों हो रही है?"* or *"When should I apply nitrogen fertilizer for paddy?"*).
2. Tap the **Get Expert Advice** button (green, sparkle icon). A spinner shows while the AI generates the response.
3. **Recommendation Cards** appear below — each card shows:
   - The primary recommendation / action step.
   - Detailed explanation in your selected language.
4. Scroll down for multiple recommendation cards covering different aspects of your query.

---

### 7. Market Prices (Mandi Bhav — बाज़ार भाव)

**Accessing:** Home Grid → Crop Price.

**What it does:** Shows real-time commodity prices from **Agmarknet mandis** (official government database) across India.

#### How to Use

1. Open the screen.
2. **Three filter selectors** (illustrated pill cards):
   - **Select Crop** → tap to pick a commodity (Wheat, Rice, Onion, Tomato, Sugar, Cotton, etc.).
   - **State** → pick your state from the full list.
   - **District** → narrow to a specific district (optional).
3. Tap the green **Search Prices** button.
4. Each **Price Card** shows:
   - Commodity name + Market (mandi) name.
   - District, State.
   - Three price badges: **औसत (Average)** in blue, **न्यूनतम (Min)** in orange, **अधिकतम (Max)** in green — all in ₹ per unit (Quintal / Kg).

---

### 8. Marketplace

**Accessing:** Home → See All → Marketplace (New).

**What it does:** Direct farmer-to-buyer trading — sell your produce, buy from other farmers, post demands, make offers. **No middlemen. No commission.**

#### Key Actions

| Action | How |
|---|---|
| **List Your Harvest** | Tap → fill item name, quantity, unit, price, photo, location → Post |
| **Browse Produce** | Scroll listings from all farmers → tap any → make offer or buy |
| **Post a Demand** | Tell the market what you need at what price → sellers will offer |
| **Browse Demands** | See what buyers need → submit a supply offer |
| **Place a Bid** | Bid on any listed item at your price |
| **My Listings** | Manage your active and past postings |
| **Purchase Requests** | See who wants to buy your listings; accept or decline |
| **Supply Offers** | See offers received on your demand posts; accept the best |

**Featured Items** and **My Demands** horizontal scrolls are shown on the home dashboard for quick access.

---

### 9. Equipment Rental

**Accessing:** Marketplace Home → toggle to **Rental** tab.

**What it does:** Peer-to-peer rental marketplace for farm equipment — tractors, threshers, harvesters, sprayers, and more.

- **Browse Rentals** — scroll available equipment with photo, daily price, owner location.
- Tap any item → detail screen with specs, availability calendar, owner info, mini-map location.
- Tap **Request Rental** → specify date range → owner gets notified.
- **Post Rental Asset** → list your own equipment: name, type, photo, price/day, availability dates, GPS location.
- **My Rental Activity** → view all your rental requests and equipment enquiries.

---

### 10. Farmer Communities

**Accessing:** Home Grid → Community.

**What it does:** Location-based farmer groups with real-time chat and resource sharing.

- App auto-detects GPS and shows **communities near you**.
- Tap **Create** (green button, bottom-left) → create a new community with a name and description. You become admin.
- Tap **Join** (bottom-right) → tapping any community card sends a join request to its admin.
- Tap a community you belong to → **Community Chat** screen with real-time messaging (Socket.IO).
- **Admins** see a **Join Requests** panel to accept or decline new members.
- Pull to refresh the community list.

---

### 11. Government Schemes & News

**Accessing:** Home Grid → Schemes.

#### Schemes Tab (Default)
- Lists all active central + state government schemes (PM-KISAN, PMFBY, KCC, Kisan Credit Card, subsidies, etc.).
- **Search bar** — type any keyword to filter in real time.
- **Category filter chips** (horizontal scroll): All, Seeds, Insurance, Subsidy, Loan, Training, Equipment. Tap to filter.
- Tap any scheme card to see full details + official link (opens in browser).

#### News Tab
- Tap **News** tab (newspaper icon) to see live agriculture news fetched from RSS feeds.
- Search bar filters news by title, content, or source.
- Tap any news card to open the full article in your browser.

---

### 12. Weather Details

**Accessing:** Tap the Home weather card or the alert banner → View.

- Current temperature, feels-like temp, humidity, wind speed and direction, UV index, visibility.
- Rain probability + precipitation amount.
- **7-day forecast** — horizontal scroll of day cards.
- **Hourly forecast** for today.
- **Weather Alerts** — storm, cyclone, frost warnings shown as red alert cards with severity level and full description.
- All data is fetched from your real GPS coordinates.

---

### 13. Notifications

**Accessing:** Home → Bell icon (top-right).

- A slide-up sheet listing all notifications in reverse chronological order.
- Unread notifications show a colored dot.
- **Types:** marketplace updates (offer accepted, new purchase request), community approvals, AI analysis done, system announcements.
- Tap any notification to jump to the relevant screen.
- All notifications are marked read when you open the sheet.

---

### 14. Profile & Settings

**Accessing:** Home → Profile avatar (top-left circle).

- View name, phone number, email, role.
- **Language Toggle** — switch between **English** and **Hindi**. The entire app (all screens, buttons, AI responses) instantly re-renders in the chosen language.
- **Edit Profile** — update name, email, notification preferences.
- **Logout** — logs out and returns to the Onboarding / Login screen.

---

## User Roles

| Role | Home After Login | Key Access |
|---|---|---|
| **Farmer** | Full feature home dashboard | All features: market, disease, advisory, marketplace, communities, schemes, chatbot |
| **Labour** | Labour job listings home | Browses and applies for seasonal farm labour jobs |

Role is set at signup and stored in the JWT. The router redirects automatically.

---

## Language Support

Every screen in the app is **fully bilingual**:

- 🇬🇧 **English** (default)
- 🇮🇳 **हिन्दी / Hindi**

This includes: all buttons, labels, headers, error messages, AI chatbot responses, disease diagnoses, crop recommendations, scheme descriptions, and advisory cards.

**Switch any time:** Login screen EN/HI toggle → or Profile → Language.  
Preference is persisted locally — the app remembers your choice.

---

## Offline Mode

Kisan Saathi is designed to keep working even where mobile data is unavailable or extremely slow.

### Offline SMS Chat — Full AI via SMS

This is the most powerful offline feature. Even with zero internet, farmers can still get AI answers — **through SMS**.

**How it works (end-to-end):**
1. The app detects no internet connection.
2. The main chatbot shows a yellow *"Offline mode"* banner.
3. The user switches to the **Offline SMS Chat** screen (SMS mode icon).
4. Type your farming question and tap Send.
5. The app **silently and automatically sends your question as an SMS** to the server's registered number — no manual SMS composing needed.
6. The server receives the SMS, processes it with AI, and **SMS-replies the answer** back to the phone.
7. The reply appears automatically as an assistant message bubble inside the app — same chat UI as the online chatbot.
8. Chat history is **persisted locally** (`SharedPreferences`) so you can review past conversations even after closing the app.

**SMS Encoding (technical):** To fit as much information as possible into a single SMS (160 chars), the app uses a custom multi-tier codec (`smscodec.standard.py` / server-side TypeScript mirror):
- Short messages (< 100 bytes, ASCII-only) → **SMAZ compression** (English text-optimised dictionary codec).
- Hindi / non-ASCII short messages → sent as raw UTF-8.
- Long messages (> 100 bytes) → **DEFLATE (zlib, raw) compression**.
- All compressed payloads are encoded to text using **Base91** (higher density than Base64).

This allows a full farming question like *"What fertilizer should I use for wheat at the tillering stage?"* to fit in a single SMS.

### On-Device Disease Detection (Offline)

- The APK bundles **9 TFLite models** (one per crop) using `tflite_flutter`.
- When there is no internet, disease detection falls back to local inference.
- Supports: Apple, Cherry, Corn/Maize, Grape, Peach, Pepper, Potato, Strawberry, Tomato.
- **Accuracy: ~55–60%** on real field photos. No treatment text in offline mode — disease name only.
- Full treatment advice requires cloud AI (internet connection).

### Other Offline Behaviours

- **AI Chatbot (online mode):** yellow banner appears; basic commands work.
- **Cached data:** last fetched weather readings and market prices remain visible from the previous successful load.

---

## Environment Variables

### Server (`server/.env`)

```env
DATABASE_URL=postgresql://user:password@host:5432/kisansaathi
JWT_SECRET=your_jwt_secret_here
GEMINI_API_KEY=your_google_gemini_key
GROQ_API_KEY=your_groq_key
OPENAI_API_KEY=your_openai_key
PORT=3000
```

### Client (`client/.env`)

```env
BASE_URL=http://YOUR_SERVER_IP:3000
```

---

<p align="center">
  Built with ❤️ for every Indian farmer — <em>Jai Kisan 🌾</em>
</p>
