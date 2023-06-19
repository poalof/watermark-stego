% input: Co原图 m嵌入的8bit信息 alpha 放大倍数

function Cw = E_BLK_8_Trellis(Co, m, alpha)

[height, width] = size(Co);
Co = im2double(Co);

% 生成wm
Wm = zeros(8,8);
state = 0;
stateTable = [[0,1];[2,3];[4,5];[6,7];[0,1];[2,3];[4,5];[6,7]];

for i=1:10
    randn('seed', state * 10 + i);
    Wr = randn(8, 8);
    if i > 8 % 末尾两个0
        Wm = Wm - Wr;
        continue;
    end

    if m(i) == 1
        Wm = Wm + Wr;
    else
        Wm = Wm - Wr;
    end

    state = stateTable(state+1, m(i)+1); % update
end

% normalize
wmean = mean(mean(Wm));
wstd = std2(Wm);
Wm = Wm - wmean;
Wm = Wm / wstd;

% vo
vo = zeros(8,8);
for i=1:height
    for j=1:width
        vo(mod(i-1,8) + 1, mod(j-1,8) + 1) = vo(mod(i-1,8) + 1, mod(j-1,8) + 1) + Co(i,j);
    end
end
vo = vo/(height*width/64.0);

% vw = vo + alpha * wm
vw = vo + alpha * Wm;

% cw = co + (vw%8 - v0%8)
Cw = zeros(height,width);
for i = 1:height
    for j = 1:width
        Cw(i, j) = Co(i, j) + vw(mod(i-1, 8)+1, mod(j-1, 8)+1) - vo(mod(i-1, 8)+1, mod(j-1, 8)+1);
    end
end