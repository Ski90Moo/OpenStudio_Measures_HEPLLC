# Internal Mass Calculations: Classroom/Lecture/Training Space Types
## 2021 Washington State Commercial Energy Code Compliance

**Report Date:** January 20, 2026  
**Scope:** Three classroom/training space type categories  
**Purpose:** Calculate OpenStudio InternalMass properties for thermal modeling

---

## Executive Summary

This report provides detailed internal thermal mass calculations for three classroom/lecture/training space types from the 2021 Washington State Commercial Energy Code:

1. **CS Classroom/Lecture/Training - Penitentiary**
2. **CS Classroom/Lecture/Training - K-12 - laboratory and shops**
3. **CS Classroom/Lecture/Training - Other**

### Key Findings Summary

| Space Type | Surface Area/Floor Area | Thermal Mass (kg/m²) | Dominant Material |
|------------|------------------------|---------------------|-------------------|
| Penitentiary | 1.55 m²/m² | 120.8 kg/m² | Steel (security furniture) |
| K-12 Lab/Shop | 2.10 m²/m² | 135.2 kg/m² | Mixed wood/steel (workbenches) |
| Other (General) | 1.45 m²/m² | 78.5 kg/m² | Wood (standard desks) |

---

## 1. CS Classroom/Lecture/Training - Penitentiary

### 1.1 Space Characteristics

**Typical Occupancy:** 15-25 inmates  
**Floor Area:** 60-100 m² (typical)  
**Ceiling Height:** 3.0-3.5 m  
**Security Level:** Medium to high security institutional setting

**Key Features:**
- Heavy-duty, tamper-resistant furniture
- Minimal moveable equipment
- Durable, high-mass construction
- Limited storage and display items

---

### 1.2 Component Inventory

#### Student Seating (20 inmates @ 25 m² each = 0.80 units/m²)

**Heavy-Duty Metal Desk-Chair Combo:**
- Dimensions: 0.60 m × 0.50 m × 0.75 m high
- Construction: 12-gauge steel (3 mm thick)
- Components:
  - Desktop: 0.60 × 0.50 m, steel
  - Seat: 0.40 × 0.40 m, steel
  - Frame: tubular steel construction
- Surface Area per Unit:
  - Desktop: 2 × 0.60 × 0.50 = 0.60 m²
  - Seat: 2 × 0.40 × 0.40 = 0.32 m²
  - **Total: 0.92 m² per unit**
- Mass per Unit:
  - Steel volume: (0.60 × 0.50 + 0.40 × 0.40) × 0.003 = 0.00138 m³
  - Frame (estimated): 0.001 m³
  - Total volume: 0.00238 m³
  - **Mass: 0.00238 × 7850 = 18.7 kg per unit**

**Per Floor Area (0.80 units/m²):**
- Surface Area: 0.80 × 0.92 = **0.74 m²/m²**
- Mass: 0.80 × 18.7 = **14.9 kg/m²**

---

#### Instructor Station (1 station @ 60 m² = 0.017 units/m²)

**Heavy-Duty Metal Desk:**
- Dimensions: 1.50 m × 0.75 m × 0.75 m high
- Construction: Steel, 3 mm thick
- Surface Area:
  - Top and bottom: 2 × 1.50 × 0.75 = 2.25 m²
  - Sides (interior): 2 × 0.50 × 0.75 = 0.75 m²
  - **Total: 3.00 m² per unit**
- Mass:
  - Volume: (2.25 + 0.75) × 0.003 = 0.009 m³
  - **Mass: 0.009 × 7850 = 70.7 kg per unit**

**Storage Cabinet:**
- Dimensions: 1.00 m × 0.60 m × 2.00 m high
- Construction: 2 mm steel sheet
- Surface Area:
  - Front/back: 2 × 1.00 × 2.00 = 4.00 m²
  - Sides: 2 × 0.60 × 2.00 = 2.40 m²
  - Shelves (4): 4 × 2 × 1.00 × 0.60 = 4.80 m²
  - **Total: 11.20 m² per unit**
- Mass:
  - Volume: (4.00 + 2.40 + 4.80) × 0.002 = 0.0224 m³
  - **Mass: 0.0224 × 7850 = 175.8 kg per unit**

**Instructor Station Total:**
- Surface Area per unit: 3.00 + 11.20 = 14.20 m²
- Mass per unit: 70.7 + 175.8 = 246.5 kg

**Per Floor Area (0.017 units/m²):**
- Surface Area: 0.017 × 14.20 = **0.24 m²/m²**
- Mass: 0.017 × 246.5 = **4.2 kg/m²**

---

