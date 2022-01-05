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
    build-essential gcc-8 g++-8 ca-certificates curl git wget unzip \
    libopencv-core-dev libopencv-highgui-dev libopencv-imgproc-dev \
    libopencv-video-dev libopencv-calib3d-dev libopencv-features2d-dev \
    software-properties-common \
    libprotobuf-dev protobuf-compiler cmake libgtk2.0-dev \
    mesa-common-dev libegl1-mesa-dev libgles2-mesa-dev mesa-utils \
    pkg-config libgtk-3-dev libavcodec-dev libavformat-dev libswscale-dev libv4l-dev \
    libxvidcore-dev libx264-dev libjpeg-dev libpng-dev libtiff-dev \
    gfortran openexr libatlas-base-dev python3-dev python3-numpy \
    libtbb2 libtbb-dev libdc1394-22-dev libcudnn8 libcudnn8-dev \
    netbase autoconf automake bzip2 dpkg-dev file imagemagick libbz2-dev libc6-dev \
    libcurl4-openssl-dev libdb-dev libevent-dev libffi-dev libgdbm-dev libglib2.0-dev \
    libgmp-dev libkrb5-dev liblzma-dev libmagickcore-dev libmagickwand-dev \
    libmaxminddb-dev libncurses5-dev libncursesw5-dev libpq-dev libreadline-dev \
    libsqlite3-dev libssl-dev libtool libwebp-dev libxml2-dev libxslt-dev libyaml-dev make \
    patch xz-utils zlib1g-dev libbluetooth-dev tk-dev uuid-dev libopus-dev libopus0 opus-tools \
    apt-transport-https gnupg dirmngr nasm zip yasm libvpx-dev locales libgdiplus && \
    add-apt-repository -y ppa:openjdk-r/ppa && \
    apt-get update && apt-get install -y openjdk-8-jdk && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-8 100 --slave /usr/bin/g++ g++ /usr/bin/g++-8

ENV HTTP_PROXY=http://192.168.2.33:1087
ENV HTTPS_PROXY=http://192.168.2.33:1087
ENV PATH=/usr/local/cuda/bin${PATH:+:${PATH}}
ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}
ENV TF_CUDA_PATHS=/usr/local/cuda,/usr/lib/x86_64-linux-gnu,/usr/include
RUN ldconfig

# install python
ENV GPG_KEY=A035C8C19219BA821ECEA86B64E628F8D684696D
ENV PYTHON_VERSION=3.10.1
RUN wget -O python.tar.xz \
    "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz" && \
    wget -O python.tar.xz.asc \
    "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz.asc" && \
    export GNUPGHOME="$(mktemp -d)" && \
    gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys "$GPG_KEY" && \
    gpg --batch --verify python.tar.xz.asc python.tar.xz && \
    { command -v gpgconf > /dev/null && gpgconf --kill all || :; } && \
    rm -rf "$GNUPGHOME" python.tar.xz.asc && mkdir -p /usr/src/python && \
    tar -xJC /usr/src/python --strip-components=1 -f python.tar.xz && \
    rm python.tar.xz && cd /usr/src/python && \
    gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" && \
    ./configure \
    --build="$gnuArch" \
    --enable-loadable-sqlite-extensions \
    --enable-optimizations \
    --enable-option-checking=fatal \
    --enable-shared \
    --with-lto \
    --with-system-expat \
    --with-system-ffi \
    --without-ensurepip && \
    make -j "$(nproc)" && make install && \
    rm -rf /usr/src/python && \    
    ldconfig && python3 --version

