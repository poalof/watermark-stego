#include<iostream>
#include<cstdlib>
#include<opencv2\opencv.hpp>
#include<opencv2\highgui\highgui.hpp>
#include<opencv2\imgproc\imgproc.hpp>
#include<io.h>
#include <fstream>

using namespace std;
using namespace cv;

// message 1-bit
int m = 1;
// embedding  strength
double alpha = 1;
// threshold
double thres = 0.7;

// 计算黑白像素占比
double CalcRatio(Mat m)
{
	int total = m.rows * m.cols;
	int bw = 0;
	for (int i = 0; i < m.rows; i++)
		for (int j = 0; j < m.cols; j++)
			if (m.at<uchar>(i, j) >= 250 || m.at<uchar>(i, j) <= 5) // 粗略估计
				bw++;
	cout << bw * 1.0 / total << endl;
	return bw*1.0/total;
}

// 防止嵌入水印后数据溢出，截断
int trun(int n)
{
	return min(max(0, n), 255);
}

// 获得文件目录下所有文件名
void GetFiles(string path, vector<string>& files)
{
	//文件句柄  
	intptr_t hFile = 0;

	//文件信息  
	struct _finddata_t fileinfo;
	string p;
	if ((hFile = _findfirst(p.assign(path).append("*").c_str(), &fileinfo)) != -1)
	{
		do
		{
			if(strcmp(fileinfo.name, ".")!=0 && strcmp(fileinfo.name, "..") != 0)
				files.push_back(path + fileinfo.name); // 加入
		} while (_findnext(hFile, &fileinfo) == 0);
		_findclose(hFile);
	}
	else
		cout << "File path error!" << endl;
}


// 水印嵌入, 应保证输入的两个Mat大小相同
Mat E_BLIND(Mat cover, Mat watermark)
{
	int row = cover.rows;
	int col = cover.cols;

	Mat cw(row, col, CV_8UC1);

	for (int i = 0; i < row; i++)
	{
		for (int j = 0; j < col; j++)
		{
			// cw = co + alpha(2m-1)wr
			cw.at<uchar>(i, j) = trun(cover.at<uchar>(i, j) + alpha * (2 * m - 1) * watermark.at<double>(i, j));
		}
	}

	return cw;
}

// 水印检测：线性相关度
double D_LC(Mat cw, Mat watermark)
{
	double zlc = 0;

	int row = cw.rows;
	int col = cw.cols;

	for (int i = 0; i < row; i++)
	{
		for (int j = 0; j < col; j++)
		{
			// zlc = 1/n^2 * c * wr
			zlc += cw.at<uchar>(i, j) * watermark.at<double>(i, j);
			
		}
	}

	zlc = zlc / (row * col);

	return zlc;
}

