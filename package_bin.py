import os
import shutil
import argparse
import bash
import sys

application_tar_gz = "application.tar.gz"
image_qcow2 = "image.qcow2"
decompress_bin_sh = "decompress_bin.sh"
refresh_index_py = "refresh_index.py"

application_dir = "applications"
target_application_tar_gz_dir = "target/application_targz"
target_application_bins_dir = "target/application_bins"
target_application_no_image_bins_dir = "target/application_no_image_bins"
images_dir = "images"


def create_directories_if_not_exist(*dir_paths):
    for path in dir_paths:
        if not os.path.exists(path):
            os.makedirs(path)


def remove_file_if_exist(file_path):
    if os.path.exists(file_path):
        os.remove(file_path)
    

def create_app_bin(app_id, architecture, version, copy_image):
    root_path = os.getcwd()
    application_union_mark = "%s__%s__%s" % (app_id, architecture, version)
    relative_path = os.path.join(app_id, architecture, version)
    # application source path
    app_path = os.path.join(application_dir, relative_path)
    # create target dir
    app_target_targz_dir_path = os.path.join(target_application_tar_gz_dir, relative_path)
    #app_target_bins_dir_path = os.path.join(target_application_bins_dir, relative_path)
    #app_target_no_images_bins_dir_path = os.path.join(target_application_no_image_bins_dir, relative_path)
    app_tmp_work_path = os.path.join("tmp", application_union_mark)
    app_image_dir_path = os.path.join(images_dir, relative_path)

    create_directories_if_not_exist(
        target_application_bins_dir,
        target_application_no_image_bins_dir,
        app_target_targz_dir_path,
        app_image_dir_path,
        app_tmp_work_path
    )

    app_image_path = os.path.join(app_image_dir_path, image_qcow2)
    if copy_image and not os.path.exists(app_image_path):
        print("image not exist, appid %s, architecture %s, version %s" % (app_id, architecture, version))
        exit(1)

    # compress application to application/{app_id}/{arch}/{version}/application.tar.gz
    # copy it to tmp/{app_id}__{arch}__{version}/application.tar.gz
    # move it to target/application_targz/{app_id}/{arch}/{version}/application.tar.gz
    compress_command = "tar -czvf %s *" % application_tar_gz
    r, _, e, = bash.bash_roe(compress_command, workdir=app_path)
    if r != 0:
        print("fail to compress application, appid %s, architecture %s, version %s, error: %s" % (
            app_id, architecture, version, e))
        exit(1)
    target_targz_file_path = os.path.join(app_target_targz_dir_path, application_tar_gz)
    remove_file_if_exist(target_targz_file_path)

    shutil.copy(os.path.join(app_path, application_tar_gz), app_tmp_work_path)
    shutil.move(os.path.join(app_path, application_tar_gz), target_targz_file_path)

    # tmp/{app_id}__{arch}__{version}/info
    file_path = os.path.join(app_tmp_work_path, "info")
    with open(file_path, "w") as file:
        file.write("APP_ID={}\n".format(app_id))
        file.write("ARCH={}\n".format(architecture))
        file.write("VERSION={}\n".format(version))
        
    # refresh_index.py -> tmp/{app_id}__{arch}__{version}/refresh_index.py
    shutil.copy(refresh_index_py, app_tmp_work_path)

    # images/{app_id}/{arch}/{version}/image.qcow2
    # ->
    # tmp/{app_id}__{arch}__{version}/image.qcow2
    if copy_image:
        shutil.copy(app_image_dir_path, app_tmp_work_path)
        bin_name = "%s.bin" % application_union_mark
        bin_target_path = "%s/%s" % (target_application_bins_dir, bin_name)
    else:
        bin_name = "%s__no_images.bin" % application_union_mark
        bin_target_path = "%s/%s" % (target_application_no_image_bins_dir, bin_name)

    # tmp/{app_id}__{arch}__{version}/* 
    # -> 
    # tmp/{app_id}__{arch}__{version}/{app_id}__{arch}__{version}.bin
    bin_targz_name = "%s.tar.gz" % application_union_mark
    tmp_bin_path = os.path.join(app_tmp_work_path, bin_name)
    compress_command = "tar -czvf %s *" % bin_targz_name
    r, _, e, = bash.bash_roe(compress_command, workdir=app_tmp_work_path)
    if r != 0:
        print("fail to compress application bin, appid %s, architecture %s, version %s, error: %s" % (
            app_id, architecture, version, e))
        exit(1)
    r, _, e = bash.bash_roe("cat %s/%s %s > %s" % (root_path, decompress_bin_sh, bin_targz_name, bin_name),
                            workdir=app_tmp_work_path)
    if r != 0:
        print("fail to create application bin file, err: %s" % e)
        exit(1)

    # tmp/{app_id}__{arch}__{version}/{app_id}__{arch}__{version}.bin ->
    # target/application_bins/{app_id}__{arch}__{version}.bin
    # or
    # target/application_no_images_bins/{app_id}__{arch}__{version}.bin
    remove_file_if_exist(bin_target_path)
    print("create application bin: %s" % bin_target_path)
    shutil.move(tmp_bin_path, bin_target_path)
    shutil.rmtree(app_tmp_work_path)


def create_all_app_bins(copy_image=False):
    for app_id in os.listdir(application_dir):
        app_path = os.path.join(application_dir, app_id)
        if not os.path.isdir(app_path):
            continue
        if app_id == "test":
            continue
        for arch in os.listdir(app_path):
            if arch not in ["x86_64", "aarch64"]:
                continue
            arch_path = os.path.join(app_path, arch)
            for version in os.listdir(arch_path):
                create_app_bin(app_id, arch, version, copy_image)

    if copy_image:
        return target_application_bins_dir
    else:
        return target_application_no_image_bins_dir


def main():
    parser = argparse.ArgumentParser(description='Process some parameters.')

    parser.add_argument('--all', action='store_true', help='Process all applications')
    parser.add_argument('--app_id', type=str, help='Application ID')
    parser.add_argument('--version', type=str, help='Version')
    parser.add_argument('--arch', type=str, help='Architecture')
    parser.add_argument('--copy_images', action='store_true', help='Include images')

    args = parser.parse_args()

    # Check if --app_id, --version, --arch are set together
    if not args.all:
        if not all([args.app_id, args.version, args.arch]):
            print("Error: When not using --all, --app_id, --version, and --arch must all be provided.")
            parser.print_help()
            sys.exit(1)
        create_app_bin(args.app_id, args.arch, args.version, args.copy_images)
    else:
        create_all_app_bins(args.copy_images)


if __name__ == "__main__":
    main()
