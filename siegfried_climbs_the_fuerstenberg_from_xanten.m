function siegfried_climbs_the_fuerstenberg_from_xanten(frame_skip, snap_dir)
% SIEGFRIED CLIMBS THE FUERSTENBERG FROM XANTEN -- Xanten GIS to gait, v2
% He is a man of Xanten. He leaves the town at St. Viktor, walks south-east
% across the lower terrace and up the long north-west shoulder of the
% Fuerstenberg to the same summit as in version 1. This is the way he
% would actually go. The ground is the real one: Geobasis NRW DGM1, 1 m
% bare earth, trimmed to a 1.6 x 2.3 km strip from the town to the hill.
%
% Version 1 (siegfried_climbs_the_fuerstenberg.m) comes from the Bislich
% floodplain in the east: 100 m of dead level, then the scarp. Better for
% biomechanics. This one is 2.1 km, never steeper than 22 %, and mostly a
% slow rise: better for the man. Gait, body and gains are IDENTICAL to
% version 1 so the two walks can be compared number for number.
%
% The DGM1 is bare earth: houses and trees are already removed, so the
% route crosses the town as open ground. Streets and walls are not known
% to him here.
%
%   siegfried_climbs_the_fuerstenberg_from_xanten            animate, one frame per 0.1 s
%   siegfried_climbs_the_fuerstenberg_from_xanten(15)        one frame per 0.3 s, faster
%   siegfried_climbs_the_fuerstenberg_from_xanten(0)         no animation, summary only
%   siegfried_climbs_the_fuerstenberg_from_xanten(n, dir)    headless, PNG snapshots to dir
%
% Architecture (same line as the sword chase, carried down to the legs):
%   Ground        : fb_trim_dem cuts the hill out of ~/dgm1_xanten_merged.tif
%                   once and caches it. Every foothold height, every ground
%                   pitch under a sole, every contact test reads that raster.
%   Route         : least metabolic energy from the plain to the summit
%                   (Minetti 2002 cost of gradient walking on a 3 m graph).
%                   Planned once, before the first step.
%   Consciousness : once per step, at touchdown. He plans ONE step: speed
%                   from the grade ahead (Tobler), step length from speed,
%                   the foothold from the map. He does not think about
%                   his knees.
%   Gait layer    : 50 Hz, below consciousness. Turns the step plan into
%                   joint targets by trying candidates in forward
%                   kinematics. No IK. (10 Hz is enough for an arm; a leg
%                   that swings through in 0.4 s drags its toe at 10 Hz.)
%   Reflex core   : 100 Hz. PD on hip, knee, hip abduction and heel rise of
%                   both legs. No I-term anywhere. Nothing integrates error.
%   Body          : the planted foot is the root. Pelvis position is FK
%                   upward from the ball of the stance foot through the
%                   ACTUAL joint angles, so a lagging joint moves the whole
%                   man. The swing foot hangs from that pelvis and lands
%                   where it really meets the ground, not where it was told.
%
% What this is not: there is no balance, no ground reaction force and no
% torque limit. It is a kinematic gait on true terrain, driven by PD joints.
% Falling is the next file.
%
% Helper functions live in fuerstenberg_gait/ (one function per file).
% MATLAB R2012b, no toolboxes. SI units. E east, N north, z up.

if nargin < 1 || isempty(frame_skip), frame_skip = 5; end
if nargin < 2, snap_dir = ''; end
headless = ~isempty(snap_dir);
if headless && ~exist(snap_dir, 'dir'), mkdir(snap_dir); end

here = fileparts(mfilename('fullpath'));
gdir = fullfile(here, 'fuerstenberg_gait');
addpath(gdir);

% ------------------------------------------------------------------
% THE HILL
% ------------------------------------------------------------------
WIN   = [323500 325100 5724450 5726750];   % [Emin Emax Nmin Nmax], UTM 32N
[sE, sN] = fb_ll2utm(51.66240226835185, 6.453457215290386);   % St. Viktor,
START = [sE sN];                           % from xanten_roman_features.csv
GOAL  = [324832 5724731];                  % the summit version 1 arrives at
D = fb_trim_dem(fullfile(gdir, 'xanten_to_fuerstenberg_dgm1.mat'), WIN);

