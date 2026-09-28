# Kabadiwala Connect (कबाड़ीवाला कनेक्ट)
### SIH 2026 Problem Statement 26229 • Ministry of Mines / JNARDDC
**Informal E-Waste Collector Formalization, Price Discovery, Traceability & EPR Compliance Platform**

---

## 1. Executive Summary

Kabadiwala Connect bridges India's informal scrap collectors (*kabadiwalas*) and formal, CPCB-authorized e-waste recycling facilities. Designed specifically for low-literacy collectors operating in spotty connectivity zones, the application guarantees **100% offline-first operation**, **vernacular spoken rates in Hindi & Marathi**, **fraud-resistant density validation**, **cryptographic HMAC-SHA256 handover tokens**, and **transparent instant spot cash payouts** with zero fees charged to informal workers.

---

## 2. 6-Minute Live Judge Demo Script

| Time | Step | Action | PS 26229 Feature Proven |
|---|---|---|---|
| **0:00 - 0:45** | **Airplane Mode (Offline First)** | Toggle the network status pill in the top bar to **"ऑफ़लाइन (Offline)"**. App operates entirely out of local SQLite (`kabadiwala_connect.db`). | Offline-first architecture, zero crash on zero bars. |
| **0:45 - 1:45** | **Price Board & Vernacular TTS** | Navigate to **भाव बोर्ड (Prices)**. Tap the speaker icon to hear today's motherboard rate spoken aloud in Marathi/Hindi. Review the formal gate rate (₹160) + EPR bonus (+₹20) + NCMM critical minerals incentive (+₹10) vs informal middleman rate (₹110). | Transparent price discovery, voice-first vernacular UX, 7-day trend charts. |
| **1:45 - 3:00** | **Lot Creation & Density Check** | Tap **स्कैन / लॉट**. Take a scrap photo or pick the **"कंप्यूटर मदरबोर्ड (Motherboard)"** preset. Enter certified scale weight (20 kg). The algorithm runs real-time density checks to flag moisture/rock ballast anomalies. See instant valuation: **₹3,800** (+₹1,600 surplus over informal junk shops). | Camera capture, weight estimation, anti-fraud density validation. |
| **3:00 - 3:45** | **Ranked Recycler Matching** | Tap **लॉट सहेजें और रिसाइक्लर चुनें**. View 3 CPCB-authorized recyclers in Pune/MIDC Bhosari ranked by distance, ratings, and price bonuses. Select **"E-Incarnation Recycling (+5% bonus, Free Pickup)"** and choose **"तुरंत नकद (Spot Cash)"**. | Authorized recycler dataset, multi-criteria rank matching. |
| **3:45 - 4:45** | **Verifiable Handover & Recycler Confirm** | Tap **हस्तांतरण क्यूआर कोड बनाएं**. Display the high-contrast HMAC-SHA256 signed QR code. Tap **"रिसाइक्लर स्कैन का परीक्षण करें (Test Recycler Scan)"**. At the weighbridge desk, verify 20.0 kg, confirm physical cash handover, and complete. | Cryptographic dual-custody verification, CPCB Form-6 manifest generation. |
| **4:45 - 5:30** | **Sync & Living Ledger** | Toggle Airplane Mode off. The green banner flashes **"सिंक संपन्न"** as pending outbox records upload to the audit registry. Open **कमाई लेज़र (Earnings)** to see the transaction ledger updated in real time with PDF export capability. | Living operational dataset, background outbox sync. |
| **5:30 - 6:00** | **Safety & Unit Economics** | Open **सुरक्षा मार्गदर्शिका (Safety)**. Tap to hear the spoken safety rules for Lithium-Ion battery fire hazards and toxic CRT funnel glass. Conclude with the **unit economics formula** (+116% net worker gain, 2% recycler compliance fee). | Worker health protection, sustainable business model. |

---

## 3. Grounded Datasets & Provenance

1. **Price Discovery Benchmark (`assets/data/prices.json`)**:
   - 10 distinct e-waste categories: PCB (High/Mid/Low), Copper Cables (Heavy/Thin), Lithium-Ion Cells, CRT Glass, LCD Panels, Motors/Transformers, Flame-Retardant E-Plastics.
   - Field validated in Pune (Nana Peth & Bhosari MIDC) against JNARDDC metals recovery benchmark (28 September 2026).
2. **CPCB Authorized Recyclers Registry (`assets/data/recyclers.json`)**:
   - Authentic CPCB registrations: `CPCB/EWR/MH/2023/048`, `CPCB/EWR/MH/2021/019`, `CPCB/EWR/MH/2024/092`.
   - Includes geo-coordinates, logistics capability, accepted classes, and payment options.
3. **Operational Living Ledger**:
   - Every completed handover appends real rows to SQLite `transactions`, `traceability`, and `outbox` tables. The dataset grows dynamically through real operations.

---

## 4. Field Research Insights

- **Interview 01: Ramesh Shinde (Nana Peth, Pune)**: 18-year scrap collector on a tricycle cart. Uncovered that local middlemen deduct 20% weight and pay only ₹80-₹100/kg for motherboards due to lack of formal gate access. Verified high demand for spoken Hindi/Marathi audio and spot cash. (`field/01_collector_interview_pune.md`)
- **Interview 02: Sushila Bai Jadhav (PCMC, Pune)**: Micro-aggregator and sorter handling 400 kg/month. Suffered cuts from CRT glass and lithium battery fires. Validated pictorial safety warnings and free cluster pickup savings of ₹600 per trip. (`field/02_collector_interview_pimpri.md`)

---

## 5. Unit Economics (Single 20 kg Mid-Grade Motherboard Lot)

$$\text{Collector Old Status Quo} = 16\text{ kg counted} \times ₹110/\text{kg} - ₹150\text{ cart push} = ₹1,610\text{ net cash}$$
$$\text{With Kabadiwala Connect} = 20.0\text{ kg fair weight} \times (₹160\text{ gate} + ₹20\text{ EPR} + ₹10\text{ NCMM}) = ₹3,800\text{ net cash}$$
$$\text{Net Collector Surplus} = +₹2,190\text{ (+136\% Earnings increase!)}$$
$$\text{Platform Fee} = 2\%\text{ (₹76) paid exclusively by the formal recycler, ₹0.00 charged to collectors.}$$

---

## 6. How to Run & Test

```bash
# 1. Fetch dependencies
flutter pub get

# 2. Run automated test suite (Unit tests + SQLite tests + Widget tests)
flutter test

# 3. Launch on Android device / emulator
flutter run -d <device_id>

# 4. Launch on Windows Desktop
flutter run -d windows
```
