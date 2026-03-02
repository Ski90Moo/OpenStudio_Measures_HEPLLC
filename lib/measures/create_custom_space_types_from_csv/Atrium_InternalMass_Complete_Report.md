# CS Atrium Internal Mass Calculations
## Comprehensive Component Breakdown and OpenStudio Implementation

**Date:** January 20, 2026  
**Author:** Energy Modeling Analysis  
**Purpose:** Internal mass calculations for Washington State Energy Code compliance

**Space Types:**
- CS Atrium - Less than or equal to 40 ft
- CS Atrium - More than 40 ft

---

## Executive Summary

This report provides detailed internal mass calculations for two atrium space type categories based on structural characteristics and typical construction approaches. The calculations show that larger atriums (>40 ft) have approximately **96% higher thermal capacitance** due to more substantial structural members required for larger spans.

| Metric | Atrium ≤40 ft | Atrium >40 ft | Ratio |
|--------|---------------|---------------|-------|
| **Surface Area (m²/m²)** | 0.31 | 0.36 | 1.16× |
| **Total Mass (kg/m²)** | 23.81 | 41.27 | 1.73× |
| **Thermal Capacitance (J/K·m²)** | 26,724 | 52,426 | 1.96× |
| **Effective Thickness (mm)** | 85.0 | 129.4 | 1.52× |
| **Effective Density (kg/m³)** | 904 | 886 | 0.98× |
| **Effective Specific Heat (J/kg·K)** | 1,122 | 1,270 | 1.13× |

**Key Finding:** Larger atriums require nearly double the thermal capacitance due to heavier structural members needed for greater spans, despite having only 16% more exposed surface area.

---

## CS Atrium - Less than or equal to 40 ft

### Design Assumptions

**Structural Characteristics:**
- Ceiling height: Up to 40 feet (12.2 m)
- Typical construction: Light wood trusses or small steel beams
- Span capability: Light structural members adequate for smaller spans
- Occupancy: Non-occupiable space (atrium volume only)
- Lighting: Minimal fixtures (relies primarily on roof daylighting via horizontal fenestration)
- Internal furnishings: Essentially none (open volume)
- Typical applications: Small lobby atriums, two-story open spaces, modest gathering areas

**Key Modeling Assumption:** Open structure with light Douglas Fir trusses or small steel beams exposed to conditioned space. Total exposed structural surface estimated at **0.31 m²/m²** floor area, which is significantly less than typical occupied spaces (which range from 1.13-2.0 m²/m²).

###  Component Breakdown

#### Component 1: Light Wood Trusses

**Material Specifications:**
- **Material:** Douglas Fir (typical light wood truss construction)
- **Member Thickness:** 100 mm (4 inches) - represents effective exposed dimension of truss members
- **Density:** 550 kg/m³
- **Specific Heat:** 1600 J/kg·K
- **Thermal Conductivity:** 0.12 W/m·K (typical for Douglas Fir)
- **Exposed Surface Area:** 0.25 m²/m² floor area
  - Rationale: Bottom chord, web members partially visible from below

**Thermal Calculations:**
```
Volume per floor area  = 0.25 m²/m² × 0.100 m = 0.025 m³/m²
Mass per floor area    = 0.025 m³/m² × 550 kg/m³ = 13.75 kg/m²
Thermal capacitance    = 13.75 kg/m² × 1600 J/kg·K = 22,000 J/K per m² floor
Percentage of total    = 22,000 / 26,724 = 82.3%
```

#### Component 2: Steel Beams (supplemental support)

**Material Specifications:**
- **Material:** Structural Steel
- **Member Thickness:** 25 mm (equivalent exposed dimension of wide-flange beam)
- **Density:** 7850 kg/m³
- **Specific Heat:** 460 J/kg·K
- **Thermal Conductivity:** 45 W/m·K (typical for structural steel)
- **Exposed Surface Area:** 0.05 m²/m² floor area
  - Rationale: Limited steel beam exposure, primarily at supports

**Thermal Calculations:**
```
Volume per floor area  = 0.05 m²/m² × 0.025 m = 0.00125 m³/m²
Mass per floor area    = 0.00125 m³/m² × 7850 kg/m³ = 9.81 kg/m²
Thermal capacitance    = 9.81 kg/m² × 460 J/kg·K = 4,514 J/K per m² floor
Percentage of total    = 4,514 / 26,724 = 16.9%
```

