# Sign Language Translation

A repository by **Ahmet Ege Tanriverdi** as part of the Bogazici University Electrical and Electronics Engineering Final Design Project.

This repository provides a ready-to-run pipeline for translating **American Sign Language (ASL) videos into English text**, built on top of Meta's [SONAR](https://github.com/facebookresearch/SONAR) and [ssvp_slt](https://github.com/facebookresearch/ssvp_slt) models. It is designed to be a practical starting point for anyone looking to implement sign language translation without having to piece together multiple research repositories.

---

## Performance

Evaluated on the **DailyMoth-70h** test set (English, `eng_Latn`):

| BLEU-1 | BLEU-2 | BLEU-3 | BLEU-4 | ROUGE-L | BLEURT |
|:------:|:------:|:------:|:------:|:-------:|:------:|
| 55.5   | 44.3   | 36.7   | 30.8   | 57.2    | 52.4   |

Reference translations can be found in [example_translations.txt](example_translations.txt).

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

This creates a conda environment called `slt` and installs all dependencies including PyTorch 2.5.1, fairseq2, SONAR, and dlib. This environment setuo script includes manual overrides that change some of the source codes of packages, so trying to setup the environment without this bach script will result in many errors.

### 3. Activate the Environment

```bash
conda activate slt
```

---

## Important Note on Translation Quality

Sign language translation accuracy is heavily influenced by factors outside the model's control:

- **Signer identity** — the model was fine-tuned on a single signer (the host of [The Daily Moth](https://www.dailymoth.com/)), and performance drops significantly with unfamiliar signers.
- **Video environment** — training data was recorded in a controlled studio setting with a clean background and consistent lighting. Cluttered backgrounds or poor lighting will degrade results.
- **Video quality** — low resolution or heavily compressed video reduces feature extraction accuracy.
- **Domain** — the training content is ASL news broadcasts. Casual conversation, different signing styles, or regional ASL variants may not translate well.

For best results, we recommend starting with the **DailyMoth-70h dataset**, which is the same data the model was trained on. It consists of ~70 hours of ASL news clips from The Daily Moth, featuring:
- A single fluent signer in a professional studio setting
- Clean, high-quality video with consistent framing
- Subtitle-aligned English translations for each clip
- Both blurred and unblurred versions of the videos

You can download it using the provided script:

```bash
cd sign_language_translation/ssvp_slt/scripts
bash download_dm70.sh
```

---

## Running Translation

To translate a video, run `translate.sh` from the repository root:

```bash
# Translate a single video
bash translate.sh /path/to/your/video.mp4

# Translate multiple videos
bash translate.sh video1.mp4 video2.mp4 video3.mp4
```

Example videos are provided in the `example_sign_language_videos/` folder.

> **Note:** The first run will download model weights (~1 GB) automatically. Subsequent runs use the cached files from `~/.cache/asl/`.

---
## Acknowledgements

This project builds directly on the following research and open-source work:

- **ssvp_slt** — Ivanovic et al., Meta AI Research. End-to-end sign language translation pipeline (SignHiera feature extractor + SONAR encoder).
  [GitHub](https://github.com/facebookresearch/ssvp_slt)

- **SONAR** — Duquenne et al., Meta AI Research. Sentence-level Multimodal and Language-Agnostic Representations.
  [Paper](https://ai.meta.com/research/publications/sonar-sentence-level-multimodal-and-language-agnostic-representations/) · [GitHub](https://github.com/facebookresearch/SONAR)

- **fairseq2** — Meta AI Research. Next generation fairseq framework.
  [GitHub](https://github.com/facebookresearch/fairseq2)

- **dlib** — King, D.E. *Dlib-ml: A Machine Learning Toolkit*. Journal of Machine Learning Research, 2009.
  [GitHub](https://github.com/davisking/dlib)

- **FLORES-200** — NLLB Team et al. No Language Left Behind: Scaling Human-Centered Machine Translation.
  [Paper](https://arxiv.org/abs/2207.04672)