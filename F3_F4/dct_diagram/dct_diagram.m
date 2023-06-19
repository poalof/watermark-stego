% 读取JPEG文件
jpegInfo_o = jpeg_read('../cover/img2.jpg');
jpegInfo = jpeg_read('../result_image/F3_result.jpg');
jpegInfo2 = jpeg_read('../result_image/F4_result.jpg');
% 获取量化DCT系数
YDCTCoeffs_o = jpegInfo_o.coef_arrays{1};
YDCTCoeffs = jpegInfo.coef_arrays{1};
YDCTCoeffs2 = jpegInfo2.coef_arrays{1};
histogram(YDCTCoeffs_o);
%histogram(YDCTCoeffs);
%histogram(YDCTCoeffs2);