#### Component 3: Minimal Lighting Fixtures

**Material Specifications:**
- **Material:** Metal/Glass composite (typical for suspended fixtures)
- **Equivalent Thickness:** 10 mm
- **Density:** 2500 kg/m³ (weighted average of steel housing and glass lens)
- **Specific Heat:** 840 J/kg·K
- **Thermal Conductivity:** 1.0 W/m·K
- **Exposed Surface Area:** 0.01 m²/m² floor area
  - Rationale: Very minimal - atriums rely on daylighting, minimal artificial lighting

**Thermal Calculations:**
```
Volume per floor area  = 0.01 m²/m² × 0.010 m = 0.0001 m³/m²
Mass per floor area    = 0.0001 m³/m² × 2500 kg/m³ = 0.25 kg/m²
Thermal capacitance    = 0.25 kg/m² × 840 J/kg·K = 210 J/K per m² floor
Percentage of total    = 210 / 26,724 = 0.8%
```

### Composite Summary - Atrium ≤40 ft

| Component | Surface Area<br>(m²/m²) | Mass<br>(kg/m²) | Thermal Cap.<br>(J/K·m²) | % of Total |
|-----------|-------------------------|-----------------|--------------------------|------------|
| Wood Trusses | 0.25 | 13.75 | 22,000 | 82.3% |
| Steel Beams | 0.05 | 9.81 | 4,514 | 16.9% |
| Lighting | 0.01 | 0.25 | 210 | 0.8% |
| **TOTAL** | **0.31** | **23.81** | **26,724** | **100.0%** |

### Effective Composite Material Properties

For OpenStudio InternalMass object, we need single-layer material properties representing the combined thermal behavior:

| Property | Value | Calculation Method |
|----------|-------|-------------------|
| **Surface Area per Space Floor Area** | 0.31 m²/m² | Direct sum of components |
| **Effective Thickness** | 0.085 m (85 mm) | Total volume / Total surface area |
| **Effective Density** | 904 kg/m³ | Total mass / Total volume |
| **Effective Specific Heat** | 1,122 J/kg·K | Total capacitance / Total mass |
| **Effective Thermal Conductivity** | 2.56 W/m·K | Mass-weighted average |
| **Thermal Absorptance** | 0.9 | Standard for interior surfaces |
| **Solar Absorptance** | 0.7 | Typical for wood/steel mix |
| **Visible Absorptance** | 0.7 | Typical for wood/steel mix |

**Verification:**
```
Thermal mass = Density × Thickness × Specific Heat
             = 904 kg/m³ × 0.085 m × 1,122 J/kg·K
             = 86,200 J/K·m² of surface

Total capacitance = Surface thermal mass × Surface area
                  = 86,200 J/K·m² × 0.31 m²/m²
                  = 26,722 J/K per m² floor ✓ (matches 26,724 within rounding)
```

---

## CS Atrium - More than 40 ft

### Design Assumptions

**Structural Characteristics:**
- Ceiling height: Greater than 40 feet (>12.2 m), often 50-80 feet
- Typical construction: Heavy glulam beams or substantial steel members
- Span capability: Requires heavier structural members for larger spans and higher loads
- Occupancy: Non-occupiable space (atrium volume only)
- Lighting: Minimal fixtures (relies primarily on roof daylighting via horizontal fenestration)
- Internal furnishings: Essentially none (open volume)
- Typical applications: Large hotel lobbies, convention center atriums, major gathering spaces

**Key Modeling Assumption:** More substantial structure required for larger spans. Heavier glulam or steel beams with greater exposed surface area and member dimensions. Total exposed structural surface estimated at **0.36 m²/m²** floor area.

### Component Breakdown

#### Component 1: Heavy Glulam/Steel Beams

**Material Specifications:**
- **Material:** Glulam (or equivalent heavy timber)
- **Member Thickness:** 150 mm (6 inches) - heavier beams required for large spans
- **Density:** 650 kg/m³ (typical for glulam - slightly denser than standard lumber)
- **Specific Heat:** 1600 J/kg·K
- **Thermal Conductivity:** 0.15 W/m·K
- **Exposed Surface Area:** 0.30 m²/m² floor area
  - Rationale: Larger, more numerous beams; greater visual exposure in tall atrium

