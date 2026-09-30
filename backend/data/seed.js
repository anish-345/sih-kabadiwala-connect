import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

export function getMasterPrices() {
  const pricesPath = path.resolve(__dirname, '../../kabadiwala_connect/assets/data/prices.json');
  try {
    if (fs.existsSync(pricesPath)) {
      return JSON.parse(fs.readFileSync(pricesPath, 'utf8'));
    }
  } catch (e) {
    console.warn('[Seed] Could not read prices.json from mobile assets, using defaults:', e.message);
  }

  return [
    {
      priceRecordId: "PRICE-2026-PCB-HIGH",
      category: "PCB",
      subCategory: "High Grade (Telecom / Server / RAM)",
      geoRegionCode: "MH-PUN",
      informalBaseRate: 290.0,
      formalGateRate: 380.0,
      eprCreditShare: 35.0,
      ncmmIncentive: 15.0,
      netOfferedPrice: 430.0,
      trend: "UP",
      trendDeltaPercent: 4.8,
      trendHistory: [390, 400, 405, 410, 420, 425, 430],
      hazardType: "NONE",
      source: "Field Research & JNARDDC E-Waste Price Benchmark, Pune",
      notes: "Gold/Palladium rich edge connectors. Formal gate gives +48% over local middleman."
    },
    {
      priceRecordId: "PRICE-2026-PCB-MID",
      category: "PCB",
      subCategory: "Mid Grade (Motherboards / GPUs)",
      geoRegionCode: "MH-PUN",
      informalBaseRate: 110.0,
      formalGateRate: 160.0,
      eprCreditShare: 20.0,
      ncmmIncentive: 10.0,
      netOfferedPrice: 190.0,
      trend: "UP",
      trendDeltaPercent: 3.2,
      trendHistory: [170, 172, 175, 180, 182, 188, 190],
      hazardType: "NONE",
      source: "Field Research & JNARDDC E-Waste Price Benchmark, Pune",
      notes: "Standard dual-sided FR-4 boards with copper traces and IC chips."
    },
    {
      priceRecordId: "PRICE-2026-PCB-LOW",
      category: "PCB",
      subCategory: "Low Grade (Power Supply / SMPS / TV)",
      geoRegionCode: "MH-PUN",
      informalBaseRate: 55.0,
      formalGateRate: 85.0,
      eprCreditShare: 12.0,
      ncmmIncentive: 5.0,
      netOfferedPrice: 102.0,
      trend: "STABLE",
      trendDeltaPercent: 0.0,
      trendHistory: [100, 101, 102, 102, 101, 102, 102],
      hazardType: "NONE",
      source: "Field Research & JNARDDC E-Waste Price Benchmark, Pune",
      notes: "Single-sided phenolic boards with transformers and aluminium heat sinks."
    },
    {
      priceRecordId: "PRICE-2026-CBL-HVY",
      category: "Cables",
      subCategory: "Heavy Copper Cables (Insulated)",
      geoRegionCode: "MH-PUN",
      informalBaseRate: 340.0,
      formalGateRate: 460.0,
      eprCreditShare: 30.0,
      ncmmIncentive: 20.0,
      netOfferedPrice: 510.0,
      trend: "UP",
      trendDeltaPercent: 5.1,
      trendHistory: [460, 470, 480, 490, 495, 505, 510],
      hazardType: "NONE",
      source: "Field Research & JNARDDC E-Waste Price Benchmark, Pune",
      notes: "High copper recovery yield (45-60%). Clean stripping yields ₹650/kg bare copper."
    },
    {
      priceRecordId: "PRICE-2026-BAT-LI",
      category: "Batteries",
      subCategory: "Lithium-Ion Cells (Laptop / EV / Mobile)",
      geoRegionCode: "MH-PUN",
      informalBaseRate: 40.0,
      formalGateRate: 95.0,
      eprCreditShare: 45.0,
      ncmmIncentive: 25.0,
      netOfferedPrice: 165.0,
      trend: "UP",
      trendDeltaPercent: 8.5,
      trendHistory: [130, 135, 140, 145, 150, 158, 165],
      hazardType: "FIRE_HAZARD",
      source: "Field Research & JNARDDC E-Waste Price Benchmark, Pune",
      notes: "Cobalt/Lithium cathode value + mandatory EPR compliance. Middlemen refuse or pay ₹30/kg."
    },
    {
      priceRecordId: "PRICE-2026-CRT-FUNNEL",
      category: "Displays",
      subCategory: "CRT Funnel Glass / Monitors",
      geoRegionCode: "MH-PUN",
      informalBaseRate: 0.0,
      formalGateRate: 8.0,
      eprCreditShare: 14.0,
      ncmmIncentive: 6.0,
      netOfferedPrice: 28.0,
      trend: "STABLE",
      trendDeltaPercent: 0.0,
      trendHistory: [25, 25, 26, 26, 27, 28, 28],
      hazardType: "LEAD_TOXIC",
      source: "Field Research & JNARDDC E-Waste Price Benchmark, Pune",
      notes: "Negative value in informal sector (dumped in rivers/nullahs). CPCB pays EPR bounty for safe disposal."
    },
    {
      priceRecordId: "PRICE-2026-PLS-ABS",
      category: "Plastics",
      subCategory: "Flame-Retardant E-Plastics (ABS/HIPS)",
      geoRegionCode: "MH-PUN",
      informalBaseRate: 14.0,
      formalGateRate: 24.0,
      eprCreditShare: 8.0,
      ncmmIncentive: 4.0,
      netOfferedPrice: 36.0,
      trend: "UP",
      trendDeltaPercent: 2.8,
      trendHistory: [32, 32, 33, 34, 34, 35, 36],
      hazardType: "TOXIC_BFR",
      source: "Field Research & JNARDDC E-Waste Price Benchmark, Pune",
      notes: "Computer/TV casings with RoHS compliance. Safe recycling requires non-incineration shredding."
    }
  ];
}

