FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV ROOT=/workspace

# Update and install system dependencies
RUN apt-get update -qq && \
    apt-get install -y -qq git git-lfs aria2 ffmpeg python3-pip && \
    rm -rf /var/lib/apt/lists/*

RUN pip3 install --upgrade pip
RUN git lfs install

# Create workspace directory
RUN mkdir -p $ROOT
WORKDIR $ROOT

# Clone ComfyUI into the desired folder name
RUN git clone https://github.com/comfyanonymous/ComfyUI.git comfyui-hunyuan-runpod

# Uninstall torch if pre-installed (ignore errors)
RUN pip3 uninstall --yes torch torchvision torchaudio || true

# Install a GPU-supported PyTorch version compatible with CUDA 11.8
# Adjust versions if needed, but these should work with CUDA 11.8
RUN pip3 install --no-cache-dir --extra-index-url https://download.pytorch.org/whl/cu118 \
    torch==2.0.1 torchvision==0.15.2 torchaudio==2.0.2

# Now install the rest of ComfyUI requirements
RUN pip3 install --no-cache-dir -r $ROOT/comfyui-hunyuan-runpod/requirements.txt

# Add custom nodes
WORKDIR $ROOT/comfyui-hunyuan-runpod/custom_nodes
RUN git clone https://github.com/kijai/ComfyUI-HunyuanVideoWrapper
RUN git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite

# Install requirements for HunyuanVideoWrapper
WORKDIR $ROOT/comfyui-hunyuan-runpod/custom_nodes/ComfyUI-HunyuanVideoWrapper
RUN pip3 install --no-cache-dir -r requirements.txt
RUN pip3 install --no-cache-dir sageattention

# Download models
RUN mkdir -p $ROOT/comfyui-hunyuan-runpod/models/clip \
             $ROOT/comfyui-hunyuan-runpod/models/unet \
             $ROOT/comfyui-hunyuan-runpod/models/vae

# Download CLIP model
RUN aria2c --console-log-level=error -c -x 16 -s 16 -k 1M \
  https://huggingface.co/openai/clip-vit-large-patch14/resolve/main/model.safetensors \
  -d $ROOT/comfyui-hunyuan-runpod/models/clip -o clip.safetensors

# Download UNet model
RUN aria2c --console-log-level=error -c -x 16 -s 16 -k 1M \
  https://huggingface.co/Kijai/HunyuanVideo_comfy/resolve/main/hunyuan_video_720_cfgdistill_fp8_e4m3fn.safetensors \
  -d $ROOT/comfyui-hunyuan-runpod/models/unet -o transformers.safetensors

# Download VAE model
RUN aria2c --console-log-level=error -c -x 16 -s 16 -k 1M \
  https://huggingface.co/Kijai/HunyuanVideo_comfy/resolve/main/hunyuan_video_vae_bf16.safetensors \
  -d $ROOT/comfyui-hunyuan-runpod/models/vae -o vae.safetensors

# Install VideoHelperSuite requirements
WORKDIR $ROOT/comfyui-hunyuan-runpod/custom_nodes
RUN pip3 install --no-cache-dir -r $ROOT/comfyui-hunyuan-runpod/custom_nodes/ComfyUI-VideoHelperSuite/requirements.txt

EXPOSE 8188
WORKDIR $ROOT/comfyui-hunyuan-runpod

CMD ["python3", "main.py", "--listen", "0.0.0.0"]
