"""
(created by swmao on May 17th)

"""
import pandas as pd
import numpy as np
from datetime import timedelta

# _PATH = r'/Users/winston/Documents/4-2/金融科技与区块链/区块链PROJ/data&code'
_PATH = r'/mnt/c/Users/Winst/Desktop/data_code'


def url2stockcode(sr: pd.Series) -> pd.Series:
    """网址中解析出股票代码"""
    return sr.apply(lambda x: x.split('stockCode=')[1].split('&announcementId')[0])


def drop_problematic_fct_info(fct_info, min_sentence_num, min_unique_word_num) -> pd.DataFrame:
    """根据债券信息&募集书文本特点 筛去不合适的“募集书”记录"""
    shape0 = fct_info.shape

    mask1 = fct_info['SNum'] >= min_sentence_num  
        # sentence number gt threshold
    mask2 = fct_info['WNum2'] >= min_unique_word_num  
        # number of unique non-stopping-word gt threshold
    mask = mask1 & mask2
    fct_info = fct_info[mask]

    fct_info = fct_info.sort_values(['date', 'code'], ascending=True)  
        # 公告发布时间正序排列，优先保留发布时间靠后的公告
    fct_info = fct_info.loc[
        fct_info.loc[:, ['date', 'VecLen', 'CNum']].drop_duplicates(keep='last').index] 
        # PDF完全一致的去重 TODO: pdf_access.py 多个债券的募集书
    fct_info = fct_info.reset_index(drop=True)
    print(f"筛选公告: {shape0} -> {fct_info.shape}")
    return fct_info


def myMLR(X, Y) -> pd.DataFrame:
    x = X.values
    y = Y.values
    x = x.reshape(-1, 1) if x.shape.__len__() == 1 else x
    y = y.reshape(-1, 1) if y.shape.__len__() == 1 else y
    assert x.shape[0] == y.shape[0]
    try:
        beta = (np.linalg.inv(x.T @ x) @ x.T @ y).T
    except np.linalg.LinAlgError:
        print(y, x)
        raise np.linalg.LinAlgError
    Beta = pd.DataFrame(beta, columns=X.columns, index=Y.columns)
    return Beta


def cal_fct_heter(Y, Y_hat) -> pd.DataFrame:
    def cal_ssr(Y, Y_hat):
        return (Y - Y_hat).apply(lambda s: np.sum(s**2)).rename('SSR')

    def cal_sst(Y):
        return Y.apply(lambda s: np.sum((s-s.mean())**2)).rename('SST')

    ssr = cal_ssr(Y, Y_hat)
    sst = cal_sst(Y)
    heter = (sst - ssr) / ssr
    if heter.iloc[0] <= 0:
        print('\n\n', heter, '\n')
    heter = np.log(heter).rename('Heter')
    heter = pd.DataFrame(heter)
    # assert heter.index.name == 'id'
    return heter


def progressbar(cur, total, msg):
    """显示进度条"""
    import math
    percent = '{:.2%}'.format(cur / total)
    print("\r[%-25s] %s (%d/%d)" % ('=' * int(math.floor(cur * 25 / total)), percent, cur, total) + msg, end='')


def cal_text_factor_heter(panel):
    Y = panel.iloc[:, 0:1]  # 面板第一列为y
    X = panel.iloc[:, 1:]  # 面板第二列开始为X
    # assert (X.index == Y.index).prod() == 1
    Beta = myMLR(X, Y)
    Y_hat = X @ Beta.T
    heter = cal_fct_heter(Y, Y_hat).values[0, 0]
    info_ctnt = (Y-Y_hat).abs().sum().values[0]
    stdd_ctnt = Beta.values[0, 0]
    return heter, info_ctnt, stdd_ctnt


