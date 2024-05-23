

<h3 align="center">KWS inference on chip</h3>

  <p align="center">
    This project focuses on implementing Keyword Spotting (KWS) inference on a chip. 

Keyword Spotting Task is a classification Task: KWS aims to classify input signals to detect the presence or absence of specific keywords, such as "Hey Snips," in real-time.
    <br />
    <a href="https://github.com/github_username/repo_name"><strong>Explore the docs »</strong></a>

  </p>
</div>


<!-- ABOUT THE PROJECT -->
## Our Scope
General KWS Pipeline: The pipeline includes stages from the initial speech signal to the final decision.

Our Scope: We focus on the stages of the keyword spotting acoustic model right after feature extraction, ending just before posterior handling.

![alt text](http://url/to/img.png)

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- GETTING STARTED -->
## Hardware modules


### Overview


This is a simple outline for our RISC-V based KWS accelerator. 

Fixed-point arithmetic is adopted to simplify the hardwar design. To preserve the the fractional part of the data, we converted our weights and inputs to 32 bits fixed-point 1.7.24 format.That is 1 Sign bit, 7 bits for the integer part, 24 bits for the fractional part.

The input features and weights are initialized on the SRAM inside the user project area.<br>

The major components include <br>
	1. A finite state machine as a **controller** for fetching instructions and orchestrating other modules <br>
(CNN component below)<br>
    2.**CMVN pool** Cepstral mean and variance normalization pool. The input data is normalized and flattened here. <br>
    3.**Linear module** is adopted to **compute matrix multiplications** between two matrices of 50x20 and 20x20 for linear transformation. <br>
    4.**ReLU function module** to perform ReLU function <br> <br>
    5.**Dilated CNN module** to perform CNN with systolic array (to be tested) <br>
    6.**Batch normalize module** to be tested) <br>
    7.**Sigmoid Activation module** (to be tested) <br>

Our weights are store in 2 4kb SRAMs from Efabless marketplace

### Model


### Data
We use the "Hey Snips" dataset, which includes various voice commands from different speakers, providing a robust dataset for training. This dataset contains thousands of audio samples of different keywords, recorded by multiple speakers, including background noise and variations in speech patterns.

### Feature Extraction
Filter Bank: We use filter bank feature extraction to transform raw speech signals into a format suitable for the model. Filter banks decompose the signal into different frequency components, highlighting relevant features for speech recognition .After the filter bank, we padding the data so that it comes out the same size in each dimension.

### Structure
The model consists of multiple layers: CMVN (Cepstral Mean and Variance Normalization), linear layers, ReLU activations, and dilated CNN blocks (repeated four times). Each dilated CNN block is followed by batch normalization and ReLU activations. The final layers include a linear layer and a sigmoid activation for binary classification.

### Why Dilated CNN 
Dilated Convolutional Neural Networks (CNNs) are chosen for their ability to handle temporal dependencies in speech signals. They capture features over larger time scales without significantly increasing computational load, making them ideal for real-time keyword spotting on limited-resource hardware.
<!-- USAGE EXAMPLES -->

## Working process: 
### Model Training:

Train the deep learning model using the prepared dataset. This involves data preprocessing, model selection, and optimization to ensure high accuracy in keyword detection.

Implementation in Python with pure tensor:
Implement the trained model in a Python environment, ensuring it is free from external library dependencies. This makes integration with hardware more straightforward.

### Weight Extraction:
Extract the model weights after the Python implementation. These weights are crucial for deploying the model on hardware.

### Implementation in Verilog:
Translate the Python implementation and extracted weights into Verilog for hardware implementation. This step involves designing the hardware description language suitable for chip design.

By implementing KWS inference on a chip, we aim to create a low-latency, efficient system capable of recognizing voice commands in real-time. This project leverages the latest advancements in deep learning and practical hardware implementation techniques to develop responsive and intelligent voice-controlled devices.


<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- ROADMAP -->
## Roadmap
   **Dilated CNN module** to perform CNN with systolic array (to be tested) <br>
**Batch normalize module** to be tested) <br>
    **Sigmoid Activation module** (to be tested) <br>

