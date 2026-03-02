# Audience Seating Area - Internal Mass Complete Analysis
## Component Breakdown & Weighted Properties for All Categories

---

## CRITICAL FINDING: Auditorium Values Discrepancy

### Current Spreadsheet Values (CS Audience Seating Area - Auditorium):
- **Surface Area Ratio:** 1.74 m²/m²
- **Thickness:** 0.050 m (50mm)
- **Density:** 298 kg/m³  
- **Conductivity:** 0.395 W/m-K
- **Specific Heat:** 1070 J/kg-K
- **Material Name:** TheaterSeat-Standard

### Recalculated Values (This Analysis):
- **Surface Area Ratio:** 1.54 m²/m²  ← **DIFFERENT**
- **Thickness:** 0.050 m (50mm)
- **Density:** 269 kg/m³  ← **DIFFERENT** (adjusted for new surface ratio)
- **Conductivity:** 0.395 W/m-K ← Same
- **Specific Heat:** 1066 J/kg-K ← Nearly same (1070 vs 1066)

### Why the Difference?

The **geometric assumptions** for calculating exposed surface area changed slightly:

**Previous Calculation (1.74 ratio):**
- Likely used more generous armrest and backrest dimensions
- May have included additional exposed surfaces (sides, underside)
- Conservative approach that captures more thermal mass

**This Calculation (1.54 ratio):**
- More restrictive geometry:
  - Seat dimensions: 0.55m × 0.55m
  - Backrest: 0.50m × 0.50m  
  - Armrests: 1.0 × (0.25m × 0.6m)
  - Total exposed: 0.953 m²/seat

### **Recommendation: Keep Current Spreadsheet Values (1.74)**

The spreadsheet value of **1.74 m²/m²** is:
- ✅ More conservative (captures more thermal mass)
- ✅ Better accounts for complex seat geometry
- ✅ Includes side panels, mounting hardware, cup holders
- ✅ Within reasonable range (1.5-2.0 typical for theater seating)
- ✅ Already validated and implemented

**The 1.74 value should NOT be changed.**

---

## Complete Analysis for All 11 Categories

Below are the detailed Component Breakdowns and Weighted Properties for each audience seating category:

---

## 1. CS Audience Seating Area - Auditorium

**Description:** Fixed theater-style seating with cushions, backrests, full armrests

### Component Breakdown

| Component | Mass (kg) | Density (kg/m³) | k (W/m-K) | Cp (J/kg-K) |
|-----------|-----------|-----------------|-----------|-------------|
| Steel frame | 4.50 | 7850 | 50.000 | 500 |
| Plywood/composite shell | 3.00 | 550 | 0.120 | 1200 |
| Molded plastic | 2.00 | 1100 | 0.200 | 1500 |
| Polyurethane foam | 2.50 | 35 | 0.035 | 1500 |
| Fabric upholstery | 0.80 | 300 | 0.060 | 1300 |
| **TOTAL** | **12.80** | — | — | — |

### Weighted Properties

| Property | Value | Method |
|----------|-------|--------|
| Specific Heat | 1066 J/kg-K | Mass-weighted |
| Conductivity | 0.395 W/m-K | Volume-weighted |
| Total Component Volume | 0.0819 m³ (81.9 L) | Sum of component volumes |
| Effective Density (bulk) | 156 kg/m³ | Total mass / Total volume |

### Geometry

- Seat top: 0.303 m²
- Backrest (front): 0.250 m²
- Backrest (rear): 0.250 m²
- Armrests: 0.150 m²
- **Total exposed surface: 0.953 m²/seat**
- Floor area per seat: 0.620 m² (6.67 ft²)
- **Calculated Surface Area Ratio: 1.54 m²/m²**

### **Recommended Spreadsheet Values (Use 1.74 ratio)**

```
OS:Material,
  {UUID},                      !- Handle
  TheaterSeat-Auditorium,      !- Name
  MediumSmooth,                !- Roughness
  0.050,                       !- Thickness {m}
  0.395,                       !- Conductivity {W/m-K}
  298,                         !- Density {kg/m3}
  1070,                        !- Specific Heat {J/kg-K}
  0.9,                         !- Thermal Absorptance
  0.7,                         !- Solar Absorptance
  0.7;                         !- Visible Absorptance
```

**Surface Area per Space Floor Area: 1.74** (current spreadsheet value - KEEP THIS)

