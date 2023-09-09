
# Characterization of QIIME 2 with Intel Technology on-premises and in Microsoft Azure Cloud


## Table of Contents

- [Project Name](#project-name)
  - [Table of Contents](#table-of-contents)
  - [Description](#description)
  - [Getting Started](#getting-started)
    - [Prerequisites](#prerequisites)
    - [Installation](#installation)
  - [Usage](#usage)
  - [Contributing](#contributing)
  - [License](#license)
  - [Acknowledgments](#acknowledgments)

## Description

This study assessed the performance of QIIME 2 for analysis on both local clusters and Microsoft Azure. It found that Intel multithreading was more efficient than hyperthreading, but efficiency dropped as the number of processors increased due to sequential tasks. These findings offer insights for resource optimization in cluster and cloud computing, especially for resource-intensive applications like metagenome analysis.

## Getting Started

Performance data collection was conducted using the Vtune Command as follows:

echo "uarch-exploration_c_01_ht-on_r1_240" vtune -c uarch-exploration -data-limit=0 -result-dir /home/vtune/uarch-exploration_c_01_ht_on_r1_240 -- python vtunes.py

To change the number of processors according to whether it was MT (20) or HT (40), zero (0) was used to deactivate and one (1) to activate the option to change the number of cores:

I. sudo bash -c 'echo 0 > /sys/devices/system/cpu/cpu(core number)/online'
II. sudo bash -c 'echo 1 > /sys/devices/system/cpu/cpu(core number)/online'

Finally, the following command was used to execute the SDE in the collection of the instruction histogram on-prem in the CICIMA cluster (Intel, 2023):

I. path-to-kit/sde -mix -iform -- user-application [args]

### Prerequisites
 - Python
 - Intel VTUNE
 - AZURE Monitor
 - INTEL SDE Performance Tool