int main(int arg, char** argv)
{
	// 1. 读取40张cover
	vector<string> paths;
	vector<Mat> covers;
	GetFiles("绝对路径\\covers\\", paths);
	for (int i = 0; i < paths.size(); i++)
	{
		// 我真服了，原来默认读入的是三通道，难怪加了水印显示不全。。。
		Mat img = imread(paths[i], IMREAD_GRAYSCALE);
		covers.push_back(img);
	}

	// 2. 生成40张水印
	vector<Mat> watermarks;
	for (int i = 0; i < 40; i++)
	{
		Mat_<double>w(512, 512);
		randn(w, Scalar(0), Scalar(1)); // 0，1高斯分布
		watermarks.push_back(w);
	}

	int fp = 0; // false positive
	int fn = 0; // false negative
	
	// 3. 一张水印嵌入40张cover, 使用第一张
	// 3.1 计算未嵌入时的相关度
	vector<double> data3_0;
	for (int i = 0; i < 40; i++)
	{
		double dlc = D_LC(covers[i], watermarks[0]);
		data3_0.emplace_back(dlc);
		if (abs(dlc) > thres) fp++;
		//cout << data3_0[i] << endl;
	}

	// 3.2 嵌入水印计算D_LC m=1
	vector<double> data3_1;
	for (int i = 0; i < 40; i++)
	{
		Mat tmp = E_BLIND(covers[i], watermarks[0]);
		double dlc = D_LC(tmp, watermarks[0]);
		data3_1.emplace_back(dlc);
		if (abs(dlc) < thres) fn++;
		//cout << data3_1[i] << endl;
	}

	// 3.3 嵌入 m=0
	m = 0;
	vector<double> data3_2;
	for (int i = 0; i < 40; i++)
	{
		Mat tmp = E_BLIND(covers[i], watermarks[0]);
		double dlc = D_LC(tmp, watermarks[0]);
		data3_2.emplace_back(dlc);
		if (dlc > -thres) fn++;
		//cout << data3_2[i] << endl;
	}

	// 3.4 查看实验结果
	cout << "-------------------------------------------" << endl;
	cout << "zlc(co, wr) = " << endl;
	for (int i = 0; i < 40; i++)
		if (i != 39) cout << data3_0[i] << ", ";
		else cout << data3_0[i] << endl;
	cout << "zlc(cw1, wr) = " << endl;
	for (int i = 0; i < 40; i++)
		if (i != 39) cout << data3_1[i] << ", ";
		else cout << data3_1[i] << endl;
	cout << "zlc(cw0, wr) = " << endl;
	for (int i = 0; i < 40; i++)
		if (i != 39) cout << data3_2[i] << ", ";
		else cout << data3_2[i] << endl;
	cout << "False positive rate: " << fp / 40.0 << endl;
	cout << "False negative rate: " << fn / 80.0 << endl;
	
	// 4. 40张水印嵌入一张黑白<0.3
	// 4.1 计算一张符合要求的cover （第一张
	/*
	int index = -1;
	for (int i = 0; i < 40; i++)
	{
		if (CalcRatio(covers[i]) <= 0.3)
		{
			index = i;
			break;
		}
	}
	*/
	
	int index = 0;
	// 4.2 计算未嵌入时的相关度
	vector<double> data4_0;
	for (int i = 0; i < 40; i++)
	{
		double dlc = D_LC(covers[index], watermarks[i]);
		data4_0.emplace_back(dlc);
		if (abs(dlc) > thres) fp++;
		//cout << data3_0[i] << endl;
	}

	m = 1;
	// 4.3 嵌入水印计算D_LC m=1
	vector<double> data4_1;
	for (int i = 0; i < 40; i++)
	{
		Mat tmp = E_BLIND(covers[index], watermarks[i]);
		double dlc = D_LC(tmp, watermarks[i]);
		data4_1.emplace_back(dlc);
		if (abs(dlc) < thres) fn++;
		//cout << data3_1[i] << endl;
	}

	// 4.4 嵌入 m=0
	m = 0;
	vector<double> data4_2;
	for (int i = 0; i < 40; i++)
	{
		Mat tmp = E_BLIND(covers[index], watermarks[i]);
		double dlc = D_LC(tmp, watermarks[i]);
		data4_2.emplace_back(dlc);
		if (dlc > -thres) fn++;
		//cout << data3_2[i] << endl;
	}

	// 4.5 查看实验结果
	cout << "-------------------------------------------" << endl;
	cout << "zlc(co, wr) = " << endl;
	for (int i = 0; i < 40; i++)
		if (i != 39) cout << data4_0[i] << ", ";
		else cout << data4_0[i] << endl;
	cout << "zlc(cw1, wr) = " << endl;
	for (int i = 0; i < 40; i++)
		if (i != 39) cout << data4_1[i] << ", ";
		else cout << data4_1[i] << endl;
	cout << "zlc(cw0, wr) = " << endl;
	for (int i = 0; i < 40; i++)
		if (i != 39) cout << data4_2[i] << ", ";
		else cout << data4_2[i] << endl;
	cout << "False positive rate: " << fp / 40.0 << endl;
	cout << "False negative rate: " << fn / 80.0 << endl;
	
	// 5. 黑白>0.5 重复4（rec.bmp）
	// 5.1 计算未嵌入时的相关度
	
	index = 35;
	vector<double> data5_0;
	for (int i = 0; i < 40; i++)
	{
		double dlc = D_LC(covers[index], watermarks[i]);
		data5_0.emplace_back(dlc);
		if (abs(dlc) > thres) fp++;
		//cout << data5_0[i] << endl;
	}

	m = 1;
	// 5.2 嵌入水印计算D_LC m=1
	vector<double> data5_1;
	for (int i = 0; i < 40; i++)
	{
		Mat tmp = E_BLIND(covers[index], watermarks[i]);
		double dlc = D_LC(tmp, watermarks[i]);
		data5_1.emplace_back(dlc);
		if (abs(dlc) < thres) fn++;
		//cout << data3_1[i] << endl;
	}

	// 5.3 嵌入 m=0
	m = 0;
	vector<double> data5_2;
	for (int i = 0; i < 40; i++)
	{
		Mat tmp = E_BLIND(covers[index], watermarks[i]);
		double dlc = D_LC(tmp, watermarks[i]);
		data5_2.emplace_back(dlc);
		if (dlc > -thres) fn++;
		//cout << data3_2[i] << endl;
	}

	// 5.4 查看实验结果
	cout << "-------------------------------------------" << endl;
	cout << "zlc(co, wr) = " << endl;
	for (int i = 0; i < 40; i++)
		if (i != 39) cout << data5_0[i] << ", ";
		else cout << data5_0[i] << endl;
	cout << "zlc(cw1, wr) = " << endl;
	for (int i = 0; i < 40; i++)
		if (i != 39) cout << data5_1[i] << ", ";
		else cout << data5_1[i] << endl;
	cout << "zlc(cw0, wr) = " << endl;
	for (int i = 0; i < 40; i++)
		if (i != 39) cout << data5_2[i] << ", ";
		else cout << data5_2[i] << endl;
	cout << "False positive rate: " << fp / 40.0 << endl;
	cout << "False negative rate: " << fn / 80.0 << endl;
	
	waitKey(0);
	system("pause");
	return 0;

}