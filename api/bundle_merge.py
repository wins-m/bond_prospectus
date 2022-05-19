"""
(created by swmao on May 17th)

"""
import pandas as pd
import os


_PATH = '.'


def merge_bundle_results(path, id_set=None) -> pd.DataFrame:
    """合并文本计算后的batch bundle, id_set指定须保留的id"""
    print(f'\nMerge bundle-results from {path} ...')
    res = []
    for file in (_ for _ in os.listdir(path) if _[0] != '.' and '.csv' in _):
        try:
            df = pd.read_csv(path + file)
        except:
            raise Exception(path + file)
        if id_set is not None:
            df = df[df['id'].apply(lambda x: x in id_set)]
        res.append(df)
    print(f'\t{len(res)} bundle read, concat ...')
    return pd.concat(res)


def bundle_result_merge(fval_path, fvec_path, wind_path_green, tgt_fval, tgt_fvec): 
    target_info = merge_bundle_results(fval_path)  # 样本债券+文本特征+id
    print('样本大小', len(target_info))
    codes_green = set(pd.read_csv(wind_path_green)['code'])
    target_info['isGreen'] = target_info['code'].apply(lambda x: x in codes_green)
    print('\t其中绿色债券数', target_info['isGreen'].sum())
    target_fvec = merge_bundle_results(fvec_path).set_index('id')  # id+词频向量
    print('词向量规模', target_fvec.shape)
    target_info.to_csv(tgt_fval, index=None)
    target_fvec.to_pickle(tgt_fvec)
    print(f'结果输出在\n\t{tgt_fval}\n\t{tgt_fvec}')


def main():
    fval_path = f'{_PATH}/pipeline/target_fvalue/'  # 待合并 募集书信息/因子 目录
    fvec_path = f'{_PATH}/pipeline/target_fvector/'  # 待合并 向量文件 目录
    wind_path_green = f'{_PATH}/src/wind_info_gre.csv'  # Wind 绿色债券
    tgt_fval = f'{_PATH}/pipeline/target_fvalue.csv'  # 募集书信息/因子(全部) 存储
    tgt_fvec = f'{_PATH}/pipeline/target_fvector.pkl'  # 词向量(全部) 存为pickle文件
    bundle_result_merge(fval_path, fvec_path, wind_path_green, tgt_fval, tgt_fvec)


if __name__ == '__main__':
    main()

