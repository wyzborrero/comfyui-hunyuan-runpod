FROM pytorch/pytorch:2.1.0-cuda11.8-cudnn8-runtime

ENV DEBIAN_FRONTEND=noninteractive
ENV ROOT=/workspace

# Install dependencies
RUN apt-get update -qq && \
    apt-get install -y -qq git git-lfs aria2 ffmpeg && \
    rm -rf /var/lib/apt/lists/* && \
    git lfs install && \
    pip3 install --upgrade pip

WORKDIR $ROOT
RUN git clone https://github.com/comfyanonymous/ComfyUI.git comfyui-hunyuan-runpod
RUN pip3 install -r $ROOT/comfyui-hunyuan-runpod/requirements.txt

WORKDIR $ROOT/comfyui-hunyuan-runpod/custom_nodes
RUN git clone https://github.com/kijai/ComfyUI-HunyuanVideoWrapper
RUN git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite

WORKDIR $ROOT/comfyui-hunyuan-runpod/custom_nodes/ComfyUI-HunyuanVideoWrapper
RUN pip3 install -r requirements.txt
RUN pip3 install sageattention

# Instead of downloading large models here, we will do it at runtime.
# Just create directories now.
RUN mkdir -p $ROOT/comfyui-hunyuan-runpod/models/clip \
             $ROOT/comfyui-hunyuan-runpod/models/unet \
             $ROOT/comfyui-hunyuan-runpod/models/vae

WORKDIR $ROOT/comfyui-hunyuan-runpod/custom_nodes
RUN pip3 install -r ComfyUI-VideoHelperSuite/requirements.txt

EXPOSE 8188
WORKDIR $ROOT/comfyui-hunyuan-runpod

# Entry command now includes model download (add a script if needed)
CMD ["/bin/bash", "-c", "\
aria2c -c -x 16 -s 16 -k 1M https://huggingface.co/openai/clip-vit-large-patch14/resolve/main/model.safetensors -d $ROOT/comfyui-hunyuan-runpod/models/clip -o clip.safetensors && \
aria2c -c -x 16 -s 16 -k 1M https://huggingface.co/Kijai/HunyuanVideo_comfy/resolve/main/hunyuan_video_720_cfgdistill_fp8_e4m3fn.safetensors -d $ROOT/comfyui-hunyuan-runpod/models/unet -o transformers.safetensors && \
aria2c -c -x 16 -s 16 -k 1M https://huggingface.co/Kijai/HunyuanVideo_comfy/resolve/main/hunyuan_video_vae_bf16.safetensors -d $ROOT/comfyui-hunyuan-runpod/models/vae -o vae.safetensors && \
python3 main.py --listen 0.0.0.0\
"]
