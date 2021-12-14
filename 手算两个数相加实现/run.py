def calu_plus(a, b):
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

    # 处理每个空中大于10的部分
    for i in range(len(a)):
        # 处理最后一位大于10
        if a[i] >= 10:
            a[i] = a[i] - 10
            if i == (len(a)-1):
                a += [1]
            else:
                a[i+1] += 1

    a.reverse()
    return a

print(calu_plus(99999901, 111111111111111111111111111111111111111))