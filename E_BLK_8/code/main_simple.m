% 1 -> 40
m = de2bi(0:255, 8, 'left-msb');
%m = randi([0,1],[1,8]);

alpha = sqrt(8);
tcc = 0.65;

filename = dir('covers');
filename = filename(3:end);

hasWatermark = 0; % 嵌入水印的总数
correct = 0; % 嵌入了水印，且检测正确
fp = 0; % 没嵌入水印，但检测出来了
fn = 0; % 嵌入了水印，但没检测出来

for c = 1:256

    for i = 1:size(filename)
        % 读入一张cover
        co = imread(['covers/' filename(i).name]);
        % 1. 计算false positive
        message = D_BLK_8_Simple(co,tcc);
        %disp(message);
    
        if message(1)~=-1 % 检测出水印
            fp = fp+1;
        end 
    
        % 2. 计算准确率和false negative
        cw = E_BLK_8_Simple(co, m(c,:), alpha);
        message = D_BLK_8_Simple(cw,tcc);
        %disp(message);
    
        if message(1) ~= -1 % 检测出水印
            hasWatermark = hasWatermark+1;
            if message == m(c,:) % 并且检测正确
                correct = correct + 1;
            end
        else % 没检测出来 zcc < tcc, false negative
            fn = fn + 1;
        end
    end

end
fprintf('correct: %d, correct rate = %2.2f%%\n', correct, double(correct/hasWatermark*100));
fprintf('False positive rate: %2.2f%%\n', double(fp/(40*256)*100));
fprintf('False Negative rate: %2.2f%%\n', double(fn/(40*256)*100));


