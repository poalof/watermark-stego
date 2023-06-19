% F3 测试

srcPath = 'cover/img2.jpg';
destPath = 'result_image/F3_result.jpg';
msgPath = 'message_ch.txt';
extractedMsgPath = 'extracted_message/F3_extracted_message.txt';

% 嵌入
msgLen = F3_embed(srcPath,destPath,msgPath);
if msgLen == -1
    fprintf("Cannot embed message: text volume exceeds capacity\n");
end

% 提取
if msgLen ~= -1
    extractedText = F3_extract(destPath, msgLen);
    fprintf("Extracted message:\n%s\n",extractedText);
    file = fopen(extractedMsgPath,'w');
    fwrite(file, extractedText);
end
