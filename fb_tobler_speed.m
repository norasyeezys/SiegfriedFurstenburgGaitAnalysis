function v = fb_tobler_speed(g)
% FB_TOBLER_SPEED  Walking speed on a gradient [m/s].
%   Tobler (1993) hiking function: 6*exp(-3.5*|g + 0.05|) km/h.
%   5.04 km/h on the flat, fastest on a slight descent.

v = 6*exp(-3.5*abs(g + 0.05)) / 3.6;
