function [ank, heel, toe] = fb_foot_fk(ball, ff, p, B)
% FB_FOOT_FK  Foot as a rigid wedge pivoting on the ball.
%   ball : world position of the ball of the foot (the pivot on the ground)
%   ff   : unit heading of the foot (horizontal), p : pitch (+ = toe up)
%   Heel rise is a NEGATIVE change of p: the heel lifts, the ankle goes up
%   and forward, and the leg behind him gets longer. That is how a man
%   reaches the next foothold uphill.

up = [0; 0; 1];
u  =  cos(p)*ff + sin(p)*up;         % heel -> toe
n  = -sin(p)*ff + cos(p)*up;         % sole normal
ank  = ball - B.BALL_X*u + B.ANK_H*n;
heel = ank  - B.HEEL_X*u - B.ANK_H*n;
toe  = ball + B.TOE_X*u;
