function H = fb_draw_init(D, R, vis)
% FB_DRAW_INIT  Build the window once. fb_draw only moves things afterwards.
%   Left   : the Fuerstenberg (hillshaded DGM1, 5 m contours) and the route
%   Right  : Siegfried on the real ground under his feet (1 m mesh)
%   Bottom : route profile, right-leg joint angles, readout

BG = [0.10 0.10 0.12]; FG = [0.85 0.85 0.85];
H.fig = figure('Name', 'Siegfried climbs the Fuerstenberg', 'NumberTitle', 'off', ...
    'Color', BG, 'Position', [60 60 1320 760], 'Visible', vis, ...
    'InvertHardcopy', 'off', 'PaperPositionMode', 'auto');

% ---------------- hill map ----------------
Zc = R.Zc;
zk = [15 22 35 50 62 73];
ck = [0.22 0.36 0.46; 0.30 0.48 0.30; 0.52 0.58 0.30; ...
      0.68 0.58 0.38; 0.80 0.72 0.55; 0.95 0.92 0.82];
zz = min(max(Zc, zk(1)), zk(end));
[gx, gy] = gradient(Zc, R.c);
nn = sqrt(gx.^2 + gy.^2 + 1);
sh = max((0.5*gx - 0.5*gy + 0.7071) ./ nn, 0);       % sun in the north-west
sh = 0.35 + 0.95*sh;
RGB = zeros([size(Zc) 3]);
for k = 1:3
    RGB(:,:,k) = min(max(interp1(zk, ck(:,k)', zz) .* sh, 0), 1);
end
H.axMap = axes('Parent', H.fig, 'Position', [0.035 0.34 0.43 0.62]);
image(R.Ec, R.Nc, RGB, 'Parent', H.axMap);
set(H.axMap, 'YDir', 'normal', 'DataAspectRatio', [1 1 1], 'Color', BG, ...
    'XColor', FG, 'YColor', FG, 'FontSize', 8, 'Layer', 'top');
hold(H.axMap, 'on');
[cm, hc] = contour(H.axMap, R.Ec, R.Nc, Zc, 20:5:70);  %#ok<ASGLU>
set(hc, 'LineColor', [0.1 0.1 0.1], 'LineWidth', 0.5);
pad = 140;
xl = [min(R.x)-pad, max(R.x)+pad]; yl = [min(R.y)-pad*1.6, max(R.y)+pad*1.6];
xl = [max(xl(1), R.Ec(1)), min(xl(2), R.Ec(end))];
yl = [max(yl(1), R.Nc(1)), min(yl(2), R.Nc(end))];
set(H.axMap, 'XLim', xl, 'YLim', yl);
line(R.x, R.y, 'Parent', H.axMap, 'Color', [1 1 1], 'LineWidth', 1.0, 'LineStyle', ':');
H.trail = line(R.x(1), R.y(1), 'Parent', H.axMap, 'Color', [0.95 0.25 0.2], 'LineWidth', 2.2);
line(R.x(1), R.y(1), 'Parent', H.axMap, 'Marker', 'o', 'Color', 'w', ...
    'MarkerFaceColor', [0.2 0.6 1], 'MarkerSize', 6, 'LineStyle', 'none');
line(R.x(end), R.y(end), 'Parent', H.axMap, 'Marker', '^', 'Color', 'w', ...
    'MarkerFaceColor', [1 0.85 0.2], 'MarkerSize', 8, 'LineStyle', 'none');
H.here = line(R.x(1), R.y(1), 'Parent', H.axMap, 'Marker', 'o', 'Color', 'k', ...
    'MarkerFaceColor', [0.95 0.25 0.2], 'MarkerSize', 8, 'LineStyle', 'none');
sname = 'Rhine plain';
if isfield(R, 'start_name'), sname = R.start_name; end
text(R.x(1)+12, R.y(1)-14, sname, 'Parent', H.axMap, 'Color', 'w', 'FontSize', 8);
text(R.x(end)-150, R.y(end)+22, ['F' char(252) 'rstenberg'], 'Parent', H.axMap, 'Color', 'w', ...
    'FontSize', 9, 'FontWeight', 'bold', 'Interpreter', 'none');
mtitle = 'DGM1 Xanten, trimmed to the hill (ETRS89 / UTM 32N, 1 m)';
if isfield(R, 'map_title'), mtitle = R.map_title; end
title(H.axMap, mtitle, ...
    'Color', FG, 'FontSize', 9, 'FontWeight', 'normal');
xlabel(H.axMap, 'Easting [m]', 'Color', FG, 'FontSize', 8);
ylabel(H.axMap, 'Northing [m]', 'Color', FG, 'FontSize', 8);

% ---------------- profile ----------------
H.axProf = axes('Parent', H.fig, 'Position', [0.055 0.075 0.41 0.19], 'Color', BG, ...
    'XColor', FG, 'YColor', FG, 'FontSize', 8, 'Box', 'on');
hold(H.axProf, 'on');
patch([R.s, R.s(end), R.s(1)], [R.z, 10, 10], [0.30 0.36 0.28], ...
    'Parent', H.axProf, 'EdgeColor', [0.6 0.7 0.5]);
set(H.axProf, 'XLim', [0 R.S], 'YLim', [10 78], 'XGrid', 'on', 'YGrid', 'on');
H.profDone = line(R.s(1), R.z(1), 'Parent', H.axProf, 'Color', [0.95 0.25 0.2], 'LineWidth', 2.2);
H.profHere = line(R.s(1), R.z(1), 'Parent', H.axProf, 'Marker', 'o', 'Color', 'w', ...
    'MarkerFaceColor', [0.95 0.25 0.2], 'MarkerSize', 7, 'LineStyle', 'none');
xlabel(H.axProf, 'distance along route [m]', 'Color', FG, 'FontSize', 8);
ylabel(H.axProf, 'height [m]', 'Color', FG, 'FontSize', 8);

% ---------------- the man ----------------
H.axMan = axes('Parent', H.fig, 'Position', [0.50 0.30 0.49 0.68], 'Color', BG, ...
    'XColor', [0.4 0.4 0.4], 'YColor', [0.4 0.4 0.4], 'ZColor', [0.4 0.4 0.4], ...
    'FontSize', 7, 'DataAspectRatio', [1 1 1], 'Projection', 'perspective', ...
    'XTickLabel', [], 'YTickLabel', [], 'ZTickLabel', [], 'XGrid', 'on', 'YGrid', 'on', 'ZGrid', 'on');
hold(H.axMan, 'on');
H.W = 3;                                           % half width of the ground patch [m]
n = 2*H.W + 1;
H.ground = surf(H.axMan, zeros(n), zeros(n), zeros(n), 'FaceColor', [0.20 0.28 0.17], ...
    'EdgeColor', [0.42 0.55 0.36], 'FaceAlpha', 0.92);
H.routeNear = line(0, 0, 0, 'Parent', H.axMan, 'Color', [1 1 1], 'LineStyle', ':', 'LineWidth', 1);
H.prints = line(0, 0, 0, 'Parent', H.axMan, 'LineStyle', 'none', 'Marker', 'o', ...
    'MarkerSize', 4, 'Color', [0.9 0.8 0.5], 'MarkerFaceColor', [0.9 0.8 0.5]);
CL = [0.35 0.75 1.0]; CR = [1.0 0.55 0.25]; CT = [0.9 0.9 0.9];
cols = {CL, CR};
% far-side limbs first so the near side is drawn on top
for j = 1:2
    H.arm(j)  = line(0, 0, 0, 'Parent', H.axMan, 'Color', 0.75*cols{j}, 'LineWidth', 3);
end
H.spine  = line(0, 0, 0, 'Parent', H.axMan, 'Color', CT, 'LineWidth', 5);
H.pelvis = line(0, 0, 0, 'Parent', H.axMan, 'Color', CT, 'LineWidth', 4);
H.should = line(0, 0, 0, 'Parent', H.axMan, 'Color', CT, 'LineWidth', 4);
H.head   = line(0, 0, 0, 'Parent', H.axMan, 'Marker', 'o', 'MarkerSize', 15, ...
    'Color', CT, 'MarkerFaceColor', [0.85 0.7 0.55], 'LineStyle', 'none');
for j = 1:2
    H.leg(j)  = line(0, 0, 0, 'Parent', H.axMan, 'Color', cols{j}, 'LineWidth', 5, ...
        'Marker', 'o', 'MarkerSize', 4, 'MarkerFaceColor', 'w');
    H.foot(j) = line(0, 0, 0, 'Parent', H.axMan, 'Color', cols{j}, 'LineWidth', 3);
end
H.manTitle = title(H.axMan, ' ', 'Color', FG, 'FontSize', 10, 'FontWeight', 'normal');
H.az = [];

% ---------------- joints ----------------
H.axJ = axes('Parent', H.fig, 'Position', [0.535 0.075 0.25 0.17], 'Color', BG, ...
    'XColor', FG, 'YColor', FG, 'FontSize', 8, 'Box', 'on', 'XGrid', 'on', 'YGrid', 'on');
hold(H.axJ, 'on');
H.jHip  = line(0, 0, 'Parent', H.axJ, 'Color', [0.4 0.9 0.5], 'LineWidth', 1.5);
H.jKnee = line(0, 0, 'Parent', H.axJ, 'Color', [1.0 0.8 0.2], 'LineWidth', 1.5);
H.jAnk  = line(0, 0, 'Parent', H.axJ, 'Color', [0.9 0.4 0.9], 'LineWidth', 1.5);
set(H.axJ, 'YLim', [-40 100]);
xlabel(H.axJ, 'time [s]', 'Color', FG, 'FontSize', 8);
ylabel(H.axJ, 'right leg [deg]', 'Color', FG, 'FontSize', 8);
text(0.02, 0.90, 'hip',   'Parent', H.axJ, 'Units', 'normalized', 'Color', [0.4 0.9 0.5], 'FontSize', 8);
text(0.14, 0.90, 'knee',  'Parent', H.axJ, 'Units', 'normalized', 'Color', [1.0 0.8 0.2], 'FontSize', 8);
text(0.30, 0.90, 'ankle', 'Parent', H.axJ, 'Units', 'normalized', 'Color', [0.9 0.4 0.9], 'FontSize', 8);

% ---------------- readout ----------------
H.axT = axes('Parent', H.fig, 'Position', [0.805 0.03 0.19 0.23], 'Visible', 'off', ...
    'XLim', [0 1], 'YLim', [0 1]);
H.hud = text(0, 1, ' ', 'Parent', H.axT, 'Color', FG, 'FontName', 'FixedWidth', ...
    'FontSize', 9, 'VerticalAlignment', 'top', 'Interpreter', 'none');
