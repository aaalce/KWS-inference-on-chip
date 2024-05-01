KWS inference on chip
=

This document is a simple outline for our RISC-V based KWS accelerator. <br>
Fixed-point arithmetic is adopted as a trade-off between project size and inference performance. 
Quantisation from 32 bits floating-point to 4 bits fixed-points is further used to adapt the project size.
All buffers are connected through wishbone bus to Caravel SRAM. The input features and weights are initialized to the Caravel RAM by the RISC-V CPU.<br>

To save chip area and cost, we will adopt a small-scale MAC array and small-capacity on-chip buffers for CNN computation 
The major components include <br>
	1. A finite state machine as a **controller** for fetching instructions and orchestrating other modules <br>
	2. A **filterbank** for feature extraction <br>
(CNN component below)<br>
    3.**Nomalisation pool** <br>
    4.Seperate **buffers** for caching input features, weights, and output features,  <br>
    5.A **Matrix module** to flatten and rearrange the input features into feature matrices compatible with the MAC array  <br>
    6.A multiply-and-accumulate (**MAC**) **array** is adopted to **compute matrix multiplications**. <br>
    7.A **Add unit** (array)for element-wise sum layers <br>
    8.A **Mutiply unit** (array)for element-wise product layers <br>
    9.A **Sumlayer unit** for calculating sum in fully-connected layers <br>
    10.A **ReLU Activation Unit** is implemented with a comparator <br>
    11.A **Sigmoid Activation Unit** via piecewise linear or lookup table approach <br>
    12.Weight **FIFOs** for matrix data flow during computing matrix multiplications.<br>

# Caravel User Project

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0) [![UPRJ_CI](https://github.com/efabless/caravel_project_example/actions/workflows/user_project_ci.yml/badge.svg)](https://github.com/efabless/caravel_project_example/actions/workflows/user_project_ci.yml) [![Caravel Build](https://github.com/efabless/caravel_project_example/actions/workflows/caravel_build.yml/badge.svg)](https://github.com/efabless/caravel_project_example/actions/workflows/caravel_build.yml)

| :exclamation: Important Note            |
|-----------------------------------------|

## Please fill in your project documentation in this README.md file 

Refer to [README](docs/source/index.rst#section-quickstart) for a quickstart of how to use caravel_user_project

Refer to [README](docs/source/index.rst) for this sample project documentation. 

Refer to the following [readthedocs](https://caravel-sim-infrastructure.readthedocs.io/en/latest/index.html) for how to add cocotb tests to your project. 
