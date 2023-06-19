% F5_3bit 测试

srcPath = 'cover/img2.jpg';
destPath = 'result_img/F5_result_3bit.jpg';
msgPath = 'message.txt';
extractedMsgPath = 'extracted_message/F5_extracted_message.txt';

% 嵌入
msgLen = F5_embed_3bit(srcPath,destPath,msgPath);
if msgLen == -1
    fprintf("Cannot embed message: text volume exceeds capacity\n");
end

% 提取
if msgLen ~= -1
    extractedText = F5_extract_3bit(destPath, msgLen);
    fprintf("Extracted message:\n%s\n",extractedText);
    file = fopen(extractedMsgPath,'w');
    fwrite(file, extractedText);
end