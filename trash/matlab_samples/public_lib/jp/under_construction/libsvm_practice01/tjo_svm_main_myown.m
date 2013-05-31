function [new_m,alpha,bias,linear_index]=tjo_svm_main_myown(xvec,delta,Cmax,loop,kernel_choice)
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% �T�|�[�g�x�N�^�[�}�V��2�����o�[�W���� by Takashi J. OZAKI %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% �������V���v���Ȏ����ł��B�Œ���̋@�\�Ƃ��āA
% 1) 3��ށi���^�E�������E�K�E�V�A��RBF�j�̃J�[�l���ɂ�����^����
% 2) SMO�iSequential Minimal Optimization: �����ŏ��œK���j
% 3) ���t�M��x_list�������_���Ɏ擾�i2��������������XOR�p�^�[���j
% 4) ���t�M��x_list�ƃe�X�g�M��xvec�̃v���b�g�A�T�|�[�g�x�N�^�[�̋����\��
% 5) ���������ʂ̃R���^�[�i�������j�\��
% ���������Ă���܂��B
% 
% ������[new_m,alpha,bias,linear_index]=tjo_svm_2d_main_procedure([4;4],4,2,100)��
% �R�}���h���C����Ŏ��s���Ă݂ĉ������B�Y���XOR�����p�^�[�����\������܂��B
% xvec�F�e�X�g�M����xy���W�i��x�N�g��[x;y]�Ŏw��j
% delta�F�J�[�l���̕ϐ��i�{���̓�:sigma�ł����߂�Ȃ����j
% Cmax�F�\�t�g�}�[�W��SVM�ɂ�����KKT�����p�����[�^C
% loop�FSMO���������Ȃ��ꍇ�̎��s�񐔂̑ł��؂����i���ꂪ�Ȃ��Ɩ������[�v����j
% 
% Matlab�͔��Ƀ��[�Y�Ȍ���ł��B�x�[�X�Ƃ��Ă͂ق�C���ꂻ�̂��̂ł��B
% C�������[�Y�ŁA�Ⴆ�Εϐ��錾�͈�ؗv��܂���i����������������
% zeros�֐��őS�v�f�[���̃x�N�g��or�s������j�B
% Java�⑼����ɈڐA����ۂ͂��̕ӂ����Ă�����ŁA�����܂ł��A���S���Y����
% ���`�Ƃ��Ă����p�������B
% 
% �Ȃ��A�u2�����o�[�W�����v�ƃ^�C�g�������Ă���܂����A
% �s��v�Z���̂ɕ��Ր����������Ă���܂��̂�3�����ł�4�����ł�n�����ł�
% �v�Z���ׂ�����������΂�����ł��g���ł��܂��i�������v���b�g�͖����ł����j�B
% 
% �ڂ��������ɂ��Ắw�T�|�[�g�x�N�^�[�}�V������x�i�ʏ̐Ԗ{�j�����Q�Ɖ������B
% ���肪�����Ŏ����Ă���܂��̂ŁA���݂��������܂��B

%%
%%%%%%%%%%%%%%%%%
% ���t�M���̐ݒ� %
%%%%%%%%%%%%%%%%%

t=6;
c=7;
d=50;

% XOR����^�p�^�[���F������Ɩ��W�����Ă݂�
x1_list=[[(-t*ones(1,d)+c*rand(1,d));(t*ones(1,d)-c*rand(1,d))] ...
    [(t*ones(1,d)-c*rand(1,d));(-t*ones(1,d)+c*rand(1,d))]];
x2_list=[[(t*ones(1,d)-c*rand(1,d));(t*ones(1,d)-c*rand(1,d))] ...
    [-t*ones(1,d)+c*rand(1,d);-t*ones(1,d)+c*rand(1,d)]];

c1=size(x1_list,2); % x1_list�̗v�f��
c2=size(x2_list,2); % x2_list�̗v�f��
clength=c1+c2; % �S�v�f���F���̌㖈��Q�Ƃ��邱�ƂɂȂ�܂��B

% ����M���Fx1��x2�Ƃŕ����������̂ŁA�Ή�����C���f�b�N�X��1��-1������U��܂��B
x_list=[x1_list x2_list]; % x1_list��x2_list���s�����ɕ��ׂĂ܂Ƃ߂܂��B
y_list=[ones(c1,1);-1*ones(c2,1)]; % ����M����x1:1, x2:-1�Ƃ��ė�x�N�g���ɂ܂Ƃ߂܂��B


%%
%%%%%%%%%%%%%%%%%
% �e�ϐ��̏����� %
%%%%%%%%%%%%%%%%%
% zeros�֐��őS�v�f0�̃x�N�g�������B

% ���O�����W���搔���i�ڍׂ͐Ԗ{�Q�Ƃ̂��Ɓj
alpha=zeros(clength,1);
% �w�K�W���i����܂��ڍׂ͐Ԗ{�Q�Ƃ̂��ƁF�ʏ�0-2���炢�Ɏ��߂�j
learn_stlength=0.5;

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ���O�����W���搔���̐��聕SMO %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% �����ł̓��𐄒肷�遁�w�K���[�`���B
% SMO��p���āA��alpha*y_list = 0�Ȃ���^����𖞂����Ȃ���A
% �Ȃ�����KKT�����𖞑����郿�𐄒肷��Ƃ�����2���œK�����������B
% �i�킩��Ȃ���ΐԖ{��ǂ݂܂��傤�I�j

% KKT�����Ɋ�Â��ă��O�����W������搔�@���������߂ɂ́A
% ���t�M��x_list�A����M��y_list�A���������������̃��O�����W���搔alpha�A
% �J�[�l���̌`��萔delta�i�{���̓Ђł����߂�Ȃ����j�A
% �S�v�f���̒lclength�A�w�K�W��learn_stlength�ASMO�ł��؂�����loop�A
% ���K�v�ɂȂ�B�ڍׂ�tjo_smo�̋L�q���Q�Ƃ̂��ƁB

[alpha,bias]=tjo_smo(x_list,y_list,alpha,delta,Cmax,clength,learn_stlength,loop,kernel_choice);

% ���O�����W���搔alpha�ƃo�C�A�Xbias�̗����������ɋ��܂�B
% ����ŕ����֐��ɕK�v�Ȓ萔���S�ē���ꂽ���ƂɂȂ�B

%%
%%%%%%%%%%%%%%%%%%%%%%%
% �����֐������������� %
%%%%%%%%%%%%%%%%%%%%%%%
% �����֐��̎Z�o�ɕK�v��w�x�N�g��(wvec)�����߂�B
% wvec�͐���M��y_list�Ɛ���ς݃��O�����W���搔alpha��2���狁�܂�B

wvec=tjo_svm_classifier(y_list,alpha,clength);

% wvec��bias�𕪗��֐�tjo_svm_trial�ɓ��͂���΁A�e�X�g���s���\�B


%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ���ނ��Ă݂�(Trial / Testing) %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ���ۂɐ���ς݂�wvec��bias��2�萔���番���֐����\�����A
% �e�X�g�M��xvec�ɑ΂��錈��֐��lnew_m�����߂�B
% new_m > 0�Ȃ�x1��(Group 1)�Anew_m < 0�Ȃ�x2��(Group 2)�Ɣ��肳���B
% �֐�tjo_svm_trial�̓R�}���h���C���ɔ��茋�ʂ̕\�����s���B

new_m=tjo_svm_trial(xvec,wvec,x_list,delta,bias,clength,kernel_choice);

% SMO���r���ł��؂�ɂȂ����ꍇ�ɔ����āA���^����alpha*y_list = 0��
% �������Ă��邩�ǂ������v�Z����B
linear_index=y_list'*alpha;

%%
%%%%%%%%%%%%%%%%%%%%%
% �����i�v���b�g�j %
%%%%%%%%%%%%%%%%%%%%%
% Matlab�ő�̕���ł�������p�[�g�B
% �R�����g�̂Ȃ��Ƃ���͓K�XMatlab�w���v�����Q�Ɖ������B

figure(1); % �v���b�g�E�B���h�E��1���

for i=1:c1 % ���t�M��x1�����ꂼ��v���b�g����
    if(alpha(i)==0) % �����֐��Ɗ֌W�Ȃ���΍������Ńv���b�g
        scatter(x_list(1,i),x_list(2,i),100,'black');hold on;
    elseif(alpha(i)>0) % �T�|�[�g�x�N�^�[�Ȃ率�F�́��Ńv���b�g
        scatter(x_list(1,i),x_list(2,i),100,[127/255 0 127/255]);hold on;
    end;
end;

for i=c1+1:c1+c2 % ���t�M��x2�����ꂼ��v���b�g����
    if(alpha(i)==0) % �����֐��Ɗ֌W�Ȃ���΍����{�Ńv���b�g
        scatter(x_list(1,i),x_list(2,i),100,'black','+');hold on;
    elseif(alpha(i)>0) % �T�|�[�g�x�N�^�[�Ȃ率�F�́{�Ńv���b�g
        scatter(x_list(1,i),x_list(2,i),100,[127/255 0 127/255],'+');hold on;
    end;
end;

if(new_m > 0) % �e�X�g�M��xvec��Group 1�Ȃ�Ԃ����Ńv���b�g
    scatter(xvec(1),xvec(2),200,'red');hold on;
elseif(new_m < 0) % �e�X�g�M��xvec��Group 2�Ȃ�Ԃ��{�Ńv���b�g
    scatter(xvec(1),xvec(2),200,'red','+');hold on;
else % �e�X�g�M��xvec�����ꕪ�������ʏ�Ȃ�����Ńv���b�g
    scatter(xvec(1),xvec(2),200,'blue');hold on;
end;

% �v���b�g�͈͂�x,y�Ƃ���[-10 10]�̐����`�̈���ɐݒ�
% xlim([-10 10]);
% ylim([-10 10]);

% �R���^�[�i�������j�v���b�g�B����̂ŏڍׂ�Matlab�w���v�����Q�Ɖ������B
[xx,yy]=meshgrid(-60000:1000:20000,-50000:1000:250000);
cxx=size(xx,1);
cyy=size(yy,2);
zz=zeros(cxx,cyy);
for p=1:cxx
    for q=1:cyy
        zz(p,q)=tjo_svm_trial_silent([xx(p,q);yy(p,q)],wvec,x_list,delta,bias,clength,kernel_choice);
    end;
end;
if(Cmax>=1)
    thr=1/Cmax;
else
    thr=Cmax;
end;
contour(xx,yy,zz,[-thr 0 thr]);hold on;

end