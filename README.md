## 项目文件结构

```sh
.
├── README.md
├── api
│   ├── bundle_merge.py
│   ├── factor_construct.py
│   ├── factor_construct_heter.py
│   ├── pdf2txt.py
│   └── pdf_access.py
├── config
│   ├── diydict.txt
│   └── stopwords.txt
├── pipeline
└── src
    ├── urllib
    │   ├── 巨潮2015.xlsx
    │   ├── 巨潮2016.xlsx
    │   ├── 巨潮2017.xlsx
    │   ├── 巨潮2018.xlsx
    │   ├── 巨潮201901-201906.xlsx
    │   ├── 巨潮201907-201912.xlsx
    │   ├── 巨潮202001-202006.xlsx
    │   ├── 巨潮202007-202012.xlsx
    │   ├── 巨潮202101-202106.xlsx
    │   └── 巨潮202107-202112.xlsx
    ├── wind_info_all.csv
    └── wind_info_gre.csv
```

- `README.md` 说明
- ***文件夹`api`：代码（git管理）***
- ***文件夹`config`：外部配置文件***
  - `diydict.txt` 用户自定义词典
  - `stopwords.txt` 用户自定义停用词词典
- ***文件夹`pipeline`：存放计算过程数据***
- ***文件夹`src`：存放外部添加的数据***
  - 文件夹`urllib` 由“八抓鱼采集器”爬取的募集说明书获取地址
  - `wind_info_all.csv` Wind上16-21年发行的所有公司债和企业债
  - `wind_info_gre.csv` Wind上16-21年发行的所有绿色债券

## 代码运行流程

0. 运行代码前，修改开头的`_PATH`为项目根目录
1. `pdf_access.py` 下载PDF文件，来源于`src/urllib/*.xlsx`
2. `pdf2txt.py` 上一步获取的PDF文件依次读取为TXT存储
3. `factor_construct.py` 逐个分析TXT文档，计算词频指标和词频向量
4. `bundle_merge.py` 合并上一步分块存储的的计算结果
5. `factor_construct_heter.py` 由合并后的词频向量计算文本异质性指标

