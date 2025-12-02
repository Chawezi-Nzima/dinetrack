FROM ubuntu:22.04

# Install Flutter dependencies
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
    && rm -rf /var/lib/apt/lists/*

# Clone Flutter
RUN git clone https://github.com/flutter/flutter.git /usr/local/flutter
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:$PATH"

# Enable Flutter web
RUN flutter channel stable
RUN flutter config --enable-web

# Set working directory
WORKDIR /app

# Copy project files
COPY . .

# Get dependencies and build
RUN flutter pub get
RUN flutter build web --release
