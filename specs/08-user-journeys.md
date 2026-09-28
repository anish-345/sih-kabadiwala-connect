# 08 — User Journeys
## Kabadiwala Connect · SIH 2026 · PS 26229

---

## 1. Personas

### Persona A — Ramesh (Collector)
- Age 34, itinerant kabadiwala, Nagpur
- Travels 25 km/day on a cycle with a weighing scale
- Hindi speaker, can read numbers but not English
- Uses a ₹8,000 Redmi 9A, 2 GB RAM, intermittent 4G
- Current pain: doesn't know EPR prices, sells at ₹50/kg for PCB vs fair ₹158/kg

### Persona B — Priya (Aggregator / Recycler staff)
- Age 28, works at GreenTech Recyclers, Nagpur
- Manages 10–20 collector drop-offs per day
- Needs to issue compliant receipts for EPR portal
- Uses an office Android tablet

---

## 2. Journey 1 — Onboarding (First Launch)

```
Screen 1 — Splash (1.5 s)
  Logo + tagline "कबाड़ी की कमाई बढ़ाएं"

Screen 2 — Language Picker
  3 large tiles: हिन्दी | मराठी | English
  Voice prompt plays: "अपनी भाषा चुनें"

Screen 3 — Role Picker
  2 tiles with icons: "मैं कबाड़ी हूँ" (collector) | "मैं रिसाइकलर हूँ" (recycler)

Screen 4 — Phone Number
  Large number pad
  Voice prompt: "अपना मोबाइल नंबर डालें"

Screen 5 — OTP Verify (6-digit)
  Auto-read SMS OTP via SMS Retriever API

Screen 6 — Walkthrough (3 swipe cards, pictorial)
  Card 1: Photo + scan icon → "अपना कबाड़ फोटो खींचें"
  Card 2: Rupee icon      → "सही दाम जानें"
  Card 3: QR code icon    → "रसीद लें"

Screen 7 — Home (collector dashboard)
```

**Error states:**
- Invalid phone → inline error in red, Hindi message
- OTP wrong → shake animation, retry, 3 attempts then 60-second lockout

---

## 3. Journey 2 — Material Capture & Lot Creation (Collector)

```
Tap "स्कैन करें" FAB (camera icon, large)
  ↓
Camera opens (full screen, CameraX preview)
  TFLite runs every 500 ms on preview frames
  Live bounding box overlay in category colour
  Label appears: "PCB ✓ 87%"
  ↓
Collector taps shutter button (large, accessible 60 dp)
  Photo captured, inference freezes on captured frame
  ↓
Screen — "वजन डालें" (Enter Weight)
  Large numpad with decimal
  OR tap mic icon → Bhashini STT → "ढाई किलो" → parsed as 2.5 kg
  Unit shown: किलो (kg)
  ↓
Density fraud check runs locally (< 5 ms)
  If WARNING: yellow banner "असामान्य वजन — जाँचें"
  If FLAG: orange dialog, collector confirms
  ↓
Screen — Price Preview
  Shows a card:
  ┌────────────────────────────────┐
  │  PCB (पीसीबी)                  │
  │  वजन: 2.5 kg                   │
  │  बाज़ार दर: ₹80/kg              │
  │  EPR बोनस: ₹33.60/kg           │
  │  NCMM प्रोत्साहन: ₹5/kg         │
  │  ══════════════════════════    │
  │  अनुमानित मूल्य: ₹296.50        │
  └────────────────────────────────┘
  TTS plays: "आपके पीसीबी का अनुमानित दाम दो सौ छियानवे रुपये पचास पैसे है"
  ↓
"पास के रिसाइकलर" button → map/list of nearby recyclers
  ↓
"लॉट बनाएं" (Create Lot) button
  Lot saved to Drift DB + outbox entry
  Unique lot ID generated: LOT-YYYYMMDD-XXXXXX
  QR generated (ECDSA signed)
  ↓
Screen — QR Display
  Large QR on white background
  Lot ID printed below in large font
  Share button (WhatsApp/SMS/PDF)
  "रिसाइकलर को दिखाएं" instruction
```