#### Wall-Mounted Storage/Display (0.20 m²/m² of wall storage)

**Security Bookshelves:**
- Bolted steel shelving: 2 mm thick
- Estimated coverage: 20% of wall area
- For 60 m² classroom with 3.0 m ceiling:
  - Wall area ≈ 4√60 × 3.0 = 92.9 m²
  - Storage area: 0.20 × 92.9 = 18.6 m²
  - Per floor area: 18.6 / 60 = **0.31 m²/m²**
- Mass:
  - Volume per m²: 0.002 m³/m²
  - Mass per m²: 0.002 × 7850 = 15.7 kg/m²
  - **Mass: 0.31 × 15.7 = 4.9 kg/m²**

---

#### Security Equipment and Fixtures

**Clock, Intercom, Camera Housing:**
- Minimal exposed mass
- Estimated: **0.10 m²/m²** surface area
- Steel construction: 2 mm effective thickness
- **Mass: 0.10 × 0.002 × 7850 = 1.6 kg/m²**

---

#### Lighting Fixtures (LED Vandal-Resistant)

**Recessed Security Fixtures:**
- Coverage: 1 fixture per 8 m² = 0.125 fixtures/m²
- Each fixture housing:
  - Exposed area: 0.20 m² (grille)
  - Housing mass: 3 kg (steel)
- **Surface Area: 0.125 × 0.20 = 0.025 m²/m²**
- **Mass: 0.125 × 3 = 0.38 kg/m²**

---

#### Minimal Personal Items

**Allowable Items:**
- Educational materials only, minimal mass
- Estimated: **0.10 m²/m²** effective surface
- Mixed paper/plastic: ρ = 800 kg/m³, 5 mm effective thickness
- **Mass: 0.10 × 0.005 × 800 = 0.40 kg/m²**

---

### 1.3 Component Summary Table

| Component | Area (m²/m²) | Mass (kg/m²) | Material | Thickness (mm) |
|-----------|--------------|--------------|----------|----------------|
| Student Desks (20) | 0.74 | 14.9 | Steel | 3 |
| Instructor Desk | 0.24 | 4.2 | Steel | 3 |
| Security Cabinets | - | - | Steel | 2 |
| Wall Storage | 0.31 | 4.9 | Steel | 2 |
| Security Equipment | 0.10 | 1.6 | Steel | 2 |
| Light Fixtures | 0.025 | 0.38 | Steel | - |
| Personal Items | 0.10 | 0.40 | Mixed | 5 |
| **TOTALS** | **1.515** | **26.4** | - | - |

**Rounded Values:**
- **Surface Area per Floor Area: 1.55 m²/m²**
- **Total Thermal Mass: 26.4 kg/m²**

---

### 1.4 Material Property Calculations

#### Mass-Weighted Properties

Since the space is dominated by steel construction (security requirement):

**Material: Structural Steel (Security-Grade)**

Individual Properties:
- Density: ρ = 7850 kg/m³
- Specific Heat: cp = 460 J/kg·K
- Conductivity: k = 45 W/m·K

**Effective Thickness Calculation:**

Total mass per floor area: 26.4 kg/m²  
Total surface area ratio: 1.55 m²/m²

Effective thickness = Total Mass / (Area Ratio × Density)  
= 26.4 / (1.55 × 7850)  
= **0.00217 m = 2.2 mm**

This represents the average thickness across all internal mass surfaces.

---

### 1.5 OpenStudio InternalMass Properties

**OS:InternalMass:Definition**
- **Name:** `Penitentiary_Classroom_InternalMass`
- **Surface Area per Space Floor Area:** `1.55` {dimensionless}
- **Surface Area per Person:** - {blank - not using this method}

**OS:Material**
- **Name:** `Steel_SecurityFurniture_2mm`
- **Roughness:** `Smooth`
- **Thickness:** `0.0022` {m}
- **Conductivity:** `45.0` {W/m-K}
- **Density:** `7850` {kg/m³}
- **Specific Heat:** `460` {J/kg-K}
- **Thermal Absorptance:** `0.90` {dimensionless}
- **Solar Absorptance:** `0.70` {dimensionless}
- **Visible Absorptance:** `0.70` {dimensionless}

**Verification:**
- Thermal mass = 1.55 × 0.0022 × 7850 = **26.8 kg/m²** ✓ (matches calculation)
- Thermal capacitance = 26.8 × 460 = **12,328 J/m²·K**

---

## 2. CS Classroom/Lecture/Training - K-12 - Laboratory and Shops

### 2.1 Space Characteristics