See the [open issues](https://github.com/github_username/repo_name/issues) for a full list of proposed features (and known issues).

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- CONTRIBUTING -->
## Contributing


<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- LICENSE -->
## License

Distributed under the MIT License. See `LICENSE.txt` for more information.

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- CONTACT -->
## Some personal thoughts

In 2023 me and my friend(Hongzhi Hou, the other author of the project) was stunned by power of LLM that transformed human learning. We decided to each learn a random skill with LLM from scratch as a fun experiment. In March 2024 I accidentally came across this challenge, picking IC design, as my target. It is something I was alway curious about but felt intimidated due to its complexity. The challenge provided a perfect start with real project and goals, it also accelerated my learning by giving it a time constraint with pressure. The real difficulties from this exercise was to decide, which direction i should go, what shall I focus on when **everything** is unknown. 

Throughout the journey, I have a few findings about LLM.

1 LLM might be perfect for debugging and spotting details we miss, it lacks of logic when a real concept needs to be applied. One of the things I spent the most time doing was to explain to Claude what Matrix Multiplication is, and how shall it be done in a data stream like ours. In the beginning I wasn’t aware it doesn’t truly ‘understand’, because it can explain matrix multiplication in perfect sentences. After realising its shortcomings, I have spent substantial amount of time, giving examples to it how the calculation and data selection logic should work, Claude seemed to understand after some examples, and gave back the correct answers if I ask in hypothetical terms, but it would be unable to produce the correct Verilog logic, unable to match everything on the correct cycle, unless I explicitly stated. Nor spot the apparent mistakes such as the wrong dimensions of the output matrix.

2 It taught me through repetitively asking and spotting mistakes, at a very fast pace(fast response), by efficiently reducing search time. At the beginning I was completely lost, at the end of the challenge I was able to read Verilog, do some debugging on my own, and have a hunch what went wrong. It also training me to talk to (and ignore) LLM more efficient and effectively.

3 LLM is pretty bad as maths. Basic arithmetic. I wouldn’t trust their answers if the numbers get big or equations gets long. 

4 They get stuck in loops sometimes, so you need to either feed it some radically new information or open a new chat. 

5 They will give you relatively similar answers, or designs in this case, for a KWS accelerator, across several LLM. Unless you start to read papers or get information elsewhere, they won’t give you anything ‘new’. Therefore I’m skeptical about its ability to create- or let’s say, innovate. 


<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- ACKNOWLEDGMENTS -->
## Acknowledgments

* []()
* []()
* []()

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->
[contributors-shield]: https://img.shields.io/github/contributors/github_username/repo_name.svg?style=for-the-badge
[contributors-url]: https://github.com/github_username/repo_name/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/github_username/repo_name.svg?style=for-the-badge
[forks-url]: https://github.com/github_username/repo_name/network/members
[stars-shield]: https://img.shields.io/github/stars/github_username/repo_name.svg?style=for-the-badge
[stars-url]: https://github.com/github_username/repo_name/stargazers
[issues-shield]: https://img.shields.io/github/issues/github_username/repo_name.svg?style=for-the-badge
[issues-url]: https://github.com/github_username/repo_name/issues





[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0) [![UPRJ_CI](https://github.com/efabless/caravel_project_example/actions/workflows/user_project_ci.yml/badge.svg)](https://github.com/efabless/caravel_project_example/actions/workflows/user_project_ci.yml) [![Caravel Build](https://github.com/efabless/caravel_project_example/actions/workflows/caravel_build.yml/badge.svg)](https://github.com/efabless/caravel_project_example/actions/workflows/caravel_build.yml)

| :exclamation: Important Note            |
|-----------------------------------------|

## Please fill in your project documentation in this README.md file 

Refer to [README](docs/source/index.rst#section-quickstart) for a quickstart of how to use caravel_user_project

Refer to [README](docs/source/index.rst) for this sample project documentation. 

Refer to the following [readthedocs](https://caravel-sim-infrastructure.readthedocs.io/en/latest/index.html) for how to add cocotb tests to your project. 
