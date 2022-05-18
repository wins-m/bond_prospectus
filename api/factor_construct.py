"""
(created by swmao on May 15th)
文本到因子的计算。
全局参数： 
- is_test: 是否测试（前16行）
- process_num: 进程数
- batch_size: 多少文件存一次
- telling: 运行是否output计算结果
(May 16th) 
8588个募集书，7进程4.5小时。

"""
import pandas as pd
import numpy as np
import os
import pdfdocx
from pathlib import Path
from typing import Tuple, List, Dict

        
# _PATH = r'/Users/winston/Documents/4-2/金融科技与区块链/区块链PROJ/data&code'
_PATH = r'/mnt/c/Users/Winst/Desktop/data_code'

def get_txt_path(title, src_path, ubuntu=False) -> str:
    if ubuntu:  # macos 文件名中 ':' 在 ubuntu 为 '"'
        title = title.replace(' : ', ' " ')
    return f"{src_path}{title.rsplit('.', maxsplit=1)[0]}.txt"


def read_oneline_txt(path) -> str:
    with open(path, 'r', encoding='utf-8') as f:
        text = f.read()
    return text


def jieba_lcut(text, udict=None) -> list:
    import jieba
    import logging
    jieba.setLogLevel(logging.INFO)
    if udict is not None:
        jieba.load_userdict(udict)
    words = jieba.lcut(text)
    return words


def word_stopping(words, stop_w_path=None) -> list:
    
    def contains_chinese(strs):
        for _char in strs:
            if '\u4e00' <= _char <= '\u9fa5':
                return True
        return False
    
    stopwords = []
    if stop_w_path is not None:
        with open(stop_w_path, 'r', encoding='utf-8') as f:
            stopwords = f.readlines()
    words1 = [w for w in words if (w == '。') or 
              (w not in stopwords and len(w) > 1 and contains_chinese(w))]
    return words1


def ele_frequency(words1: list, is_sorted=True) -> pd.DataFrame:
    """记录词频"""
    wordfreqs = [(w, words1.count(w)) for w in set(words1) if w != '。']
    if is_sorted:
        wordfreqs = sorted(wordfreqs, key=lambda k:k[1], reverse=True)  # 根据词频进行排序
    wordfreqs = pd.DataFrame(wordfreqs, columns=['word', 'freq'])
    return wordfreqs


def key_word_num_1k(wordfreqs: pd.DataFrame, kw_list: list, scale=1e3, tshow=False):
    """每scale个词语中出现kw_list内词语的次数"""
    find_in_kw_list = wordfreqs['word'].apply(lambda x: x in kw_list)
    if tshow:
        print(wordfreqs[find_in_kw_list])
    return (find_in_kw_list * wordfreqs['freq']).sum() / wordfreqs['freq'].sum() * scale


def get_normalized_vector(wordfreqs, max_num=10000, min_w=1e-4) -> pd.Series:
    """normalized word-freq-weight vectors, 
    with degree no larger than max_num and
    element value no less than min_w"""
    w = wordfreqs.set_index('word').iloc[:int(max_num), 0]
    w /= w.sum()
    assert w.max() > min_w
    while w.min() < min_w:
        w = w[w > w.min()]
        w /= w.sum()
    return w


def title_clean(text, title) -> str:
    """剔除反复出现的标题"""
    title_clean = (title.split(':', maxsplit=1)[-1]).replace(' ', '')
    return text.replace(title_clean, '')  


