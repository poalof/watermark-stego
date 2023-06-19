% 返回解码的message
function message = D_BLK_8_Simple(cw, tcc)

message = zeros(1,8);
[row, col] = size(cw);

% v 8x8
v = zeros(8, 8);
for i = 1:row
    for j = 1:col
        v(mod(i-1, 8)+1, mod(j-1, 8)+1) = v(mod(i-1, 8)+1, mod(j-1, 8)+1) + cw(i, j);
    end
end
v = v / (row*col / 64.0);

% decode
wr = zeros(8,8);
for i = 1:8
    randn('seed',i);
    w = randn(8,8);
    if sum(sum(v.*w)) > 0 % 只看zlc符号
        message(i) =1;
        wr = wr + w;
    else
        message(i) =0;
        wr = wr - w;
    end
end

% mean
v = v - mean(v);
wr = wr - mean(wr);

% zcc = v dot wm / (sqrt(v dot v) * sqrt(wm dot wm))
if (sqrt(sum(sum(v.*v))) * sqrt(sum(sum(wr.*wr)))) < 0.000001
    zcc = 0;
else
    zcc = sum(sum(v.*wr)) / (sqrt(sum(sum(v.*v))) * sqrt(sum(sum(wr.*wr))));
end

if zcc < tcc % 没嵌入水印 返回-1
    message = -1 * ones(1,8);
end

end