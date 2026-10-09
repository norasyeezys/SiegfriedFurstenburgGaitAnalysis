function [p, t, g, z] = fb_route_at(R, s)
% FB_ROUTE_AT  Sample the route at arc length s [m].
%   p = [E; N], t = unit tangent, g = grade (rise/run), z = ground height.

n = numel(R.x);
u = min(max(s, 0), R.S)/R.ds + 1;
i = min(floor(u), n-1);
a = u - i;
p = [R.x(i) + a*(R.x(i+1)-R.x(i)); R.y(i) + a*(R.y(i+1)-R.y(i))];
t = [R.tx(i) + a*(R.tx(i+1)-R.tx(i)); R.ty(i) + a*(R.ty(i+1)-R.ty(i))];
t = t / norm(t);
g = R.g(i) + a*(R.g(i+1)-R.g(i));
z = R.z(i) + a*(R.z(i+1)-R.z(i));
