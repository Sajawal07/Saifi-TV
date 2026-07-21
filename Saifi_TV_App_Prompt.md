# Saifi TV — Flutter App Development Prompt

## App Overview
Build a Flutter mobile app named **"Saifi TV"** (Play Store listing name: **"Saifi TV – Islamic Videos"**) — a comprehensive Ahl-e-Sunnat wal Jamaat Islamic app offering Naats, Bayanat, Quran (with audio, text, and translation), Prayer Times, Hadith, a Sufi Zikr Counter, and other daily-use Islamic tools. Monetization is via Google AdMob (banner/interstitial ads placed in UI only — never overlaying or interrupting audio/video playback). Shop, Affiliate, and Donations are planned for a future phase once the app has an established active user base — these are NOT part of the initial build.

---

## Content Sections (Core — build these first)

### A. Naats Section (Permission-Based YouTube Embed)
- Naats from YouTube channels where the channel owner has given explicit permission to embed their content.
- Fetch video lists via YouTube Data API v3 from specific channel IDs/playlist IDs (owner-approved channels only, maintained via editable config/Firestore list — not scraped indiscriminately).
- Embed using `youtube_player_flutter` or `youtube_player_iframe` (official player only — never download/rehost/strip audio).
- **Ad rule:** No custom ads on/over the YouTube player. AdMob ads only in surrounding UI (list/home screens).
- Show channel/creator credit (native YouTube player attribution — never hidden).
- Push notification triggered (via Firebase Cloud Messaging + Cloud Function) whenever a new approved Naat is added to Firestore.

### B. Bayanat Section
- Same method as Naats section: permission-based YouTube embed from approved scholars/channels, own Firestore-managed list, same ad placement rules, same notification trigger on new upload.

### C. Quran Section (Free Public API + Text + Translation + Counter)
- Audio: fetch from a free, open-use Quran audio API (e.g. alquran.cloud, quran.com API) — reciter selectable if supported.
- Text: Arabic Quran text + translation (Urdu/English) fetched from the same or a complementary free Quran text API.
- Audio player: `just_audio` or `audioplayers`, with background playback support.
- **Ad rule:** Interstitial/banner ads only BEFORE or AFTER playback — never during active recitation.
- Display reciter name/credit on the player screen.
- **Khatam Counter (separate from Zikr Counter):** On each Surah's screen and on a "Whole Quran" tracking screen, include a **"+1 / Mark as Read"** manual button that lets the user log each time they complete reading/reciting that Surah or the full Quran (e.g. tracking repeated reading of Surah Yaseen). Counts stored in local storage (`hive`/`shared_preferences`), shown as a running tally per Surah and a lifetime total.

### D. Daily Hadith
- Pulled from a free, authentic Hadith API (verify source is Sahih Bukhari/Muslim or similarly authentic collections).
- One Hadith displayed per day (rotating), with option to browse past/all Hadith by category.

### E. Zikr Counter (Lataif-e-Sitta — Naqshbandi Tradition)
A dedicated tasbeeh/counter screen cycling through the seven Lataif points, following the Naqshbandi tradition associated with the app's Ahl-e-Sunnat wal Jamaat identity:

| # | Latifa | Location | Color (screen background) | Associated with |
|---|--------|----------|---------------------------|------------------|
| 1 | Qalb | Two fingers below left nipple | Zardi/Yellow | Hazrat Adam (A.S) |
| 2 | Ruh | Two fingers below right nipple | Red | Hazrat Nooh & Hazrat Ibrahim (A.S) |
| 3 | Sirri | Above the Qalb point | White | Hazrat Musa (A.S) |
| 4 | Khaffi | Above the Sirri point | Black | Hazrat Isa (A.S) |
| 5 | Akhfa | Middle of the chest | Green | Hazrat Muhammad (SAW) |
| 6 | Nufs | Forehead | White | Divine Light (Noor) |
| 7 | Sultan-ul-Azkar | Top center of the head | Golden-White Noor | Divine Light (Noor) |

