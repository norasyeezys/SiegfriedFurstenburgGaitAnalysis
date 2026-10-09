function [ball, sig] = fb_foot_place(D, ank, ff, B)
% FB_FOOT_PLACE  Lay the sole on the ground under a given ankle position.
%   sig  : pitch of the ground under the foot along its heading
%   ball : where the ball of the foot ends up (the pivot for this stance)

xy  = ank(1:2);
zb  = fb_terrain_z(D, xy(1) + B.BALL_X*ff(1), xy(2) + B.BALL_X*ff(2));
zh  = fb_terrain_z(D, xy(1) - B.HEEL_X*ff(1), xy(2) - B.HEEL_X*ff(2));
sig = atan2(zb - zh, B.BALL_X + B.HEEL_X);
up  = [0; 0; 1];
u   =  cos(sig)*ff + sin(sig)*up;
n   = -sin(sig)*ff + cos(sig)*up;
ball = ank + B.BALL_X*u - B.ANK_H*n;
