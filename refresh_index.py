import os
import json
import time
import argparse


def get_supported_versions(base_path):
    support_versions = []
    for arch in os.listdir(base_path):
        arch_path = os.path.join(base_path, arch)
        if os.path.isdir(arch_path):
            versions = []
            for version in os.listdir(arch_path):
                version_path = os.path.join(arch_path, version)
                if os.path.isdir(version_path):
                    versions.append(version)
            support_versions.append({
                "architecture": arch,
                "versions": versions
            })
    return support_versions


def refresh(root_path):
    applications = []
    for app_id in os.listdir(root_path):
        app_path = os.path.join(root_path, app_id)
        if os.path.isdir(app_path):
            support_versions = get_supported_versions(app_path)
            if support_versions:
                applications.append({
                    "app_id": app_id,
                    "support_versions": support_versions
                })

    data = {
        "applications": applications,
        "update_at": int(time.time())
    }

    with open(os.path.join(root_path, 'index.json'), 'w') as f:
        json.dump(data, f, indent=2)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Generate index.json for application.')
    parser.add_argument('--root_path', type=str, help='Root path of the application repo', default="./applications")
    args = parser.parse_args()

    refresh(args.root_path)