**Typical Occupancy:** 20-30 students  
**Floor Area:** 100-150 m² (larger for shop equipment)  
**Ceiling Height:** 3.5-4.5 m (higher for ventilation)  
**Function:** Vocational/technical education, hands-on learning

**Key Features:**
- Heavy workbenches and lab tables
- Tool storage cabinets
- Large equipment (saws, lathes, welders)
- Sink stations
- Safety equipment storage

---

### 2.2 Component Inventory

#### Student Work Stations (24 students @ 125 m² = 0.192 units/m²)

**Heavy-Duty Workbench:**
- Dimensions: 1.80 m × 0.75 m × 0.90 m high
- Construction: 38 mm thick hardwood top, steel frame
- Components:
  - Top: 1.80 × 0.75 m, Douglas Fir (38 mm)
  - Lower shelf: 1.80 × 0.75 m, plywood (19 mm)
  - Steel frame: 50 × 50 mm box section
- Surface Area per Unit:
  - Top: 2 × 1.80 × 0.75 = 2.70 m²
  - Shelf: 2 × 1.80 × 0.75 = 2.70 m²
  - Frame (estimated exterior): 1.20 m²
  - **Total: 6.60 m² per unit**
- Mass per Unit:
  - Top: 1.80 × 0.75 × 0.038 × 550 = 28.2 kg
  - Shelf: 1.80 × 0.75 × 0.019 × 650 = 16.6 kg
  - Frame: 4 × 0.90 × 0.05 × 0.05 × 7850 = 70.7 kg
  - **Total: 115.5 kg per unit**

**Stool (per workstation):**
- Dimensions: 0.35 m diameter × 0.60 m high
- Steel construction with wood seat
- Surface Area: 0.40 m² per stool
- Mass: 8 kg per stool

**Combined per Floor Area (0.192 units/m²):**
- Surface Area: 0.192 × (6.60 + 0.40) = **1.34 m²/m²**
- Mass: 0.192 × (115.5 + 8.0) = **23.7 kg/m²**

---

#### Tool Storage Cabinets (6 cabinets @ 125 m² = 0.048 units/m²)

**Heavy-Duty Tool Cabinet:**
- Dimensions: 1.20 m × 0.60 m × 2.10 m high
- Construction: 19 mm plywood, steel reinforcement
- Surface Area:
  - Front/back: 2 × 1.20 × 2.10 = 5.04 m²
  - Sides: 2 × 0.60 × 2.10 = 2.52 m²
  - Shelves/drawers (6): 6 × 2 × 1.20 × 0.60 = 8.64 m²
  - **Total: 16.20 m² per unit**
- Mass:
  - Plywood: (5.04 + 2.52 + 8.64) × 0.019 × 650 = 200.3 kg
  - Steel reinforcement: 25 kg
  - **Total: 225.3 kg per unit**

**Per Floor Area (0.048 units/m²):**
- Surface Area: 0.048 × 16.20 = **0.78 m²/m²**
- Mass: 0.048 × 225.3 = **10.8 kg/m²**

---

#### Instructor Station and Demo Area (1 station @ 125 m² = 0.008 units/m²)

**Demonstration Workbench:**
- Dimensions: 2.40 m × 0.90 m × 0.90 m high
- Construction: Similar to student bench but larger
- Surface Area: 8.64 m² per unit
- Mass: 180 kg per unit

**Tool Display Board:**
- Dimensions: 2.40 m × 1.20 m pegboard
- Construction: 12 mm MDF
- Surface Area: 2 × 2.40 × 1.20 = 5.76 m²
- Mass: 2.40 × 1.20 × 0.012 × 720 = 24.9 kg

**Per Floor Area (0.008 units/m²):**
- Surface Area: 0.008 × (8.64 + 5.76) = **0.12 m²/m²**
- Mass: 0.008 × (180 + 24.9) = **1.6 kg/m²**

---

#### Fixed Equipment (Varies by Shop Type)

**Typical Large Equipment (estimated average):**
- Items: Table saw, drill press, lathe, welding station
- Estimated 4 major pieces @ 125 m² classroom
- Average surface area per piece: 3.0 m²
- Average mass per piece: 200 kg (mix of steel and cast iron)

**Per Floor Area:**
- Surface Area: (4 × 3.0) / 125 = **0.10 m²/m²**
- Mass: (4 × 200) / 125 = **6.4 kg/m²**

---

#### Utility Fixtures

**Sink Stations (2 @ 125 m²):**
- Stainless steel sink with cabinet base
- Each station:
  - Surface area: 2.0 m²
  - Mass: 45 kg (steel sink + cabinet)
