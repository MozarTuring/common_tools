from mjw_common_utils_mjw import *

db_obj = Database(host='120.79.52.236', port=31004, user='maojingwei', passwd='9213@fCOW', db="sribd_attendance", charset="utf8")

sql = "select name_face, name_body, img_time, img_url from sribd_attendance where camera_id=0 and p_fall is NULL order by img_time desc limit 5;"

raw_data = db_obj.run_sql(sql)

for ele in raw_data:
    print(ele)
