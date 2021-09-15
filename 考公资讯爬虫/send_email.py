import zmail


def send_email(subject, content_text, recipients_list):

    # set server email info
    ads = "862024320@qq.com"
    pwd = "bomtxjlgznnnbdaj"
    server = zmail.server(ads, pwd)


    content = {
        'subject': subject,  # Anything you want.
        'content_text': content_text,  # Anything you want.
        # 'attachments': ['/Users/zyh/Documents/example.zip','/root/1.jpg'],  # Absolute path will be better.
    }


    server.send_mail(recipients_list, content)

# send_email("更新！", "黄山市公考报名系统", ['862024320@qq.com'])

# '805901483@qq.com',
# '527374388@qq.com'