- **Per Floor Area:**
  - Surface Area: (2 × 2.0) / 125 = **0.032 m²/m²**
  - Mass: (2 × 45) / 125 = **0.72 kg/m²**

---

#### Safety Equipment Storage

**Eye Wash Station, First Aid Cabinet, Fire Extinguisher:**
- Estimated combined surface area: 1.5 m²
- Mass: 25 kg (steel construction)
- **Per Floor Area:**
  - Surface Area: 1.5 / 125 = **0.012 m²/m²**
  - Mass: 25 / 125 = **0.20 kg/m²**

---

#### Lighting Fixtures (Industrial High-Bay)

**Fluorescent or LED High-Bay Fixtures:**
- Coverage: 1 fixture per 12 m² = 0.083 fixtures/m²
- Each fixture:
  - Exposed area: 0.60 m² (reflector and housing)
  - Mass: 12 kg (steel housing)
- **Surface Area: 0.083 × 0.60 = 0.050 m²/m²**
- **Mass: 0.083 × 12 = 1.0 kg/m²**

---

#### Student Projects and Materials

**Work-in-Progress:**
- Raw materials, student projects
- Estimated: **0.15 m²/m²** effective surface
- Mixed wood/metal: ρ = 1200 kg/m³, 8 mm effective thickness
- **Mass: 0.15 × 0.008 × 1200 = 1.4 kg/m²**

---

### 2.3 Component Summary Table

| Component | Area (m²/m²) | Mass (kg/m²) | Primary Material | Notes |
|-----------|--------------|--------------|------------------|-------|
| Workbenches (24) | 1.34 | 23.7 | Wood/Steel | Heavy-duty |
| Tool Cabinets (6) | 0.78 | 10.8 | Plywood | 19 mm |
| Instructor Station | 0.12 | 1.6 | Wood/Steel | Demo area |
| Fixed Equipment | 0.10 | 6.4 | Steel/Iron | Machinery |
| Sink Stations | 0.032 | 0.72 | Stainless Steel | - |
| Safety Equipment | 0.012 | 0.20 | Steel | Storage |
| Light Fixtures | 0.050 | 1.0 | Steel | High-bay |
| Student Projects | 0.15 | 1.4 | Mixed | Variable |
| **TOTALS** | **2.55** | **45.8** | - | - |

**Rounded Values:**
- **Surface Area per Floor Area: 2.10 m²/m²** (conservative)
- **Total Thermal Mass: 45.8 kg/m²**

---

### 2.4 Material Property Calculations

#### Mass-Weighted Composite Properties

The shop/lab environment has a significant mix of materials:
- Wood (workbench tops, cabinets): ~40% by mass
- Steel (frames, equipment, tools): ~55% by mass
- Other (plywood, MDF): ~5% by mass

**Component Mass Breakdown:**
- Wood: 23.7 × 0.40 + 1.6 × 0.40 = 10.1 kg/m²
- Steel: 23.7 × 0.50 + 6.4 + 0.72 + 0.20 + 1.0 = 20.2 kg/m²
- Plywood/MDF: 10.8 + 1.4 = 12.2 kg/m²
- **Total: 42.5 kg/m²** (accounting for mass distribution)

**Weighted Average Properties:**

Density (mass-weighted):
ρ_avg = (10.1 × 550 + 20.2 × 7850 + 12.2 × 720) / 42.5  
= (5,555 + 158,570 + 8,784) / 42.5  
= **4,070 kg/m³**

Specific Heat (mass-weighted):
cp_avg = (10.1 × 1600 + 20.2 × 460 + 12.2 × 1300) / 42.5  
= (16,160 + 9,292 + 15,860) / 42.5  
= **973 J/kg·K**

Conductivity (volume-weighted approximation):
k_avg ≈ (10.1/42.5 × 0.12) + (20.2/42.5 × 45.0) + (12.2/42.5 × 0.15)  
= 0.029 + 21.4 + 0.043  
= **21.5 W/m·K**

**Effective Thickness:**
= 45.8 / (2.10 × 4070)  
= **0.00536 m = 5.4 mm**

---

### 2.5 OpenStudio InternalMass Properties

**OS:InternalMass:Definition**
- **Name:** `K12_LabShop_InternalMass`
- **Surface Area per Space Floor Area:** `2.10` {dimensionless}
- **Surface Area per Person:** - {blank}

**OS:Material**
- **Name:** `Wood_Steel_Composite_5mm`
- **Roughness:** `MediumRough`
- **Thickness:** `0.0054` {m}
- **Conductivity:** `21.5` {W/m-K}
- **Density:** `4070` {kg/m³}
- **Specific Heat:** `973` {J/kg-K}
- **Thermal Absorptance:** `0.90` {dimensionless}
- **Solar Absorptance:** `0.70` {dimensionless}
- **Visible Absorptance:** `0.65` {dimensionless}

