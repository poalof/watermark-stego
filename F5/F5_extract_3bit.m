% F5 matrix code (1, 7, 3)
function extractedText=F5_extract_3bit(srcPath, msgLen)
% 读取嵌入了信息的图像
% 读取JPEG文件
% 获取量化DCT系数
jpegInfo = jpeg_read(srcPath);
encodedImage = jpegInfo.coef_arrays{1};

% bitList 是8的倍数 但是嵌入是3bit为单位的 要填充
pad = 3-mod(msgLen,3); % 填充的bit数
msgLen_pad = msgLen+pad;

% 获取图像的尺寸
[rows, cols] = size(encodedImage);
rng(42);
% 提取的文本信息
extractedText = '';
% 将矩阵展开为一维数组
matrix_flat = encodedImage(:);
% 生成随机排列的索引
random_indices = randperm(numel(matrix_flat));
% 根据随机索引重新排列一维数组
dct_flat = matrix_flat(random_indices);

lsb = []; % 7 bit lsb
for dctIdx=1:rows*cols
    if dct_flat(dctIdx) == 0 % 跳过0 AC系数
        continue;
    end
    if numel(lsb) < 7
        if dct_flat(dctIdx) > 0
            lsb(end+1) = mod(dct_flat(dctIdx),2);
        else % 负数取反
            lsb(end+1) = 1-mod(dct_flat(dctIdx),2);
        end
    end
    if numel(lsb) == 7
        fa = 0;
        for i=1:7
            fa = bitxor(fa,lsb(i)*i);
        end
        extractedBit = dec2bin(fa,3);
        extractedText = [extractedText, extractedBit];
        lsb = [];
        lsb_idx = [];
        % 如果已经嵌入完所有文本信息，则退出循环
        if numel(extractedBit) >= msgLen_pad
            break;
        end
    end
end

% 将提取的二进制字符串转换为文本信息
extractedText(msgLen+1:end) = [];
extractedText = bin2dec(reshape(extractedText, 8, [])');
extractedText = native2unicode(extractedText, 'UTF-8');

end