**Thermal Calculations:**
```
Volume per floor area  = 0.30 m²/m² × 0.150 m = 0.045 m³/m²
Mass per floor area    = 0.045 m³/m² × 650 kg/m³ = 29.25 kg/m²
Thermal capacitance    = 29.25 kg/m² × 1600 J/kg·K = 46,800 J/K per m² floor
Percentage of total    = 46,800 / 52,426 = 89.3%
```

#### Component 2: Steel Support Elements

**Material Specifications:**
- **Material:** Structural Steel
- **Member Thickness:** 30 mm (equivalent exposed dimension - larger than ≤40 ft case)
- **Density:** 7850 kg/m³
- **Specific Heat:** 460 J/kg·K
- **Thermal Conductivity:** 45 W/m·K
- **Exposed Surface Area:** 0.05 m²/m² floor area
  - Rationale: Connections, tension members, supplemental supports

**Thermal Calculations:**
```
Volume per floor area  = 0.05 m²/m² × 0.030 m = 0.0015 m³/m²
Mass per floor area    = 0.0015 m³/m² × 7850 kg/m³ = 11.78 kg/m²
Thermal capacitance    = 11.78 kg/m² × 460 J/kg·K = 5,416 J/K per m² floor
Percentage of total    = 5,416 / 52,426 = 10.3%
```

#### Component 3: Minimal Lighting Fixtures

**Material Specifications:**
- **Material:** Metal/Glass composite (same as ≤40 ft case)
- **Equivalent Thickness:** 10 mm
- **Density:** 2500 kg/m³
- **Specific Heat:** 840 J/kg·K
- **Thermal Conductivity:** 1.0 W/m·K
- **Exposed Surface Area:** 0.01 m²/m² floor area
  - Rationale: Same minimal lighting density (relies on daylighting)

**Thermal Calculations:**
```
Volume per floor area  = 0.01 m²/m² × 0.010 m = 0.0001 m³/m²
Mass per floor area    = 0.0001 m³/m² × 2500 kg/m³ = 0.25 kg/m²
Thermal capacitance    = 0.25 kg/m² × 840 J/kg·K = 210 J/K per m² floor
Percentage of total    = 210 / 52,426 = 0.4%
```

### Composite Summary - Atrium >40 ft

| Component | Surface Area<br>(m²/m²) | Mass<br>(kg/m²) | Thermal Cap.<br>(J/K·m²) | % of Total |
|-----------|-------------------------|-----------------|--------------------------|------------|
| Heavy Glulam/Steel | 0.30 | 29.25 | 46,800 | 89.3% |
| Steel Supports | 0.05 | 11.78 | 5,416 | 10.3% |
| Lighting | 0.01 | 0.25 | 210 | 0.4% |
| **TOTAL** | **0.36** | **41.27** | **52,426** | **100.0%** |

### Effective Composite Material Properties

| Property | Value | Calculation Method |
|----------|-------|-------------------|
| **Surface Area per Space Floor Area** | 0.36 m²/m² | Direct sum of components |
| **Effective Thickness** | 0.1294 m (129 mm) | Total volume / Total surface area |
| **Effective Density** | 886 kg/m³ | Total mass / Total volume |
| **Effective Specific Heat** | 1,270 J/kg·K | Total capacitance / Total mass |
| **Effective Thermal Conductivity** | 3.01 W/m·K | Mass-weighted average |
| **Thermal Absorptance** | 0.9 | Standard for interior surfaces |
| **Solar Absorptance** | 0.7 | Typical for wood/steel mix |
| **Visible Absorptance** | 0.7 | Typical for wood/steel mix |

**Verification:**
```
Thermal mass = Density × Thickness × Specific Heat
             = 886 kg/m³ × 0.1294 m × 1,270 J/kg·K
             = 145,539 J/K·m² of surface

Total capacitance = Surface thermal mass × Surface area
                  = 145,539 J/K·m² × 0.36 m²/m²
                  = 52,394 J/K per m² floor ✓ (matches 52,426 within rounding)
```

---

## Comparison and Context

### Relative Thermal Mass Comparison

