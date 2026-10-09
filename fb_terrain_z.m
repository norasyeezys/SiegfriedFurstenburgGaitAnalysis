function z = fb_terrain_z(D, x, y)
% FB_TERRAIN_Z  Bilinear ground height from the trimmed DGM1.
%   z = fb_terrain_z(D, x, y)   x = easting, y = northing (any shape).

[ny, nx] = size(D.Z);
fx = (x - D.E(1)) + 1;
fy = (y - D.N(1)) + 1;
fx = min(max(fx, 1), nx - 1e-6);
fy = min(max(fy, 1), ny - 1e-6);
j  = floor(fx);  a = fx - j;
i  = floor(fy);  b = fy - i;
i0 = i + (j-1)*ny;
z  = (1-a).*(1-b).*double(D.Z(i0))    + a.*(1-b).*double(D.Z(i0+ny)) + ...
     (1-a).*b    .*double(D.Z(i0+1))  + a.*b    .*double(D.Z(i0+ny+1));