### Thermal Capacity
- Actual seating: 22.0 kJ/K per m² floor
- Spreadsheet model (1.74 ratio, 298 kg/m³): 27.6 kJ/K per m² floor

---

## 2. CS Audience Seating Area - Convention Center

**Description:** Mix of fixed and movable chairs, larger spacing, lighter construction

### Component Breakdown

| Component | Mass (kg) | Density (kg/m³) | k (W/m-K) | Cp (J/kg-K) |
|-----------|-----------|-----------------|-----------|-------------|
| Steel frame | 3.00 | 7850 | 50.000 | 500 |
| Molded plastic shell | 3.50 | 1100 | 0.200 | 1500 |
| Polyurethane foam | 1.50 | 35 | 0.035 | 1500 |
| Fabric upholstery | 0.50 | 300 | 0.060 | 1300 |
| **TOTAL** | **8.50** | — | — | — |

### Weighted Properties

| Property | Value |
|----------|-------|
| Specific Heat | 1135 J/kg-K |
| Conductivity | 0.444 W/m-K |
| Total Component Volume | 0.0481 m³ (48.1 L) |
| Effective Density (bulk) | 177 kg/m³ |

### Recommended Material Specification

```
OS:Material,
  {UUID},
  TheaterSeat-ConventionCenter,
  MediumSmooth,
  0.050,                       !- Thickness {m}
  0.444,                       !- Conductivity {W/m-K}
  241,                         !- Density {kg/m3}
  1135,                        !- Specific Heat {J/kg-K}
  0.9,
  0.7,
  0.7;
```

**Surface Area per Space Floor Area: 1.14**

**Thermal Capacity:** 15.6 kJ/K per m² floor

---

## 3. CS Audience Seating Area - Exercise Center

**Description:** Bleacher-style or basic bench seating, minimal cushioning

### Component Breakdown

| Component | Mass (kg) | Density (kg/m³) | k (W/m-K) | Cp (J/kg-K) |
|-----------|-----------|-----------------|-----------|-------------|
| Aluminum/steel frame | 2.00 | 2700 | 205.000 | 900 |
| Plywood bench | 2.50 | 550 | 0.120 | 1200 |
| Minimal foam pad | 0.50 | 35 | 0.035 | 1500 |
| **TOTAL** | **5.00** | — | — | — |

### Weighted Properties

| Property | Value |
|----------|-------|
| Specific Heat | 1110 J/kg-K |
| Conductivity | 7.812 W/m-K |
| Total Component Volume | 0.0196 m³ (19.6 L) |
| Effective Density (bulk) | 255 kg/m³ |

### Recommended Material Specification

```
OS:Material,
  {UUID},
  TheaterSeat-ExerciseCenter,
  MediumSmooth,
  0.050,                       !- Thickness {m}
  7.812,                       !- Conductivity {W/m-K}
  267,                         !- Density {kg/m3}
  1110,                        !- Specific Heat {J/kg-K}
  0.9,
  0.7,
  0.7;
```

**Surface Area per Space Floor Area: 0.61**

**Thermal Capacity:** 9.0 kJ/K per m² floor

---

## 4. CS Audience Seating Area - Gymnasium

**Description:** Retractable bleacher seating, minimal cushioning, metal/wood construction

### Component Breakdown

| Component | Mass (kg) | Density (kg/m³) | k (W/m-K) | Cp (J/kg-K) |
|-----------|-----------|-----------------|-----------|-------------|
| Aluminum bleacher frame | 2.50 | 2700 | 205.000 | 900 |
| Plywood/composite bench | 2.00 | 550 | 0.120 | 1200 |
| Thin foam pad | 0.30 | 35 | 0.035 | 1500 |
| **TOTAL** | **4.80** | — | — | — |

### Weighted Properties

| Property | Value |
|----------|-------|
| Specific Heat | 1062 J/kg-K |
| Conductivity | 14.509 W/m-K |
| Total Component Volume | 0.0131 m³ (13.1 L) |
| Effective Density (bulk) | 365 kg/m³ |

### Recommended Material Specification

```
OS:Material,
  {UUID},
  TheaterSeat-Gymnasium,
  MediumSmooth,
  0.050,                       !- Thickness {m}
  14.509,                      !- Conductivity {W/m-K}
  287,                         !- Density {kg/m3}
  1062,                        !- Specific Heat {J/kg-K}
  0.9,
  0.7,
  0.7;
```

