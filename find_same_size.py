import os
import shutil
from collections import defaultdict
import hashlib
import argparse


parser = argparse.ArgumentParser(description='这是一个示例程序。')

parser.add_argument('--remove', action='store_true', help='是否显示详细输出')
parser.add_argument('--danger', action='store_true', help='是否显示详细输出')

args = parser.parse_args()

def get_file_hash(filename, block_size=65536):
    hash = hashlib.sha256()
    with open(filename, 'rb') as f:
        for block in iter(lambda: f.read(block_size), b''):
            hash.update(block)
    return hash.hexdigest()


large_ls = [(0, 0)] * 4
def find_files_with_same_size(directory):
    # 创建一个字典，键是文件大小，值是具有相同大小的文件列表
    size_to_files = defaultdict(list)
    
    # 遍历目录中的所有文件
    for root, dirs, files in os.walk(directory):
        print(root)
        tmp = len(dirs)+len(files)
        if tmp == 0:
            shutil.rmtree(root)
            print(f"{root} removed")
        for filename in files:
            filepath = os.path.join(root, filename)
            if args.danger and filename.split(".")[-1] in ["html", "apk", "mht", "chm", "htm", "DS_Store", "url", "ini", "txt", "exe", "log", "js", "torrent"]:
                # os.remove(filepath)
                print(f"{filepath} removed")
                continue
            try:
                # 获取文件大小
                size = None
                if filepath.split(".")[-1] in ["jpg", "png", "JPG", "pdf", "txt", "doc", "docx", "md", "ppt", "pptx"]:
                    size = get_file_hash(filepath)
                    # if filepath == r'F:\LenovoSoftstore\src\1 - 副本 (23)\1 - 副本 (23)\XNJPBO\BHDP.TUMBLR.COM (1).jpg':
                    # if filepath == r'F:\LenovoSoftstore\src\XNJPBO\BHDP.TUMBLR.COM (1).jpg':
                    #     print(size)
                    #     exit()
                else:
                    size = os.path.getsize(filepath)
                    if size > large_ls[-1][-1]:
                        large_ls[-1] = (filepath, size)
                        large_ls.sort(key=lambda x: x[-1], reverse=True)
                    pass
                    
                # 将文件路径添加到对应大小的列表中
                if size:
                    size_to_files[size].append(filepath)
            except OSError as e:
                print(f"Error: {e}")
                continue
    
    # 找出具有相同大小的文件对
    same_size_files = []
    for size, files in size_to_files.items():
        if len(files) > 1:
            same_size_files.append((size, files))
    
    return same_size_files



if __name__ == "__main__":

    inp_path = r"C:\BaiduSyncdisk\mydrive"

    files_with_same_size = find_files_with_same_size(inp_path)

    print("start output same -------------\n\n\n\n\n")
    for size, files in files_with_same_size:
        if size == 0:
            for ele in files:
                os.remove(ele)
                print(f"0 size {ele} removed")
            continue

        print(f"\nFiles with size {size} bytes:")
        count = True
        for file in files:
            if args.remove:
                if count:
                    print(f"{file} saved")
                    count = False
                    continue
                os.remove(file)
                print(f"  {file} removed")
            # else:
            #     if file.split(".")[-1] == "downloading":
            #         os.remove(file)
            #         print(f"{file} removed")
            #     else:
            #         print(f"  {file}")
            print(file)
    print(f"large files: {large_ls}")
