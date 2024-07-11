import time
import pymysql
import traceback
from MJWcommon import *



class Database(mjwBase):
    # 初始化，连接数据库并获得操作对象
    def __init__(self, **kwargs):
#host='localhost', user='root', passwd='9213@fCOW', db="sribd_attendance", charset="utf8"
        super().__init__()
        for k, v in kwargs.items():
            setattr(self, k, v)
        self._conn()
        self.cursor = self.connection.cursor()
        # 存储的表名
#        sql=f'insert into {self.table} (camera_id) values(%s)'
#        self.insert_(sql, [-1])
#        print("heeeeeeeeeeeeeeee")


    # 判断数据库表imags2是否存在，不存在则新建
    def _conn(self, ):
#        ret = pymysql.connect(host='10.20.14.27', user='root', passwd='root', db='test', charset="utf8")
        self.connection = pymysql.connect(host=self.host, port=self.port, user=self.user, passwd=self.passwd, db=self.db, charset=self.charset)
        self.logger.info("done connection")

#    @myDecorator("thread") will cause error
    @except_wrapper
    def keep_conn(self, every_seconds=300):
        self.logger.info("start")
        while True:
            try:
                self.connection.ping()
                self.logger.info("ping sql")
            except:
                self._conn()
                self.logger.info("reconnect sql")
            time.sleep(every_seconds)


#    def get_label_data(self,):
#        sql = 'select name,img_date,result_mark from {} where result_mark <> ""'.format(self.table)
#        self.cursor.execute(sql)
#        result = self.cursor.fetchall()
#        return result

    def run_sql(self, sql, verbose=False):
        if verbose:
            self.logger.info(sql)
        self.cursor.execute(sql)
        sql_split = sql.split(" ")
        if sql_split[0].lower() == "select":
            result = self.cursor.fetchall()
            return result
        elif sql_split[0].lower() in ["create","update","insert"]:
            self.connection.commit()


    def get_data(self, sql):
        self.cursor.execute(sql)
        result = self.cursor.fetchall()
        return result


    def get_multi_data(self, date, list_keys):
        s = list_keys[0]
        for i in range(1, len(list_keys)):
            s = s+',' + list_keys[i]
        sql = 'select ' + s + ' from {} where substring(img_date,6,5)="{}"'.format(self.table,date)
        try:
            print('开始获取数据库数据')
            self.cursor.execute(sql)
            print('成功获取数据库数据')
            result = self.cursor.fetchall()
            return result
        except pymysql.Error:
            print(pymysql.Error)
            print('获取数据失败')

    # 修改聚类值,
    # key是要修改的字段名，value是修改后的字段值
    # name和img_date是数据库字段名，根据这两个字段得到要修改的记录
    # result_cluster是聚类结果值（int类型），result_mark是标记后的结果（字符串类型）
#    @dec_timer
    def update_table_one_kv(self,key,value,name,img_date):
        if type(value)==str:
            sql = 'update {} set {}="{}" where name="{}" and img_date ="{}"'.format(self.table, key, value, name,img_date)
        else:
            sql = 'update {} set {}={} where name="{}" and img_date ="{}"'.format(self.table,key,value,name,img_date)
        try:
            #print('开始修改数据库数据')
            start = time.time()
            self.cursor.execute(sql)
            print("time1: {}".format(time.time()-start))
            start = time.time()
            self.connection.commit()
            print("time2: {}".format(time.time()-start))
            #print('成功修改:记录{}，{}的字段{}聚类值为{}'.format(name,img_date,key,value))
        except pymysql.Error:
            print(pymysql.Error)
            print('修改数据失败')


    def insert_image(self, image):
        sql = "insert into {}(camera_id,img_time,name_face,name_body,img_face,img_body) values(%s,%s,%s,%s,%s,%s)".format(self.table)
        try:
            self.cursor.execute(sql, image)
            self.connection.commit()
        except pymysql.Error:
            print(pymysql.Error)

    def insert_(self, sql, data_img):
        try:
            print(f"here {sql}")
            self.cursor.execute(sql, data_img)
            self.connection.commit()
        except:
            print(traceback.format_exc())



