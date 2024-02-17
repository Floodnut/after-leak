import os

def get_template_files(root):
    all_files = []

    for path, subdirs, files in os.walk(root):
        for name in files:
            all_files.append(os.path.join(path, name).replace("\\", "/").replace(root, ""))

    return(all_files)

def replace_keyvalues(file_content, keyvalues):
    for keyvalue in keyvalues:
        file_content = file_content.replace("${}$".format(keyvalue.get("key")), format(keyvalue.get("value")))
    
    return file_content
