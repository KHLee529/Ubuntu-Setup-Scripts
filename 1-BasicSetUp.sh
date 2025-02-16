#!/bin/bash


set -e

spatialPrint() {
    echo ""
    echo ""
    echo "$1"
	echo "================================"
}

# To note: the execute() function doesn't handle pipes well
execute () {
	echo "$ $*"
	OUTPUT=$($@ 2>&1)
	if [ $? -ne 0 ]; then
        echo "$OUTPUT"
        echo ""
        echo "Failed to Execute $*" >&2
        exit 1
    fi
}

# Speed up the process
# Env Var NUMJOBS overrides automatic detection
if [[ -n $NUMJOBS ]]; then
    MJOBS=$NUMJOBS
elif [[ -f /proc/cpuinfo ]]; then
    MJOBS=$(grep -c processor /proc/cpuinfo)
elif [[ "$OSTYPE" == "darwin"* ]]; then
	MJOBS=$(sysctl -n machdep.cpu.thread_count)
else
    MJOBS=4
fi

execute sudo apt update -y
if [[ ! -n $CIINSTALL ]]; then
    sudo apt upgrade -y
    sudo apt install ubuntu-restricted-extras -y
fi

# Choice for terminal that will be adopted: Tilda+tmux
# Not guake because tilda is lighter on resources
# Not terminator because tmux sessions continue to run if you accidentally close the terminal emulator
execute sudo apt install build-essential git wget curl -y
execute sudo apt install tilda tmux byobu -y
# execute sudo apt install gimp -y
execute sudo apt install xclip xsel -y # this is used for the copying tmux buffer to clipboard buffer
execute sudo apt install vim-gui-common vim-runtime -y

cp ./config_files/vimrc ~/.vimrc
# refer : [http://www.rushiagr.com/blog/2016/06/16/everything-you-need-to-know-about-tmux-copy-pasting-ubuntu/] for tmux buffers in ubuntu
cp ./config_files/tmux.conf ~/.tmux.conf
cp ./config_files/tmux.conf.local ~/.tmux.conf.local
mkdir -p ~/.config/tilda
cp ./config_files/config_0 ~/.config/tilda/

#Checks if ZSH is partially or completely Installed to Remove the folders and reinstall it
rm -rf ~/.z*
zsh_folder=/opt/.zsh/
if [[ -d $zsh_folder ]];then
	sudo rm -r /opt/.zsh/*
fi

spatialPrint "Setting up Zsh + Zim now"
execute sudo apt install zsh -y
sudo mkdir -p /opt/.zsh/ && sudo chmod ugo+w /opt/.zsh/
export ZIM_HOME=/opt/.zsh/zim
curl -fsSL https://raw.githubusercontent.com/zimfw/install/master/install.zsh | zsh
# Change default shell to zsh
command -v zsh | sudo tee -a /etc/shells
sudo chsh -s "$(command -v zsh)" "${USER}"

# execute sudo apt install aria2 -y

# Create bash aliases
# cp ./config_files/bash_aliases /opt/.zsh/bash_aliases >/dev/null  # Suppress error messages in case the file already exists
# rm -f ~/.bash_aliases
# ln -s /opt/.zsh/bash_aliases ~/.bash_aliases
# 
# {
#     echo "if [ -f ~/.bash_aliases ]; then"
#     echo "  source ~/.bash_aliases"
#     echo "fi"
# 
#     echo "# Switching to 256-bit colour by default so that zsh-autosuggestion's suggestions are not suggested in white, but in grey instead"
#     echo "export TERM=xterm-256color"
# } >> ~/.zshrc

# Now create shortcuts
# execute sudo apt install run-one xbindkeys xbindkeys-config wmctrl xdotool -y
# cp ./config_files/xbindkeysrc ~/.xbindkeysrc

# Now download and install bat
# spatialPrint "Installing bat, a handy replacement for cat"
# latest_bat_setup=$(curl --silent "https://api.github.com/repos/sharkdp/bat/releases/latest" | grep "deb" | grep "browser_download_url" | head -n 1 | cut -d \" -f 4)
# aria2c --file-allocation=none -c -x 10 -s 10 --dir /tmp -o bat.deb $latest_bat_setup
# execute sudo dpkg -i /tmp/bat.deb
# execute sudo apt install -f

# Check if Anaconda's Miniconda is already installed
# if [[ -n $(echo $PATH | grep 'conda') ]]; then
#     echo "Anaconda is already installed, skipping installation"
#     echo "To reinstall, delete the Anaconda install directory (/opt/anaconda3 if done by this script) and remove from PATH as well"
# else
# 
#     spatialPrint "Installing the latest Anaconda Python in /opt/anaconda3"
#     latest_anaconda_setup="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh"
#     aria2c --file-allocation=none -c -x 10 -s 10 -o anacondaInstallScript.sh --dir ./extras ${continuum_website}${latest_anaconda_setup}
#     sudo mkdir -p /opt/anaconda3 && sudo chmod ugo+w /opt/anaconda3
#     execute bash ./extras/anacondaInstallScript.sh -f -b -p /opt/anaconda3
# 
#     spatialPrint "Setting up your anaconda"
#     execute /opt/anaconda3/bin/conda update conda -y
#     execute /opt/anaconda3/bin/conda clean --all -y
#     execute /opt/anaconda3/bin/conda install anaconda -y
#     execute /opt/anaconda3/bin/conda install ipython -y
# 
#     execute /opt/anaconda3/bin/conda install libgcc -y
#     execute /opt/anaconda3/bin/pip install numpy scipy matplotlib scikit-learn scikit-image jupyter notebook pandas h5py cython jupyterlab
#     execute /opt/anaconda3/bin/pip install msgpack
#     execute /opt/anaconda3/bin/conda install line_profiler -y
#     sed -i.bak "/anaconda3/d" ~/.zshrc
# 
#     /opt/anaconda3/bin/conda info -a
# 
#     spatialPrint "Adding anaconda to path variables"
#     {
#         echo "# Anaconda Python. Change the \"conda activate base\" to whichever environment you would like to activate by default"
#         echo ". /opt/anaconda3/etc/profile.d/conda.sh"
#         echo "conda activate base"
#     } >> ~/.zshrc
# 
# fi # Anaconda Installation end

# echo "*************************** NOTE *******************************"
# echo "If you ever mess up your anaconda installation somehow, do"
# echo "\$ conda remove anaconda matplotlib mkl mkl-service nomkl openblas"
# echo "\$ conda clean --all"
# echo "Do this for each environment as well as your root. Then reinstall all except nomkl"

# For utilities such as lspci
execute sudo apt install pciutils

## Detect if an Nvidia card is attached, and install the graphics drivers automatically if not already installed
if [[ -n $(lspci | grep -i nvidia) && ! $(command -v nvidia-smi) ]]; then
    spatialPrint "Installing Display drivers and any other auto-detected drivers for your hardware"
    execute sudo add-apt-repository ppa:graphics-drivers/ppa -y
    execute sudo apt update
    execute sudo ubuntu-drivers autoinstall
fi

spatialPrint "The script has finished. Please enter credentials to access your new shell"
if [[ ! -n $CIINSTALL ]]; then
    su - $USER
fi
