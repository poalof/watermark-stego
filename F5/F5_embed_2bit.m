% F5 嵌入 matrix code (1, 3, 2)

function  msgLen=F5_embed_2bit(srcPath, destPath, msgPath)
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

rng(42);
% 将矩阵展开为一维数组
matrix_flat = YDCTCoeffs(:);
% 生成随机排列的索引
random_indices = randperm(numel(matrix_flat));
% 根据随机索引重新排列一维数组
dct_flat = matrix_flat(random_indices);
% 恢复成原始的二维数组形式
%encodedImage = reshape(reshaped_matrix_flat, size(YDCTCoeffs));

% 将文本信息嵌入到jpeg图像的DCT系数中
lsb = []; % 3bit lsb
lsb_idx = []; % 对应dct下标
bitIndex = 1;  % 当前要嵌入的二进制位索引
for dctIdx=1:rows*cols
    if numel(lsb) < 3
        if dct_flat(dctIdx) > 0
            lsb(end+1) = mod(dct_flat(dctIdx),2);
            lsb_idx(end+1) = dctIdx;
        else if dct_flat(dctIdx) < 0 % 负数取反
            lsb(end+1) = 1-mod(dct_flat(dctIdx),2);
            lsb_idx(end+1) = dctIdx;
        else
            continue;
        end
    end
    if numel(lsb)==3
        % 得到3 bit向量
        % 2 bit 信息 异或两次
        flag = 0;
        if bitxor(lsb(1), lsb(2)) ~= bitList(bitIndex)
            flag = 1;
        end
        if bitxor(lsb(2),lsb(3)) ~= bitList(bitIndex+1)
           if flag == 1
               flag = 2;
           else
               flag = 3;
           end
        end
        % 修改对应lsb
        if flag > 0
            if dct_flat(lsb_idx(flag)) > 0
                dct_flat(lsb_idx(flag)) = dct_flat(lsb_idx(flag))-1;
            else
                dct_flat(lsb_idx(flag)) = dct_flat(lsb_idx(flag))+1;
            end
            if dct_flat(lsb_idx(flag)) == 0 % 跳过
                lsb(flag) = [];
                lsb_idx(flag) = [];
                continue;
            end
        end
    
        % 更新要嵌入的二进制位索引
        bitIndex = bitIndex + 2;
        lsb = [];
        lsb_idx = [];
        % 如果已经嵌入完所有文本信息，则退出循环
        if bitIndex > msgLen
            break;
        end
    end
    end
end

if bitIndex <= msgLen % 无法嵌入全部信息
    msgLen = -1;
end

% 使用随机索引的逆序恢复成原来matrix的排列顺序
m_flat_rand(random_indices) = dct_flat;
% 恢复成原来matrix的二维数组形式
restored_matrix = reshape(m_flat_rand, size(YDCTCoeffs));

% 将修改后的量化DCT系数保存为JPEG图像
jpegInfo.coef_arrays{1} = restored_matrix;
jpeg_write(jpegInfo, destPath);

end