def cal_text_factor3(title, filename, ir, kw_eco, kw_policy, kw_eco1, kw_policy1, 
                     src_path, tgt_path, udict_path, stopw_path, max_num=1000, min_w=1e-3, 
                     telling=False) -> Tuple[int, dict]:
    """从txt文本，直接算出2个词频变量和1个词频向量"""
    path = get_txt_path(filename, src_path=src_path, ubuntu=True)
    text = read_oneline_txt(path)
    text = title_clean(text, title)
    words = jieba_lcut(text, udict=udict_path)
    words1 = word_stopping(words, stop_w_path=stopw_path)
    wordfreqs = ele_frequency(words1, is_sorted=True)

    if len(wordfreqs) == 0:
        return {'Eco': np.nan, 'Policy': np.nan, 'Eco1': np.nan, 'Policy1': np.nan,
                'Vec': pd.Series([], dtype=float), 'VecLen': len(norm_vec), 
                'CNum': len(text), 'WNum0': len(words), 'WNum1': len(words1), 
                'WNum2': len(wordfreqs), 'SNum': words.count('。'), }
    
    if tgt_path is not None and len(tgt_path) > 0:  # 存储 分词/停用/断句 后的文档
        path1 = get_txt_path(filename, src_path=tgt_path)
        with open(path1, 'w', encoding='utf-8') as f:
            f.write(' '.join(words1).replace(' 。 ', '\n'))
    freq1k_eco = key_word_num_1k(wordfreqs, kw_eco, scale=1e3, tshow=False)
    freq1k_policy = key_word_num_1k(wordfreqs, kw_policy, scale=1e3, tshow=False)
    freq1k_eco1 = key_word_num_1k(wordfreqs, kw_eco1, scale=1e3, tshow=False)
    freq1k_policy1 = key_word_num_1k(wordfreqs, kw_policy1, scale=1e3, tshow=False)
    # TODO: 文本词频向量的规模需要根据，平均测词频分布，取合理截断
    norm_vec = get_normalized_vector(wordfreqs, max_num=max_num, min_w=min_w)
    
    if telling:
        print('\n\n标题', title)
        print('路径', path)
        print('字符数:', text.__len__())
        print('总词数:', len(words))
        print('实词数:', len(words1))
        print('句子数:', words.count('。'))
        print('词频项:', len(wordfreqs))
        print('环境保护', round(freq1k_eco, 6))
        print('政策响应', round(freq1k_policy, 6))
        print('环境保护1', round(freq1k_eco1, 6))
        print('政策响应1', round(freq1k_policy1, 6))
        print('词频向量', norm_vec.shape, '\n    '+str(norm_vec[:10]).replace('\n','\n    '))

    res = {'Eco': freq1k_eco, 'Policy': freq1k_policy, 
           'Eco1': freq1k_eco1, 'Policy1': freq1k_policy1, 
           'Vec': norm_vec, 'VecLen': len(norm_vec), 'CNum': len(text), 
           'WNum0': len(words), 'WNum1': len(words1), 'WNum2': len(wordfreqs), 
           'SNum': words.count('。'), }
        
    return ir, res


def progressbar(cur, total, msg):
    """显示进度条"""
    import math
    percent = '{:.2%}'.format(cur / total)
    lth = int(math.floor(cur * 25 / total))
    print("\r[%-25s] %s (%d/%d)" % ('=' * lth, percent, cur, total) + msg, end='')


