# 募集书文本与债券发行利差 | 金融科技研究论文 

- [论文](./Doc/07-募集说明书文本与债券发行利差.pdf)
- [报告](./Doc/07-“绿色债券”的募集说明书%20如何影响其风险溢价？-ppt.pdf)

## 项目文件结构

```sh
.
├── README.md
├── STATA
│   ├── Code
│   ├── Data
│   ├── Full_0521.dta
│   ├── Graph_Density.png
│   ├── Main.do
│   ├── README.md
│   ├── Tables_0518
│   └── Tables_0521
├── api
│   ├── bundle_merge.py
│   ├── factor_construct.py
│   ├── factor_construct_heter.py
│   ├── pdf2txt.py
│   └── pdf_access.py
├── config
│   ├── diydict.txt
│   └── stopwords.txt
├── pipeline
│   ├── target_fvalue
│   ├── target_fvalue(4425,\ 27).csv
│   ├── target_fvalue.csv
│   ├── target_fvector
│   └── text_splitted
└── src
    ├── all_pdf
    ├── all_text
    ├── parse_target_all.csv
    ├── urllib
    ├── urllib_combined.csv
    ├── wind_info_all.csv
    └── wind_info_gre.csv
```

- `README.md` 说明
- ***文件夹`STATA`: 描述性统计和回归的Stata代码***
- ***文件夹`api`: 文本获取和处理的Python代码***
- ***文件夹`config`: 外部配置文件***
  - `diydict.txt` 用户自定义词典
  - `stopwords.txt` 用户自定义停用词词典
- ***文件夹`pipeline`: 存放计算过程数据***
  - 文件夹`target_fvalue` 分段处理的文本指标
  - `target_fvalue(4425,\ 27).csv` <u>最终的样本文本指标面板</u>
  - `target_fvalue.csv` 分段处理后文本指标合并
  - 文件夹`target_fvector` 分段处理的文本词频向量
  - 文件夹`text_splitted` 分词、停用、分句后的文本，可用作未来研究

- ***文件夹`src`: 存放外部添加的数据***
  - 文件夹`all_pdf` 下载的原始pdf文件
  - 文件夹`all_text` 原始pdf读取获得的txt文件
  - `parse_target_all.csv` 筛选后的样本
  - `urllib_combined.csv` 从爬虫结果合并的pdf网址记录
  - 文件夹`urllib` 由“八抓鱼采集器”爬取的募集说明书获取地址
  - `wind_info_all.csv` Wind上16-21年发行的所有公司债和企业债
  - `wind_info_gre.csv` Wind上16-21年发行的所有绿色债券

## Python部分运行流程

0. 运行代码前，修改开头的`_PATH`为项目根目录
1. `pdf_access.py` 下载PDF文件，来源于`src/urllib/*.xlsx`
2. `pdf2txt.py` 上一步获取的PDF文件依次读取为TXT存储
3. `factor_construct.py` 逐个分析TXT文档，计算词频指标和词频向量
4. `bundle_merge.py` 合并上一步分块存储的的计算结果
5. `factor_construct_heter.py` 由合并后的词频向量计算文本异质性指标

