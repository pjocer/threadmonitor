import os
import re

# 当前路径
current_directory = os.getcwd()
# 定义排除列表文件（每行一个目录）
exclude_list_path = os.path.join(current_directory, "exclude_paths.txt") 
# 非正常匹配的文件列表（需要手动更改）
unexpected_path = os.path.join(current_directory, "unexpected_paths.txt") 

# 检查排除列表文件是否存在，如果不存在则创建它
if not os.path.exists(exclude_list_path):
    # 如果文件不存在，创建一个空的排除列表文件
    open(exclude_list_path, "w").close()

# 读取排除列表并存入一个集合
with open(exclude_list_path, "r") as f:
    exclude_set = set([line.strip() for line in f])

# 在当前目录及其子目录中查找所有PNG文件，排除在排除列表中的目录
exceptFileList = []
for root, dirs, files in os.walk(current_directory, topdown=True):
    # 从搜索中移除排除的目录
    dirs[:] = [d for d in dirs if os.path.join(root, d) not in exclude_set]

    for filename in files:
        if not filename.endswith(".png"):
            continue
        # 检查父目录是否在排除列表中
        if os.path.basename(root) in exclude_set:
            continue # 如果目录在排除列表中，则跳过此文件
        
        fPath = os.path.join(root, filename)
        skip = False
        for line in exclude_set:
            if line in fPath:
                skip = True
                break;
        # print("!!!skip path:" + fPath)
        if "xcasset" not in fPath:
            skip = True
        if skip :
            continue
        

        # 获取父目录的名称并移除 .xcasset 后缀
        parent = os.path.basename(root).replace(".imageset", "")

        # 使用正则表达式提取PNG文件的前缀（不包括 @2x/@3x 后缀）
        match = re.match(r"^(.+)/([^/@]+)@[0-9]+x\.png$", filename)
        if match:
            prefix = match.group(2)
        else:
            prefix = os.path.splitext(filename)[0]

        # 从前缀中移除 @2x/@3x 后缀（如果存在）
        # prefix = prefix.replace("@2x", "").replace("@3x", "")
    
        prefix2x = parent + "@2x"
        prefix3x = parent + "@3x"
        # 比较PNG文件的前缀与父目录的名称
        if prefix != prefix2x and prefix != prefix3x and prefix != parent:
            # 使用正确的前缀生成新文件名
            new_filename = ""
            newPrefix = ""
            if "@2x" in prefix:
                newPrefix = prefix2x
                new_filename = os.path.join(root, prefix2x + ".png")
            if "@3x" in prefix:
                newPrefix = prefix3x
                new_filename = os.path.join(root, prefix3x + ".png")
            if newPrefix == "" :
                # exceptFileList.append(os.path.join(root, filename))
                # 将绝对路径改为相对路径
                exceptFileList.append(os.path.relpath(os.path.join(root, filename), current_directory))  
                break
            # 重命名文件
            os.rename(os.path.join(root, filename), new_filename)
            print(f"已重命名\n{os.path.join(root, filename)}\n{new_filename}")
            contentJsonPath = os.path.join(root, "Contents.json")
            retLines = []
            with open(contentJsonPath, 'r') as contentJson:
                lines = contentJson.readlines()
            for line in lines:
                if prefix in line:
                    # print(line)
                    # print(newPrefix)
                    retLines.append(line.replace(prefix, newPrefix))
                else :
                    retLines.append(line)
            with open(contentJsonPath, 'w') as contentJson:
                contentJson.writelines(retLines)

# 检查需要手动修改的文件是否存在，如果不存在则创建它
if not os.path.exists(unexpected_path):
    # 如果文件不存在，创建一个空的排除列表文件
    open(unexpected_path, "w").close()

# 写入
with open(unexpected_path, "w") as f:
    for file in exceptFileList:
        f.write(file + "\n")
        print("例外文件，请手动修改这些文件: "+ file)


