from datetime import datetime
import os

def jwcopy_file_content(src_file_path, dest_file_path, th=50):
    cur_time = datetime.now().strftime("%Y%m%d_%H%M%S")
    with open(src_file_path, 'a') as wf:
        wf.write(f'\n[OUTEND@{cur_time}]')

    with open(src_file_path, 'r') as src_file:
        lines = src_file.readlines()
        line_count = len(lines)

    with open(dest_file_path, 'a') as dest_file:
        out = ['\n']
        if line_count < th:
            out.extend(lines)
            os.remove(src_file_path)
        else:
            out.append(src_file_path)#+f'  [OUTEND@{cur_time}]')
        out.append('\n')
        dest_file.writelines(out)