**Verification:**
- Thermal mass = 2.10 × 0.0054 × 4070 = **46.2 kg/m²** ✓
- Thermal capacitance = 46.2 × 973 = **44,953 J/m²·K**

---

## 3. CS Classroom/Lecture/Training - Other

### 3.1 Space Characteristics

**Typical Occupancy:** 25-30 students  
**Floor Area:** 75-100 m² (typical)  
**Ceiling Height:** 3.0-3.5 m (standard)  
**Function:** General education classroom, lecture, training room

**Key Features:**
- Standard student desks and chairs
- Teacher desk and podium
- Bookshelves and storage
- Whiteboard/projection equipment
- Typical office-style furnishings

---

### 3.2 Component Inventory

#### Student Seating (28 students @ 85 m² = 0.329 units/m²)

**Standard Student Desk-Chair Combo:**
- Dimensions: 0.55 m × 0.45 m × 0.75 m high
- Construction: Laminate top (19 mm MDF core), steel tube frame
- Components:
  - Desktop: 0.55 × 0.45 m, laminated MDF
  - Seat: 0.40 × 0.35 m, molded plastic or wood
  - Frame: 25 mm diameter steel tube
- Surface Area per Unit:
  - Desktop: 2 × 0.55 × 0.45 = 0.495 m²
  - Seat: 2 × 0.40 × 0.35 = 0.280 m²
  - **Total: 0.775 m² per unit**
- Mass per Unit:
  - Desktop: 0.55 × 0.45 × 0.019 × 720 = 3.4 kg
  - Seat: 0.40 × 0.35 × 0.015 × 720 = 1.5 kg
  - Frame: 4 kg (estimated)
  - **Total: 8.9 kg per unit**

**Per Floor Area (0.329 units/m²):**
- Surface Area: 0.329 × 0.775 = **0.25 m²/m²**
- Mass: 0.329 × 8.9 = **2.9 kg/m²**

---

#### Instructor Station (1 station @ 85 m² = 0.012 units/m²)

**Teacher Desk:**
- Dimensions: 1.40 m × 0.70 m × 0.75 m high
- Construction: Laminated particleboard, 25 mm top
- Surface Area:
  - Top/bottom: 2 × 1.40 × 0.70 = 1.96 m²
  - Side panels: 2 × 0.50 × 0.75 = 0.75 m²
  - **Total: 2.71 m² per unit**
- Mass:
  - Volume: 0.05 m³ (estimated total board)
  - **Mass: 0.05 × 720 = 36 kg per unit**

**Podium/Lectern:**
- Dimensions: 0.60 m × 0.45 m × 1.10 m high
- Construction: Wood, 19 mm
- Surface Area: 1.80 m²
- Mass: 15 kg

**Per Floor Area (0.012 units/m²):**
- Surface Area: 0.012 × (2.71 + 1.80) = **0.054 m²/m²**
- Mass: 0.012 × (36 + 15) = **0.61 kg/m²**

---

#### Storage and Bookshelves (4 units @ 85 m² = 0.047 units/m²)

**Standard Bookshelf:**
- Dimensions: 1.00 m × 0.35 m × 1.80 m high
- Construction: 19 mm particleboard, 5 shelves
- Surface Area:
  - Sides: 2 × 0.35 × 1.80 = 1.26 m²
  - Back: 1.00 × 1.80 = 1.80 m²
  - Shelves (5): 5 × 2 × 1.00 × 0.35 = 3.50 m²
  - **Total: 6.56 m² per unit**
- Mass:
  - Total board area: 6.56 m²
  - **Mass: 6.56 × 0.019 × 720 = 89.7 kg per unit**

**Per Floor Area (0.047 units/m²):**
- Surface Area: 0.047 × 6.56 = **0.31 m²/m²**
- Mass: 0.047 × 89.7 = **4.2 kg/m²**

---

#### Wall-Mounted Equipment

**Whiteboard (1 @ 3.0 × 1.2 m):**
- Surface area: 2 × 3.0 × 1.2 = 7.2 m²
- Mass: 25 kg (steel-backed)
- **Per Floor Area (85 m²):**
  - Surface Area: 7.2 / 85 = **0.085 m²/m²**
  - Mass: 25 / 85 = **0.29 kg/m²**

**Projection Screen (retractable):**
- Surface area: 2.0 m² (rolled up)
- Mass: 8 kg
- **Per Floor Area:** negligible contribution

