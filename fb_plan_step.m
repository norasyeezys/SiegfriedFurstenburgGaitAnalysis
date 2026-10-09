function P = fb_plan_step(R, D, B, G, sA, ankA, ballA, ffA, sigA, s_now, z_now, sgnB, th0, ballO, ffO, sigO)
% FB_PLAN_STEP  One step ahead: where the free foot goes and how the hip rides.
%   Called at every touchdown. The foot that just landed is A (ankle ankA
%   at route arc length sA). The other foot (ball ballO, heel rise th0) is
%   about to leave the ground and is sent to foothold B.
%
%   Speed from Tobler on the grade ahead. Step length follows speed
%   (Grieve: L ~ v^0.42) and is cut so one step never rises more than
%   G.DZMAX. The foothold height is read off the DGM1.
%
%   Hip height is three knots joined by cosine ramps:
%     z0  where the hip is now
%     zm  over foot A, leg almost straight (the vault)
%     z1  at the next touchdown, as high as BOTH legs allow: the front leg
%         reaching B, the rear leg pushing off A on its toes.

Lleg = B.L_TH + B.L_SH;
LM   = G.LMAX*Lleg;

[pa, ta, g] = fb_route_at(R, min(sA + 0.6, R.S));  %#ok<ASGLU>
v = fb_tobler_speed(g);
L = G.L0*(v/G.V0)^0.42;
L = min(L, G.DZMAX/max(abs(g), 1e-3));
L = max(L, 0.22);

P.last = false;
if sA >= R.S - 0.30
    P.last = true;                 % close the feet and stand
    sB = sA;
elseif sA + L > R.S
    sB = R.S;
else
    sB = sA + L;
end

[pb, tb] = fb_route_at(R, sB);
lb  = [-tb(2); tb(1)];
xy  = pb + sgnB*B.FOOT_W*lb;
zB  = fb_terrain_z(D, xy(1), xy(2)) + B.ANK_H;
P.Pb = [xy; zB];
zf  = fb_terrain_z(D, xy(1) + B.BALL_X*tb(1), xy(2) + B.BALL_X*tb(2));
zh  = fb_terrain_z(D, xy(1) - B.HEEL_X*tb(1), xy(2) - B.HEEL_X*tb(2));
P.sigB = atan2(zf - zh, B.BALL_X + B.HEEL_X);

% toe-off pose of the leaving foot, and the clearance its arc needs
P.th0  = th0;
P.thTO = max(th0, G.TH_TO);
P.Pto  = fb_foot_fk(ballO, ffO, sigO - P.thTO, B);
a  = linspace(0.1, 0.9, 9);
lx = P.Pto(1) + a*(P.Pb(1) - P.Pto(1));
ly = P.Pto(2) + a*(P.Pb(2) - P.Pto(2));
lz = P.Pto(3) + a*(P.Pb(3) - P.Pto(3));
ex = max(fb_terrain_z(D, lx, ly) + B.ANK_H - lz);
P.C = G.CLR + 1.2*max(ex, 0);

% pelvis clock for this step
P.s0 = s_now;
if P.last
    P.s1 = sA;
else
    P.s1 = 0.5*(sA + sB) + G.LEAD;
end
P.s1   = max(P.s1, P.s0 + 0.05);
P.phim = min(max((sA - P.s0)/(P.s1 - P.s0), 0.2), 0.8);

% hip height knots
zA   = ankA(3);
P.z0 = z_now;
P.zm = zA + G.HC*Lleg;
dB   = sB - P.s1;
z1f  = zB + sqrt(max(LM^2 - dB^2, 0.09));
ankR = fb_foot_fk(ballA, ffA, sigA - G.TH_MAX, B);
dr   = (P.s1 - sA) - (ankR - ankA)'*ffA;
z1r  = ankR(3) + sqrt(max(LM^2 - dr^2, 0.09));
P.z1 = min([z1f, z1r, max(zA, zB) + G.HC*Lleg]);
if P.last
    P.z1 = min(zA, zB) + G.HC*Lleg;
end

P.sA = sA; P.sB = sB; P.L = sB - sA; P.v = v; P.g = g;