rfile = fullfile(gdir, 'xanten_to_fuerstenberg_route.mat');
if exist(rfile, 'file')
    S = load(rfile); R = S.R;
else
    fprintf('Planning the way up (once, about 20 s) ...\n');
    R = fb_plan_route(D, START, GOAL, 3);
    R.start_name = 'Xanten, St. Viktor';
    R.map_title  = 'DGM1 Xanten, town to hill (ETRS89 / UTM 32N, 1 m)';
    save(rfile, 'R');
end
fprintf('Route: %.0f m, from %.1f m to %.1f m, steepest %.0f %%\n', ...
    R.S, R.z(1), R.z(end), 100*max(R.g));

% ------------------------------------------------------------------
% THE MAN (190 cm, same frame as the sword chase)
% ------------------------------------------------------------------
B.L_TH   = 0.47;     % thigh [m]
B.L_SH   = 0.46;     % shank [m]
B.ANK_H  = 0.08;     % ankle above the sole [m]
B.BALL_X = 0.17;     % ankle to ball of foot, along the sole [m]
B.HEEL_X = 0.07;     % ankle back to heel [m]
B.TOE_X  = 0.07;     % ball to toe tip [m]
B.HIP_W  = 0.09;     % half distance between hip joints [m]
B.FOOT_W = 0.075;    % half step width [m]
B.TRUNK  = 0.56;     % hip line to shoulder line [m] (shoulders at 1.57)
B.SH_W   = 0.26;     % half biacromial [m]
B.NECK   = 0.21;     % shoulder line to head centre [m]
B.L_UP   = 0.36;     % upper arm [m]
B.L_FORE = 0.39;     % forearm + hand [m]
B.MASS   = 95;       % [kg]
Lleg = B.L_TH + B.L_SH;
SG   = [1 -1];       % leg 1 = left, leg 2 = right

% ------------------------------------------------------------------
% GAIT
% ------------------------------------------------------------------
G.V0     = fb_tobler_speed(0);   % level speed, 1.40 m/s
G.L0     = 0.78;     % level step length [m] (0.41 x stature)
G.DZMAX  = 0.20;     % most height one step may gain [m]
G.HC     = 0.985;    % hip height over the stance ankle at mid-stance / leg
G.LMAX   = 0.995;    % furthest the leg is asked to reach / leg
G.TH_TO  = 0.55;     % heel rise at toe-off [rad]
G.TH_MAX = 0.75;     % heel rise the hip plan may count on [rad]
G.CLR    = 0.06;     % swing clearance over the ground [m]
G.LEAD   = 0.03;     % hip ahead of the mid-point between the feet at touchdown [m]
G.SWAY   = 0.02;     % pelvis sway toward the stance foot [m]
DSF      = 0.15;     % share of the step with both feet down
TDF      = 0.95;     % phase at which the foot is asked to be down

% ------------------------------------------------------------------
% MUSCLES (PD at the joint, 100 Hz; legs are stiffer than arms)
% ------------------------------------------------------------------
KP = 600; KD = 33; JI = 0.55;
DT   = 0.01;                    % reflex, 100 Hz
SUB  = 2;                       % reflex steps per gait-layer tick
DT_C = DT*SUB;                  % gait layer, 50 Hz
Q_LO = [-0.9; 0.0; -0.35; 0.0];
Q_HI = [ 1.9; 2.4;  0.35; 0.9];

% ------------------------------------------------------------------
% STAND AT THE START
% ------------------------------------------------------------------
[pc, tc, gc] = fb_route_at(R, 0);
psi = atan2(tc(2), tc(1));
f = [tc; 0]; l = [-tc(2); tc(1); 0];
ball = zeros(3,2); ffv = zeros(3,2); sig = zeros(1,2);
ank0 = zeros(3,2);
for j = 1:2
    xy = pc + SG(j)*B.FOOT_W*l(1:2);
    ank0(:,j) = [xy; fb_terrain_z(D, xy(1), xy(2)) + B.ANK_H];
    [ball(:,j), sig(j)] = fb_foot_place(D, ank0(:,j), f, B);
    ffv(:,j) = f;
