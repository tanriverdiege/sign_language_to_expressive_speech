#!/bin/bash
# Setup script for the SONAR ASL demo environment.
#
# Tested configuration:
#   Python 3.10, fairseq2 0.3.0, sonar-space 0.2.1
#   torch 2.5.1 (CUDA 12.1 bundled by fairseq2n — no pre-install needed)
#
# Key design decisions:
#   - fairseq2n 0.3.0 hard-requires torch==2.5.1; we let it own torch.
#     Pre-installing torch 2.2.0+cu118 before fairseq2 caused pip to later
#     "correct" the violation by downgrading torch back to 2.2.0, breaking
#     fairseq2n. Solution: install fairseq2 first.
#   - fairseq-sl (the old fairseq fork) requires omegaconf<2.1, which is
#     incompatible with hydra-core>=1.2 used by stopes and ssvp_slt.
#     The demo (run.py) never imports old fairseq, so we skip it entirely.
#   - fairseq2 requires numpy~=1.23. We pin numpy=1.26.4 and protect it with
#     a pip constraints file so requirements.txt cannot upgrade to numpy 2.x.
#

set -euo pipefail

ENV_NAME="${1:-slt}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONDA_RUN="conda run --no-capture-output -n $ENV_NAME"

echo "======================================================"
echo " Creating conda environment: $ENV_NAME"
echo "======================================================"
conda create -n "$ENV_NAME" python=3.10 cmake -y

echo ""
echo "======================================================"
echo " Installing av via conda-forge (video decoding)"
echo "======================================================"
conda run --no-capture-output -n "$ENV_NAME" conda install av -c conda-forge -y

echo ""
echo "======================================================"
echo " Installing fairseq2 0.3.0"
echo " (fairseq2n will pull in torch==2.5.1 with CUDA 12.1)"
echo "======================================================"
$CONDA_RUN pip install "fairseq2==0.3.0" \
    --extra-index-url "https://fair.pkg.atmeta.com/fairseq2/whl/pt2.2.0/cu118/"

echo ""
echo "======================================================"
echo " Pinning numpy to 1.26.4 (fairseq2 requires numpy~=1.23)"
echo "======================================================"
$CONDA_RUN pip install "numpy==1.26.4" --force-reinstall

echo ""
echo "======================================================"
echo " Installing torchvision 0.20.1 (compatible with torch 2.5.1)"
echo "======================================================"
$CONDA_RUN pip install "torchvision==0.20.1"

echo ""
echo "======================================================"
echo " Installing sonar-space 0.3.2"
echo "======================================================"
$CONDA_RUN pip install "sonar-space==0.3.2"

echo ""
echo "======================================================"
echo " Patching sonar-space 0.3.2 for fairseq2 0.3.0 final"
echo " (load_nllb_tokenizer removed; speech pipeline disabled)"
echo "======================================================"
SONAR_SITE=$($CONDA_RUN python -c "import sonar, os; print(os.path.dirname(sonar.__file__))")

# Replace load_nllb_tokenizer (removed in 0.3.0 final) with a direct NllbTokenizer loader
$CONDA_RUN python - <<'PYEOF'
import pathlib, sonar, os
loader = pathlib.Path(os.path.dirname(sonar.__file__)) / "models/sonar_text/loader.py"
text = loader.read_text()
text = text.replace(
    "from fairseq2.models.nllb import load_nllb_tokenizer",
    (
        "from fairseq2.assets import default_asset_download_manager, default_asset_store\n"
        "from fairseq2.data.text import NllbTokenizer"
    )
)
new_fn = (
    "def load_sonar_tokenizer(name_or_card, *, progress=False, force=False):\n"
    "    from fairseq2.assets import AssetCard\n"
    "    if isinstance(name_or_card, AssetCard):\n"
    "        card = name_or_card\n"
    "    else:\n"
    "        card = default_asset_store.retrieve_card(name_or_card)\n"
    "    tokenizer_uri = card.field(\"tokenizer\").as_(str)\n"
    "    from typing import List\n"
    "    langs = card.field(\"langs\").as_(List[str])\n"
    "    default_lang = card.field(\"default_lang\").as_(str)\n"
    "    path = default_asset_download_manager.download_tokenizer(\n"
    "        tokenizer_uri, card.name, force=force, progress=progress\n"
    "    )\n"
    "    return NllbTokenizer(path, langs, default_lang)"
)
text = text.replace("load_sonar_tokenizer = load_nllb_tokenizer", new_fn)
loader.write_text(text)
print("  patched sonar/models/sonar_text/loader.py")
PYEOF