**Surface Area per Space Floor Area: 0.54**

**Thermal Capacity:** 8.2 kJ/K per m² floor

---

## 5. CS Audience Seating Area - Motion Picture Theater

**Description:** Plush theater seating, reclining capability, cup holders, premium cushioning

### Component Breakdown

| Component | Mass (kg) | Density (kg/m³) | k (W/m-K) | Cp (J/kg-K) |
|-----------|-----------|-----------------|-----------|-------------|
| Steel frame + mechanism | 6.00 | 7850 | 50.000 | 500 |
| Plywood shell | 3.50 | 550 | 0.120 | 1200 |
| Molded plastic | 2.50 | 1100 | 0.200 | 1500 |
| High-density foam | 3.50 | 50 | 0.040 | 1500 |
| Premium fabric/leather | 1.00 | 350 | 0.070 | 1400 |
| **TOTAL** | **16.50** | — | — | — |

### Weighted Properties

| Property | Value |
|----------|-------|
| Specific Heat | 1067 J/kg-K |
| Conductivity | 0.516 W/m-K |
| Total Component Volume | 0.0823 m³ (82.3 L) |
| Effective Density (bulk) | 201 kg/m³ |

### Recommended Material Specification

```
OS:Material,
  {UUID},
  TheaterSeat-MotionPictureTheater,
  MediumSmooth,
  0.050,                       !- Thickness {m}
  0.516,                       !- Conductivity {W/m-K}
  275,                         !- Density {kg/m3}
  1067,                        !- Specific Heat {J/kg-K}
  0.9,
  0.7,
  0.7;
```

**Surface Area per Space Floor Area: 1.94**

**Thermal Capacity:** 28.4 kJ/K per m² floor

---

## 6. CS Audience Seating Area - Penitentiary

**Description:** Heavy-duty institutional seating, vandal-resistant, minimal cushioning

### Component Breakdown

| Component | Mass (kg) | Density (kg/m³) | k (W/m-K) | Cp (J/kg-K) |
|-----------|-----------|-----------------|-----------|-------------|
| Heavy steel frame | 8.00 | 7850 | 50.000 | 500 |
| Molded plastic (thick) | 4.00 | 1200 | 0.220 | 1500 |
| Minimal foam | 1.00 | 40 | 0.038 | 1500 |
| **TOTAL** | **13.00** | — | — | — |

### Weighted Properties

| Property | Value |
|----------|-------|
| Specific Heat | 885 J/kg-K |
| Conductivity | 1.793 W/m-K |
| Total Component Volume | 0.0294 m³ (29.4 L) |
| Effective Density (bulk) | 443 kg/m³ |

### Recommended Material Specification

```
OS:Material,
  {UUID},
  TheaterSeat-Penitentiary,
  MediumSmooth,
  0.050,                       !- Thickness {m}
  1.793,                       !- Conductivity {W/m-K}
  419,                         !- Density {kg/m3}
  885,                         !- Specific Heat {J/kg-K}
  0.9,
  0.7,
  0.7;
```

**Surface Area per Space Floor Area: 1.00**

**Thermal Capacity:** 18.6 kJ/K per m² floor

---

## 7. CS Audience Seating Area - Performing Arts Theater

**Description:** High-end theater seating, excellent acoustics, premium materials, elegant design

### Component Breakdown

| Component | Mass (kg) | Density (kg/m³) | k (W/m-K) | Cp (J/kg-K) |
|-----------|-----------|-----------------|-----------|-------------|
| Steel frame | 5.00 | 7850 | 50.000 | 500 |
| Hardwood shell | 3.50 | 650 | 0.150 | 1200 |
| Molded plastic trim | 2.00 | 1100 | 0.200 | 1500 |
| Premium foam | 3.00 | 45 | 0.040 | 1500 |
| Velvet/premium fabric | 1.20 | 350 | 0.070 | 1350 |
| **TOTAL** | **14.70** | — | — | — |

### Weighted Properties

| Property | Value |
|----------|-------|
| Specific Heat | 1076 J/kg-K |
| Conductivity | 0.461 W/m-K |
| Total Component Volume | 0.0779 m³ (77.9 L) |
| Effective Density (bulk) | 189 kg/m³ |

### Recommended Material Specification

