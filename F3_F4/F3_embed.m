% 从scrPath加载图片，添加信息路径msgPath，保存到destPath
function msgLen=F3_embed(srcPath, destPath, msgPath)

% 读取JPEG文件
jpegInfo = jpeg_read(srcPath);

% 获取量化DCT系数
YDCTCoeffs = jpegInfo.coef_arrays{1};

% char类型文本转bit序列
bitList = [];
fid = fopen(msgPath, 'rb');
byteList = fread(fid,'*char');
fclose(fid);

byteList = unicode2native(byteList, 'UTF-8');

for i = 1:numel(byteList)
    b = byteList(i);
    for j = 0:7
        bitList = [bitList, bitget(b, (7-j)+1)];
    end
end

%disp(bitList);
msgLen = numel(bitList);

% 获取图像的尺寸和像素总数
[rows, cols] = size(YDCTCoeffs);
%disp(rows);
%disp(cols);
%disp(YDCTCoeffs);
% --------------------------------------------------------------------
% 生成下标数组，标记不可改变的DC
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
rng(42);
% 将矩阵展开为一维数组
matrix_flat = YDCTCoeffs(:);
m_flat = m(:);
% 生成随机排列的索引
random_indices = randperm(numel(matrix_flat));
% 根据随机索引重新排列一维数组
reshaped_matrix_flat = matrix_flat(random_indices);
m_flat = m_flat(random_indices);
% 恢复成原始的二维数组形式
encodedImage = reshape(reshaped_matrix_flat, size(YDCTCoeffs));
m_rand = reshape(m_flat, size(m));

% 将文本信息嵌入到jpeg图像的DCT系数中
%encodedImage = YDCTCoeffs(randperm(rows,cols),:);
bitIndex = 1;  % 当前要嵌入的二进制位索引
for row = 1:rows
    for col = 1:cols
        %fprintf("%d ", YDCTCoeffs(row, col));
        if m_rand(row,col) == -1
            continue;
        end
        if encodedImage(row,col) == 0 || ((encodedImage(row,col)==1 || encodedImage(row,col)==-1) && bitList(bitIndex)==0)
            encodedImage(row,col) = 0;
            continue; % coeff为零的跳过
        end
        % 将文本信息的一个二进制位嵌入到像素的最低有效位中
        if bitList(bitIndex) == 0
            if encodedImage(row,col) < 0 && mod(encodedImage(row,col),2)==1
                encodedImage(row,col) = encodedImage(row,col)+1;
            elseif encodedImage(row,col) > 0 && mod(encodedImage(row,col),2)==1
                encodedImage(row,col) = encodedImage(row,col)-1;
            end
        else
            if encodedImage(row,col) < 0 && mod(encodedImage(row,col),2)==0
                encodedImage(row,col) = encodedImage(row,col)+1;
            elseif encodedImage(row,col) > 0 && mod(encodedImage(row,col),2)==0
                encodedImage(row,col) = encodedImage(row,col)-1;
            end
        end
        % 更新要嵌入的二进制位索引
        bitIndex = bitIndex + 1;
        % 如果已经嵌入完所有文本信息，则退出循环
        if bitIndex > msgLen
            break;
        end
    end
    if bitIndex > msgLen
        break;
    end
end

if bitIndex <= msgLen % 无法嵌入全部信息
    msgLen = -1;
end

% 使用随机索引的逆序恢复成原来matrix的排列顺序
m_flat = encodedImage(:);
m_flat_rand(random_indices) = m_flat;
% 恢复成原来matrix的二维数组形式
restored_matrix = reshape(m_flat_rand, size(YDCTCoeffs));

%encodedImage(randperm(msgLen),:) = encodedImage;
% 将矩阵展开为一维数组
%matrix_flat = encodedImage(:);
% 根据随机索引重新排列一维数组
%reshaped_matrix_flat(random_indices) = matrix_flat;
% 恢复成原始的二维数组形式
%encodedImage = reshape(reshaped_matrix_flat, size(YDCTCoeffs));

% 将修改后的量化DCT系数保存为JPEG图像
jpegInfo.coef_arrays{1} = restored_matrix;
jpeg_write(jpegInfo, destPath);

% 我说怎么用bmp和png也读不对，破案了，原来我保存的时候是jpg。。。。
% 如果打开jpg，保存bmp/png，不会失真
%imwrite(encodedImage,'result.png');
end
