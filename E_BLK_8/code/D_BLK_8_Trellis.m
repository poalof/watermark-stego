% input: cw检测图像 tcc阈值

function message = D_BLK_8_Trellis(Cw, tcc)

[height, width] = size(Cw);

% vm
v = zeros(8,8);
for i=1:height
    for j=1:width
        v(mod(i-1,8) + 1, mod(j-1,8) + 1) =  double(v(mod(i-1,8) + 1, mod(j-1,8) + 1)) + double(Cw(i,j));
    end
end
v = v/(height*width/64.0);

% decode message
zlc = zeros(1,8); % z[i] 初始为-1
zlc = zlc - 1;
zlc(1) = 0; % 从0/'A'开始
p = zeros(8,8); % path
stateTable = [[0,1];[2,3];[4,5];[6,7];[0,1];[2,3];[4,5];[6,7]];
for i=1:10
    tmpZ = zeros(1,8);
    tmpZ = tmpZ - 1;
    tmpP = zeros(8,8);
    for state = 0:7
        if zlc(state+1) ~= -1 % 当前run可以到达的状态
            randn('seed',state * 10 + i);
            Wr = randn(8, 8);
            lc = sum(sum(v.*Wr))/ 64.0; % current zlc with wr(bit 1)
            
            % update 0
            next = stateTable(state+1, 1);
            if tmpZ(next+1)==-1 || tmpZ(next+1) < zlc(state+1) - lc
                tmpZ(next+1) = zlc(state+1) - lc;
                tmpP(next+1,:) = p(state+1,:);
            end

            % update 1
            next = stateTable(state+1, 2);
            if tmpZ(next+1)==-1 || tmpZ(next+1) < zlc(state+1) + lc
                tmpZ(next+1) = zlc(state+1) + lc;
                tmpP(next+1,:) = p(state+1,:);
                if i<=8 % 防止越界
                    tmpP(next+1,i) = 1;
                end
            end

        end  
    end
    zlc = tmpZ;
    p = tmpP;   
end

% 选择zlc最大的路径
mx = 1;
for state=2:8
    if zlc(state) > zlc(mx)
        mx = state;
    end
end

message = p(mx,:); % 解出的message

% 重新embed计算zcc 查看是否嵌入水印
Wm = zeros(8,8);
state = 0;

for i=1:10
    randn('seed', state * 10 + i);
    Wr = randn(8, 8);
    if i > 8 % 末尾两个0
        Wm = Wm - Wr;
        continue;
    end
    if message(i) == 1
        Wm = Wm + Wr;
    else
        Wm = Wm - Wr;
    end
    state = stateTable(state+1, message(i)+1); % update
end

% zcc = v dot wm / (sqrt(v dot v) * sqrt(wm dot wm))
v = v - mean(v);
Wm = Wm - mean(Wm);

zcc = sum(sum(v.*Wm)) / (sqrt(sum(sum(v.*v))) * sqrt(sum(sum(Wm.*Wm))));

if abs(zcc) < tcc % 没嵌入水印 返回-1
    message = -1 * ones(1,8);
end