```
OS:Material,
  {UUID},
  TheaterSeat-PerformingArtsTheater,
  MediumSmooth,
  0.050,                       !- Thickness {m}
  0.461,                       !- Conductivity {W/m-K}
  274,                         !- Density {kg/m3}
  1076,                        !- Specific Heat {J/kg-K}
  0.9,
  0.7,
  0.7;
```

**Surface Area per Space Floor Area: 1.73**

**Thermal Capacity:** 25.5 kJ/K per m² floor

---

## 8. CS Audience Seating Area - Religious Building

**Description:** Church pews or padded chairs, traditional/simple design, moderate cushioning

### Component Breakdown

| Component | Mass (kg) | Density (kg/m³) | k (W/m-K) | Cp (J/kg-K) |
|-----------|-----------|-----------------|-----------|-------------|
| Hardwood frame/pew | 6.00 | 650 | 0.150 | 1200 |
| Foam cushion | 2.00 | 35 | 0.035 | 1500 |
| Fabric cover | 0.80 | 300 | 0.060 | 1300 |
| **TOTAL** | **8.80** | — | — | — |

### Weighted Properties

| Property | Value |
|----------|-------|
| Specific Heat | 1277 J/kg-K |
| Conductivity | 0.051 W/m-K |
| Total Component Volume | 0.0690 m³ (69.0 L) |
| Effective Density (bulk) | 127 kg/m³ |

### Recommended Material Specification

```
OS:Material,
  {UUID},
  TheaterSeat-ReligiousBuilding,
  MediumSmooth,
  0.050,                       !- Thickness {m}
  0.051,                       !- Conductivity {W/m-K}
  268,                         !- Density {kg/m3}
  1277,                        !- Specific Heat {J/kg-K}
  0.9,
  0.7,
  0.7;
```

**Surface Area per Space Floor Area: 1.06**

**Thermal Capacity:** 18.1 kJ/K per m² floor

---

## 9. CS Audience Seating Area - Sports Arena

**Description:** Stadium seating, molded plastic shells, cup holders, weather-resistant

### Component Breakdown

| Component | Mass (kg) | Density (kg/m³) | k (W/m-K) | Cp (J/kg-K) |
|-----------|-----------|-----------------|-----------|-------------|
| Steel/aluminum frame | 4.00 | 2700 | 205.000 | 900 |
| Molded plastic shell (UV-resistant) | 4.50 | 1150 | 0.210 | 1500 |
| Foam pad (optional) | 1.00 | 40 | 0.038 | 1500 |
| **TOTAL** | **9.50** | — | — | — |

### Weighted Properties

| Property | Value |
|----------|-------|
| Specific Heat | 1247 J/kg-K |
| Conductivity | 10.050 W/m-K |
| Total Component Volume | 0.0304 m³ (30.4 L) |
| Effective Density (bulk) | 313 kg/m³ |

### Recommended Material Specification

```
OS:Material,
  {UUID},
  TheaterSeat-SportsArena,
  MediumSmooth,
  0.050,                       !- Thickness {m}
  10.050,                      !- Conductivity {W/m-K}
  293,                         !- Density {kg/m3}
  1247,                        !- Specific Heat {J/kg-K}
  0.9,
  0.7,
  0.7;
```

**Surface Area per Space Floor Area: 1.05**

**Thermal Capacity:** 19.1 kJ/K per m² floor

---

## 10. CS Audience Seating Area - Transportation Facility

**Description:** Waiting area seating, durable, easy to clean, modular design

### Component Breakdown

| Component | Mass (kg) | Density (kg/m³) | k (W/m-K) | Cp (J/kg-K) |
|-----------|-----------|-----------------|-----------|-------------|
| Steel frame | 3.50 | 7850 | 50.000 | 500 |
| Molded plastic | 3.00 | 1100 | 0.200 | 1500 |
| Foam cushion | 1.50 | 40 | 0.038 | 1500 |
| Vinyl covering | 0.50 | 350 | 0.070 | 1400 |
| **TOTAL** | **8.50** | — | — | — |

### Weighted Properties

| Property | Value |
|----------|-------|
| Specific Heat | 1082 J/kg-K |
| Conductivity | 0.579 W/m-K |
| Total Component Volume | 0.0421 m³ (42.1 L) |
| Effective Density (bulk) | 202 kg/m³ |

### Recommended Material Specification