| Metric | Atrium ≤40 ft | Atrium >40 ft | Ratio |
|--------|---------------|---------------|-------|
| **Surface Area (m²/m²)** | 0.31 | 0.36 | 1.16× |
| **Total Mass (kg/m²)** | 23.81 | 41.27 | 1.73× |
| **Thermal Capacitance (J/K·m²)** | 26,724 | 52,426 | 1.96× |
| **Effective Thickness (mm)** | 85 | 129 | 1.52× |
| **Effective Specific Heat (J/kg·K)** | 1,122 | 1,270 | 1.13× |

**Key Insights:**
1. Surface area increases modestly (16%) but mass nearly doubles (73%) due to thicker structural members
2. Thermal capacitance nearly doubles (96%) - important for thermal mass effects in energy modeling
3. Effective thickness increases 52% - reflects heavier beam dimensions required for larger spans
4. Both space types have much lower thermal mass than typical occupied spaces (see below)

### Comparison to Other Space Types

For context, here's how atrium internal mass compares to typical occupied spaces:

| Space Type Category | Surface Area<br>(m²/m²) | Thermal Capacitance<br>(J/K·m²) | Ratio vs<br>Atrium ≤40 ft |
|---------------------|-------------------------|--------------------------------|---------------------------|
| **CS Atrium ≤40 ft** | 0.31 | 26,724 | 1.00× (baseline) |
| **CS Atrium >40 ft** | 0.36 | 52,426 | 1.96× |
| Theater Auditorium Seating | 1.74 | 82,634 | 3.09× |
| Convention Center Seating | 1.47 | 67,752 | 2.54× |
| Standard Office (DOE default) | 2.00 | 172,800 | 6.47× |

**Observations:**
- Atriums have the lowest internal mass of any space category due to minimal furnishings and open volume
- Even large atriums have less than 1/3 the thermal mass of a typical auditorium with seating
- DOE prototype defaults (~6× higher) would significantly overestimate atrium thermal behavior
- These custom calculations provide much more accurate thermal modeling for atrium spaces

---

## OpenStudio InternalMass Object Specifications

### IDF Format Objects

#### CS Atrium ≤40 ft

```idf
!- Internal Mass Definition
OS:InternalMass:Definition,
  Atrium-40ft-InternalMass-Def,     !- Name
  ,                                  !- Surface Area {m2}
  0.31,                              !- Surface Area per Space Floor Area {dimensionless}
  ;                                  !- Surface Area per Person {m2/person}

!- Material Layer
OS:Material,
  Atrium-40ft-Composite-Material,    !- Name
  MediumSmooth,                       !- Roughness
  0.085,                              !- Thickness {m}
  2.56,                               !- Conductivity {W/m-K}
  904,                                !- Density {kg/m3}
  1122,                               !- Specific Heat {J/kg-K}
  0.9,                                !- Thermal Absorptance
  0.7,                                !- Solar Absorptance
  0.7;                                !- Visible Absorptance

!- Construction (single layer)
OS:Construction,
  Atrium-40ft-InternalMass-Const,    !- Name
  ,                                   !- Surface Rendering Name
  Atrium-40ft-Composite-Material;    !- Layer 1
```

#### CS Atrium >40 ft

```idf
!- Internal Mass Definition
OS:InternalMass:Definition,
  Atrium-Over40ft-InternalMass-Def,  !- Name
  ,                                   !- Surface Area {m2}
  0.36,                               !- Surface Area per Space Floor Area {dimensionless}
  ;                                   !- Surface Area per Person {m2/person}

!- Material Layer
OS:Material,
  Atrium-Over40ft-Composite-Material, !- Name
  MediumSmooth,                        !- Roughness
  0.1294,                              !- Thickness {m}
  3.01,                                !- Conductivity {W/m-K}
  886,                                 !- Density {kg/m3}
  1270,                                !- Specific Heat {J/kg-K}
  0.9,                                 !- Thermal Absorptance
  0.7,                                 !- Solar Absorptance
  0.7;                                 !- Visible Absorptance

!- Construction (single layer)
OS:Construction,
  Atrium-Over40ft-InternalMass-Const,  !- Name
  ,                                     !- Surface Rendering Name
  Atrium-Over40ft-Composite-Material;  !- Layer 1
```

### Ruby Code for OpenStudio SDK

