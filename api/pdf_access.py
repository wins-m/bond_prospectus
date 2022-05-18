"""
(created by swmao)
Merge PDF infomation from crawler results; Download all PDF files. 

"""
import pandas as pd
import urllib.request
import os, time


_PATH = r'/Users/winston/Documents/4-2/金融科技与区块链/区块链PROJ/data&code'

            
def main():    
    # Input
    crawler_res = f'{_PATH}/src/urllib/'  # 爬虫结果
    wind_info = f'{_PATH}/src/wind_info_all.csv'  # '../src/wind_info_gre.csv'
    
    # Output
    url_all = f'{_PATH}/src/urllib_combined.csv'  # 爬虫的网址结果合并
    parse_target = f'{_PATH}/src/parse_target_all.csv'  # '../src/parse_target_gre.csv'  
    pdf_path = f'{_PATH}/src/all_pdf/'
    
    # Config
    title_stop_word = ['摘要', '更正公告', '评级报告', '变更说明', '已取消']
    
    urllib_merge(src=crawler_res, tgt=url_all)
    info_match(urls=url_all, info=wind_info, tgt=parse_target, tit_sw=title_stop_word)
    pdf_access(src=parse_target, tgt=pdf_path)


def progressbar(cur, total, msg):
    """显示进度条"""
    import math
    percent = '{:.2%}'.format(cur / total)
    lth = int(math.floor(cur * 25 / total))
    print("\r[%-25s] %s (%d/%d)" % ('=' * lth, percent, cur, total) + msg, end='')


def pdf_access(src, tgt):
    """Download PDF from url in info"""
    
    os.makedirs(tgt, exist_ok=True)
    
    parse_target = pd.read_csv(src)
    assert parse_target['code'].value_counts().max() == 1  # ensure unique code
    parse_target['url1'] = ''  # 跳转网址
    parse_target['filename'] = ''  # 存储pdf文件名
    
    cnt = 0
    print(parse_target.iloc[cnt]) 
    for ir in parse_target.iloc[cnt:].iterrows():
        url, code, title = ir[1]['url'], ir[1]['code'], ir[1]['title']
        filename = f'[{code}]{title}.pdf'
        parse_target.loc[ir[0], 'filename'] = filename
        
        announcementId = url.split('announcementId=')[1].split('&orgId')[0]
        announcementTime = url.split('announcementTime=')[1]
        url1 = f'http://static.cninfo.com.cn/finalpage/{announcementTime}/{announcementId}.PDF' 
        try:
            response = urllib.request.urlopen(url1) 
        except:
            url1 = url1.replace('.PDF', '.pdf')
            response = urllib.request.urlopen(url1)
        parse_target.loc[ir[0], 'url1'] = url1
         
        with open(f'{tgt}/{filename}', 'wb') as f:
            f.write(response.read())
        cnt += 1
        progressbar(cnt, len(parse_target), msg=f" {url1} {ir[1]['name']:8s}")  
        if cnt % 10 == 9:
            time.sleep(1)
            
    print('FINISHED.')
    parse_target.to_csv(src, index=None)
   

def info_match(urls, info, tgt, tit_sw=[]):
    urllib = pd.read_csv(urls)
   
    # title 停用关键字 如 摘要
    if len(tit_sw) > 0:
        mask = urllib['title'].apply(lambda x: all([w not in x for w in tit_sw]))
        urllib = urllib[mask]
        
    # 募集书对应多只债券code 直接去除
    urllib = urllib[urllib['codes'].apply(lambda x: ',' not in x)]
     
    # 同一只债券多次出现 去重 优先保留发布时间靠后的公告
    urllib = urllib.sort_values('date', ascending=True)  # 公告发布时间正序排列 15..21 
    urllib = urllib.loc[urllib[['codes']].drop_duplicates(keep='last').index]  
    
    # 合并Wind获取的债券信息，取交集
    parse_target = pd.read_csv(info)
    parse_target['name'] = parse_target['name'].apply(lambda x: x.replace(' ', ''))
    parse_target['codes'] = parse_target['code'].apply(lambda x: x.split('.')[0])
    parse_target_with_url = parse_target.merge(urllib, on='codes', how='inner')
    
    parse_target_with_url.to_csv(tgt, index=None)
    print(f'Matched info saved, tab size = {parse_target_with_url.shape}')


def url2stockcode(sr: pd.Series) -> pd.Series:
    """网址中解析出股票代码"""
    return sr.apply(lambda x: x.split('stockCode=')[1].split('&announcementId')[0])
           
    
def urllib_merge(src, tgt):  
    urllib = pd.DataFrame()
    for file in sorted(os.listdir(src)):
        df =  pd.read_excel(src + file)
        urllib = pd.concat([df, urllib])
    urllib.columns = ['url', 'title', 'date']
    urllib['date'] = urllib['date'].apply(lambda x: x.strip()[:10])
    # urllib['name'] = urllib['title'].apply(lambda x: x.split(':')[0].strip())
    urllib['codes'] = url2stockcode(urllib['url'])
    urllib.to_csv(tgt, index=False)
    
    print(f'Merged urls saved, tab size = {urllib.shape}')

    
if __name__ == '__main__':
    main()
