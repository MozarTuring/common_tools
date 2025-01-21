import sys
import time
import os

def jwcopy_file_content(src_file_path, dest_file_path, th=50):

    with open(src_file_path, 'r') as src_file:
        lines = src_file.readlines()
        line_count = len(lines)

    with open(dest_file_path, 'a') as dest_file:
        out = ['[O]']
        if line_count < th:
            out.extend(lines)
            os.remove(src_file_path)
        else:
            with open(src_file_path, 'a') as src_file:
                src_file.write('\n[OUTEND]')

            out.append(src_file_path)#+f'  [OUTEND@{cur_time}]')
        out.append('\n')
        dest_file.writelines(out)
