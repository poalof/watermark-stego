
function cw = E_BLK_8_Simple(cover, message, alpha)

[row, col] = size(cover);
cw = zeros(row, col);
cover = im2double(cover);

% 生成vo
v = zeros(8, 8);
for i = 1:row
    for j = 1:col
        v(mod(i-1, 8)+1, mod(j-1, 8)+1) = v(mod(i-1, 8)+1, mod(j-1, 8)+1) + cover(i, j);
    end
end
v = v / (row*col / 64);

% 生成wm
wm = zeros(8, 8);
for k = 1:8
    randn('seed',k);
    w = randn(8,8);
    if message(k) == 1
        wm = wm + w;%watermark{k};
    else
        wm = wm - w;%watermark{k};
    end
end
wm = wm / std2(wm);

% 嵌入vm
% vm = vo + alpha*wm
vm = v + alpha * wm;

% 变换回cw
% cw = co + (vm - vo)
for i = 1:row
    for j = 1:col
        cw(i, j) = cover(i, j) + vm(mod(i-1, 8)+1, mod(j-1, 8)+1) - v(mod(i-1, 8)+1, mod(j-1, 8)+1);
    end
end

end