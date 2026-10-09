function H = fb_draw(H, D, R, V)
% FB_DRAW  Move everything in the window to the current instant.
%   V.s, V.pel, V.psi, V.K (from fb_skeleton), V.prints (3 x n),
%   V.tt/V.hip/V.knee/V.ank (joint history), V.hud (cell of lines),
%   V.title (string)

% map + profile
i = min(floor(V.s/R.ds) + 1, numel(R.x));
set(H.trail, 'XData', R.x(1:i), 'YData', R.y(1:i));
set(H.here,  'XData', V.pel(1), 'YData', V.pel(2));
set(H.profDone, 'XData', R.s(1:i), 'YData', R.z(1:i));
set(H.profHere, 'XData', R.s(i), 'YData', R.z(i));

% ground patch: the real 1 m cells around him
[ny, nx] = size(D.Z);
jc = round(V.pel(1) - D.E(1)) + 1;
ic = round(V.pel(2) - D.N(1)) + 1;
jj = min(max(jc + (-H.W:H.W), 1), nx);
ii = min(max(ic + (-H.W:H.W), 1), ny);
[X, Y] = meshgrid(D.E(jj), D.N(ii));
Z = double(D.Z(ii, jj));
set(H.ground, 'XData', X, 'YData', Y, 'ZData', Z);

i1 = max(i - 50, 1); i2 = min(i + 50, numel(R.x));
set(H.routeNear, 'XData', R.x(i1:i2), 'YData', R.y(i1:i2), 'ZData', R.z(i1:i2) + 0.01);
if ~isempty(V.prints)
    set(H.prints, 'XData', V.prints(1,:), 'YData', V.prints(2,:), 'ZData', V.prints(3,:) + 0.01);
end

K = V.K;
set(H.spine,  'XData', K.spine(1,:),     'YData', K.spine(2,:),     'ZData', K.spine(3,:));
set(H.pelvis, 'XData', K.pelvis(1,:),    'YData', K.pelvis(2,:),    'ZData', K.pelvis(3,:));
set(H.should, 'XData', K.shoulders(1,:), 'YData', K.shoulders(2,:), 'ZData', K.shoulders(3,:));
set(H.head,   'XData', K.head(1),        'YData', K.head(2),        'ZData', K.head(3));
for j = 1:2
    set(H.leg(j),  'XData', K.leg{j}(1,:),  'YData', K.leg{j}(2,:),  'ZData', K.leg{j}(3,:));
    set(H.foot(j), 'XData', K.foot{j}(1,:), 'YData', K.foot{j}(2,:), 'ZData', K.foot{j}(3,:));
    set(H.arm(j),  'XData', K.arm{j}(1,:),  'YData', K.arm{j}(2,:),  'ZData', K.arm{j}(3,:));
end

% camera rides at his right shoulder, a little behind and above
az = V.psi*180/pi - 28;
if isempty(H.az)
    H.az = az;
else
    d = mod(az - H.az + 180, 360) - 180;
    H.az = H.az + 0.15*d;
end
zg = V.pel(3) - 1.0;
set(H.axMan, 'XLim', V.pel(1) + [-1.7 1.7], 'YLim', V.pel(2) + [-1.7 1.7], ...
    'ZLim', [zg - 0.9, zg + 2.1]);
view(H.axMan, H.az, 10);
set(H.manTitle, 'String', V.title);

% joint history
if numel(V.tt) > 1
    set(H.jHip,  'XData', V.tt, 'YData', V.hip);
    set(H.jKnee, 'XData', V.tt, 'YData', V.knee);
    set(H.jAnk,  'XData', V.tt, 'YData', V.ank);
    set(H.axJ, 'XLim', [V.tt(end) - 5, V.tt(end) + 0.01]);
end
set(H.hud, 'String', V.hud);
drawnow;
