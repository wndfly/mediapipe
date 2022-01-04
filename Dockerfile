# Copyright 2019 The MediaPipe Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

FROM nvidia/cudagl:10.1-devel-ubuntu18.04

MAINTAINER <mediapipe@google.com>

WORKDIR /io
WORKDIR /mediapipe

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        gcc-8 g++-8 \
        ca-certificates \
        curl \
        ffmpeg \
        git \
        wget \
        unzip \
        python3-dev \
        python3-opencv \
        python3-pip \
        libopencv-core-dev \
        libopencv-highgui-dev \
        libopencv-imgproc-dev \
        libopencv-video-dev \
        libopencv-calib3d-dev \
        libopencv-features2d-dev \
        software-properties-common \
        python3-venv libprotobuf-dev protobuf-compiler cmake libgtk2.0-dev \
        mesa-common-dev libegl1-mesa-dev libgles2-mesa-dev mesa-utils \
        pkg-config libgtk-3-dev libavcodec-dev libavformat-dev libswscale-dev libv4l-dev \
        libxvidcore-dev libx264-dev libjpeg-dev libpng-dev libtiff-dev \
        gfortran openexr libatlas-base-dev python3-dev python3-numpy \
        libtbb2 libtbb-dev libdc1394-22-dev libcudnn8 libcudnn8-dev && \
    add-apt-repository -y ppa:openjdk-r/ppa && \
    apt-get update && apt-get install -y openjdk-8-jdk && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-8 100 --slave /usr/bin/g++ g++ /usr/bin/g++-8

ENV PATH=/usr/local/cuda/bin${PATH:+:${PATH}}
ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}
ENV TF_CUDA_PATHS=/usr/local/cuda,/usr/lib/x86_64-linux-gnu,/usr/include
RUN ldconfig

ENV HTTP_PROXY=http://192.168.2.33:1087
ENV HTTPS_PROXY=http://192.168.2.33:1087

RUN pip3 install --upgrade setuptools pip

RUN ln -s /usr/bin/python3 /usr/bin/python

# Install bazel
ARG BAZEL_VERSION=4.2.1
RUN mkdir /bazel && \
    wget --no-check-certificate -O /bazel/installer.sh "https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/b\
azel-${BAZEL_VERSION}-installer-linux-x86_64.sh" && \
    wget --no-check-certificate -O  /bazel/LICENSE.txt "https://raw.githubusercontent.com/bazelbuild/bazel/master/LICENSE" && \
    chmod +x /bazel/installer.sh && \
    /bazel/installer.sh  && \
    rm -f /bazel/installer.sh

COPY . /mediapipe/

WORKDIR /mediapipe/

RUN rm -rf /mediapipe/mediapipe/examples/ && \
    pip3 install -r requirements.txt && \
    python setup.py build --link-opencv && \
    python setup.py gen_protos && \
    python setup.py install --link-opencv && \
    rm -rf /root/.cache && \
    rm -rf /mediapipe/

ENV HTTP_PROXY=
ENV HTTPS_PROXY=

WORKDIR /

# If we want the docker image to contain the pre-built object_detection_offline_demo binary, do the following
# RUN bazel build -c opt --define MEDIAPIPE_DISABLE_GPU=1 mediapipe/examples/desktop/demo:object_detection_tensorflow_demo
