#!/bin/bash

# 创建 raw 和 parquet 文件夹，如果已存在则忽略
mkdir -p parquet


echo "正在创建Python虚拟环境_myenv将dta转换为parquet："
# 创建 Python 虚拟环境
python3 -m venv _myenv

# 激活虚拟环境
source _myenv/bin/activate

# 安装需要的 Python 依赖
echo "正在安装必要的Python库："
pip install pandas pyarrow tqdm rich

# 运行嵌入的 python 脚本
python3 <<EOF
import glob
import pandas as pd
from pathlib import Path
from rich import print
from tqdm import tqdm

def convert_to_parquet(input_dir: str, output_dir: str):
    """
    Converts all CSV and DTA files in a directory to Parquet files.
    """
    print("开始扫描当前目录下的CSV和DTA文件...")
    input_files = glob.glob(f"{input_dir}/*.dta")
    print("已扫描到当前路径下的CSV和DTA文件如下:", [Path(i).name for i in input_files])
    print("开始转换CSV和DTA文件为Parquet格式...")
    output_path = Path(output_dir)
    output_path.mkdir(exist_ok=True)
    convert_progress = tqdm(input_files, unit="file")

    for file in convert_progress:
        convert_progress.set_description(f"正在转换{Path(file).name}")
        filename = output_path / Path(file).with_suffix('.parquet').name
        if file.endswith('.csv'):
            df = pd.read_csv(file,engine='pyarrow')
        elif file.endswith('.dta'):
            df = pd.read_stata(file, convert_categoricals=False)
        else:
            print(f"跳过不支持的文件: {file}")
            continue
        df.convert_dtypes().to_parquet(filename, engine='pyarrow', compression='gzip')

    print(f"完成转换，转换后的Parquet文件保存在'{output_path.resolve()}'.")

input_dir = "`pwd`" 
output_dir= "`pwd`/parquet"
convert_to_parquet(input_dir = input_dir, output_dir= output_dir)
EOF

# 关闭和删除虚拟环境
deactivate
rm -rf _myenv/



