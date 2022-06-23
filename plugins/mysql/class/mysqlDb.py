# coding: utf-8

import re
import os
import sys

# sys.path.append("/usr/local/lib/python3.9/site-packages")

sys.path.append(os.getcwd() + "/class/core")
import mw

# if mw.isAppleSystem():
#     cmd = 'ls /usr/local/lib/ | grep python  | cut -d \\  -f 1 | awk \'END {print}\''
#     info = mw.execShell(cmd)
#     p = "/usr/local/lib/" + info[0].strip() + "/site-packages"
#     sys.path.append(p)


class mysqlDb:
    __DB_PASS = None
    __DB_USER = 'root'
    __DB_PORT = 3306
    __DB_HOST = 'localhost'
    __DB_CONN = None
    __DB_CUR = None
    __DB_ERR = None
    __DB_CNF = '/etc/my.cnf'

    def __Conn(self):
        '''连接MYSQL数据库'''
        try:
            import mw
            socket = '/www/server/mysql/mysql.sock'
            try:
                import MySQLdb
            except Exception as ex:
                # print('dd')
                self.__DB_ERR = ex
                return False
            try:
                myconf = mw.readFile(self.__DB_CNF)
                rep = "port\s*=\s*([0-9]+)"
                self.__DB_PORT = int(re.search(rep, myconf).groups()[0])
            except:
                self.__DB_PORT = 3306
            # print self.__DB_PASS
            #self.__DB_PASS = mw.M('config').where('id=?', (1,)).getField('mysql_root')
            try:
                self.__DB_CONN = MySQLdb.connect(host=self.__DB_HOST, user=self.__DB_USER, passwd=self.__DB_PASS,
                                                 port=self.__DB_PORT, charset="utf8", connect_timeout=1, unix_socket=socket)
            except MySQLdb.Error as e:
                self.__DB_HOST = '127.0.0.1'
                self.__DB_CONN = MySQLdb.connect(host=self.__DB_HOST, user=self.__DB_USER, passwd=self.__DB_PASS,
                                                 port=self.__DB_PORT, charset="utf8", connect_timeout=1, unix_socket=socket)
            self.__DB_CUR = self.__DB_CONN.cursor()
            return True
        except MySQLdb.Error as e:
            self.__DB_ERR = e
            return False

    def setDbConf(self, conf):
        self.__DB_CNF = conf

    def setPwd(self, pwd):
        self.__DB_PASS = pwd

    def getPwd(self):
        return self.__DB_PASS

    def execute(self, sql):
        # 执行SQL语句返回受影响行
        if not self.__Conn():
            return self.__DB_ERR
        try:
            result = self.__DB_CUR.execute(sql)
            self.__DB_CONN.commit()
            self.__Close()
            return result
        except Exception as ex:
            return ex

    def query(self, sql):
        # 执行SQL语句返回数据集
        if not self.__Conn():
            return self.__DB_ERR
        try:
            self.__DB_CUR.execute(sql)
            result = self.__DB_CUR.fetchall()
            # 将元组转换成列表
            # data = list(map(list, result))
            self.__Close()
            return result
        except Exception as ex:
            return ex

    # 关闭连接
    def __Close(self):
        self.__DB_CUR.close()
        self.__DB_CONN.close()
