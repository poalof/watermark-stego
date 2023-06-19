#include<iostream>
#include<cstdlib>
#include<opencv2\opencv.hpp>
#include<opencv2\highgui\highgui.hpp>
#include<opencv2\imgproc\imgproc.hpp>
#include<io.h>
#include<cmath>

using namespace std;
using namespace cv;

// embedding strength
double alpha = sqrt(8);
// threshold
double thres = 0.7;

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

// 水印嵌入：根据message[8]生成对应的水印
Mat E_SIMPLE_8(Mat cover, vector<Mat> watermark, vector<int> message)
{
	int row = cover.rows;
	int col = cover.cols;

	Mat cw = Mat::zeros(row, col, CV_64FC1);

	// 生成wm
	Mat wm = Mat::zeros(row, col, CV_64FC1);
	for (int k = 0; k < message.size(); k++)
	{
		wm += message[k] == 1 ? watermark[k] : -watermark[k];
	}
	Mat means, stddev;
	meanStdDev(wm, means, stddev); //均值和标准差
	wm = wm / stddev.at<double>(0);

	// 嵌入co
	// cw = co + alpha*wm
	cw = alpha * wm;
	cw += cover;
	cw.convertTo(cw, CV_8UC1);

	return cw;
}

// 水印检测：返回8个检测值
vector<double> D_SIMPLE_8(Mat cw, vector<Mat> watermark)
{
	vector<double> zlc(watermark.size(), 0);

	int row = cw.rows;
	int col = cw.cols;

	Mat cwd(row, col, CV_64FC1);
	cw.convertTo(cwd, CV_64FC1);
	for (int i = 0; i < watermark.size(); i++)
	{
		zlc[i] = cwd.dot(watermark[i]) / (row * col);
	}

	return zlc;
}

// 有水印的图像中得到的message，为了每一位都有值，临界点定为0
vector<int> GetMessage(vector<double> zlc)
{
	vector<int> m;
	for (int i = 0; i < zlc.size(); i++)
	{
		if (zlc[i] > 0) m.emplace_back(1);
		else m.emplace_back(0);
	}
	return m;
}

// 打印查看
void PrintMsg(vector<int> m)
{
	for (int i = 0; i < m.size(); i++)
		cout << m[i];
	cout << endl;
}

// 根据阈值判断是否有水印：4个value超过即认为存在
bool HasWatermark(vector<double> zlc)
{
	int cnt = 0;
	for (int i = 0; i < zlc.size(); i++)
		if (zlc[i] > thres || zlc[i] < -thres)
			cnt++;

	return cnt >= 4 ? true : false;
}

// 比较两个vector是否相同
bool CompareVec(vector<int> v1, vector<int> v2)
{
	for (int i = 0; i < v2.size(); i++)
		if (v1[i] != v2[i]) return false;
	return true;
}