class FacHeter(object):

    def __init__(self, data, fvec):
        self.data = data.reset_index(drop=True)
        self.id_info = data.set_index('date')[['id']].sort_index()
        self.fvec = fvec
        self.length = len(data)

    def mean_freq_vec_within_window(self, td, win_len, min_w=1e-3):
        td0, td1 = td - timedelta(days=win_len), td - timedelta(days=1)
        w_id = self.id_info.loc[td0: td1, 'id'].to_list()
        fvec = self.fvec.loc[w_id].copy().dropna(how='all', axis=1).fillna(0)
        fvec = fvec.mean().rename(f'm{win_len}')
        fvec /= fvec.sum()
        while fvec.min() <  min_w:
            fvec = fvec[fvec > fvec.min()]
            fvec /= fvec.sum()
        return len(w_id), fvec

    def calculat(self, w_len):
        self.data[f'Heter{w_len}'] = np.nan
        self.data[f'DocNum{w_len}'] = -1
        self.data[f'Info{w_len}'] = np.nan
        self.data[f'Stdd{w_len}'] = np.nan
        print(f'\nCalculate Heter{w_len} values ...')
        for ir in self.data.iterrows():
            ind, td, idd = ir[0], ir[1]['date'], ir[1]['id']
            if td.year < 2016:
                continue
            adj_num, adj_vec = self.mean_freq_vec_within_window(td, w_len)
            self.data.loc[ind, f'DocNum{w_len}'] = adj_num
            if adj_num == 0:
                continue
            cur_vec = self.fvec.loc[idd].dropna().copy()
            panel = pd.concat([cur_vec, adj_vec], axis=1).dropna()
            heter, info_ctnt, stdd_ctnt = cal_text_factor_heter(panel)
            self.data.loc[ind, f'Heter{w_len}'] = heter
            self.data.loc[ind, f'Info{w_len}'] = info_ctnt
            self.data.loc[ind, f'Stdd{w_len}'] = stdd_ctnt
            msg1 = f" Heter={heter:6.3f} Info={info_ctnt:6.3f} Stdd={stdd_ctnt:6.3f} AdjacentNum={adj_num} {td.strftime('%Y-%m-%d')} {ir[1]['name']:10s}"
            progressbar(ind+1, self.length, msg=msg1)

    def get_data(self):
        return self.data.copy()


def func(fct_value, freq_vector, win_len):
    FH = FacHeter(fct_value, freq_vector)
    print(FH.data.shape)
    for w_len in win_len:
        FH.calculat(w_len=w_len)
    fct_value = FH.get_data()
    print(fct_value.shape)


def factor_construct_bundle(path_fval, path_fvec, min_sentence_num, min_unique_word_num, win_len, tgt_file):
    fct_value = pd.read_csv(path_fval)
    fct_value = drop_problematic_fct_info(fct_value, min_sentence_num, min_unique_word_num)
    print(f"去重后 样本债券{len(fct_value)}只，绿色债券{fct_value['isGreen'].sum()}只")
    # fct_value.to_csv(f'{_PATH}/pipeline/without_heter.csv')
    fct_value['date'] = pd.to_datetime(fct_value['date'])  # 公告发行日为准
    freq_vector = pd.DataFrame(pd.read_pickle(path_fvec))
    FH = FacHeter(fct_value, freq_vector)
    FH.calculat(w_len=win_len)
    fct_value = FH.get_data()
    fct_value.to_csv(tgt_file.format(fct_value.shape), index=None)


def main():
    # Input:
    path_fval = f'{_PATH}/pipeline/target_fvalue.csv'
    path_fvec = f'{_PATH}/pipeline/target_fvector.pkl'
    # Config:
    min_sentence_num = 100
    min_unique_word_num = 1000
    win_len = 90
    # Output:
    tgt_file = _PATH + '/pipeline/target_fvalue{}.csv'

    factor_construct_bundle(path_fval, path_fvec, min_sentence_num, min_unique_word_num, win_len, tgt_file)


if __name__ == '__main__':
    main()
