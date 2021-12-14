import os

def calu_plus(a, b, y_):
    process_ = [] # 记录过程
    # print(a+b)
    a = [int(i) for i in str(a)]
    b = [int(i) for i in str(b)]
    if len(a) < len(b):
        tmp_ = b
        b = a
        a = tmp_
    a.reverse()
    b.reverse()

    for i in range(len(b)):
        a[i] = a[i] + b[i]
        if y_:
            process_.append(str(a[i])+"\n")
            process_.append(str(b[i])+"\n")
            process_.append(str(a[i])+"\n")

    # 处理每个空中大于10的部分
    for i in range(len(a)):
        # 处理最后一位大于10
        if a[i] >= 10:
            a[i] = a[i] - 10
            if y_:
                process_.append(str(a[i])+"\n")
            if i == (len(a)-1):
                a += [1]
            else:
                a[i+1] += 1

    a.reverse()
    return a, process_

# print(calu_plus(99999901, 111111111111111111111111111111111111111))
print("============以手写形式计算两个整数============")
# 检查是否存在D盘
assert os.path.isdir("D:/"), "结果存于D盘，本机无D盘."

y_ = input("是否记录运算过程(y/n): ")
y_ = y_.lower()
if y_ == 'y' or y_ == "yes":
    y_ = True
else:
    y_ = False
a = input("整数a: ")
b = input("整数b: ")

res_path = "D:/tmp_res.txt"
with open(res_path, mode="w", encoding="UTF-8") as w:
    w.write(str(a))
    w.write('+')
    w.write(str(b))
    w.write('=\n')
    res_, pro_ = calu_plus(a, b, y_)
    # w.write(res_)
    for e in res_:
        w.write(str(e))

    if y_:
        w.write('\n过程：\n')
        for e in pro_:
            w.write(str(e))

print("----------->结果在{}中.".format(res_path))

