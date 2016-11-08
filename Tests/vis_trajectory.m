function vis_trajectory()
load('trajectory.mat')
plot3(pos(1,:),pos(2,:),pos(3,:),'-')
plot3(pos(1,:),pos(2,:),pos(3,:),'-'),hold on, grid on
plot3(pos(1,:),pos(2,:),pos(3,:),'-'),hold on, grid on
xlabel('x')
ylabel('y')
zlabel('z')
axis([-20 20 0 500 0 500])
daspect([1 1 1])
view(80,-30)
end