# Sign Language to Expressive Speech

A repository by **Ahmet Ege Tanriverdi** as part of the Bogazici University Electrical and Electronics Engineering Final Design Project.

This repository provides a ready-to-run pipeline for translating **American Sign Language (ASL) videos into English text**, built on top of Meta's [SONAR](https://github.com/facebookresearch/SONAR) and [ssvp_slt](https://github.com/facebookresearch/ssvp_slt) models. It is designed to be a practical starting point for anyone looking to implement sign language translation without having to piece together multiple research repositories.

---

## Requirements

- Linux (tested on Ubuntu)
- NVIDIA GPU with CUDA 12.1
- [Miniconda](https://docs.conda.io/en/latest/miniconda.html)

---

## Setup

### 1. Install Miniconda (if not already installed)

```bash
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh -b -p ~/miniconda3
rm Miniconda3-latest-Linux-x86_64.sh
~/miniconda3/bin/conda init bash
source ~/.bashrc
```

### 2. Run the Environment Setup Script

```bash
cd sign_language_translation/ssvp_slt
bash setup_env.sh
```

This creates a conda environment called `slt` and installs all dependencies including PyTorch 2.5.1, fairseq2, SONAR, and dlib.

### 3. Activate the Environment

```bash
conda activate slt
```

---

## Running Translation

To translate a video, run `translate.sh` from the repository root:

```bash
# Translate a single video
bash translate.sh /path/to/your/video.mp4

# Translate multiple videos
bash translate.sh video1.mp4 video2.mp4 video3.mp4

# Run on the built-in sample video (downloads automatically)
bash translate.sh
```

Example videos are provided in the `example_sign_language_videos/` folder.

> **Note:** The first run will download model weights (~1 GB) from Meta's servers automatically. Subsequent runs use the cached files from `~/.cache/asl/`.

---