**Accessibility notes:**
- All labels in 18 sp minimum
- Touch targets ≥ 48 dp
- Voice feedback for every main action
- Works with Android TalkBack

---

## 4. Journey 3 — Price Board (Collector, offline capable)

```
Tap "भाव बोर्ड" (Price Board) bottom nav
  ↓
Screen — Price Board
  Heading: "आज के भाव" with last-updated timestamp
  
  Category filter row (horizontal scroll):
  [सभी] [इलेक्ट्रॉनिक्स] [प्लास्टिक] [धातु] [कागज]
  
  Price cards (2 per row):
  ┌──────────┐  ┌──────────┐
  │ PCB      │  │ तांबा    │
  │ ₹158/kg  │  │ ₹480/kg  │
  │ ↑ ₹5     │  │ → स्थिर  │
  └──────────┘  └──────────┘
  
  Tap any card → detail screen:
    7-day sparkline chart (fl_chart)
    Informal vs formal rate comparison bar
    EPR credit breakdown
    "यह दाम CPCB से लिया गया है" source label
  
  Mic button at bottom:
    Voice query: "पीसीबी का क्या दाम है?"
    TTS response: "पीसीबी का आज का दाम एक सौ अठावन रुपये प्रति किलो है"
```

**Offline behaviour:** Price board loads from Drift cache (stale timestamp shown in amber). Sync happens automatically when network restores.

---

## 5. Journey 4 — Recycler Matching

```
From price preview screen OR main screen:
Tap "रिसाइकलर खोजें" (Find Recycler)
  ↓
Screen — Nearby Recyclers
  Map view (Google Maps or OSM) with green pins
  List view toggle
  
  Each recycler card:
  ┌────────────────────────────────────┐
  │ GreenTech Recyclers                │
  │ ✓ CPCB प्रमाणित                    │
  │ 3.2 km दूर  ·  ★ 4.5              │
  │ PCB, प्लास्टिक, धातु               │
  │ पिकअप उपलब्ध  ·  UPI / नकद        │
  │ [संपर्क करें]  [लॉट भेजें]          │
  └────────────────────────────────────┘
  
  Sort options: दूरी | रेटिंग | सर्वोत्तम दाम
  Filter: पिकअप उपलब्ध | आज खुला है
  
  Tap "लॉट भेजें":
    Select pending lots (checkbox list)
    Notification sent to recycler via FCM
    Transaction status → QUOTED
```

---

## 6. Journey 5 — Handover & QR Verification (Recycler)

```
Recycler opens app (Recycler Mode)
  ↓
Dashboard shows pending handovers with count badge
  ↓
Tap "नया हस्तांतरण" (New Handover) OR tap notification
  ↓
Screen — Scan Collector QR
  Camera opens in full screen
  Mobile scanner scans QR
  ↓
Signature verified (pointycastle ECDSA) — < 30 ms
  
  If VALID:
    Green checkmark animation
    Show lot details:
      Collector ID (masked phone)
      Material: PCB · 2.5 kg · Grade B
      Quoted: ₹296.50
      Generated: 12 min ago · Nagpur
    
  If EXPIRED (> 24 h):
    Red × — "QR कोड की अवधि समाप्त हो गई है"
    Instruct collector to generate new QR
    
  If INVALID signature:
    Red alert — "QR कोड असत्य है — रुकें"
    Log fraud event, do not proceed
  ↓
Dual-Custody Photo Step
  Screen split: "अपना फोटो लें" (Take your photo)
    Recycler camera opens
    Captures recycler + material + collector in frame
    GPS + timestamp embedded in Exif
  ↓
  "अब कलेक्टर का फोटो लें" (Now take collector's photo)
    Recycler points camera at collector
    Collector holds up the QR screen (QR visible in photo)
  ↓
Weight Confirmation
  Recycler enters actual scale reading
  If > 20% deviation from collector's estimate:
    Yellow alert: "वजन में अंतर — कृपया जाँच करें"
  ↓
Tap "हस्तांतरण की पुष्टि करें" (Confirm Handover)
  Traceability record written (trace_id, QR hash, photos, location)
  Transaction → VERIFIED
  Payment selector:
    [नकद] [UPI] [बैंक ट्रांसफर]
  ↓
Payment screen:
  UPI deeplink opens (PhonePe/BHIM)
  OR cash amount displayed with ✓ button
  ↓
Transaction → COMPLETED
  Push notification to collector: "₹296.50 मिले — GreenTech Recyclers से"
  EPR cert trigger sent to backend
  Handover receipt PDF generated (downloadable)
```