# Remove speech pipeline imports that trigger the broken load chain
$CONDA_RUN python - <<'PYEOF'
import pathlib, sonar, os
init = pathlib.Path(os.path.dirname(sonar.__file__)) / "inference_pipelines/__init__.py"
text = init.read_text()
# Remove speech imports block; keep only text imports
speech_block = (
    "from sonar.inference_pipelines.speech import (\n"
    "    SpeechInferenceParams as SpeechInferenceParams,\n"
    ")\n"
    "from sonar.inference_pipelines.speech import (\n"
    "    SpeechToEmbeddingPipeline as SpeechToEmbeddingPipeline,\n"
    ")\n"
    "from sonar.inference_pipelines.speech import (\n"
    "    SpeechToTextPipeline as SpeechToTextPipeline,\n"
    ")\n"
)
text = text.replace(speech_block, "")
init.write_text(text)
print("  patched sonar/inference_pipelines/__init__.py")
PYEOF

echo ""
echo "======================================================"
echo " Installing stopes (core only, no fairseq2 extras)"
echo "======================================================"
$CONDA_RUN pip install "git+https://github.com/facebookresearch/stopes.git"

echo ""
echo "======================================================"
echo " Installing transformers 4.38.0 (pinned by requirements.txt)"
echo "======================================================"
$CONDA_RUN pip install "transformers==4.38.0"

echo ""
echo "======================================================"
echo " Installing remaining requirements"
echo "======================================================"

# Constraints file prevents requirements.txt from upgrading numpy to 2.x
# or downgrading torch away from the version fairseq2n requires.
CONSTRAINTS_FILE="$(mktemp /tmp/demo_constraints.XXXXXX.txt)"
cat > "$CONSTRAINTS_FILE" << 'EOF'
numpy==1.26.4
torch==2.5.1
torchvision==0.20.1
transformers==4.38.0
EOF

$CONDA_RUN pip install -r "$SCRIPT_DIR/requirements.txt" -c "$CONSTRAINTS_FILE"
rm "$CONSTRAINTS_FILE"

echo ""
echo "======================================================"
echo " Installing ssvp_slt package"
echo "======================================================"
# --no-deps avoids pulling in tensorflow (listed in setup.py but not needed
# for inference) and avoids re-running the dependency resolver, which could
# downgrade pinned packages.
$CONDA_RUN pip install -e "$SCRIPT_DIR" --no-deps --no-build-isolation

echo ""
echo "======================================================"
echo " Installing dlib (CPU face detection)"
echo "======================================================"
$CONDA_RUN pip install dlib

echo ""
echo "======================================================"
echo " Verifying key packages"
echo "======================================================"
$CONDA_RUN python -c "
import torch, fairseq2, sonar, torchvision, numpy, dlib, cv2
from ssvp_slt.modeling.sonar import SonarTranslator
print(f'  torch:       {torch.__version__}')
print(f'  torchvision: {torchvision.__version__}')
print(f'  fairseq2:    {fairseq2.__version__}')
print(f'  sonar-space: {sonar.__version__}')
print(f'  numpy:       {numpy.__version__}')
print(f'  dlib:        {dlib.__version__}')
print(f'  opencv:      {cv2.__version__}')
print(f'  CUDA avail:  {torch.cuda.is_available()}')
print(f'  SonarTranslator: OK')
"

echo ""
echo "======================================================"
echo " Downloading dlib face detector model"
echo "======================================================"
DLIB_DAT="$SCRIPT_DIR/examples/sonar/mmod_human_face_detector.dat"
if [ -f "$DLIB_DAT" ]; then
    echo " - Already exists, skipping download."
else
    wget "http://dlib.net/files/mmod_human_face_detector.dat.bz2" -P "$SCRIPT_DIR/examples/sonar/"
    bzip2 -d "$SCRIPT_DIR/examples/sonar/mmod_human_face_detector.dat.bz2"
fi

echo ""
echo "======================================================"
echo " Setup complete!"
echo "======================================================"
echo ""