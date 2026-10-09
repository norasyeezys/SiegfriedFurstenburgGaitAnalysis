function [knee, ank] = fb_leg_fk(hip, q, f, l, sgn, B)
% FB_LEG_FK  Forward kinematics of one leg, hip joint down to the ankle.
%   q(1) hip flexion   (thigh forward of vertical, + = forward)
%   q(2) knee flexion  (+ = shank folds back)
%   q(3) hip abduction (+ = foot away from the midline)
%   f, l : forward and left unit vectors of the pelvis. sgn = +1 left leg,
%   -1 right leg. Angles are against the world vertical.

up = [0; 0; 1];
x1 = B.L_TH*sin(q(1));            r1 = B.L_TH*cos(q(1));
x2 = x1 + B.L_SH*sin(q(1)-q(2));  r2 = r1 + B.L_SH*cos(q(1)-q(2));
sb = sgn*sin(q(3)); cb = cos(q(3));
knee = hip + x1*f + r1*sb*l - r1*cb*up;
ank  = hip + x2*f + r2*sb*l - r2*cb*up;