# install FFmpeg
RUN git clone https://git.ffmpeg.org/ffmpeg.git --config "http.proxy=${HTTP_PROXY}" && \
    cd ffmpeg && \
    git checkout n4.4 && \
    ./configure \
    --prefix=/usr \
    --disable-debug \
    --disable-doc \
    --disable-programs \
    --disable-stripping \
    --enable-avresample \
    --enable-lto \
    --enable-gpl \
    --enable-libx264 \
    --enable-shared \
    --enable-version3 \
    --disable-alsa \
    --disable-bzlib \
    --disable-iconv \
    --disable-libxcb \
    --disable-amf \
    --disable-lzma \
    --disable-sndio \
    --disable-sdl2 \
    --disable-xlib \
    --disable-zlib \
    --disable-audiotoolbox \
    --disable-cuda-llvm \
    --disable-cuvid \
    --disable-ffnvcodec \
    --disable-nvdec \
    --disable-nvenc \
    --disable-v4l2-m2m \
    --disable-vaapi \
    --disable-vdpau \
    --disable-videotoolbox && \
    make -j "$(nproc)" && \
    make install && \
    cd .. && \
    rm -rf ffmpeg

RUN ln -s /usr/local/bin/idle3 /usr/bin/idle && \
    ln -s /usr/local/bin/pydoc3 /usr/bin/pydoc && \
    ln -s /usr/local/bin/python3 /usr/bin/python && \
    ln -s /usr/local/bin/python3-config /usr/bin/python-config

# install pip
RUN python -m ensurepip --upgrade
# ENV PYTHON_PIP_VERSION=21.2.4
# ENV PYTHON_SETUPTOOLS_VERSION=57.5.0
# ENV PYTHON_GET_PIP_URL=https://github.com/pypa/get-pip/raw/3cb8888cc2869620f57d5d2da64da38f516078c7/public/get-pip.py
# ENV PYTHON_GET_PIP_SHA256=c518250e91a70d7b20cceb15272209a4ded2a0c263ae5776f129e0d9b5674309

# RUN wget -O get-pip.py "$PYTHON_GET_PIP_URL" && \
#     echo "$PYTHON_GET_PIP_SHA256 *get-pip.py" | sha256sum --check --strict - && \
#     python get-pip.py --disable-pip-version-check --no-cache-dir "pip==$PYTHON_PIP_VERSION" \
#     "setuptools==$PYTHON_SETUPTOOLS_VERSION" && pip --version && \
#     find /usr/local -depth \(	\( -type d -a \( -name test -o -name tests -o -name idle_test \) \) \
#     -o \( -type f -a \( -name '*.pyc' -o -name '*.pyo' \) \) \) -exec rm -rf '{}' + && \
#     rm -f get-pip.py

# Install bazel
# ARG BAZEL_VERSION=4.2.1
# RUN mkdir /bazel && \
#     wget --no-check-certificate -O /bazel/installer.sh "https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/b\
# azel-${BAZEL_VERSION}-installer-linux-x86_64.sh" && \
#     wget --no-check-certificate -O  /bazel/LICENSE.txt "https://raw.githubusercontent.com/bazelbuild/bazel/master/LICENSE" && \
#     chmod +x /bazel/installer.sh && \
#     /bazel/installer.sh  && \
#     rm -f /bazel/installer.sh
COPY bazel-4.2.1-installer-linux-x86_64.sh /installer.sh

RUN mkdir /bazel && mv /installer.sh /bazel/installer.sh && \
    chmod +x /bazel/installer.sh && \
    /bazel/installer.sh  && \
    rm -f /bazel/installer.sh    
#RUN npm install -g @bazel/bazelisk

COPY . /mediapipe/

WORKDIR /mediapipe/

RUN rm -rf /mediapipe/mediapipe/examples/ && \
    pip3 install -r requirements.txt && \
    python setup.py build_py --link-opencv && \
    python setup.py gen_protos && \
    python setup.py install --link-opencv && \
    rm -rf /root/.cache && \
    rm -rf /mediapipe/

ENV HTTP_PROXY=
ENV HTTPS_PROXY=

WORKDIR /

# If we want the docker image to contain the pre-built object_detection_offline_demo binary, do the following
# RUN bazel build -c opt --define MEDIAPIPE_DISABLE_GPU=1 mediapipe/examples/desktop/demo:object_detection_tensorflow_demo
