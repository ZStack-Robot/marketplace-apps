import datetime
import os
import argparse
import shutil

import refresh_index
import package_bin
import bash

decompress_repo_sh = "decompress_repo.sh"
refresh_index_py = "refresh_index.py"

def generate_repo_bin_name(include_image=None):
    now = datetime.datetime.now()
    formatted_time = now.strftime('%Y%m%d%H%M')
    if include_image:
        name = 'zstack-marketplace-repo-{}.bin'.format(formatted_time)
    else:
        name = 'zstack-marketplace-no-image-repo-{}.bin'.format(formatted_time)
    return name


def compress_repo_bin(app_bins_path, include_image):
    shutil.copy(refresh_index_py, app_bins_path)

    repo_targz_path = os.path.join(app_bins_path, "repo.tar.gz")
    compress_command = "tar -czvf repo.tar.gz *"
    r, _, e = bash.bash_roe(compress_command, workdir=app_bins_path)
    if r != 0:
        print("fail to compress repo, err: %s" % e)
        exit(1)

    bin_name = generate_repo_bin_name(include_image)
    r, _, e = bash.bash_roe("cat %s %s > %s" % (decompress_repo_sh, repo_targz_path, bin_name))
    if r != 0:
        print("fail to create repo bin file, err: %s" % e)
        exit(1)
    os.remove(repo_targz_path)
    os.remove(os.path.join(app_bins_path, refresh_index_py))

    return bin_name


def create_repo_bin_file(include_images):
    app_bins_path = package_bin.create_all_app_bins(include_images)
    repo_bin_file_name = compress_repo_bin(app_bins_path, include_images)
    return repo_bin_file_name


def main():
    parser = argparse.ArgumentParser(description='Process some parameters.')
    parser.add_argument('--include_images', action='store_true',
                        help='Include images, will generate bin file in application_bins')

    args = parser.parse_args()

    include_images = args.include_images
    filename = create_repo_bin_file(include_images=include_images)
    refresh_index.refresh("applications")
    absolute_path = os.path.abspath(filename)
    print("\nbuild repo bin file success!")
    print("repo file name is: %s" % absolute_path)


if __name__ == "__main__":
    main()