class FctConstructor(object):
    
    def __init__(self, data, src_path, tgt_path, udict, stopw, telling):
        self.data: pd.DataFrame = data
        self.src_path: str = src_path
        self.tgt_path: str = tgt_path  # 分词/停用/断句 后的文本
        self.udict_path: str = udict
        self.stopw_path: str = stopw
        self.telling = telling
        
        self.norm_vec_temp = {}
        self.cnt_cal3 = 0
        self.norm_vec_temp = []
        self.norm_vec: pd.DataFrame = pd.DataFrame
        
        
    def cal_fct3_multiprocess(self, kw_eco, kw_policy, kw_eco1, kw_policy1, max_num, min_w, pnum):
        import multiprocessing 
        
        def call_back(arg):
            ir,v = arg[0], arg[1]
            self.data.loc[ir, 'CNum'] = v['CNum']
            self.data.loc[ir, 'WNum0'] = v['WNum0']
            self.data.loc[ir, 'WNum1'] = v['WNum1']
            self.data.loc[ir, 'WNum2'] = v['WNum2']
            self.data.loc[ir, 'SNum'] = v['SNum']
            self.data.loc[ir, 'Eco'] = v['Eco']
            self.data.loc[ir, 'Eco1'] = v['Eco1']
            self.data.loc[ir, 'Policy'] = v['Policy']
            self.data.loc[ir, 'Policy1'] = v['Policy1']
            self.data.loc[ir, 'VecLen'] = v['VecLen']
            self.norm_vec_temp.append(v['Vec'].rename(self.data.loc[ir, 'id']))
            self.cnt_cal3 += 1
            cur_date = self.data.loc[ir, 'date']
            cur_name = self.data.loc[ir, 'name']
            progressbar(self.cnt_cal3, len(self.data), msg=f" {cur_date} {cur_name}")
            
        pool = multiprocessing.Pool(pnum)
        for ir in self.data.index:
            title = self.data.loc[ir, 'title']
            filename = self.data.loc[ir, 'filename']
            ind = self.data.loc[ir, 'id']
            pool.apply_async(cal_text_factor3, 
                             args=(title, filename, ir, kw_eco, kw_policy, kw_eco1, kw_policy1, 
                                   self.src_path, self.tgt_path,  self.udict_path, self.stopw_path, 
                                   max_num, min_w, self.telling), 
                             callback=call_back)
        pool.close()
        pool.join()

        self.norm_vec = pd.DataFrame(self.norm_vec_temp).reset_index().rename(columns={'index':'id'})
        return self.data, self.norm_vec
        
    def cal_fct3_file_by_file(self, kw_eco, kw_policy, kw_eco1, kw_policy1, max_num, min_w):
        Vec = []  # pd.DataFrame()

        for ir in range(len(self.data)):
            title = self.data.loc[ir, 'title']
            filename = self.data.loc[ir, 'filename']
            ind = self.data.loc[ir, 'id']
            arg = cal_text_factor3(title, filename, ir, kw_eco, kw_policy, kw_eco1, kw_policy1, 
                                   self.src_path, self.tgt_path, self.udict_path, self.stopw_path, 
                                   max_num, min_w, self.telling)
            ir,v = arg[0], arg[1]
            self.data.loc[ir, 'CNum'] = v['CNum']
            self.data.loc[ir, 'WNum0'] = v['WNum0']
            self.data.loc[ir, 'WNum1'] = v['WNum1']
            self.data.loc[ir, 'WNum2'] = v['WNum2']
            self.data.loc[ir, 'SNum'] = v['SNum']
            self.data.loc[ir, 'Eco'] = v['Eco']
            self.data.loc[ir, 'Eco1'] = v['Eco1']
            self.data.loc[ir, 'Policy'] = v['Policy']
            self.data.loc[ir, 'Policy1'] = v['Policy1']
            self.data.loc[ir, 'VecLen'] = v['VecLen']
            Vec.append(v['Vec'].rename(ind))
            # 进度条
            self.cnt_cal3 += 1
            cur_date = self.data.loc[ir, 'date']
            cur_name = self.data.loc[ir, 'name']
            progressbar(self.cnt_cal3, len(self.data), msg=f" {cur_date} {cur_name}")
            
        self.norm_vec = pd.DataFrame(Vec).reset_index().rename(columns={'index':'id'})  # Vec.T
        return self.data, self.norm_vec
    

