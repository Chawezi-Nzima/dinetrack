# Base image
FROM ubuntu:22.04

# Install dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    libgtk-3-0 \
    libblkid-dev \
    liblzma-dev \
    libgl1-mesa-glx \
    libgl1-mesa-dev \
    libc6-dev \
    ncurses-bin \
    build-essential \
    python3 \
    python3-pip \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -ms /bin/bash flutteruser
USER flutteruser
WORKDIR /home/flutteruser

# Add Flutter to PATH
RUN git clone https://github.com/flutter/flutter.git /home/flutteruser/flutter
ENV PATH="/home/flutteruser/flutter/bin:/home/flutteruser/flutter/bin/cache/dart-sdk/bin:$PATH"

# Enable Flutter web
RUN flutter channel stable
RUN flutter config --enable-web

# Copy project files
COPY --chown=flutteruser:flutteruser . .

# Get dependencies and build
RUN flutter pub get
RUN flutter build web --release
