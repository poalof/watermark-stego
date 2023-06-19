% 从srcPath图像中提取信息字符串并返回
function extractedText=F3_extract(srcPath,msgLen)
% 读取嵌入了信息的图像
% 读取JPEG文件
% 获取量化DCT系数
jpegInfo = jpeg_read(srcPath);
encodedImage = jpegInfo.coef_arrays{1};

% 获取图像的尺寸
[rows, cols] = size(encodedImage);
rng(42);
% 提取的文本信息
extractedText = '';
%encodedImage = encodedImage(randperm(msgLen),:);
m = zeros(rows,cols);
for i=1:rows
    for j=1:cols
        if mod(i,8)==1 && mod(j,8)==1
            m(i,j) = -1;
            continue;
        end
        m(i,j) = (i-1)*8+j;
    end
end
% 将矩阵展开为一维数组
matrix_flat = encodedImage(:);
m_flat = m(:);
% 生成随机排列的索引
random_indices = randperm(numel(matrix_flat));
% 根据随机索引重新排列一维数组
reshaped_matrix_flat = matrix_flat(random_indices);
m_flat = m_flat(random_indices);
% 恢复成原始的二维数组形式
encodedImage = reshape(reshaped_matrix_flat, size(encodedImage));
m_rand = reshape(m_flat,size(m));
% 逐像素提取嵌入的信息
bitIndex = 1;  % 当前提取的二进制位索引
for row = 1:rows
    for col = 1:cols
        if m_rand(row,col) == -1
            continue;
        end
        if encodedImage(row,col) == 0
            continue; % coeff为零的跳过
        end
        pixel = encodedImage(row, col);
        % 将像素值转换为二进制字符串
        binaryPixel = dec2bin(pixel, 8);
        % 提取像素的最低有效位作为文本信息的二进制位
        extractedBit = binaryPixel(end);
        % 将提取的二进制位添加到文本信息中
        extractedText = [extractedText extractedBit];
        % 更新提取的二进制位索引
        bitIndex = bitIndex + 1;
        % 如果已经提取完所有嵌入的信息，则退出循环
        if bitIndex > msgLen
            break;
        end
    end
    if bitIndex > msgLen
        break;
    end
end

% 将提取的二进制字符串转换为文本信息
extractedText = bin2dec(reshape(extractedText, 8, [])');
extractedText = native2unicode(extractedText, 'UTF-8');

% 显示提取的文本信息
%fprintf('Extracted Text: %s\n', extractedText);

end