function hf = fb_summary(LOG, STEPS, R, vis)
% FB_SUMMARY  The gait-lab sheet after the climb.
%   Right-leg hip, knee and ankle angle over the gait cycle (touchdown to
%   next touchdown of the same foot), averaged separately for level
%   ground, moderate climb and steep climb. Plus step length and cadence
%   against grade, and speed and energy along the route.
%
%   LOG   columns: t, s, pelvis z, v, grade, hipL, kneeL, ankL, hipR,
%                  kneeR, ankR [deg], stance leg, energy [J]
%   STEPS columns: t touchdown, leg, s of ankle, step length, grade, v

BG = [0.10 0.10 0.12]; FG = [0.85 0.85 0.85];
hf = figure('Name', 'Siegfried climbs the Fuerstenberg: gait sheet', 'NumberTitle', 'off', ...
    'Color', BG, 'Position', [90 90 1320 720], 'Visible', vis, ...
    'InvertHardcopy', 'off', 'PaperPositionMode', 'auto');

cls  = [-0.02 0.04; 0.04 0.15; 0.15 1.0];
cnam = {'level (< 4 %)', 'climb (4-15 %)', 'steep (> 15 %)'};
ccol = [0.35 0.75 1.0; 1.0 0.8 0.2; 0.95 0.3 0.25];
pc   = linspace(0, 100, 101);
td   = STEPS(STEPS(:,2) == 2, 1);                % right-foot touchdowns
cyc  = cell(3, 3); ncyc = zeros(1, 3);
for i = 1:numel(td)-1
    m = LOG(:,1) >= td(i) & LOG(:,1) <= td(i+1);
    if sum(m) < 8, continue; end
    dur = td(i+1) - td(i);
    if dur > 4, continue; end
    gm = mean(LOG(m,5));
    c  = find(gm >= cls(:,1) & gm < cls(:,2), 1);
    if isempty(c), continue; end
    tt = 100*(LOG(m,1) - td(i))/dur;
    [tt, iu] = unique(tt);
    Y  = LOG(m, 9:11); Y = Y(iu,:);
    ncyc(c) = ncyc(c) + 1;
    for jn = 1:3
        cyc{c,jn}(end+1,:) = interp1(tt, Y(:,jn), pc, 'linear', 'extrap'); %#ok<AGROW>
    end
end

jnam = {'hip flexion [deg]', 'knee flexion [deg]', 'ankle dorsiflexion [deg]'};
for jn = 1:3
    ax = axes('Parent', hf, 'Position', [0.05 + (jn-1)*0.32, 0.57, 0.27, 0.36], 'Color', BG, ...
        'XColor', FG, 'YColor', FG, 'FontSize', 9, 'Box', 'on', 'XGrid', 'on', 'YGrid', 'on');
    hold(ax, 'on');
    for c = 1:3
        if ncyc(c) < 1, continue; end
        m = mean(cyc{c,jn}, 1);
        s = std(cyc{c,jn}, 0, 1);
        patch([pc, pc(end:-1:1)], [m + s, m(end:-1:1) - s(end:-1:1)], ccol(c,:), ...
            'Parent', ax, 'EdgeColor', 'none', 'FaceAlpha', 0.18);
        line(pc, m, 'Parent', ax, 'Color', ccol(c,:), 'LineWidth', 2);
    end
    set(ax, 'XLim', [0 100]);
    xlabel(ax, '% gait cycle (right touchdown to right touchdown)', 'Color', FG, 'FontSize', 8);
    title(ax, jnam{jn}, 'Color', FG, 'FontSize', 10, 'FontWeight', 'normal');
    if jn == 1
        for c = 1:3
            text(0.04, 0.95 - 0.07*(c-1), sprintf('%s   n = %d', cnam{c}, ncyc(c)), ...
                'Parent', ax, 'Units', 'normalized', 'Color', ccol(c,:), 'FontSize', 8);
        end
    end
end

% step length and cadence against grade
ok  = STEPS(:,4) > 0.05;
ok(1) = false; ok(end) = false;
dts = [NaN; diff(STEPS(:,1))];
ax = axes('Parent', hf, 'Position', [0.05 0.08 0.27 0.36], 'Color', BG, ...
    'XColor', FG, 'YColor', FG, 'FontSize', 9, 'Box', 'on', 'XGrid', 'on', 'YGrid', 'on');
hold(ax, 'on');
line(100*STEPS(ok,5), STEPS(ok,4), 'Parent', ax, 'LineStyle', 'none', 'Marker', '.', ...
    'Color', [0.35 0.75 1.0], 'MarkerSize', 7);
xlabel(ax, 'grade [%]', 'Color', FG, 'FontSize', 8);
ylabel(ax, 'step length [m]', 'Color', FG, 'FontSize', 8);
title(ax, 'step length on the ground he actually met', 'Color', FG, 'FontSize', 10, 'FontWeight', 'normal');

ax = axes('Parent', hf, 'Position', [0.37 0.08 0.27 0.36], 'Color', BG, ...
    'XColor', FG, 'YColor', FG, 'FontSize', 9, 'Box', 'on', 'XGrid', 'on', 'YGrid', 'on');
hold(ax, 'on');
okc = ok & dts > 0.2 & dts < 3;
line(100*STEPS(okc,5), 60./dts(okc), 'Parent', ax, 'LineStyle', 'none', 'Marker', '.', ...
    'Color', [1.0 0.8 0.2], 'MarkerSize', 7);
xlabel(ax, 'grade [%]', 'Color', FG, 'FontSize', 8);
ylabel(ax, 'cadence [steps/min]', 'Color', FG, 'FontSize', 8);
title(ax, 'cadence', 'Color', FG, 'FontSize', 10, 'FontWeight', 'normal');

% speed and energy along the route
ax = axes('Parent', hf, 'Position', [0.69 0.08 0.27 0.36], 'Color', BG, ...
    'XColor', FG, 'YColor', FG, 'FontSize', 9, 'Box', 'on', 'XGrid', 'on', 'YGrid', 'on');
hold(ax, 'on');
zn = (R.z - min(R.z))/(max(R.z) - min(R.z));
patch([R.s, R.s(end), R.s(1)], [1.6*zn, 0, 0], [0.22 0.26 0.21], 'Parent', ax, 'EdgeColor', 'none');
line(LOG(:,2), LOG(:,4), 'Parent', ax, 'Color', [0.35 0.75 1.0], 'LineWidth', 1.2);
line(LOG(:,2), 1.6*LOG(:,13)/max(LOG(end,13), 1), 'Parent', ax, 'Color', [0.95 0.3 0.25], 'LineWidth', 1.8);
set(ax, 'XLim', [0 R.S], 'YLim', [0 1.7]);
xlabel(ax, 'distance along route [m]', 'Color', FG, 'FontSize', 8);
ylabel(ax, 'speed [m/s]', 'Color', FG, 'FontSize', 8);
text(0.03, 0.94, 'speed', 'Parent', ax, 'Units', 'normalized', 'Color', [0.35 0.75 1.0], 'FontSize', 8);
text(0.03, 0.87, sprintf('energy, 0 .. %.0f kcal', LOG(end,13)/4184), 'Parent', ax, ...
    'Units', 'normalized', 'Color', [0.95 0.3 0.25], 'FontSize', 8);
text(0.03, 0.80, 'hill profile', 'Parent', ax, 'Units', 'normalized', 'Color', [0.5 0.6 0.45], 'FontSize', 8);
title(ax, 'speed and metabolic energy', 'Color', FG, 'FontSize', 10, 'FontWeight', 'normal');
