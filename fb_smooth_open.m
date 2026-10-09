function v = fb_smooth_open(v, w, passes)
% FB_SMOOTH_OPEN  Moving average on an open curve, endpoints stay put.
%   v = fb_smooth_open(v, w, passes)   v row vector, w odd window length.
%   The ends are padded by point reflection, so v(1) and v(end) survive.

h = (w - 1)/2;
k = ones(1, w)/w;
n = numel(v);
if n < w + 2, return; end
for p = 1:passes
    a = 2*v(1)   - v(h+1:-1:2);
    b = 2*v(end) - v(n-1:-1:n-h);
    t = conv([a, v, b], k);
    v = t(w : w+n-1);
end
