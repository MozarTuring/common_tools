import os
import shutil

# for root, dirs, files in os.walk("camera1"):
#     # print(root, dirs, files)
#     for ele in dirs:
#         print(ele)
#         for subele in os.listdir(os.path.join(root, ele)):
#             print(subele)
#             # if subele == "frame.jpg":
#             #     shutil.move(os.path.join(root, ele, subele), os.path.join("frame", ele+".jpg"))
#             # if "frameFace" in subele:
#             #     shutil.move(os.path.join(root, ele, subele), os.path.join("frameFace", ele+subele))
#             # if "_face" in subele:
#             #     shutil.move(os.path.join(root, ele, subele), os.path.join("bodyFace", ele+subele))
#             if "body" in subele:
#                 shutil.move(os.path.join(root, ele, subele), os.path.join("body", ele+subele))


for root, dirs, files in os.walk("camera1_faceOnly"):
    # print(root, dirs, files)
    for ele in dirs:
        print(ele)
        if "Face1" not in "".join(os.listdir(os.path.join(root, ele))):
            shutil.move(os.path.join(root, ele, "frame_ori.jpeg"), os.path.join("camera1_faceOnly_bak", ele+"frame_ori.jpeg"))
        os.system("rm -rf {}".format(os.path.join(root, ele)))
        # break
    break