import json
import time

def insert():
    student_list = []
    while True:
        id = input("请输入id（如1001）：")
        if not id:
            break
        name = input("请输入姓名：")
        if not name:
            break
        try:
            english = int(input("请输入英语成绩（整数）："))
            python = int(input("请输入python成绩（整数）："))
            java = int(input("请输入Java成绩（整数）："))
        except:
            print("异常，请输入整数型成绩")
            continue
        # 将学生成绩放入字典中：
        student = {"id": id, "name": name, "english": english, "python": python, "java": java}
        student_list.append(student)

        answer = input("是否继续添加y/n:")
        if answer in ['y', 'Y']:
            continue
        else:
            enterContinue()
            break
    save(student_list)
    print("本次成绩录入完毕")
    enterContinue()
    time.sleep(1)

def save(s):
    try:
        file = open("./student.txt", mode='a', encoding='utf-8')
    except:
        # 如果文件不存在，以新建方式写入
        file = open("student.txt", mode='w', encoding='utf-8')

    for item in s:
        file.write(str(item)+'\n')
    file.close()

def search():
    while True:
        id = input("请输入需要查找的学生id：")
        try:
            with open("./student.txt", mode="r", encoding='utf-8') as f:
                lines = f.readlines()
                selected_student = []
                # flag用来判断是否有此id
                flag = True
                for e in lines:
                    tmp = dict(eval(e))
                    tmp_e = e
                    if id == tmp['id']:
                        flag = False
                        break
                if flag:
                    print("此学生id不存在。")
                else:
                    selected_student.append(tmp_e)
                    showStudentInfo(selected_student)
        except e:
            print("学生成绩文件不存在，请先录入信息。{}".format(e))
            break
        answer = input("是否继续查询 y/n：")
        if answer in ['y', 'Y']:
            continue
        else:
            enterContinue()
            break
    pass


def delete():
    while True:
        print("请输入要删除的学生id：")
        id = input("id：")
        try:
            with open("./student.txt", mode="r", encoding='utf-8') as f:
                lines = f.readlines()
                deleted_lines = []
                # flag用来判断是否有此id
                flag = True
                for e in lines:
                    tmp = dict(eval(e))
                    if id == tmp['id']:
                        flag = False
                        continue
                    deleted_lines.append(tmp)
                if flag:
                    print("此学生id不存在。")
                else:
                    with open("./student.txt", mode="w", encoding='utf-8') as f:
                        pass
                    save(deleted_lines)
                    print("学生id为 ：{}，已删除".format(id))
        except:
            print("学生成绩文件不存在，请先录入信息。")
            break
        answer = input("是否继续删除 y/n：")
        if answer in ['y', 'Y']:
            continue
        else:
            enterContinue()
            break

    pass

def modify():

    while True:
        print("请输入要修改的学生id：")
        id = input("id：")
        old_s_info_str = ""
        new_s_info_str = ""
        try:
            with open("./student.txt", mode="r", encoding='utf-8') as f:
                lines = f.readlines()
                modified_lines = []
                # flag用来判断是否有此id
                flag = True
                for e in lines:
                    tmp = dict(eval(e))
                    if id == tmp['id']:
                        old_s_info_str = e
                        name = input("请输入要修改的姓名（回车不修改）：")
                        english = input("请输入要修改的英语成绩（回车不修改）：")
                        python = input("请输入要修改的python成绩（回车不修改）：")
                        java = input("请输入要修改的java成绩（回车不修改）：")
                        if name != '':
                            tmp['name'] = name
                        if english != '':
                            tmp['english'] = english
                        if python != '':
                            tmp['python'] = python
                        if java != '':
                            tmp['java'] = java
                        flag = False
                        new_s_info_str = str(tmp)
                    modified_lines.append(tmp)
                if flag:
                    print("此学生id不存在。")
                else:
                    with open("./student.txt", mode="w", encoding='utf-8') as f:
                        pass
                    save(modified_lines)
                    print("学生id为 ：{}，已修改,上下分别为修改前后信息".format(id))
                    compare_infos = []
                    compare_infos.append(old_s_info_str)
                    compare_infos.append(new_s_info_str)
                    showStudentInfo(compare_infos)
                    enterContinue()
        except:
            print("学生成绩文件不存在，请先录入信息。")
            break
        answer = input("是否继续修改 y/n：")
        if answer in ['y', 'Y']:
            continue
        else:
            enterContinue()
            break

    pass

