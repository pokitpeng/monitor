#!/usr/bin/env bash

arch=""

function check_arch(){
    if [[ "$(uname -m)" == "x86_64" ]]; then
        arch="x86_64"
    elif [[ "$(uname -m)" == "aarch64" ]]; then
        arch="arm64"
    else
        echo "Unsupported CPU architecture: $(uname -m)"
        exit -1
    fi
}

function deploy_node-exporter(){
    cp ./${arch}/node-exporter /usr/bin/node-exporter

    cat > /usr/lib/systemd/system/node-exporter.service <<EOF
[Unit]
Description=node-exporter
Documentation=https://prometheus.io/
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/node-exporter --collector.filesystem.mount-points-exclude="^/(sys|proc|dev|host|etc|fuse.glusterfs)($$|/)"
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl start node-exporter
    systemctl enable node-exporter
}

function deploy_process-exporter(){
    cp ./${arch}/process-exporter /usr/bin/process-exporter


    cat > /usr/lib/systemd/system/process-exporter.service <<EOF
[Unit]
Description=process-exporter
Documentation=https://prometheus.io/
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/process-exporter -config.path /etc/process-exporter/process-exporter.yml
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

    mkdir -p /etc/process-exporter

    cat > /etc/process-exporter/process-exporter.yml <<EOF
process_names:
  - name: "{{.ExeFull}}"
    cmdline:
    - '/usr/sbin/slurmctld'
  - name: "{{.ExeFull}}"
    cmdline:
    - '/usr/sbin/slurmd'
  - name: "{{.ExeFull}}"
    cmdline:
    - '/usr/sbin/slurmdbd'
  - name: "{{.ExeFull}}"
    cmdline:
    - '/usr/sbin/slurmrestd'
  - name: "{{.ExeFull}}"
    cmdline:
    - '/usr/sbin/glusterfs'
  - name: "{{.ExeFull}}"
    cmdline:
    - '/usr/sbin/glusterd' 
EOF

    systemctl daemon-reload
    systemctl start process-exporter
    systemctl enable process-exporter
}


# process_names:
#   - name: "{{.ExeFull}}"
#     cmdline:
#     - '/usr/sbin/slurmctld'
#   - name: "{{.ExeFull}}"
#     cmdline:
#     - '/usr/sbin/slurmd'
#   - name: "{{.ExeFull}}"
#     cmdline:
#     - '/usr/sbin/slurmdbd'
#   - name: "{{.ExeFull}}"
#     cmdline:
#     - '/usr/sbin/slurmrestd'
#   - name: "{{.ExeFull}}"
#     cmdline:
#     - '/usr/sbin/glusterd'  

#   - name: "{{.Matches}}"
#     cmdline:
#     - 'gv_slurmctl_production'
#     - 'gv_jobs_production'
#     - 'gv_images_production'

function deploy_slurm-exporter(){
    cp ./${arch}/slurm-exporter /usr/bin/slurm-exporter
    cat > /usr/lib/systemd/system/slurm-exporter.service <<EOF
[Unit]
Description=slurm-exporter
Documentation=https://prometheus.io/
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/slurm-exporter
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl start slurm-exporter
    systemctl enable slurm-exporter
}

function deploy_nvidia-gpu-exporter(){
    cp ./${arch}/nvidia-gpu-exporter /usr/bin/nvidia-gpu-exporter
    cat > /usr/lib/systemd/system/nvidia-gpu-exporter.service <<EOF
[Unit]
Description=nvidia-gpu-exporter
Documentation=https://prometheus.io/
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/nvidia-gpu-exporter
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl start nvidia-gpu-exporter
    systemctl enable nvidia-gpu-exporter
}

function remove_all(){
    systemctl stop process-exporter
    systemctl stop node-exporter
    systemctl stop slurm-exporter
    systemctl stop nvidia-gpu-exporter

    rm -rf /usr/lib/systemd/system/process-exporter.service
    rm -rf /usr/lib/systemd/system/node-exporter.service
    rm -rf /usr/lib/systemd/system/slurm-exporter.service
    rm -rf /usr/lib/systemd/system/nvidia-gpu-exporter.service
    rm -rf /usr/bin/process-exporter
    rm -rf /usr/bin/node-exporter
    rm -rf /usr/bin/slurm-exporter
    rm -rf /usr/bin/nvidia-gpu-exporter
    rm -rf /etc/process-exporter

    systemctl daemon-reload
}

function deploy_all(){
    deploy_node-exporter
    deploy_process-exporter
    deploy_nvidia-gpu-exporter
    echo "check: systemctl status node-exporter process-exporter nvidia-gpu-exporter"
}

# The command line help
function display_help() {
    echo "Usage: $0 [option...]" >&2
    echo
    printf "\033[36m%-30s\033[0m %-30s\n" "deploy_node-exporter" "deploy node-exporter"
    printf "\033[36m%-30s\033[0m %-30s\n" "deploy_process-exporter" "deploy process-exporter"
    printf "\033[36m%-30s\033[0m %-30s\n" "deploy_nvidia-gpu-exporter" "deploy nvidia-gpu-exporter"
    printf "\033[36m%-30s\033[0m %-30s\n" "deploy_slurm-exporter" "deploy slurm-exporter"
    printf "\033[36m%-30s\033[0m %-30s\n" "deploy_all" "deploy all, without slurm-exporter"
    printf "\033[36m%-30s\033[0m %-30s\n" "remove_all" "remove all"
    echo
}


check_arch
# Check if parameters options are given on the commandline
case "$1" in
deploy_node-exporter)
    deploy_node-exporter
    ;;
deploy_nvidia-gpu-exporter)
    deploy_nvidia-gpu-exporter
    ;;
deploy_process-exporter)
    deploy_process-exporter
    ;;
deploy_slurm-exporter)
    deploy_slurm-exporter
    ;;
deploy_all)
    deploy_all
    ;;
remove_all)
    remove_all
    ;;
-h | --help | help)
    display_help
    ;;
*) # No more options
    display_help
    exit 1
    ;;
esac