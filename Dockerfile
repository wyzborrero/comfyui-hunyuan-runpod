FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV ROOT=/workspace

# Update and install system dependencies
RUN apt-get update -qq && \
    apt-get install -y -qq git git-lfs aria2 ffmpeg python3-pip && \
    rm -rf /var/lib/apt/lists/*

RUN pip3 install --upgrade pip && \
    pip3 install uv

# Set up git lfs
RUN git lfs install

# Create workspace directory and go there
RUN mkdir -p $ROOT
WORKDIR $ROOT

# Clone ComfyUI into the desired folder name
RUN git clone https://github.com/comfyanonymous/ComfyUI.git comfyui-hunyuan-runpod

# Uninstall torch if it’s pre-installed, then install requirements
RUN uv pip uninstall --yes --system torch torchvision torchaudio
RUN uv pip install --system -r $ROOT/comfyui-hunyuan-runpod/requirements.txt

# Add custom nodes
WORKDIR $ROOT/comfyui-hunyuan-runpod/custom_nodes
RUN git clone https://github.com/kijai/ComfyUI-HunyuanVideoWrapper
RUN git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite

# Install requirements for HunyuanVideoWrapper
WORKDIR $ROOT/comfyui-hunyuan-runpod/custom_nodes/ComfyUI-HunyuanVideoWrapper
RUN uv pip install --system -r requirements.txt
RUN uv pip install --system sageattention

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
RUN uv pip install --system -r $ROOT/comfyui-hunyuan-runpod/custom_nodes/ComfyUI-VideoHelperSuite/requirements.txt

EXPOSE 8188
WORKDIR $ROOT/comfyui-hunyuan-runpod

CMD ["python3", "main.py", "--listen", "0.0.0.0"]