function [E, N] = fb_ll2utm(lat, lon)
% FB_LL2UTM  Geographic (ETRS89 / GRS80, degrees) to UTM zone 32N [m].
%   Snyder's transverse Mercator series, good to a millimetre here.
%   Lets the start be given the way the Xanten feature table gives it.

a = 6378137.0; fl = 1/298.257222101; k0 = 0.9996;
e2 = fl*(2 - fl); ep2 = e2/(1 - e2);
phi = lat*pi/180; lam = lon*pi/180; lam0 = 9*pi/180;
Nn = a./sqrt(1 - e2*sin(phi).^2);
T  = tan(phi).^2;
C  = ep2*cos(phi).^2;
A  = (lam - lam0).*cos(phi);
M  = a*((1 - e2/4 - 3*e2^2/64 - 5*e2^3/256)*phi ...
      - (3*e2/8 + 3*e2^2/32 + 45*e2^3/1024)*sin(2*phi) ...
      + (15*e2^2/256 + 45*e2^3/1024)*sin(4*phi) ...
      - (35*e2^3/3072)*sin(6*phi));
E = 500000 + k0*Nn.*(A + (1 - T + C).*A.^3/6 ...
      + (5 - 18*T + T.^2 + 72*C - 58*ep2).*A.^5/120);
N = k0*(M + Nn.*tan(phi).*(A.^2/2 + (5 - T + 9*C + 4*C.^2).*A.^4/24 ...
      + (61 - 58*T + T.^2 + 600*C - 330*ep2).*A.^6/720));
