function q = fb_leg_search(q0, hip, f, l, sgn, mode, P, ff, sig, B)
% FB_LEG_SEARCH  Pick joint targets for one leg by trying candidates in FK.
%   No inverse kinematics, no Jacobian. A grid of candidate joint angles
%   around the last target is pushed through forward kinematics, the
%   candidate whose ankle lands closest wins, and the grid shrinks around
%   it. Same idea as the arm in the sword chase, minus the exploration.
%
%   q0   : [hip flexion; knee flexion; hip abduction; heel rise] warm start
%   hip  : where this leg's hip joint is wanted
%   mode 1 (swing)  : P = wanted ankle position. Heel rise is not searched.
%   mode 2 (stance) : P = ball of the planted foot (ff heading, sig ground
%                     pitch). The ankle rides on the foot, so heel rise is
%                     a fourth candidate dimension. It is only allowed once
%                     the hip has passed over the ankle, and it is charged
%                     a small price so he rises on his toes only when the
%                     leg would otherwise be too short.

lo = [-0.9; 0.03; -0.30; 0.0];
hi = [ 1.9; 2.40;  0.30; 0.9];
span = [0.22; 0.28; 0.08; 0.22];
g = linspace(-1, 1, 5);
q = min(max(q0(:), lo), hi);

if mode == 1
    [G1, G2, G3] = ndgrid(g, g, g);
    G4 = 0;
    d  = P - hip;
    tx = d'*f; ty = d'*l; tz = d(3);
    reg = 0;
    thmax = 0;
else
    [G1, G2, G3, G4] = ndgrid(g, g, g, g);
    d  = P - hip;
    b0 = [d'*f; d'*l; d(3)];
    cf = ff'*f; cl = ff'*l;
    a0 = -B.BALL_X*cos(sig) - B.ANK_H*sin(sig);
    if b0(1) + a0*cf < -0.02          % flat ankle is behind the hip
        thmax = hi(4);
    else
        thmax = 0;
    end
end

for lev = 1:5
    h = min(max(q(1) + span(1)*G1, lo(1)), hi(1));
    k = min(max(q(2) + span(2)*G2, lo(2)), hi(2));
    b = min(max(q(3) + span(3)*G3, lo(3)), hi(3));
    if mode == 2
        th = min(max(q(4) + span(4)*G4, 0), thmax);
        p  = sig - th;
        a  = -B.BALL_X*cos(p) - B.ANK_H*sin(p);
        tx = b0(1) + a*cf;
        ty = b0(2) + a*cl;
        tz = b0(3) - B.BALL_X*sin(p) + B.ANK_H*cos(p);
        reg = 1e-3*th.^2;
    end
    x = B.L_TH*sin(h) + B.L_SH*sin(h-k);
    r = B.L_TH*cos(h) + B.L_SH*cos(h-k);
    y = sgn*r.*sin(b);
    z = -r.*cos(b);
    c = (x-tx).^2 + (y-ty).^2 + (z-tz).^2 + reg ...
        + 2e-3*((h-q0(1)).^2 + (k-q0(2)).^2);      % of two equal poses, the nearer one
    [cmin, i] = min(c(:));  %#ok<ASGLU>
    q(1) = h(i); q(2) = k(i); q(3) = b(i);
    if mode == 2, q(4) = th(i); end
    span = 0.45*span;
end
