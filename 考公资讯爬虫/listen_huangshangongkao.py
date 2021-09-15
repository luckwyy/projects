import requests
from bs4 import BeautifulSoup
import send_email
import time

# 公务员和事业单位
gwyandsydw = "http://www.apta.gov.cn/Officer"
# 市县考试服务平台
sxksfw = "http://www.apta.gov.cn/CityExams"
# 黄山市人事考试网上报名系统
hsrsks = "http://hsrskp.pzhl.net/index.php"
# 黄山市人力资源和社会保障局
hsrsjtz = "http://rsj.huangshan.gov.cn/tzgg/index.html"

sites = {"安徽公务员和事业单位": gwyandsydw,
         "安徽市县考试服务平台": sxksfw,
         "黄山市人事考试网上报名系统": hsrsks,
         "黄山市人力资源和社会保障局": hsrsjtz
         }

def g():
    content = []
    headers = {
        'Host': 'www.apta.gov.cn',
        'Connection': 'keep-alive',
        'Cache-Control': 'max-age=0',
        'Upgrade-Insecure-Requests': '1',
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/93.0.4577.63 Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9',
        'Accept-Encoding': 'gzip, deflate',
        'Accept-Language': 'zh-CN,zh;q=0.9',
        'Cookie': '__jsluid_h=24f7e514f81006ed8f6a21a790689978'
    }
    r = requests.get(gwyandsydw, headers = headers)
    r_text = r.text
    soup = BeautifulSoup(r_text, 'html.parser')

    text = soup.find_all('table')[2].find_all('table')[16].find_all('tr')
    for e in text:
        content.append(e.text)
        # print(e.text)
    return content

def s():
    content = []
    headers = {
        'Host': 'www.apta.gov.cn',
        'Connection': 'keep-alive',
        'Cache-Control': 'max-age=0',
        'Upgrade-Insecure-Requests': '1',
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/93.0.4577.63 Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9',
        'Accept-Encoding': 'gzip, deflate',
        'Accept-Language': 'zh-CN,zh;q=0.9',
        'Cookie': '__jsluid_h=24f7e514f81006ed8f6a21a790689978'
    }
    r = requests.get(sxksfw, headers = headers)
    r_text = r.text
    soup = BeautifulSoup(r_text, 'html.parser')

    text = soup.find_all('table')[3].find_all('table')[0].find_all('tr')
    for e in text:
        content.append(e.text)

    return content

def h():
    content = []

    r = requests.get(hsrsks)
    r.encoding = "gb2312"
    r_text = r.text
    soup = BeautifulSoup(r_text, 'html.parser')

    text = soup.find_all('div')[7].find_all('tr')
    for e in text:
        content.append(e.text)

    return content

def hsrs():
    content = []
    r = requests.get(hsrsjtz)
    r.encoding = 'utf-8'
    r_text = r.text
    soup = BeautifulSoup(r_text, 'html.parser')
    text = soup.find_all("div", class_='navjz clearfix')[0].find_all("li")
    for e in text:
        content.append(e.text)

    return content


def main():
    print("已启动...")
    total = 0
    while True:
        sites_ = "（自动邮件，勿回复）资讯收集来自网址: \n" + str(sites.items())
        content = [
            "====安徽公务员和事业单位==== {}".format("+".join(g())),
            "====安徽市县考试服务平台==== {}".format("+".join(s())),
            "====安徽黄山市人事考试网==== {}".format("+".join(h())),
            "====黄山市人社局通知公告==== {}".format("+".join(hsrs()))
        ]
        content = [sites_ + "\n" + c for c in content]

        # 邮件设置
        subject = [sites_sub for sites_sub in sites.keys()]
        content = content
        recipients_list = ['862024320@qq.com',
                           '2506257822@qq.com'
                           ]
        # 发送邮件
        colected_sites = [gwyandsydw, sxksfw, hsrsks, hsrsjtz]
        for idx, site in enumerate(colected_sites):
            send_email.send_email("考讯（来自爬虫）-"+str(idx+1)+subject[idx], content[idx], recipients_list)

        total += 1
        print("已发送 {} 次，休眠 {} 秒".format(total, 1*24*60*60))
        time.sleep(1*24*60*60)

if __name__ == '__main__':
    main()
# g()
# s()
# h()