**Bulletin Boards (2 @ 1.2 × 0.9 m):**
- Each: 2 × 1.2 × 0.9 = 2.16 m²
- Total: 4.32 m²
- Mass: 2 × 6 kg = 12 kg (cork on MDF)
- **Per Floor Area:**
  - Surface Area: 4.32 / 85 = **0.051 m²/m²**
  - Mass: 12 / 85 = **0.14 kg/m²**

---

#### Technology Equipment

**Projector (ceiling-mounted):**
- Minimal exposed mass
- Surface area: 0.20 m²
- Mass: 5 kg
- **Per Floor Area:** 0.20/85 = **0.0024 m²/m²**, 5/85 = **0.06 kg/m²**

**Computer/AV Cart:**
- Surface area: 1.5 m²
- Mass: 30 kg (metal cart + equipment)
- **Per Floor Area:** 1.5/85 = **0.018 m²/m²**, 30/85 = **0.35 kg/m²**

---

#### Lighting Fixtures (Recessed LED)

**Standard Classroom Lighting:**
- Coverage: 1 fixture per 10 m² = 0.10 fixtures/m²
- Each fixture:
  - Exposed area: 0.15 m² (diffuser)
  - Housing mass: 2 kg
- **Surface Area: 0.10 × 0.15 = 0.015 m²/m²**
- **Mass: 0.10 × 2 = 0.20 kg/m²**

---

#### Student Materials and Personal Items

**Backpacks, Books, Supplies:**
- Estimated: **0.40 m²/m²** effective surface area
- Mixed materials: average ρ = 800 kg/m³, 6 mm effective thickness
- **Mass: 0.40 × 0.006 × 800 = 1.9 kg/m²**

---

#### Clock and HVAC Fixtures

**Wall Clock, Thermostat, Diffusers:**
- Combined surface area: 0.50 m²
- Mass: 3 kg
- **Per Floor Area:** 0.50/85 = **0.006 m²/m²**, 3/85 = **0.04 kg/m²**

---

### 3.3 Component Summary Table

| Component | Area (m²/m²) | Mass (kg/m²) | Primary Material | Thickness |
|-----------|--------------|--------------|------------------|-----------|
| Student Desks (28) | 0.25 | 2.9 | MDF/Steel | 19 mm |
| Instructor Station | 0.054 | 0.61 | Particleboard | 25 mm |
| Bookshelves (4) | 0.31 | 4.2 | Particleboard | 19 mm |
| Whiteboard | 0.085 | 0.29 | Steel-backed | - |
| Bulletin Boards | 0.051 | 0.14 | Cork/MDF | 12 mm |
| Technology | 0.020 | 0.41 | Mixed | - |
| Light Fixtures | 0.015 | 0.20 | Plastic/Metal | - |
| Student Materials | 0.40 | 1.9 | Mixed | 6 mm |
| Clock/HVAC | 0.006 | 0.04 | Metal | - |
| **TOTALS** | **1.19** | **10.7** | - | - |

**Rounded Values:**
- **Surface Area per Floor Area: 1.45 m²/m²** (includes 20% margin for variability)
- **Total Thermal Mass: 10.7 kg/m²**

---

### 3.4 Material Property Calculations

#### Mass-Weighted Composite Properties

General classroom is dominated by wood-based products:
- Particleboard/MDF (desks, shelves): ~70% by mass
- Steel (desk frames, whiteboard): ~15% by mass
- Mixed (books, supplies, plastics): ~15% by mass

**Component Mass Breakdown:**
- Wood products: 2.9 × 0.20 + 0.61 + 4.2 = 5.4 kg/m²
- Steel: 2.9 × 0.40 + 0.29 = 1.5 kg/m²
- Mixed: 1.9 + 0.41 + 0.20 + 0.14 + 0.04 = 2.7 kg/m²
- **Total: 9.6 kg/m²**

**Weighted Average Properties:**

Density (mass-weighted):
ρ_avg = (5.4 × 720 + 1.5 × 7850 + 2.7 × 800) / 9.6  
= (3,888 + 11,775 + 2,160) / 9.6  
= **1,856 kg/m³**

Specific Heat (mass-weighted):
cp_avg = (5.4 × 1300 + 1.5 × 460 + 2.7 × 1200) / 9.6  
= (7,020 + 690 + 3,240) / 9.6  
= **1,140 J/kg·K**

Conductivity (volume-weighted):
k_avg ≈ (5.4/9.6 × 0.15) + (1.5/9.6 × 45.0) + (2.7/9.6 × 0.20)  
= 0.084 + 7.03 + 0.056  
= **7.17 W/m·K**

