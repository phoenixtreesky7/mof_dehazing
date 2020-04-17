# Introduction of mof_dehaizng

This is a Matlab re-implementation of the paper.

**Multi-scale Optimal Fusion Model for Single Image Dehazing**

Dong Zhao, Long Xu, Yihua Yan, Jie Chen, Lingyu Duan

This work has been accepted by journal Signal Processing: Image Communication, 2019. This paper can be download from:

https://www.sciencedirect.com/science/article/abs/pii/S0923596518308804 .

If you have any interesting problems on our work, we sincerely welcome your valuable advise, and you can email us by:

lxu@nao.cas.cn | dzhao@nao.cas.cn | zhaodong_biti@163.com

# Abstract

Image acquisition is usually vulnerable to bad weathers, like haze, fog and smoke. Haze removal, namely dehazing has always been a great challenge in many fields. This paper proposes an efficient and fast dehazing algorithm for addressing transmission map misestimation and oversaturation commonly happening in dehazing. We discover that the transmission map is commonly misestimated around the edges where grayscale change abruptly. These Transmission MisEstimated (TME) edges further result in halo artifacts in patch-wise dehazing. Although pixel-wise method is free from halo artifacts, it has trouble with oversaturation. Therefore, we firstly propose a TME recognition method to distinguish TME and non-TME regions. Secondly, we propose a Multi-scale Optimal Fusion (MOF) model to fuse pixel-wise and patch-wise transmission maps optimally to avoid misestimated transmission region. This MOF is then embedded into patch-wise dehazing to suppress halo artifacts. Furthermore, we provide two post-processing methods to improve robustness and reduce computational complexity of the MOF. Extensive experimental results demonstrate that, the MOF can achieve additional improvement beyond the prototypes of the benchmarks; in addition, the MOF embedded dehazing algorithm outperforms most of the state-of-the-arts in single image dehazing. For implementation details, source codec can be accessed via https://github.com/phoenixtreesky7/mof_dehazing. 

# Model of the MOF Dehazing


 ![model of TME](https://github.com/phoenixtreesky7/mof_dehazing/raw/master/figures/TME_model1.png)

 ![model of MOF](https://github.com/phoenixtreesky7/mof_dehazing/raw/master/figures/TME_costfunctionmodel.png)


 ![hazy image](https://github.com/phoenixtreesky7/mof_dehazing/raw/master/figures/3.png)  ![mof dehazed image](https://github.com/phoenixtreesky7/mof_dehazing/raw/master/figures/MSpipa_3J.png)

 ![zoom in](https://github.com/phoenixtreesky7/mof_dehazing/raw/master/figures/MSpipa_3Jzoomin.png)

# Implementation 

Add all file paths into MATLAB.

Then, run the code mof_demo.m

# BibTeX

@article{zhao2019multi,
  title={Multi-scale Optimal Fusion model for single image dehazing},
  author={Zhao, Dong and Xu, Long and Yan, Yihua and Chen, Jie and Duan, Ling-Yu},
  journal={Signal Processing: Image Communication},
  volume={74},
  pages={253--265},
  year={2019},
  publisher={Elsevier}
}
