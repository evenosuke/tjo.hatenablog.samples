function [new_m,alpha,bias]=tjo_perceptron_3d_svm03_smo(xvec)
%%
% SMOあり

%%
% xy座標系の値を素性とした訓練データ
% 適当に決めて第1集団なら1
% 第2集団なら-1を正解ラベルとする

x1_list=[[1;1] [2;3] [2;1] [2;-1] [3;2] [5;5] [-1;3] [-3;2] ...
    [-2;1] [2;-1] [3;-2] [4;-4] [1;-4] [-8;1] [1;-8] [-6;1] [1;-6] ...
    [3;-5] [2;-2] [1;-2] [-4;4] [1;-5]];
x2_list=[[-1;-1] [0;-1] [0;-2] [-1;-2] [-1;-3] [-3;-3] [-4;0] ...
    [-3;-1] [-5;0] [-8;-2] [-2;-8] [0;-4] [0;-5] [0;-6] [-6;0] [-5;0] ...
    [0;-2] [-3;-4] [-4;-3] [-2;-2]];
x_list=[x1_list x2_list];

[r1,c1]=size(x1_list);
[r2,c2]=size(x2_list);
y_list=[ones(c1,1);-1*ones(c2,1)];

clength=c1+c2;
%%
% 変数設定パート
alpha=zeros(c1+c2,1);
e_list=zeros(c1+c2,1);
% loop=1000; % 訓練の繰り返し回数
learn_stlength=1.5;

%%
% alphaを推定する。ここがSVMのtrainingの肝

% ここをSMOに換装する！！

alpha=tjo_smo(x_list,y_list,e_list,alpha,delta,Cmax,loop,clength,learn_stlength);

%%
% biasを推定する

bias=tjo_svm_bias_estimate_smo(x_list,y_list,alpha,delta,clength);

% bias=0;

%%
% 分類してみる(Trial / Testing)

new_m=tjo_svm_trial_smo(xvec,x_list,y_list,alpha,delta,bias);


%%
% おまけで可視化

% [xx,yy]=meshgrid(-5:.1:5,-5:.1:5);
% zz=-(a/c)*xx-(b/c)*yy-(d/c);
h=figure;
% mesh(xx,yy,zz);hold on;
scatter(x_list(1,1:c1),x_list(2,1:c1),100,'black');hold on;
scatter(x_list(1,c1+1:c1+c2),x_list(2,c1+1:c1+c2),100,'black','+');hold on;
if(new_m > 0)
    scatter(xvec(1),xvec(2),100,'red');
elseif(new_m < 0)
    scatter(xvec(1),xvec(2),100,'red','+');
else
    scatter(xvec(1),xvec(2),100,'blue');
end;
xlim([-10 10]);
ylim([-10 10]);

end