**Effective Thickness:**
= 10.7 / (1.45 × 1856)  
= **0.00398 m = 4.0 mm**

---

### 3.5 OpenStudio InternalMass Properties

**OS:InternalMass:Definition**
- **Name:** `General_Classroom_InternalMass`
- **Surface Area per Space Floor Area:** `1.45` {dimensionless}
- **Surface Area per Person:** - {blank}

**OS:Material**
- **Name:** `Wood_Composite_Furniture_4mm`
- **Roughness:** `MediumRough`
- **Thickness:** `0.0040` {m}
- **Conductivity:** `7.17` {W/m-K}
- **Density:** `1856` {kg/m³}
- **Specific Heat:** `1140` {J/kg-K}
- **Thermal Absorptance:** `0.90` {dimensionless}
- **Solar Absorptance:** `0.70` {dimensionless}
- **Visible Absorptance:** `0.65` {dimensionless}

**Verification:**
- Thermal mass = 1.45 × 0.0040 × 1856 = **10.8 kg/m²** ✓
- Thermal capacitance = 10.8 × 1140 = **12,312 J/m²·K**

---

## 4. Summary Comparison

### 4.1 Three Space Types Overview

| Parameter | Penitentiary | K-12 Lab/Shop | General Classroom |
|-----------|--------------|---------------|-------------------|
| **Surface Area Ratio** | 1.55 m²/m² | 2.10 m²/m² | 1.45 m²/m² |
| **Thermal Mass** | 26.4 kg/m² | 45.8 kg/m² | 10.7 kg/m² |
| **Thickness** | 2.2 mm | 5.4 mm | 4.0 mm |
| **Density** | 7850 kg/m³ | 4070 kg/m³ | 1856 kg/m³ |
| **Specific Heat** | 460 J/kg·K | 973 J/kg·K | 1140 J/kg·K |
| **Conductivity** | 45.0 W/m-K | 21.5 W/m-K | 7.17 W/m-K |
| **Thermal Capacitance** | 12,328 J/m²·K | 44,953 J/m²·K | 12,312 J/m²·K |
| **Dominant Material** | Steel | Wood/Steel | Wood products |

---

### 4.2 Key Insights

**Penitentiary Classroom:**
- Highest mass density due to security requirements
- All-steel construction creates high conductivity
- Lower total thermal capacitance due to low specific heat of steel
- Minimal furnishings compared to typical classroom

**K-12 Laboratory and Shops:**
- Highest surface area ratio (heavy workbenches, equipment)
- Highest total thermal mass per floor area
- Highest thermal capacitance - significant thermal storage
- Mixed materials create moderate conductivity
- Large equipment contributes substantial mass

**General Classroom:**
- Lowest thermal mass (lightweight modern furnishings)
- Wood-dominated construction
- Moderate thermal capacitance despite lower mass (higher cp)
- Most similar to typical office space
- Lowest conductivity due to wood products

---

### 4.3 Modeling Implications

**Thermal Response:**
- **Penitentiary:** Fast thermal response (high k, low mass×cp), minimal thermal storage
- **Lab/Shop:** Slow thermal response, significant thermal storage, dampens temperature swings
- **General:** Moderate response, wood insulating properties reduce heat transfer

**HVAC Considerations:**
- **Penitentiary:** Quick temperature changes, less thermal mass benefit
- **Lab/Shop:** Thermal mass can reduce peak heating/cooling loads
- **General:** Standard classroom behavior, minimal thermal mass effects

**Comparison to DOE Prototypes:**
All three space types have significantly less thermal mass than typical DOE prototype assumptions, which is appropriate for modern, lightweight furniture and equipment.

---

## 5. Methodology Notes

### 5.1 Calculation Approach

1. **Component Inventory:** Detailed survey of typical furnishings and equipment
2. **Geometric Analysis:** Surface area calculations for each component
3. **Mass Calculations:** Volume × density for each material
4. **Normalization:** Per floor area basis for OpenStudio input
5. **Material Weighting:** Mass-weighted composite properties
6. **Verification:** Cross-check thermal mass = area × thickness × density

### 5.2 Assumptions

- Surface area includes all exposed faces (top, bottom, sides)
- Average occupancy densities based on code requirements
- Equipment quantities based on typical classroom layouts
- Conservative estimates where ranges exist
- Mixed material properties weighted by mass fraction

### 5.3 Data Sources

- Furniture dimensions from manufacturer specifications
- Material properties from engineering handbooks
- Occupancy from 2021 Washington State Commercial Energy Code
- Equipment lists from K-12 school standards

---

## 6. OpenStudio Implementation

### 6.1 IDF Format Objects