export function getMasterRecyclers() {
  const recyclersPath = path.resolve(__dirname, '../../kabadiwala_connect/assets/data/recyclers.json');
  try {
    if (fs.existsSync(recyclersPath)) {
      return JSON.parse(fs.readFileSync(recyclersPath, 'utf8'));
    }
  } catch (e) {
    console.warn('[Seed] Could not read recyclers.json from mobile assets, using defaults:', e.message);
  }

  return [
    {
      recyclerId: "REC-CPCB-MH-001",
      legalEntityName: "Eco-Friendly Recyclers Pvt Ltd",
      cpcbRegNumber: "CPCB/EPR/MH/2023/REC-0412",
      facilityLat: 18.6298,
      facilityLon: 73.7997,
      distanceKm: 4.2,
      facilityAddress: "Plot 42, MIDC Bhosari Industrial Area, Pune 411026",
      acceptedClasses: ["PCB", "Batteries", "Cables", "Plastics"],
      logisticsCapability: "PICKUP_AND_DROP",
      verificationStatus: "VERIFIED_CPCB",
      rating: 4.9,
      totalHandovers: 342,
      priceMultiplier: 1.05,
      contactPerson: "Rajesh Shinde",
      contactPhone: "+91 98220 12345",
      minLotWeightKg: 10.0,
      features: ["Spot Cash Payout", "Digital Form-6 Manifest", "Instant Weighbridge", "Direct Bank / UPI"]
    },
    {
      recyclerId: "REC-CPCB-MH-002",
      legalEntityName: "Maha Green Tech Disposers",
      cpcbRegNumber: "CPCB/EPR/MH/2024/REC-0889",
      facilityLat: 18.5204,
      facilityLon: 73.8567,
      distanceKm: 8.5,
      facilityAddress: "Gat No 118, Uruli Devachi, Pune-Saswad Road, Pune 412308",
      acceptedClasses: ["Displays", "PCB", "Cables"],
      logisticsCapability: "DROP_OFF_ONLY",
      verificationStatus: "VERIFIED_CPCB",
      rating: 4.7,
      totalHandovers: 198,
      priceMultiplier: 1.0,
      contactPerson: "Anand Deshmukh",
      contactPhone: "+91 94220 67890",
      minLotWeightKg: 5.0,
      features: ["CRT Glass Processing", "PCB Hydrometallurgy", "EPR Certificate Issuer"]
    }
  ];
}