def stuSort():
    while True:
        try:
            with open("./student.txt", mode='r', encoding='utf-8') as f:
                lines = f.readlines()
                lines = [dict(eval(i)) for i in lines]
                print(lines)
                sort_id = input("输入1，2，3分别根据英语，python，java成绩排序。")
                if sort_id == '1':
                    lines = sorted(lines, key=lambda x: x['english'])
                elif sort_id == '2':
                    lines = sorted(lines, key=lambda x: x['python'])
                    pass
                elif sort_id == '3':
                    lines = sorted(lines, key=lambda x: x['java'])
                    pass
                else:
                    print("请输入正确。")
                    break

                lines = [str(i) for i in lines]
                showStudentInfo(lines)
                break
        except Exception as e:
            print("无学生成绩文件，请先录入一些信息。{}".format(e))
            break
    enterContinue()
    pass

def total():
    total = 0
    try:
        with open("./student.txt", mode='r', encoding='utf-8') as f:
            lines = f.readlines()
            total = len(lines)

    except:
        print("无学生成绩文件，请先录入一些信息。")

    print("共有 {} 条记录。".format(total))
    enterContinue()
    pass

def show():

    print("以下是学生成绩文件中的所有学生信息：")
    try:
        with open("./student.txt", mode='r', encoding='utf-8') as f:
            lines = f.readlines()
            showStudentInfo(lines)
    except:
        print("无学生成绩文件，请先录入一些信息。")
    enterContinue()
    pass

def showStudentInfo(lines):
    print("{:^8}\t{:^8}\t{:^8}\t{:^8}\t{:^8}".format("id", "姓名", "英语成绩", "python成绩", "java成绩"))
    for e in lines:
        dict_e = dict(eval(e))
        print("{:^10}\t{:^10}\t{:^10}\t{:^10}\t{:^10}".format(dict_e['id'], dict_e['name'], dict_e['english'],
                                                              dict_e['python'], dict_e['java']))

def enterContinue():
    input("按回车继续...")

def main():

    while True:
        menum()
        choice = int(input("请选择："))

        if choice in [0, 1, 2, 3, 4, 5, 6, 7]:
            if choice == 0:
                print("您确认要退出系统吗? y/n")
                answer = input("y/n：")
                if answer in ['y', 'Y']:
                    print("欢迎下次使用")
                    break
                else:
                    continue
            elif choice == 1:
                insert()
            elif choice == 2:
                search()
            elif choice == 3:
                delete()
            elif choice == 4:
                modify()
            elif choice == 5:
                stuSort()
            elif choice == 6:
                total()
            elif choice == 7:
                show()


def menum():
    print("========================================")
    print("\t\t\t\t\t\t学生信息管理系统")
    print("\t\t\t\t\t\t功能菜单")
    print("\t\t\t\t\t\t1.录入学生信息")
    print("\t\t\t\t\t\t2.查找学生信息")
    print("\t\t\t\t\t\t3.删除学生信息")
    print("\t\t\t\t\t\t4.修改学生信息")
    print("\t\t\t\t\t\t5.根据成绩排序")
    print("\t\t\t\t\t\t6.统计学生人数")
    print("\t\t\t\t\t\t7.显示所有学生")
    print("\t\t\t\t\t\t0.退出系统")
    print("========================================")

if __name__ == '__main__':
    main()

