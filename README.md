# Targeted-Illumination-Microscopy (TIM)

Welcome to Northeastern Wormneurolab's Target Illumination Microscopy! Please visit us if you are interested in our works https://chung-lab.sites.northeastern.edu/.

The TIM paper is currently on https://onlinelibrary.wiley.com/doi/10.1002/lpor.202501980, featured as the back cover. We hope you love this cartoonish drawing of an optical microscopy concept!

<img width="1653" height="2173" alt="image" src="https://github.com/user-attachments/assets/dcab4997-eec4-4b42-9fd6-76fa9f2f9dba" />


In widefield fluorescence imaging, out-of-focus and scattered light from the bright cell body often obscures nearby dim fibers and degrades their contrast. Scanning techniques can solve this problem, but are limited by reduced imaging speed and increased cost. We greatly reduce stray light in widefield imaging by modulating the illumination intensity to different structures. We identify fibers by real-time iterated image processing, and target illumination to fibers by a digital micromirror device add-on to a common widefield microscope. We illuminate bright cell bodies with minimal light intensity and in-focus fibers with high light intensity. This procedure minimizes the background and enhances the visibility of fibers while maintaining a fast-imaging speed and low cost. 

In this repository, we show the codes we used to control a Nikon Ti2 inverted microscope, a Hamamatsu fusion BT sCMOS camera, and a DLi900 DMD (digital micromirror device, https://dlinnovations.com/products/dli9000-9-wqxga-development-kit/, and any other DMD including projector extracted DMD will also work) for performing TIM.

Always use the LiveHamWithDMD.m first to locate the imaging area and know your sample. It also helps in setting up some parameters that the later TIM needs.
Use TIM_2D for a simple and single 2D image. This will generate a typical widefield and the TIM image.
Use TIM_3D for Z stack image. This will generate a typical widefield Z stack and the TIM Z stack image.
Use TIM_2D_ActivityTracking if you only need 2D tracking of your sample over a period when it is moving or changing over time. 

Note that the code is intended solely for demonstrating our TIM concept and is not optimized for computational efficiency or broad compatibility. 

![image](https://github.com/wormneurolab/Targeted-Illumination-Microscopy/assets/73413475/db961494-074b-41ad-b8da-f6855a30163b)

Contributors:
1. Yao L. Wang, ywang07@rockefeller.edu
2. Jia Fan, jia.fan2@case.edu
3. Tina T.N. Hoang, nguyenhoang.t@northeastern.edu