---

## 7. Journey 6 — Earnings Ledger (Collector)

```
Tap "कमाई" (Earnings) bottom nav
  ↓
Screen — Earnings Ledger
  
  Summary cards:
  ┌──────────────┐  ┌──────────────┐
  │ इस महीने     │  │ कुल कमाई    │
  │ ₹1,240       │  │ ₹18,450     │
  └──────────────┘  └──────────────┘
  
  Transaction list (reverse chronological):
  Each row:
  ✅ PCB · 2.5 kg · ₹296.50 · 28 Sep · GreenTech
  ⏳ तांबा · 1.2 kg · ₹576 · 27 Sep · Pending
  ✅ प्लास्टिक · 5 kg · ₹225 · 25 Sep · EcoRecycle
  
  Status icons:
  ✅ = COMPLETED   ⏳ = PENDING   ❌ = CANCELLED
  
  Tap row → transaction detail (lot photos, QR hash, recycler info, EPR cert ID)
```

---

## 8. Journey 7 — Safety Guide

```
Tap "सुरक्षा" (Safety) in nav or settings
  ↓
Screen — Safety Guide
  
  6 hazard tiles (pictorial, 2×3 grid):
  
  🔥 केबल जलाना     — "खतरनाक: कभी न जलाएं"
  ⚗️ एसिड लीचिंग   — "ज़हरीला: केवल प्रमाणित रिसाइकलर"
  🔋 बैटरी           — "छेदें या जलाएं नहीं"
  📺 CRT मॉनिटर     — "सीसा / कांच — सावधानी से रखें"
  💻 PCB             — "साबुन से हाथ धोएं"
  🧤 सुरक्षा         — "दस्ताने + मास्क पहनें"
  
  Tap any tile:
    Full-screen card with:
    • Pictogram (SVG illustration)
    • 2-sentence text (Hindi / Marathi)
    • Audio button → Bhashini TTS plays guidance
    
  "सुरक्षित अभ्यास" footer button → links to CPCB guidelines PDF
```

---

## 9. Journey 8 — Recycler Dashboard (Tablet/Web)

```
Login → Recycler dashboard (Flutter Web or tablet)
  ↓
KPI bar:
  Today: 12 handovers · 45.2 kg · ₹6,840 · 3 pending
  
Pending Handovers tab:
  Table: Collector | Material | Weight | Quoted | Time | Action
  [Verify] [Reject]
  
Completed tab:
  Table with EPR cert IDs
  Download EPR CSV button
  
Analytics tab:
  Bar chart: kg by category (last 7 days)
  Line chart: payout per kg trend
  Map: collector origin heatmap
  
Price Management tab (admin only):
  CRUD price feed per category × region
  Bulk CSV import
```

---

## 10. Edge Cases & Error States

| Scenario | Handling |
|----------|----------|
| No network during lot creation | Save locally, sync later via WorkManager |
| Camera permission denied | Permission rationale dialog with pictogram |
| Bhashini API down | Fall back to text input, show keyboard automatically |
| TFLite model load failure | Show manual category picker (6 tiles) |
| QR expired | "नया QR बनाएं" button, old one invalidated |
| Recycler rejects lot | Rejection reason shown, collector notified |
| Battery < 15% during scan | Low-battery warning, save draft before close |
| Weight entry = 0 | Validation: "वजन 0 नहीं हो सकता" inline error |
| Duplicate image hash | "यह लॉट पहले से बना है" — prevents double submission |

---

**Status:** ✅ Ready for screen-by-screen UI implementation
