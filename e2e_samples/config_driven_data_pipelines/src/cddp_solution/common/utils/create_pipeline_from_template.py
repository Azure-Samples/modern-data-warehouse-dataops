import glob
import os
import ntpath
from jinja2 import Environment
from jinja2.loaders import FileSystemLoader
import shutil
import sys

template_name = sys.argv[1]
app_name = sys.argv[2]
customer_name = sys.argv[3]
app_path =  sys.argv[4]

template_folder = './src/cddp_solution/app_template'

if __name__ == "__main__":
    # create application
    env = Environment(loader=FileSystemLoader(f"{template_folder}/{template_name}/"))
    app_folder=f'{app_path}/{app_name}/'
    if not os.path.exists(app_folder):
        os.makedirs(app_folder)
        
    for name in glob.glob(f'{template_folder}/{template_name}/**'):
        tmpl = env.get_template(ntpath.basename(name))
        fn = app_folder+ntpath.basename(name)
        print(fn)
        with open(fn, 'w') as f:
            f.write(tmpl.render(app_name=app_name))

    # create customer
    env = Environment(loader=FileSystemLoader(f"{template_folder}/{template_name}_customers/customer_1/"))
    app_customer_folder=f'{app_path}/{app_name}_customers/{customer_name}/'
    if not os.path.exists(app_customer_folder):
        os.makedirs(app_customer_folder)
        
    for name in glob.glob(f'{template_folder}/{template_name}_customers/customer_1/*.*'):
        tmpl = env.get_template(ntpath.basename(name))
        fn = app_customer_folder+ntpath.basename(name)
        print(fn)
        with open(fn, 'w') as f:
            f.write(tmpl.render(app_name=app_name,customer_name=customer_name))


    # create sample data
    source_folder =f"{template_folder}/{template_name}_customers/customer_1/raw_data/"
    if os.path.exists(source_folder):
        destination_folder = f"{app_customer_folder}raw_data/"
        if not os.path.exists(destination_folder):
            shutil.copytree(source_folder, destination_folder, symlinks=False, ignore=None, ignore_dangling_symlinks=False, dirs_exist_ok=False)

    print(f"Application {app_name} and Customer {customer_name} created")
