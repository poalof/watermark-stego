% 读取JPEG文件
jpegInfo_o = jpeg_read('../cover/img2.jpg');
jpegInfo = jpeg_read('../result_img/F5_result_2bit.jpg');
jpegInfo2 = jpeg_read('../result_img/F5_result_3bit.jpg');
% 获取量化DCT系数
YDCTCoeffs_o = jpegInfo_o.coef_arrays{1};
YDCTCoeffs = jpegInfo.coef_arrays{1};
YDCTCoeffs2 = jpegInfo2.coef_arrays{1};
histogram(YDCTCoeffs_o);
%histogram(YDCTCoeffs);
%histogram(YDCTCoeffs2);
%{
subplot(2,2,1);
histogram(YDCTCoeffs_o);
title('original image');
subplot(2,2,2);
histogram(YDCTCoeffs);
title('F5 2bit');
subplot(2,2,3);
histogram(YDCTCoeffs2);
title('F5 3bit');
%}