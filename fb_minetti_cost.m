function c = fb_minetti_cost(g)
% FB_MINETTI_COST  Metabolic cost of walking on a gradient [J/kg/m].
%   Minetti, Moia, Roi, Susta, Ferretti (2002), J Appl Physiol 93:1039,
%   5th-order fit, valid for gradients -0.45 .. +0.45 (rise/run).
%   The cost is per metre travelled ALONG the slope. Outside the measured
%   range the polynomial is held at its end value; nothing is extrapolated.

g = min(max(g, -0.45), 0.45);
c = 280.5*g.^5 - 58.7*g.^4 - 76.8*g.^3 + 51.9*g.^2 + 19.6*g + 2.5;
