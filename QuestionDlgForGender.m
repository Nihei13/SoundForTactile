function [ gender ] = QuestionDlgForGender( )
%UNTITLED6 ���̊֐��̊T�v�������ɋL�q
%   �ڍא����������ɋL�q

gender_choice = questdlg('���ʂ���͂��Ă�������', ...
    '����', ...
    '�j��','����','���̑�','���̑�');
switch gender_choice
    case '�j��'
        gender = 1;
    case '����'
        gender = 0;
    case '���̑�'
        gender = 2;
end

end

