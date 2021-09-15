import zmail


def send_email(subject, content_text, recipients_list):

    # set server email info
    ads = "xxx@qq.com"
    pwd = "xxx"
    server = zmail.server(ads, pwd)


    content = {
        'subject': subject,  # Anything you want.
        'content_text': content_text,  # Anything you want.
        # 'attachments': ['/Users/zyh/Documents/example.zip','/root/1.jpg'],  # Absolute path will be better.
    }


    server.send_mail(recipients_list, content)

