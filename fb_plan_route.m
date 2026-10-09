function R = fb_plan_route(D, startEN, goalEN, c)
% FB_PLAN_ROUTE  The way up: least metabolic energy over the real ground.
%   R = fb_plan_route(D, [E N], [E N])     goalEN = [] means the summit.
%   R = fb_plan_route(D, [E N], [E N], c)  planning cell in metres (default 2).
%
%   The DGM1 is block-averaged to 2 m. Every cell is linked to 16
%   neighbours (king + knight moves). Each edge is walked in ~1 m pieces
%   over the full-resolution ground, and every piece is charged Minetti's
%   metabolic cost at its own gradient times its slope length. So the
%   route climbs at the gradient a human finds cheapest, goes AROUND the
%   scarp instead of straight up it, and cannot hop a ditch unseen. Beyond the measured +-45 % the
%   cost is multiplied by a steepness penalty: he walks, he does not climb.
%
%   Shortest path by vectorised label correcting (no toolboxes, no heap).
%   The cell path is then smoothed and resampled every 0.10 m.

if nargin < 4 || isempty(c), c = 2; end
[ny, nx] = size(D.Z);
my = floor(ny/c); mx = floor(nx/c);
Zc = reshape(double(D.Z(1:my*c, 1:mx*c)), c, my, c, mx);
Zc = reshape(mean(mean(Zc, 1), 3), my, mx);
Ec = D.E(1) + (c-1)/2 + (0:mx-1)*c;
Nc = D.N(1) + (c-1)/2 + (0:my-1)'*c;

if isempty(goalEN)
    Zs = conv2(Zc, ones(15)/225, 'same');      % 30 m box: the hill, not a mound
    [zmax, im] = max(Zs(:));  %#ok<ASGLU>
    [gi, gj] = ind2sub([my mx], im);
else
    [dmy, gj] = min(abs(Ec - goalEN(1)));  %#ok<ASGLU>
    [dmy, gi] = min(abs(Nc - goalEN(2)));  %#ok<ASGLU>
end
[dmy, sj] = min(abs(Ec - startEN(1)));  %#ok<ASGLU>
[dmy, si] = min(abs(Nc - startEN(2)));  %#ok<ASGLU>

offs = [1 0; -1 0; 0 1; 0 -1; 1 1; 1 -1; -1 1; -1 -1; ...
        1 2; 1 -2; -1 2; -1 -2; 2 1; 2 -1; -2 1; -2 -1];
K = size(offs, 1);
DI = cell(K,1); DJ = cell(K,1); SI = cell(K,1); SJ = cell(K,1); C = cell(K,1);
for k = 1:K
    di = offs(k,1); dj = offs(k,2);
    DI{k} = max(1, 1+di) : min(my, my+di);  SI{k} = DI{k} - di;
    DJ{k} = max(1, 1+dj) : min(mx, mx+dj);  SJ{k} = DJ{k} - dj;
    run  = c*sqrt(di^2 + dj^2);
    nseg = ceil(run);
    [Xd, Yd] = meshgrid(Ec(DJ{k}), Nc(DI{k}));
    [Xs, Ys] = meshgrid(Ec(SJ{k}), Nc(SI{k}));
    C{k} = zeros(size(Xd));
    za = fb_terrain_z(D, Xs, Ys);
    for q = 1:nseg
        a  = q/nseg;
        zb = fb_terrain_z(D, Xs + a*(Xd-Xs), Ys + a*(Yd-Ys));
        g  = (zb - za) / (run/nseg);
        C{k} = C{k} + fb_minetti_cost(g) .* (1 + 25*max(abs(g) - 0.45, 0)) ...
                      .* (run/nseg) .* sqrt(1 + g.^2);
        za = zb;
    end
end

T = inf(my, mx);  T(si, sj) = 0;
Pred = zeros(my, mx);
for sweep = 1:5000
    changed = false;
    for k = 1:K
        cand = T(SI{k}, SJ{k}) + C{k};
        cur  = T(DI{k}, DJ{k});
        m    = cand < cur - 1e-9;
        if any(m(:))
            cur(m) = cand(m);
            T(DI{k}, DJ{k}) = cur;
            pk = Pred(DI{k}, DJ{k});
            pk(m) = k;
            Pred(DI{k}, DJ{k}) = pk;
            changed = true;
        end
    end
    if ~changed, break; end
end

% walk the predecessors back from the summit
pi_ = gi; pj_ = gj;
ii = gi; jj = gj;
while ~(ii == si && jj == sj)
    k  = Pred(ii, jj);
    ii = ii - offs(k,1);
    jj = jj - offs(k,2);
    pi_(end+1) = ii; pj_(end+1) = jj; %#ok<AGROW>
end
px = Ec(pj_(end:-1:1));
py = Nc(pi_(end:-1:1))';

% resample 1 m, smooth, resample 0.10 m
sc = [0, cumsum(sqrt(diff(px).^2 + diff(py).^2))];
s1 = 0:1:sc(end);
x1 = fb_smooth_open(interp1(sc, px, s1), 7, 3);
y1 = fb_smooth_open(interp1(sc, py, s1), 7, 3);
sc = [0, cumsum(sqrt(diff(x1).^2 + diff(y1).^2))];
ds = 0.10;
s  = 0:ds:sc(end);
x  = interp1(sc, x1, s);
y  = interp1(sc, y1, s);
z  = fb_terrain_z(D, x, y);

zs = fb_smooth_open(z, 41, 2);                 % ~4 m: what the legs average over
g  = gradient(zs, ds);
tx = gradient(fb_smooth_open(x, 21, 1), ds);
ty = gradient(fb_smooth_open(y, 21, 1), ds);
tn = sqrt(tx.^2 + ty.^2);

R.x = x; R.y = y; R.z = z; R.g = g; R.s = s;
R.tx = tx./tn; R.ty = ty./tn;
R.ds = ds; R.S = s(end);
R.Ec = Ec; R.Nc = Nc; R.Zc = Zc; R.c = c;
R.start = [x(1) y(1)]; R.goal = [x(end) y(end)];
R.energy_per_kg = T(gi, gj);                    % J/kg on the planning graph