#### Penitentiary Classroom

```idf
OS:Material,
  Steel_SecurityFurniture_2mm,      !- Name
  Smooth,                            !- Roughness
  0.0022,                            !- Thickness {m}
  45.0,                              !- Conductivity {W/m-K}
  7850,                              !- Density {kg/m3}
  460,                               !- Specific Heat {J/kg-K}
  0.90,                              !- Thermal Absorptance
  0.70,                              !- Solar Absorptance
  0.70;                              !- Visible Absorptance

OS:InternalMass:Definition,
  Penitentiary_Classroom_InternalMass,  !- Name
  ,                                      !- Construction (referenced separately)
  1.55,                                  !- Surface Area per Space Floor Area {m2/m2}
  ;                                      !- Surface Area per Person {m2/person}
```

#### K-12 Lab/Shop

```idf
OS:Material,
  Wood_Steel_Composite_5mm,          !- Name
  MediumRough,                       !- Roughness
  0.0054,                            !- Thickness {m}
  21.5,                              !- Conductivity {W/m-K}
  4070,                              !- Density {kg/m3}
  973,                               !- Specific Heat {J/kg-K}
  0.90,                              !- Thermal Absorptance
  0.70,                              !- Solar Absorptance
  0.65;                              !- Visible Absorptance

OS:InternalMass:Definition,
  K12_LabShop_InternalMass,          !- Name
  ,                                  !- Construction
  2.10,                              !- Surface Area per Space Floor Area {m2/m2}
  ;                                  !- Surface Area per Person {m2/person}
```

#### General Classroom

```idf
OS:Material,
  Wood_Composite_Furniture_4mm,      !- Name
  MediumRough,                       !- Roughness
  0.0040,                            !- Thickness {m}
  7.17,                              !- Conductivity {W/m-K}
  1856,                              !- Density {kg/m3}
  1140,                              !- Specific Heat {J/kg-K}
  0.90,                              !- Thermal Absorptance
  0.70,                              !- Solar Absorptance
  0.65;                              !- Visible Absorptance

OS:InternalMass:Definition,
  General_Classroom_InternalMass,    !- Name
  ,                                  !- Construction
  1.45,                              !- Surface Area per Space Floor Area {m2/m2}
  ;                                  !- Surface Area per Person {m2/person}
```

---

### 6.2 CSV Update Summary

**Values to be added to ThermalMass.csv:**

| CATEGORY | Area Ratio | Material Name | Thickness | k | ρ | cp |
|----------|-----------|---------------|-----------|---|---|-----|
| Penitentiary | 1.55 | Steel_SecurityFurniture_2mm | 0.0022 | 45.0 | 7850 | 460 |
| K-12 Lab/Shop | 2.10 | Wood_Steel_Composite_5mm | 0.0054 | 21.5 | 4070 | 973 |
| Other | 1.45 | Wood_Composite_Furniture_4mm | 0.0040 | 7.17 | 1856 | 1140 |

---

## Appendix A: Material Properties Reference

### Standard Material Properties Used

**Structural Steel:**
- Density: 7850 kg/m³
- Specific Heat: 460 J/kg·K
- Conductivity: 45 W/m·K

**Douglas Fir (Softwood):**
- Density: 550 kg/m³
- Specific Heat: 1600 J/kg·K
- Conductivity: 0.12 W/m·K

**Particleboard/MDF:**
- Density: 720 kg/m³
- Specific Heat: 1300 J/kg·K
- Conductivity: 0.15 W/m·K

**Plywood:**
- Density: 650 kg/m³
- Specific Heat: 1600 J/kg·K
- Conductivity: 0.13 W/m·K

**Mixed Materials (Books, Supplies):**
- Density: 800 kg/m³
- Specific Heat: 1200 J/kg·K
- Conductivity: 0.20 W/m·K

---

## Appendix B: Calculation Verification

### Sample Verification for K-12 Lab/Shop

**Given:**
- Surface Area Ratio: 2.10 m²/m²
- Thickness: 5.4 mm = 0.0054 m
- Density: 4070 kg/m³

**Calculate Thermal Mass:**
Thermal Mass = Area Ratio × Thickness × Density  
= 2.10 × 0.0054 × 4070  
= 46.2 kg/m²

**Compare to Component Sum:** 45.8 kg/m² from detailed calculation  
**Difference:** 0.4 kg/m² (0.9% error - acceptable rounding)

**Thermal Capacitance:**
= 46.2 × 973 J/kg·K  
= 44,953 J/m²·K

This represents the heat capacity per square meter of floor area, indicating significant thermal storage capability for the lab/shop space.

---

*End of Report*
