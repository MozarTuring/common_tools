import time
import os
import json
import multiprocessing
from datetime import datetime
from functools import wraps
import traceback
import logging
import sys



# import logging
# logging.basicConfig(level=logging.INFO,
#                     format='%(asctime)s - %(pathname)s\nLINE%(lineno)d - \n%(message)s\nMSG-END',
#                     datefmt='%Y-%m-%d %H:%M:%S')
# jwprint = logging.info
# 这种设置会导致其它所有使用了logging的地方都变成这里设定的格式，而不只是使用 jwprint 的地方


jwPlatform = os.getenv("jwPlatform")
logger = logging.getLogger("my_logger")
logger.setLevel(logging.INFO)

console_handler = logging.StreamHandler(sys.stdout)
console_handler.setLevel(logging.INFO)
logger.addHandler(console_handler)

jwprint=logger.info

jw_cur_dir = os.getenv("jw_cur_dir")
def jwcl():
    cur_time = datetime.now().strftime("%Y%m%d_%H%M%S")
    jwoutput = os.path.join(jw_cur_dir, f"jwo{jwPlatform}/{cur_time}")
    os.environ["jwo"] = jwoutput
    print(jwoutput)
    os.makedirs(jwoutput)
    logPath = os.path.join(jwoutput, f"log.txt")
    formatter = logging.Formatter('LINE%(lineno)d - %(asctime)s - %(pathname)s\n%(message)s\nMSG-END', datefmt='%Y-%m-%d %H:%M:%S')
    logger = logging.getLogger("my_logger")
    for ele in logger.handlers:
        logger.removeHandler(ele)
    file_handler = logging.FileHandler(logPath, mode="a")
    file_handler.setFormatter(formatter)
    file_handler.setLevel(logging.INFO)
    logger.addHandler(file_handler)
    console_handler = logging.StreamHandler(sys.stdout)
    formatter = logging.Formatter('%(message)s\nMSG-END #'+jwoutput, datefmt='%Y-%m-%d %H:%M:%S')
    console_handler.setFormatter(formatter)
    console_handler.setLevel(logging.INFO)
    logger.addHandler(console_handler)
    jwprint("start")



week_day_ch = ["一", "二", "三", "四", "五", "六", "日"]




def timer_wrapper(inp_func):
    @wraps(inp_func)
    def decorated(*args, **kwargs):
        tmp = time.time()
        inp_func(*args, **kwargs)
        jwprint(time.time() - tmp)
    return decorated



def except_wrapper(inp_func):
    @wraps(inp_func)
    def decorated(*args, **kwargs):
        try:
            inp_func(*args, **kwargs)
        except:
            jwprint(traceback.format_exc())
    return decorated




def getDay(shift):
    cur_day=datetime.date.today()
    oneday=datetime.timedelta(days=1)
    return cur_day+shift*oneday


def date2str(inp_date, inp_format="%H%M%S"):
    # length could be different
    return inp_date.strftime(inp_format)

def str2date(inp_str="2010/08/09", inp_format="%Y/%m/%d"):
    # must be same length
    return datetime.strptime(inp_str, inp_format)


def getTime(inp_format, shift):
    return time.strftime(inp_format, time.localtime(time.time())+shift)

def quick2json(inp_path, inp_data):
    with open(inp_path, "w", encoding="utf8") as wf:
        wf.write(json.dumps(inp_data, ensure_ascii=False, indent=2))



def start_mp(targets, args_ls):
    p_list = list()
    for tar, ar in zip(targets, args_ls):
        p_list.append(multiprocessing.Process(target=tar, args=ar))
        p_list[-1].start()

    for ele in p_list:
        ele.join() ## 不加这个 按 ctrl c 杀不死