- **Separate category (not part of the 1-7 sequence):** Nafi Asbat — لَا إِلٰهَ إِلَّا اللّٰه — its own counter screen/category, own target-count option (same 100/500/manual system as below).
- On each Lataifa's counter screen: show the **Latifa name and its color as the full screen background**, large tap-to-count button in the center.
- **Vibration on every single count** (using `vibration` or `haptic_feedback` package).
- **Target selection:** user can pick a preset target (100, 500) or enter a manual custom number before starting.
- All counts (per Latifa, per session, and cumulative) saved to local storage.

---

## Utility Features (build alongside core sections)
- **Prayer Times** — location-based, using a free Prayer Times API (e.g. Aladhan API).
- **Qibla Compass** — device compass + coordinates.
- **Islamic (Hijri) Calendar** — using a Hijri calendar package/API.
- **Favorites** — bookmark any Naat, Bayan, Surah, or Hadith (local storage).
- **Continue Listening** — resume playback position across Naats/Bayanat/Quran (local storage).
- **Search** — unified search across Naats, Bayanat, Quran, and Hadith sections.
- **Notifications** — Firebase Cloud Messaging push alert whenever a new Naat or Bayan is uploaded/approved.

## Planned for Later Phase (show as "Coming Soon" placeholder in UI for now — do not build backend logic yet)
- **Islamic Shop** — affiliate product catalog (partner sellers, "Buy Now" opens seller site via `url_launcher`, mandatory affiliate-disclosure text).
- **Donations** — deferred until proper legal/organizational registration is in place (Play Store donation policy compliance required before enabling).
- ~~Premium Features~~ — removed from scope entirely, not included even as a placeholder.

---

## General App Requirements
- **App Name (in-app):** Saifi TV
- **Play Store Listing Name:** Saifi TV – Islamic Videos
- **Framework:** Flutter (latest stable version)
- **Navigation:** Bottom navigation bar or drawer menu covering: Home | Naats | Bayanat | Quran | Zikr Counter | Prayer Times | Qibla | Calendar | Hadith | Favorites | Search (grouped/organized sensibly — not all as top-level tabs; use a Home dashboard linking to less-frequent sections)
- **Extra features to avoid "thin wrapper app" rejection on Play Store:**
  - Category-wise sorting (e.g. Ramzan Special, Milad, Reciter/Scholar-wise)
  - Background audio playback with notification controls
  - Dark mode / light mode toggle
  - Share button (share a Naat/Bayan/Surah link with others)
- **Monetization:** Google Mobile Ads SDK (`google_mobile_ads` package) — banner ads on list/home screens, interstitial ads between screen transitions (never during playback, never overlapping YouTube embeds, never during Zikr counting).
- **Backend:** Firebase (Firestore for content metadata/approved channel lists, Firebase Cloud Messaging for notifications, Firebase Storage if any owned/licensed audio is hosted directly).
- **Local Storage:** `hive` or `shared_preferences` for Favorites, Continue Listening, Zikr/Khatam counts, and user preferences (dark mode, etc.).
- **Compliance notes for developer:**
  - Do not download or rehost YouTube video/audio content — use official embed only.
  - Do not use any content without verified permission or license.
  - Include a Privacy Policy and Terms of Use screen (required for Play Store submission, especially with ads).
  - Include a content takedown/contact mechanism in case a rights holder requests removal.

---

## Deliverable
A complete, well-structured Flutter project with:
- Clean folder structure (`/lib/screens`, `/lib/models`, `/lib/services`, `/lib/widgets`)
- Working navigation between all sections listed above, including a "Coming Soon" placeholder for Shop
- API/Firebase integration points clearly set up (with placeholder keys/config to be filled in)
- AdMob integration scaffolded per the placement rules above
- Zikr Counter screens with correct per-Latifa background colors, vibration on tap, and target-count selection as specified above
- Clean, mobile-friendly UI with an Islamic-themed color palette (greens/golds suggested) for general screens, while Zikr Counter screens use their specific Latifa colors as described