end
z_des = min(ank0(3,:)) + G.HC*Lleg;
pel   = [pc; z_des];
q  = zeros(4,2); qd = zeros(4,2);
for j = 1:2
    q(:,j) = fb_leg_search([0.15; 0.30; 0; 0], pel + SG(j)*B.HIP_W*l, f, l, SG(j), ...
                           1, ank0(:,j), f, 0, B);
end
st = 1; sw = 2;                 % left foot holds, right foot goes first
s_des = 0; v_cur = 0; late = 0;
P = fb_plan_step(R, D, B, G, 0, ank0(:,st), ball(:,st), ffv(:,st), sig(st), ...
                 s_des, z_des, SG(sw), 0, ball(:,sw), ffv(:,sw), sig(sw));
qt_new = q; qt_prev = q;
psi_prev = psi; psi_new = psi;
psw = sig(sw);  psw_t = psw;    % pitch of the free foot (drawn, not driven)
up3 = [0; 0; 1];
x3 = [0.05; 0; 0]; x3d = [0; 0; 0]; x3t = x3;    % trunk lean, arm L, arm R
finished = false; settle = 0;
hip = zeros(3,2); knee = zeros(3,2); ank = ank0;

% logs
NL = 300000; LOG = zeros(NL, 13); nl = 0;
STEPS = zeros(10000, 6); ns = 0;
prints = zeros(3, 0);
t = 0; tick = 0; energy = 0; s_last = 0; climbed = 0; z_last = pel(3);

if frame_skip > 0
    if headless, vis = 'off'; else vis = 'on'; end
    H = fb_draw_init(D, R, vis);
    set(H.fig, 'Name', 'Siegfried climbs the Fuerstenberg from Xanten');
    next_snap = 0;
end