int main(int arg, char** argv)
{
	// 1. 读取40张cover
	vector<string> paths;
	vector<Mat> covers;
	GetFiles("绝对路径\\covers\\", paths);
	for (int i = 0; i < paths.size(); i++)
	{
		Mat img = imread(paths[i], IMREAD_GRAYSCALE);
		covers.push_back(img);
	}

	// 2. 生成40个[0, 255]范围内message
	vector<vector<int> > messages(40, vector<int>(8, 0));
	for (int i = 0; i < 40; i++)
	{
		for (int j = 0; j < 8; j++)
			messages[i][j] = rand() % 2;
	}

	// 2. 生成8个reference pattern + 1个message得到一张水印
	vector<Mat> patterns;
	for (int i = 0; i < 8; i++)
	{
		Mat_<double>w(512, 512);
		randn(w, Scalar(0), Scalar(1)); // 0，1高斯分布
		patterns.push_back(w);
	}

	int fp = 0;
	int fn = 0;
	int correct = 0;
	int correctf = 0;
	// 3. 一张水印嵌入40张cover，使用messages[0]
	// 计算false positive
	for (int i = 0; i < 40; i++)
	{
		vector<double> zlc = D_SIMPLE_8(covers[i], patterns);
		if (HasWatermark(zlc) == true)
			fp++;
	}
	// 计算false negative/correctness
	for (int i = 0; i < 40; i++)
	{
		Mat res = E_SIMPLE_8(covers[i], patterns, messages[0]);
		vector<double> zlc = D_SIMPLE_8(res, patterns);

		if (HasWatermark(zlc) == false)
		{
			fn++;
			if (CompareVec(GetMessage(zlc), messages[0]) == true)
				correctf++;
			continue;
		}
		if (CompareVec(GetMessage(zlc), messages[0]) == true)
			correct++;
	}
	
	// 查看结果
	cout << "--------------------------" << endl;
	cout << "Message: " << endl;
	PrintMsg(messages[0]);
	cout << "False Positive Rate: " << fp / 40.0 << endl;
	cout << "False Negative Rate: " << fn / 40.0 << endl;
	cout << "Correctness: " << correct*1.0/(40.0-fn) << endl;
	cout << "Correctness of all covers: " << (correct+correctf) * 1.0 / (40.0) << endl;
	cout << "--------------------------" << endl;

	// 4. 40张水印嵌入同一封面 covers[0]
	fp = fn = correct = 0;
	correctf = 0;
	for (int i = 0; i < 40; i++)
	{
		patterns.clear();
		for (int j = 0; j < 8; j++) // pattern
		{
			Mat_<double>w(512, 512);
			randn(w, Scalar(0), Scalar(1)); // 0，1高斯分布
			patterns.push_back(w);
		}
		
		// 计算false positive
		vector<double> zlc = D_SIMPLE_8(covers[0], patterns);
		if (HasWatermark(zlc) == true)
			fp++;

		// 计算false negative/correctness
		Mat res = E_SIMPLE_8(covers[0], patterns, messages[i]);
		zlc = D_SIMPLE_8(res, patterns);
		if (HasWatermark(zlc) == false)
		{
			fn++;
			if (CompareVec(GetMessage(zlc), messages[0]) == true)
				correctf++;
			continue;
		}
		if (CompareVec(GetMessage(zlc), messages[i]) == true)
			correct++;
	}

	// 查看结果
	cout << "--------------------------" << endl;
	cout << "False Positive Rate: " << fp / 40.0 << endl;
	cout << "False Negative Rate: " << fn / 40.0 << endl;
	cout << "Correctness: " << correct * 1.0 / (40.0 - fn) << endl;
	cout << "Correctness of all covers: " << (correct + correctf) * 1.0 / (40.0) << endl;
	cout << "--------------------------" << endl;

	// 5. 信息长度增加--16bit 再次做3）
	// 计算false positive
	patterns.clear();
	fn = fp = correct = correctf = 0;
	vector<int> message16(16,0);
	for (int i = 0; i < 16; i++)
	{
		message16[i] = rand() % 2;
	}
	for (int i = 0; i < 16; i++)
	{
		Mat_<double>w(512, 512);
		randn(w, Scalar(0), Scalar(1)); // 0，1高斯分布
		patterns.push_back(w);
	}
	for (int i = 0; i < 40; i++)
	{
		vector<double> zlc = D_SIMPLE_8(covers[i], patterns);
		if (HasWatermark(zlc) == true)
			fp++;
	}
	
	// 计算false negative/correctness
	for (int i = 0; i < 40; i++)
	{
		Mat res = E_SIMPLE_8(covers[i], patterns, message16);
		vector<double> zlc = D_SIMPLE_8(res, patterns);

		if (HasWatermark(zlc) == false)
		{
			fn++;
			if (CompareVec(GetMessage(zlc), message16) == true)
				correctf++;
			continue;
		}
		if (CompareVec(GetMessage(zlc), message16) == true)
			correct++;
	}
	// 查看结果
	cout << "--------------------------" << endl;
	cout << "Message: " << endl;
	PrintMsg(message16);
	cout << "False Positive Rate: " << fp / 40.0 << endl;
	cout << "False Negative Rate: " << fn / 40.0 << endl;
	cout << "Correctness: " << correct * 1.0 / (40.0 - fn) << endl;
	cout << "Correctness of all covers: " << (correct + correctf) * 1.0 / (40.0) << endl;
	cout << "--------------------------" << endl;


	waitKey(0);
	system("pause");
	return 0;

}