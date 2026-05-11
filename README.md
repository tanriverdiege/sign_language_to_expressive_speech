This is a repository created by Ahmet Ege Tanriverdi as a part of the Bogazici University Electrical and Electronics Engineering Final Design Project.

The repository seamlessly will walk you thorugh your first ever Sign Language Translation model. I believe that this repository will serve as a great starting point for your project that includes sign language translation.

The reason I wanted to create such a repository is that I spent a lot of time trying to find a model that translates american sign language videos to english text. Even though there are some good papers it seemed really hard for me to just implement their repositories. Hope this helps.

Please follow these steps to setup your environment.
To set up your environement move to he sign_language_translation/ssvp_slt folder and run the bash script called setup_env.sh.

If conda is not installed you need to first install conda to your machine. The environment setup strictly requires conda.

wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh -b -p /directory_you_want_to_keep_conda_in/miniconda
rm Miniconda3-latest-Linux-x86_64.sh
/root/miniconda3/bin/conda init bash
source ~/.bashrc




cd sign_language_translation/ssvp_slt/
bash setup_env.sh