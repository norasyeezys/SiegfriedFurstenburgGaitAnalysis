function K = fb_skeleton(B, pel, f, l, lean, arm, hip, knee, ank, footp, footf)
% FB_SKELETON  Turn the body state into polylines for drawing.
%   Column 1 of hip/knee/ank/footp/footf is the LEFT leg, column 2 the
%   right. Returns 3 x n arrays, one per limb.

up   = [0; 0; 1];
td   = sin(lean)*f + cos(lean)*up;            % trunk axis
sc   = pel + B.TRUNK*td;                      % between the shoulders
K.spine = [pel, sc];
K.pelvis = [hip(:,1), hip(:,2)];
K.shoulders = [sc + B.SH_W*l, sc - B.SH_W*l];
K.head  = sc + B.NECK*(sin(0.6*lean)*f + cos(0.6*lean)*up);
K.leg = cell(1,2); K.foot = cell(1,2); K.arm = cell(1,2);
for j = 1:2
    K.leg{j} = [hip(:,j), knee(:,j), ank(:,j)];
    p = footp(j); ff = footf(:,j);
    u =  cos(p)*ff + sin(p)*up;
    n = -sin(p)*ff + cos(p)*up;
    heel = ank(:,j) - B.HEEL_X*u - B.ANK_H*n;
    toe  = ank(:,j) + (B.BALL_X + B.TOE_X)*u - B.ANK_H*n;
    K.foot{j} = [heel, ank(:,j), toe, heel];
    sh = K.shoulders(:,j);
    a  = arm(j);
    el = sh + B.L_UP*(sin(a)*f - cos(a)*up);
    ha = el + B.L_FORE*(sin(a + 0.45)*f - cos(a + 0.45)*up);
    K.arm{j} = [sh, el, ha];
end
