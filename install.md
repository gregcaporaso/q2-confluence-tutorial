# Creating the environment

🛠️ Install the QIIME 2 2026.10 distribution by following the instructions at [install.qiime2.org](https://install.qiime2.org); they create a conda environment named `rachis-qiime2-2026.10`.
Then add sylph and the two plugins to that environment with this repository's extras file:

```shell
wget https://raw.githubusercontent.com/gregcaporaso/q2-confluence-tutorial/main/environment-files/q2-confluence-tutorial-extras.yml

conda env update \
  -n rachis-qiime2-2026.10 \
  --file q2-confluence-tutorial-extras.yml

conda activate rachis-qiime2-2026.10

qiime dev refresh-cache
qiime confluence --help
qiime sylph --help
```

Both plugin repositories are public; the download of the extras file needs GitHub credentials while this repository is private.