```ruby
# CS Atrium ≤40 ft
def create_atrium_40ft_internal_mass(model, space_type)
  # Create material
  material = OpenStudio::Model::StandardOpaqueMaterial.new(model)
  material.setName("Atrium-40ft-Composite-Material")
  material.setRoughness("MediumSmooth")
  material.setThickness(0.085)
  material.setConductivity(2.56)
  material.setDensity(904)
  material.setSpecificHeat(1122)
  material.setThermalAbsorptance(0.9)
  material.setSolarAbsorptance(0.7)
  material.setVisibleAbsorptance(0.7)
  
  # Create construction
  construction = OpenStudio::Model::Construction.new(model)
  construction.setName("Atrium-40ft-InternalMass-Const")
  layers = OpenStudio::Model::MaterialVector.new
  layers << material
  construction.setLayers(layers)
  
  # Create internal mass definition
  internal_mass_def = OpenStudio::Model::InternalMassDefinition.new(model)
  internal_mass_def.setName("Atrium-40ft-InternalMass-Def")
  internal_mass_def.setSurfaceAreaperSpaceFloorArea(0.31)
  internal_mass_def.setConstruction(construction)
  
  # Create internal mass instance
  internal_mass = OpenStudio::Model::InternalMass.new(internal_mass_def)
  internal_mass.setName("#{space_type.name.get}_InternalMass")
  internal_mass.setSpaceType(space_type)
  
  return internal_mass
end

# CS Atrium >40 ft
def create_atrium_over40ft_internal_mass(model, space_type)
  # Create material
  material = OpenStudio::Model::StandardOpaqueMaterial.new(model)
  material.setName("Atrium-Over40ft-Composite-Material")
  material.setRoughness("MediumSmooth")
  material.setThickness(0.1294)
  material.setConductivity(3.01)
  material.setDensity(886)
  material.setSpecificHeat(1270)
  material.setThermalAbsorptance(0.9)
  material.setSolarAbsorptance(0.7)
  material.setVisibleAbsorptance(0.7)
  
  # Create construction
  construction = OpenStudio::Model::Construction.new(model)
  construction.setName("Atrium-Over40ft-InternalMass-Const")
  layers = OpenStudio::Model::MaterialVector.new
  layers << material
  construction.setLayers(layers)
  
  # Create internal mass definition
  internal_mass_def = OpenStudio::Model::InternalMassDefinition.new(model)
  internal_mass_def.setName("Atrium-Over40ft-InternalMass-Def")
  internal_mass_def.setSurfaceAreaperSpaceFloorArea(0.36)
  internal_mass_def.setConstruction(construction)
  
  # Create internal mass instance
  internal_mass = OpenStudio::Model::InternalMass.new(internal_mass_def)
  internal_mass.setName("#{space_type.name.get}_InternalMass")
  internal_mass.setSpaceType(space_type)
  
  return internal_mass
end
```

---

## Methodology Notes

### Assumptions and Limitations

1. **Structural exposure estimates** are based on typical atrium construction with open truss/beam systems. Actual exposure may vary.

2. **No interior partitions** - Atriums are assumed to be open volumes with no subdividing walls or furniture.

3. **Minimal lighting** - Assumption that atriums rely primarily on daylighting through horizontal roof fenestration.

4. **Single composite material** - OpenStudio requires a single material layer for InternalMass. The effective properties represent the thermal behavior of the combined components.

5. **Conservative approach** - Surface area estimates may be conservative compared to highly articulated structural systems.

### Validation

These calculations can be validated by:
1. Comparing to measured thermal mass in similar spaces
2. Sensitivity analysis in EnergyPlus to verify thermal lag behavior
3. Comparison to DOE prototype assumptions (which are 3-6× higher for typical spaces)

---

## Recommendations

1. **Use these custom values** instead of DOE prototype defaults for atrium spaces to avoid significantly overestimating thermal mass.

2. **Adjust surface area** if actual structural exposure differs significantly from assumptions (e.g., exposed ductwork, more extensive steel framing).

3. **Consider height threshold** - The 40 ft threshold is based on typical structural system changes. Adjust if project-specific conditions differ.

4. **Validate with structural drawings** - If available, use actual beam sizes and spacing to refine exposed surface area estimates.

---

**Document Version:** 1.0  
**Date:** January 20, 2026  
**Status:** Final - Ready for SpaceTypes.csv Integration
