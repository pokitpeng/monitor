# epc-cluster-monitor

epc集群监控

## 使用说明

### exporter
exporter中包含常用的数据采集工具。每个需要采集的机器都要部署，具体部署的工具，根据具体情况决定。（比如某个节点需要采集英伟达GPU数据，就需要部署nvidia-gpu-exporter）
使用的方式使用`bash deploy.sh --help`进行查看。

### collector
collector中包含prometheus和grafana等服务，为了方便部署，使用docker-compose方式进行安装。
- docker安装：https://docs.docker.com/engine/install/
- docker-compose安装：https://github.com/docker/compose/releases
安装好上述依赖后，修改`collector/prometheus/prometheus.yml`配置文件，根据具体采集的机器和指标修改配置。
执行`docker-compose up -d`启动服务。