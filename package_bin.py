import os
import shutil
import argparse
import bash
import sys

application_tar_gz = "application.tar.gz"
image_qcow2 = "image.qcow2"
decompress_bin_sh = "decompress_bin.sh"

application_dir = "applications"
application_tar_gz_dir = "target/application_targz"
application_bins_dir = "target/application_bins"
application_no_image_bins_dir = "target/application_no_image_bins"
images_dir = "images"


def create_app_bin(app_id, architecture, version, copy_image):
    root_path = os.getcwd()
    application_union_mark = "%s__%s__%s" % (app_id, architecture, version)
    relative_path = os.path.join(app_id, architecture, version)

    app_path = os.path.join(application_dir, relative_path)

    image_path = os.path.join(images_dir, relative_path, image_qcow2)
    if not os.path.exists(os.path.join(images_dir, relative_path)):
        os.makedirs(os.path.join(images_dir, relative_path))

    # check image exist if needed
    if copy_image and not os.path.exists(image_path):
        print("image not exist, appid %s, architecture %s, version %s" % (app_id, architecture, version))
        exit(1)

    targz_path = os.path.join(application_tar_gz_dir, relative_path, application_tar_gz)
    if not os.path.exists(os.path.join(images_dir, relative_path)):
        os.makedirs(os.path.join(application_tar_gz_dir, relative_path))

    app_tmp_work_path = os.path.join("tmp", application_union_mark)
    if not os.path.exists(app_tmp_work_path):
        os.makedirs(app_tmp_work_path)

    # compress application to application/{app_id}/{arch}/{version}/application.tar.gz
    # copy it to tmp/{app_id}__{arch}__{version}/application.tar.gz
    # move it to target/application_targz/{app_id}/{arch}/{version}/application.tar.gz
    compress_command = "tar -czvf %s *" % application_tar_gz
    r, _, e, = bash.bash_roe(compress_command, workdir=app_path)
    if r != 0:
        print("fail to compress application, appid %s, architecture %s, version %s, error: %s" % (
            app_id, architecture, version, e))
        exit(1)
    if os.path.exists(targz_path):
        os.remove(targz_path)

    shutil.copy(os.path.join(app_path, application_tar_gz), app_tmp_work_path)
    shutil.move(os.path.join(app_path, application_tar_gz), targz_path)

    # tmp/{app_id}__{arch}__{version}/info
    file_path = os.path.join(app_tmp_work_path, "info")
    with open(file_path, "w") as file:
        file.write("APP_ID={}\n".format(app_id))
        file.write("ARCH={}\n".format(architecture))
        file.write("VERSION={}\n".format(version))

    # images/{app_id}/{arch}/{version}/image.qcow2
    # ->
    # tmp/{app_id}__{arch}__{version}/image.qcow2
    if copy_image:
        if not os.path.exists(application_bins_dir):
            os.makedirs(application_bins_dir)
        shutil.copy(image_path, app_tmp_work_path)
        bin_name = "%s.bin" % application_union_mark
        bin_target_path = "%s/%s" % (application_bins_dir, bin_name)
    else:
        if not os.path.exists(application_no_image_bins_dir):
            os.makedirs(application_no_image_bins_dir)
        bin_name = "%s__no_images.bin" % application_union_mark
        bin_target_path = "%s/%s" % (application_no_image_bins_dir, bin_name)

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
    if os.path.exists(bin_target_path):
        os.remove(bin_target_path)
    shutil.move(tmp_bin_path, bin_target_path)
    shutil.rmtree(app_tmp_work_path)


def create_all_app_bins(copy_image=False):
    for app_id in os.listdir(application_dir):
        app_path = os.path.join(application_dir, app_id)
        if not os.path.isdir(app_path):
            continue
        for arch in os.listdir(app_path):
            if arch not in ["x86_64", "aarch64"]:
                continue
            arch_path = os.path.join(app_path, arch)
            for version in os.listdir(arch_path):
                create_app_bin(app_id, arch, version, copy_image)

    if copy_image:
        return application_bins_dir
    else:
        return application_no_image_bins_dir


def main():
    parser = argparse.ArgumentParser(description='Process some parameters.')
    group = parser.add_mutually_exclusive_group(required=True)

    # Add --app_id, --version, --arch arguments
    app_group = group.add_argument_group('Application Information')
    app_group.add_argument('--app_id', type=str, help='Application ID')
    app_group.add_argument('--version', type=str, help='Version')
    app_group.add_argument('--arch', type=str, help='Architecture')

    # Add --all argument
    group.add_argument('--all', action='store_true', help='Process all applications')

    # Add --include_images argument
    parser.add_argument('--copy_images', type=bool, default=False, help='Include images')

    args = parser.parse_args()

    # Check if --app_id, --version, --arch are set together
    if not args.all:
        if not (args.app_id and args.version and args.arch):
            print("Error: --app_id, --version, --arch parameters must be set together")
            parser.print_help()
            sys.exit(1)

        create_app_bin(args.app_id, args.version, args.arch, args.copy_images)
    else:
        create_all_app_bins(args.copy_images)


if __name__ == "__main__":
    main()
