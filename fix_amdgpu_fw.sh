#!/bin/bash
FW_DIR="/lib/firmware/amdgpu"
FILES=(
    "cyan_skillfish_gpu_info.bin"
    "ip_discovery.bin"
    "vega10_cap.bin"
    "navi12_cap.bin"
    "aldebaran_cap.bin"
    "gc_11_0_0_toc.bin"
    "gc_12_0_1_toc.bin"
    "gc_12_0_0_toc.bin"
    "gc_11_0_3_mes.bin"
)

# Create target directory if it doesn't exist
sudo mkdir -p $FW_DIR

BASE_URL="https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/plain/amdgpu"

# Download the firmware file
file_downloaded=0
for file in "${FILES[@]}";do
    _path="$FW_DIR/$file"
    
    if [ -f "$_path" ];then continue; fi

    if sudo curl -s -o "$_path" "$BASE_URL/$file";then
        file_downloaded=1
        echo "Firmware $file downloaded successfully."
    else
        echo -e "Failed to download $file."
    fi   
done

# Update initramfs
if [ $file_downloaded -gt 0 ];then
    sudo update-initramfs -u
fi