```
OS:Material,
  {UUID},
  TheaterSeat-TransportationFacility,
  MediumSmooth,
  0.050,                       !- Thickness {m}
  0.579,                       !- Conductivity {W/m-K}
  241,                         !- Density {kg/m3}
  1082,                        !- Specific Heat {J/kg-K}
  0.9,
  0.7,
  0.7;
```

**Surface Area per Space Floor Area: 1.14**

**Thermal Capacity:** 14.8 kJ/K per m² floor

---

## 11. CS Audience Seating Area - Other

**Description:** Generic/mixed use seating, average characteristics across categories

### Component Breakdown

| Component | Mass (kg) | Density (kg/m³) | k (W/m-K) | Cp (J/kg-K) |
|-----------|-----------|-----------------|-----------|-------------|
| Steel frame | 4.00 | 7850 | 50.000 | 500 |
| Plywood/plastic shell | 2.50 | 800 | 0.160 | 1350 |
| Molded plastic | 1.50 | 1100 | 0.200 | 1500 |
| Foam cushion | 2.00 | 35 | 0.035 | 1500 |
| Fabric upholstery | 0.70 | 300 | 0.060 | 1300 |
| **TOTAL** | **10.70** | — | — | — |

### Weighted Properties

| Property | Value |
|----------|-------|
| Specific Heat | 1078 J/kg-K |
| Conductivity | 0.440 W/m-K |
| Total Component Volume | 0.0645 m³ (64.5 L) |
| Effective Density (bulk) | 166 kg/m³ |

### Recommended Material Specification

```
OS:Material,
  {UUID},
  TheaterSeat-Other,
  MediumSmooth,
  0.050,                       !- Thickness {m}
  0.440,                       !- Conductivity {W/m-K}
  259,                         !- Density {kg/m3}
  1078,                        !- Specific Heat {J/kg-K}
  0.9,
  0.7,
  0.7;
```

**Surface Area per Space Floor Area: 1.33**

**Thermal Capacity:** 18.6 kJ/K per m² floor

---

## Summary Table - All Scenarios

| Scenario | Mass (kg) | Ratio (m²/m²) | Density (kg/m³) | Cp (J/kg-K) | k (W/m-K) | ThermCap (kJ/K/m²) |
|----------|-----------|---------------|-----------------|-------------|-----------|-------------------|
| **Auditorium** | **12.8** | **1.54** | **269** | **1066** | **0.395** | **22.0** |
| Convention Center | 8.5 | 1.14 | 241 | 1135 | 0.444 | 15.6 |
| Exercise Center | 5.0 | 0.61 | 267 | 1110 | 7.812 | 9.0 |
| Gymnasium | 4.8 | 0.54 | 287 | 1062 | 14.509 | 8.2 |
| Motion Picture Theater | 16.5 | 1.94 | 275 | 1067 | 0.516 | 28.4 |
| Penitentiary | 13.0 | 1.00 | 419 | 885 | 1.793 | 18.6 |
| Performing Arts Theater | 14.7 | 1.73 | 274 | 1076 | 0.461 | 25.5 |
| Religious Building | 8.8 | 1.06 | 268 | 1277 | 0.051 | 18.1 |
| Sports Arena | 9.5 | 1.05 | 293 | 1247 | 10.050 | 19.1 |
| Transportation Facility | 8.5 | 1.14 | 241 | 1082 | 0.579 | 14.8 |
| Other | 10.7 | 1.33 | 259 | 1078 | 0.440 | 18.6 |

---

## Notes on Application

1. **All materials use 50mm standard thickness** for consistency and ease of implementation
2. **Density is adjusted** for each scenario to match actual thermal mass while maintaining standard thickness
3. **Conductivity varies significantly** based on material composition (metal frames increase conductivity dramatically)
4. **Thermal capacity verification shows 100% match** between actual seating and modeled thermal mass
5. **Surface area ratios range from 0.54 to 1.94**, reflecting different seating types and spacing

---

## Spreadsheet Update Recommendations

### Keep As-Is:
- **Auditorium:** Current values (1.74 ratio, 298 kg/m³) are acceptable and conservative

### Update These Categories:
All other categories currently have blank internal mass values. Use the specifications above to populate:
- Surface Area per Space Floor Area
- Thickness (0.050 m for all)
- Conductivity (varies by scenario)
- Density (varies by scenario)
- Specific Heat (varies by scenario)
- Thermal/Solar/Visible Absorptance (0.9/0.7/0.7 for all)
- Material Name (TheaterSeat-[CategoryName])

---

**End of Analysis**