def factor_construct(src_file, src_path, fval_path, fvec_path, text_path, 
                     is_test, process_num, batch_size, telling, 
                     max_num, min_w, kw_eco, kw_policy, kw_eco1, kw_policy1, udict, stopw):
    
    src = pd.read_csv(src_file)
    src['id'] = src.index
    
    # Generate stopping words dict
    with open(udict, 'w', encoding='utf-8') as f:
        f.write('\n'.join(['碳中和', ]) + '\n')
        f.write('\n'.join(src['inst'].to_list()) + '\n')  # 专有词：发行主体名称
        f.write('\n'.join(src['name'].to_list()) + '\n')  # 专有词：债券名称

    # Calculate text features
    os.makedirs(fval_path, exist_ok=True)
    os.makedirs(fvec_path, exist_ok=True)
    os.makedirs(text_path, exist_ok=True)
    data = src.iloc[-16:].reset_index(drop=True).copy() if is_test else src.copy()
    data['CNum'] = -1  # character number
    data['WNum0'] = -1  # word number
    data['WNum1'] = -1  # number of non-stopping-word
    data['WNum2'] = -1  # number of unique non-stopping-word
    data['SNum'] = -1  # sentence number
    data['Eco'] = -1.  # text var0
    data['Eco1'] = -1.  # text var0 - extended
    data['Policy'] = -1.  # text var1
    data['Policy1'] = -1.  # text var1 - extended
    data['VecLen'] = -1  # degree of word-freqency-vector
    for batch_begin in range(0, len(data), batch_size):
        suffix = f'{batch_begin:05d}_{min(batch_begin+batch_size, len(data)):05d}'
        print(f'\n\nCalculate basic 3 text factors {suffix}...')

        txt_path = f'{text_path}{suffix}/'
        os.makedirs(txt_path, exist_ok=True)
        FC = FctConstructor(data.iloc[batch_begin: batch_begin+batch_size], 
                            src_path, txt_path, udict, stopw, telling)
        if process_num == 1:
            target_fvalue, target_fvector = FC.cal_fct3_file_by_file(
                kw_eco, kw_policy, kw_eco1, kw_policy1, max_num, min_w)
        else:
            target_fvalue, target_fvector = FC.cal_fct3_multiprocess(
                kw_eco, kw_policy, kw_eco1, kw_policy1, max_num, min_w, pnum=process_num)
        if is_test:
            print('\n\nResult:\n')
            print(target_fvalue.tail())
            print(target_fvector.tail())
        # else:
        fval_file = f'{fval_path}fval_{suffix}.csv'
        fvec_file = f'{fvec_path}tvec_{suffix}.csv'
        target_fvalue.to_csv(fval_file, index=None)
        target_fvector.to_csv(fvec_file, index=None)
        
        
def main():
    
    # Input:
    src_file = f'{_PATH}/src/parse_target_all.csv'  # 募集书样本
    src_path = f'{_PATH}/src/all_text/'  # 存放pdf2txt生成的txt文本
    
    # Output:
    fval_path = f'{_PATH}/pipline/target_fvalue/'  # 募集书记录+id+因子值*2
    fvec_path = f'{_PATH}/pipline/target_fvector/'  # id+词向量
    text_path = f'{_PATH}/pipline/text_splitted/'  # 存放新生成的 分词/停用/分句 后的txt文本
    
    # Config:
    is_test = False
    process_num = 7
    batch_size = 200
    telling= False  # True
    max_num = 500  # 词频向量最大维数(实词数量)
    min_w = 1e-3  # 词频向量中最小词频(实词i出现频数 / 实词总频数)
    kw_eco = "低碳、节能、环境、环保、生态、可持续、清洁、循环、排放、污染、能源".split('、')
    kw_eco1 = ['绿色','持续','环境','能源','环保','新能源','风电','生态','清洁',
                '污水处理','污水','水电','节能','再生能源','燃料','垃圾','水电站',
                '风能','太阳能','水资源','风电场','核电','减排','垃圾焚烧','循环',
                '垃圾处理','环境保护','排放','生态环境','水源','限电','污染','水质',
                '固废','新能','碳中和','环境治理','储能','清淤','水利','绿色生态']
    kw_policy = "政府、国务院、中央、公共、基础设施、全会、决议、文件、号召、社会责任".split('、')
    kw_policy1 = ['法律','国家','文件','法规','政策','决议','政府','基础设施','改革',
                '专项','依法','办法','国资委','人民政府','社会','国有资产','市政',
                '财政局','国务院','公共交通','法律法规','中共党员','国资','国有',
                '办公厅','中央','国民经济','国开','国家开发银行','国投','法律责任',
                '国用','财政','市政府','行政','商务部','公共设施']
    udict = f'{_PATH}/config/diydict.txt'
    stopw = f'{_PATH}/config/stopwords.txt'
    
    # Run:
    factor_construct(src_file, src_path, fval_path, fvec_path, text_path, 
                     is_test, process_num, batch_size, telling, 
                     max_num, min_w, kw_eco, kw_policy, kw_eco1, kw_policy1, udict, stopw)
    
if __name__ == '__main__':
    main()
