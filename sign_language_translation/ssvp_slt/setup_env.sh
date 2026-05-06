#!/bin/bash
# Setup script for the ASL Translation environment.
#
# Tested with: CUDA 11.8, Python 3.10, PyTorch 2.2.0
#
# Key version constraints:
#   - fairseq2 0.3.0  (sonar.py uses the 0.3.x API: fairseq2.nn.padding,
#                      fairseq2.models.sequence, fairseq2.typing)
#   - sonar-space 0.2.1 (run.py uses EmbeddingToTextModelPipeline.predict()
#                        which changed in 0.3+)
#
# Usage:
#   bash setup_demo_env.sh
#   conda activate slt
#   # then run the demo

set -euo pipefail

ENV_NAME="slt"
CUDA_VERSION="cu118"
TORCH_VERSION="2.2.0"
CUDA_HOME_PATH="/usr/local/cuda-11.8"

echo "======================================================"
echo " Creating conda environment: $ENV_NAME"
echo "======================================================"
conda create -n "$ENV_NAME" python=3.10 cmake -y

# From here we use 'conda run' so the scripts work without sourcing conda.
CONDA_RUN="conda run --no-capture-output -n $ENV_NAME"

echo ""
echo "======================================================"
echo " Installing PyTorch $TORCH_VERSION for CUDA 11.8"
echo "======================================================"
$CONDA_RUN pip install \
    torch==2.2.0 \
    torchvision==0.17.0 \
    torchaudio==2.2.0 \
    --index-url https://download.pytorch.org/whl/cu118

echo ""
echo "======================================================"
echo " Installing av via conda-forge"
echo "======================================================"
conda run --no-capture-output -n "$ENV_NAME" conda install av -c conda-forge -y

echo ""
echo "======================================================"
echo " Installing fairseq2 0.3.0 (CUDA 11.8 wheel)"
echo "======================================================"
# This pre-built wheel bundles the CUDA-compatible fairseq2 native extension.
# The wheel index is specific to the pt2.2.0 + cu118 combination.
$CONDA_RUN pip install fairseq2==0.3.0 \
    --extra-index-url "https://fair.pkg.atmeta.com/fairseq2/whl/pt2.2.0/cu118/"

echo ""
echo "======================================================"
echo " Installing sonar-space 0.2.1"
echo "======================================================"
# 0.2.x is compatible with fairseq2 0.3.x and the predict() API used in sonar.py.
$CONDA_RUN pip install "sonar-space==0.2.1"

echo ""
echo "======================================================"
echo " Installing stopes (core only, no fairseq2 extras)"
echo "======================================================"
# Install core stopes without the [sonar_mining] extra, which would try to
# pull in fairseq2==0.2.* and conflict with our 0.3.0 pin.
$CONDA_RUN pip install "git+https://github.com/facebookresearch/stopes.git"

echo ""
echo "======================================================"
echo " Installing remaining requirements"
echo "======================================================"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# transformers 4.38.0 is pinned in requirements.txt. Install it explicitly
# first so pip doesn't upgrade it when resolving other deps.
$CONDA_RUN pip install "transformers==4.38.0"

# Install the rest of requirements.txt. stopes and transformers are already
# satisfied, so pip will skip reinstalling them.
$CONDA_RUN pip install -r "$SCRIPT_DIR/requirements.txt"

echo ""
echo "======================================================"
echo " Installing fairseq-sl (local fork)"
echo "======================================================"
$CONDA_RUN pip install -e "$SCRIPT_DIR/fairseq-sl"

echo ""
echo "======================================================"
echo " Installing ssvp_slt package"
echo "======================================================"
$CONDA_RUN pip install -e "$SCRIPT_DIR"

echo ""
echo "======================================================"
echo " Installing dlib (CPU face detection)"
echo "======================================================"
# CPU-only dlib is sufficient for the preprocessing step.
# For GPU-accelerated face detection, see INSTALL.md step 4.
$CONDA_RUN pip install dlib

echo ""
echo "======================================================"
echo " Setup complete!"
echo "======================================================"
echo ""
echo "Activate the environment and set CUDA paths:"
echo ""
echo "  conda activate $ENV_NAME"
echo "  export CUDA_HOME=$CUDA_HOME_PATH"
echo "  export LD_LIBRARY_PATH=$CUDA_HOME_PATH/lib64:\${LD_LIBRARY_PATH}"
echo ""
echo "Download a dlib face detector model (e.g. mmod_human_face_detector.dat):"
echo "  https://github.com/davisking/dlib-models"
echo ""
echo "Then run the demo from the examples/sonar directory:"
echo "  cd $SCRIPT_DIR/examples/sonar"
echo "  ./demo.sh /path/to/dlib/detector_model.dat"
echo ""
