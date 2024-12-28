# 使用Python 3.7作为基础镜像
FROM python:3.7-slim

# 设置工作目录
WORKDIR /app

# 完全清理所有已存在的源列表文件，然后添加清华源
RUN rm -rf /etc/apt/sources.list.d/* && \
    rm -f /etc/apt/sources.list && \
    echo "deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm main contrib non-free non-free-firmware" > /etc/apt/sources.list && \
    echo "deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm-updates main contrib non-free non-free-firmware" >> /etc/apt/sources.list && \
    echo "deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm-backports main contrib non-free non-free-firmware" >> /etc/apt/sources.list && \
    echo "deb https://mirrors.tuna.tsinghua.edu.cn/debian-security bookworm-security main contrib non-free non-free-firmware" >> /etc/apt/sources.list

# 安装系统依赖
RUN apt-get update && apt-get install -y \
    graphviz \
    git \
    && rm -rf /var/lib/apt/lists/*

# 配置pip
RUN pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple \
    && pip config set install.trusted-host pypi.tuna.tsinghua.edu.cn

# 复制项目文件
COPY requirements.txt ./
COPY *.py ./
COPY dataset/ ./dataset/
COPY templates/ ./templates/
COPY api/ ./api/
COPY model/ ./model/

# 安装项目依赖
RUN pip install -r requirements.txt --timeout 600

# 设置环境变量
ENV PYTHONUNBUFFERED=1

# 暴露端口
EXPOSE 5000

# 先训练模型
RUN python DeepPanel.py

# 修改默认命令为启动 Web 服务
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "api.app:app"]