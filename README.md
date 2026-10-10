# SiegfriedFurstenburgGaitAnalysis

Gait analysis of a Siegfried-shaped man walking up the Fürstenburg hill in Xanten. Elevation data based on OpenNRW GIS.

Two versions.
1. `siegfried_climbs_the_fuerstenberg.m` Approaching west from Bislicher floodplain. More useful for biomechanics since it starts from a flat surface.
2. `siegfried_climbs_the_fuerstenberg_from_xanten.m` Approaching southeast from St Viktor's cathedral. This is closer to what would actually occur in canon.

Written by Claude Code with Opus 5.5. Confirmed working on MATLAB R2015a on RHEL6 (yes, that old). Elevation data from Open NRW GIS. You can download the files at www.opengeodata.nrw.de/produkte/geobasis/hm/dgm1_tiff/dgm1_tiff/


  Sources used

  1. Metabolic cost of walking on a gradient (route planning and the energy readout, fb_minetti_cost.m).
     The fifth-order polynomial, valid for gradients of ±0.45, comes from this paper.
     Minetti, A. E., Moia, C., Roi, G. S., Susta, D., & Ferretti, G. (2002). Energy cost of walking and
     running at extreme uphill and downhill slopes. Journal of Applied Physiology, 93(3), 1039–1046.
  2. Walking speed from grade (fb_tobler_speed.m): v = 6·exp(−3.5·|g + 0.05|) km/h.
     Tobler, W. (1993). Three presentations on geographical analysis and modeling: Non-isotropic 
     geographic modeling; speculations on the geometry of geography; and global spatial analysis
     (Technical Report 93-1). National Center for Geographic Information and Analysis, University of
     California, Santa Barbara.
  3. Step length from speed (fb_plan_step.m): step length proportional to v^0.42. This is the citation I
     am least sure of; I know the exponent mainly through Kuo's paper, which attributes it to Grieve.
     Grieve, D. W. (1968). Gait patterns and the speed of walking. Bio-Medical Engineering, 3, 119–122.
     Kuo, A. D. (2001). A simple model of bipedal walking predicts the preferred speed–step length
     relationship. Journal of Biomechanical Engineering, 123(3), 264–269.
  4. Swing-foot path (main file): the minimum-jerk profile 10τ³ − 15τ⁴ + 6τ⁵ for the foot's travel from
     toe-off to foothold.
     Flash, T., & Hogan, N. (1985). The coordination of arm movements: An experimentally confirmed
     mathematical model. Journal of Neuroscience, 5(7), 1688–1703.
  5. Segment lengths (thigh, shank, ankle height, foot as fractions of a 190 cm stature). I rounded the
     values, so the code does not match the table exactly.
     Winter, D. A. (2009). Biomechanics and motor control of human movement (4th ed.). John Wiley & Sons.
  6. Lat/lon to UTM (fb_ll2utm.m, version 2 start point). This is not gait math, but it is a formula
     taken from a source.
     Snyder, J. P. (1987). Map projections: A working manual (U.S. Geological Survey Professional
     Paper 1395). U.S. Government Printing Office.
  7. Terrain data. The metadata in your tiles names the publisher; I did not check the licence terms.
     Bezirksregierung Köln, Geobasis NRW. Digitales Geländemodell Gitterweite 1 m (DGM1) [Data set].

  Not from any source:

  - Level step length: 0.78 m (0.41 × stature) is a common rule of thumb; I have no primary source for
    it.
  - Hip height: the three-knot profile with cosine ramps and the 0.985 and 0.995 leg-length factors.
  - Foot and timing: the heel-rise angles, the 15 % double-support share, the 6 cm swing clearance and
    the 2 cm pelvis sway.
  - Step cap: the 0.20 m maximum height gain per step.
  - Posture: the trunk-lean rule and the arm-swing gain.
  - Control: the leg PD gains (the arm gains are copied from your sword chase file).
  - Route penalty: the steepness multiplier beyond ±45 % grade, which is outside Minetti's measured
    range.
