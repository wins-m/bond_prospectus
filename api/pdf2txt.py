"""
(created by swmao on May 13th)

"""
import pandas as pd
import numpy as np
import os


_PATH = r'/Users/winston/Documents/4-2/金融科技与区块链/区块链PROJ/data&code'


def main(): 
    pdf_path = f'{_PATH}/src/all_pdf/' 
    tgt_path = f'{_PATH}/src/all_text/'
    pdf2txt(src=pdf_path, tgt=tgt_path)
    

def progressbar(cur, total, msg):
    """显示进度条"""
    import math
    percent = '{:.2%}'.format(cur / total)
    lth = int(math.floor(cur * 25 / total))
    print("\r[%-25s] %s (%d/%d)" % ('=' * lth, percent, cur, total) + msg, end='')

    
def pdf2txt(src, tgt) -> pd.DataFrame:
    """Extract pure text from *.pdf"""
    import pdfdocx
    os.makedirs(tgt, exist_ok=True)
    src_files = os.listdir(src)
    cnt = 0
    wtf = []
    for file in src_files:
        src_file = src + file
        tgt_file = tgt + file.replace('.pdf', '.txt')
        if os.path.exists(tgt_file):
            cnt += 1
            continue
        try:
            text = pdfdocx.read_pdf(src_file)
        except RuntimeError:
            raise Exception(f'FAIL: {file}')
        with open(tgt_file, 'w', encoding='utf-8') as f:
            f.write(text)
        cnt += 1
        progressbar(cnt, len(src_files), 
                    msg=f" text_length={len(text)} {file[1:].split(']')[0]:10s}")
    print('\nFINISHTED')

    
if __name__ == '__main__':
    main()
