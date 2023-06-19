% 1 -> 40
m = de2bi(0:255, 8, 'left-msb');
%m = randi([0,1],[1,8]);

alpha = sqrt(8);
tcc = 0.65;

filename = dir('covers');
filename = filename(3:end);

hasWatermark = 0; % Ƕ��ˮӡ������
correct = 0; % Ƕ����ˮӡ���Ҽ����ȷ
fp = 0; % ûǶ��ˮӡ������������
fn = 0; % Ƕ����ˮӡ����û������

for c = 1:256

    for i = 1:size(filename)
        % ����һ��cover
        co = imread(['covers/' filename(i).name]);
        % 1. ����false positive
        message = D_BLK_8_Simple(co,tcc);
        %disp(message);
    
        if message(1)~=-1 % ����ˮӡ
            fp = fp+1;
        end 
    
        % 2. ����׼ȷ�ʺ�false negative
        cw = E_BLK_8_Simple(co, m(c,:), alpha);
        message = D_BLK_8_Simple(cw,tcc);
        %disp(message);
    
        if message(1) ~= -1 % ����ˮӡ
            hasWatermark = hasWatermark+1;
            if message == m(c,:) % ���Ҽ����ȷ
                correct = correct + 1;
            end
        else % û������ zcc < tcc, false negative
            fn = fn + 1;
        end
    end

end
fprintf('correct: %d, correct rate = %2.2f%%\n', correct, double(correct/hasWatermark*100));
fprintf('False positive rate: %2.2f%%\n', double(fp/(40*256)*100));
fprintf('False Negative rate: %2.2f%%\n', double(fn/(40*256)*100));


