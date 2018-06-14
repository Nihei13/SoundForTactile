function [ gender ] = QuestionDlgForGender( )
%UNTITLED6 この関数の概要をここに記述
%   詳細説明をここに記述

gender_choice = questdlg('性別を入力してください', ...
    '性別', ...
    '男性','女性','その他','その他');
switch gender_choice
    case '男性'
        gender = 1;
    case '女性'
        gender = 0;
    case 'その他'
        gender = 2;
end

end

