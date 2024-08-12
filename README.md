# marketplace-apps
用于打包应用市场的应用的配置文件，本仓库不包含镜像 （test应用仅用于测试和示例，打包默认会跳过）

镜像会单独在下面这个地址备份
```
http://192.168.200.100/mirror/xinhao.huang/marketplace-apps
```

## 应用市场的CDN地址
```
http://cdn.zstack.io/marketplace/v1
```

## 发布新应用的流程
### 0. clone本仓库

### 1. 在applications里新建应用目录
```
$ mkdir -p applications/${app_id}/${arch}/${version}/
```
- app_id  
  - 应用的唯一标识
- arch    
  - 架构 (x86_64, aarch64)
- version 
  - 应用版本（x.x....）

#### 所需的文件
- application.json 
  - 应用的描述
- input.json
  - 输入表单
- output.json
  - 输出表单
- logo.png
  - 应用的图标，当前只支持png
- src
  - terraform的资源编排文件

### 2. 打包测试应用

执行
```
python package_repo.py 
```
生成images的对应目录

把qcow2镜像放至images的对应目录里并命名为image.qcow2

```
python package_bin --app_id xxx --version xxx --arch xxx --include_images
```
会在 target/application_bins/${app_id}/${arch}/${version}/xxx.bin 生成带镜像的bin包

上传至管理节点执行bash xxx.bin，再在ui上点击同步应用即可在应用市场看见


### 3. 打包与提交
```
$ python package_repo.py
```

该命令会在target里生成应用所需的 application.tar.gz

```
target/application_targz/${app_id}/${arch}/${version}/application.tar.gz
```

同时会生成新的index.json

提交代码至本仓库

### 4. 上传至cdn

**cdn的应用包联网的用户都会同步，未经过测试过的应用包请勿上传至cdn！！！**

1. 在cdn新建目录
    ```
    ${app_id}/${arch}/${version}/
    ```

2. 将应用的压缩包（application.tar.gz）和 镜像 (image.qcow2) 放到该目录下

3. 确认无误后，用新的index.json 替换原先的index.json




## 生成不带镜像的REPO BIN包
该包会放在marketplace-server的安装文件里，用于安装完后，生成不带镜像的本地应用repo

使用户在没有联网的情况下，也可以看到当前平台提供那些应用
```
$ python package_repo.py 
```

会在根目录生成zstack-marketplace-no-image-repo-xxxx.bin
拷贝到服务器端执行
```
$ bash zstack-marketplace-no-image-repo-xxxx.bin

# 默认仓库地址是 /opt/zstack-marketplace-repo/, 如需指定则执行:
# bash zstack-marketplace-no-image-repo-xxxx.bin $repo_path

```
即可更新当前服务器的应用仓库


## 生成带镜像单个应用BIN包
有些客户可能无法联网,需要手动拷贝应用包

1. 将image.qcow2 放到images的对应目录（如果没有目录，先执行一次 python package_repo.py ）
2. 打包应用
  ```
  python package_bin --app_id xxx --version xxx --arch xxx --include_images
  ```
  
  会在 target/application_bins/${app_id}/${arch}/${version}/xxx.bin
  生成带镜像的bin包

3. 拷贝到服务器端执行
  ```
  $ bash xxx___xxxx___xxxx.bin
  
  # 默认仓库地址是 /opt/zstack-marketplace-repo/, 如需指定则执行:
  # bash xxx___xxxx___xxxx.bin $repo_path
  ```
  即可更新当前服务器的应用仓库，并把当应用的镜像拷贝到服务器本地的应用仓库

## 其他
生成带镜像的REPO的 BIN包 ----- 因为应用镜像都特别大，几乎不会有使用场景

生成不带镜像的应用BIN包 ----- 没有使用场景