% ==================================================================
% THE WALK
% ==================================================================
while tick < 300000
    tick = tick + 1;

    % ---------------- gait layer, 50 Hz ----------------
    if ~finished
        v_cur = v_cur + 0.08*(P.v - v_cur);
        s_new = s_des + v_cur*DT_C;
        if s_new >= P.s1                 % hip is where the step ends: wait
            s_new = P.s1;                % for the foot, and press it down
            late  = late + DT_C;
        end
        s_des = s_new;
    end
    phi = min(max((s_des - P.s0)/(P.s1 - P.s0), 0), 1);

    [pc, tc, gc] = fb_route_at(R, s_des);
    psi_prev = psi_new;
    psi_new  = atan2(tc(2), tc(1));
    f = [tc; 0]; l = [-tc(2); tc(1); 0];

    if phi < P.phim
        z_des = P.z0 + (P.zm - P.z0)*0.5*(1 - cos(pi*phi/P.phim));
    else
        z_des = P.zm + (P.z1 - P.zm)*0.5*(1 - cos(pi*(phi - P.phim)/(1 - P.phim)));
    end
    pel_des  = [pc + G.SWAY*SG(st)*sin(pi*phi)*l(1:2); z_des];
    hipS_des = pel_des + SG(st)*B.HIP_W*l;
    hipW_des = pel_des + SG(sw)*B.HIP_W*l;

    qt_prev = qt_new;
    qt_new(:,st) = fb_leg_search(qt_new(:,st), hipS_des, f, l, SG(st), 2, ...
                                 ball(:,st), ffv(:,st), sig(st), B);

    % where the free ankle should be at the end of this tick
    tau = (phi - DSF)/(TDF - DSF) + late/0.25;
    if finished
        aw = fb_foot_fk(ball(:,sw), ffv(:,sw), sig(sw), B);
        psw_t = sig(sw);
    elseif phi < DSF
        th = P.th0 + (P.thTO - P.th0)*phi/DSF;      % still down, rolling onto the toe
        aw = fb_foot_fk(ball(:,sw), ffv(:,sw), sig(sw) - th, B);
        psw_t = sig(sw) - th;
    else
        tc1 = min(tau, 1);
        e   = 10*tc1^3 - 15*tc1^4 + 6*tc1^5;
        aw  = P.Pto + (P.Pb - P.Pto)*e;
        aw(3) = aw(3) + P.C*sin(pi*tc1);
        if tau > 1, aw(3) = aw(3) - 0.25*(tau - 1); end
        psw_t = (1 - e)*(sig(sw) - P.thTO) + e*P.sigB;
    end
    qt_new(:,sw) = fb_leg_search(qt_new(:,sw), hipW_des, f, l, SG(sw), 1, aw, f, 0, B);
    qt_new(4,sw) = 0;

    hm  = 0.5*(qt_new(1,1) + qt_new(1,2));
    x3p = x3t;
    x3t = [0.05 + 0.55*atan(gc); -0.7*(qt_new(1,1) - hm); -0.7*(qt_new(1,2) - hm)];

    % ---------------- reflex, 100 Hz ----------------
    dpsi = mod(psi_new - psi_prev + pi, 2*pi) - pi;
    landed = false;
    for k = 1:SUB
        a   = k/SUB;
        qs  = qt_prev + (qt_new - qt_prev)*a;
        qsd = (qt_new - qt_prev)/DT_C;
        qdd = (KP*(qs - q) + KD*(qsd - qd))/JI;
        qd  = qd + qdd*DT;
        q   = q + qd*DT;
        for j = 1:2
            q(:,j) = min(max(q(:,j), Q_LO), Q_HI);
        end
        x3s = x3p + (x3t - x3p)*a;
        x3d = x3d + (60*(x3s - x3) - 12*x3d)/0.55*DT;      % arm gains from the sword chase
        x3  = x3 + x3d*DT;
        psi = psi_prev + a*dpsi;
        fr  = [cos(psi); sin(psi); 0]; lr = [-sin(psi); cos(psi); 0];
        t   = t + DT;

        % the body, from the planted foot upward
        ank(:,st) = fb_foot_fk(ball(:,st), ffv(:,st), sig(st) - q(4,st), B);
        [kr, ar]  = fb_leg_fk([0;0;0], q(:,st), fr, lr, SG(st), B);
        hip(:,st)  = ank(:,st) - ar;
        knee(:,st) = hip(:,st) + kr;
        pel        = hip(:,st) - SG(st)*B.HIP_W*lr;
        hip(:,sw)  = pel + SG(sw)*B.HIP_W*lr;
        [knee(:,sw), ank(:,sw)] = fb_leg_fk(hip(:,sw), q(:,sw), fr, lr, SG(sw), B);
        psw = psw + 0.25*(psw_t - psw);

        if k == SUB && nl < NL
            pf = [0 0]; pf(st) = sig(st) - q(4,st); pf(sw) = psw;
            nl = nl + 1;
            LOG(nl,:) = [t, s_des, pel(3), v_cur, gc, ...
                (q(1,1) + x3(1))*180/pi, q(2,1)*180/pi, (pf(1) - (q(1,1) - q(2,1)))*180/pi, ...
                (q(1,2) + x3(1))*180/pi, q(2,2)*180/pi, (pf(2) - (q(1,2) - q(2,2)))*180/pi, ...
                st, energy];
        end

        % touchdown: the free foot meets the real ground
        if ~finished && tau > 0.5 && ...
                ank(3,sw) - B.ANK_H <= fb_terrain_z(D, ank(1,sw), ank(2,sw)) + 0.003
            landed = true;
            break;
        end
    end

    % metabolic bill for the ground covered this tick (Minetti, J/kg/m)
    ds = s_des - s_last; s_last = s_des;
    energy  = energy + fb_minetti_cost(gc)*B.MASS*ds*sqrt(1 + gc^2);
    climbed = climbed + max(pel(3) - z_last, 0); z_last = pel(3);

    if landed
        [ball(:,sw), sig(sw)] = fb_foot_place(D, ank(:,sw), fr, B);
        ffv(:,sw) = fr;
        q(4,sw) = 0; qd(4,sw) = 0;
        th0 = q(4,st);
        sA  = s_des + (ank(1:2,sw) - pc)'*tc;
        ns  = ns + 1;
        STEPS(ns,:) = [t, sw, sA, norm(ank(1:2,sw) - ank(1:2,st)), gc, v_cur];
        prints(:,end+1) = ank(:,sw) - [0; 0; B.ANK_H]; %#ok<AGROW>
        tmp = st; st = sw; sw = tmp;
        if P.last
            finished = true;
            P.s0 = s_des - 1; P.s1 = s_des; P.z0 = z_des; P.zm = z_des; P.phim = 0.5;
        else
            P = fb_plan_step(R, D, B, G, sA, ank(:,st), ball(:,st), ffv(:,st), sig(st), ...
                             s_des, z_des, SG(sw), th0, ball(:,sw), ffv(:,sw), sig(sw));
        end
        late = 0;
        psw  = sig(sw) - th0;
        qt_new = q;                      % intentions restart from where the body is
    end
    if finished
        settle = settle + 1;
        if settle > 60, break; end
    end

    % ---------------- draw ----------------
    if frame_skip > 0 && (mod(tick, frame_skip) == 0 || finished)
        pf = [0 0]; pf(st) = sig(st) - q(4,st); pf(sw) = psw;
        fd = ffv; fd(:,sw) = fr;
        V.K = fb_skeleton(B, pel, fr, lr, x3(1), x3(2:3), hip, knee, ank, pf, fd);
        V.s = s_des; V.pel = pel; V.psi = psi;
        V.prints = prints(:, max(1, end-11):end);
        i1 = max(nl - 250, 1);
        V.tt = LOG(i1:nl,1)'; V.hip = LOG(i1:nl,9)'; V.knee = LOG(i1:nl,10)'; V.ank = LOG(i1:nl,11)';
        cad = 0; sl = 0;
        if ns > 2
            cad = 60/(STEPS(ns,1) - STEPS(ns-1,1));
            sl  = STEPS(ns,4);
        end
        V.hud = { ...
            sprintf('time      %5.0f s  (%4.1f min)', t, t/60), ...
            sprintf('distance  %5.0f / %.0f m', s_des, R.S), ...
            sprintf('height    %5.1f m   (+%.1f)', pel(3) - Lleg - B.ANK_H, R.z(min(floor(s_des/R.ds)+1, end)) - R.z(1)), ...
            sprintf('grade     %+5.0f %%', 100*gc), ...
            sprintf('speed     %5.2f m/s', v_cur), ...
            sprintf('step      %5.2f m   %3.0f /min', sl, cad), ...
            sprintf('steps     %5d', ns), ...
            sprintf('energy    %5.1f kcal', energy/4184), ...
            sprintf('power     %5.0f W', fb_minetti_cost(gc)*B.MASS*v_cur*sqrt(1 + gc^2))};
        if finished
            V.title = ['He stands on the F' char(252) 'rstenberg. Xanten is behind him.'];
        elseif gc > 0.15
            V.title = 'steep: short steps, bent knees, trunk into the hill';
        elseif gc > 0.04
            V.title = 'climbing';
        else
            V.title = 'level walking';
        end
        H = fb_draw(H, D, R, V);
        if headless && (t >= next_snap || finished)
            print(H.fig, fullfile(snap_dir, sprintf('fb_%05.0f.png', t)), '-dpng', '-r80');
            next_snap = next_snap + 180;
        end
    end
end

LOG = LOG(1:nl,:); STEPS = STEPS(1:ns,:);
fprintf('Summit after %.0f s (%.1f min): %d steps, %.0f m walked, %.1f m climbed.\n', ...
    t, t/60, ns, s_des, R.z(end) - R.z(1));
fprintf('Mean speed %.2f m/s, mean step %.2f m, %.0f kcal (%.0f kJ), mean %.0f W.\n', ...
    s_des/t, mean(STEPS(:,4)), energy/4184, energy/1000, energy/t);
if finished
    fprintf('He stands on the Fuerstenberg.\n');
else
    fprintf('He did not make it. Stopped at %.0f m.\n', s_des);
end

if headless, vis = 'off'; else vis = 'on'; end
hs = fb_summary(LOG, STEPS, R, vis);
if headless
    print(hs, fullfile(snap_dir, 'fb_summary.png'), '-dpng', '-r80');
    save(fullfile(snap_dir, 'fb_log.mat'), 'LOG', 'STEPS');
end
