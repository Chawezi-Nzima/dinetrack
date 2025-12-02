# Use Ubuntu 22.04 as base
FROM ubuntu:22.04

# Install dependencies including tput (ncurses-bin)
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    ncurses-bin \
    build-essential \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Install Flutter
RUN git clone https://github.com/flutter/flutter.git /usr/local/flutter
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:$PATH"

# Enable Flutter web
RUN flutter channel stable && flutter upgrade
RUN flutter config --enable-web

# Set working directory inside container
WORKDIR /app

# Copy project files from local machine into container
COPY . .

# Get dependencies and build Flutter web
RUN flutter pub get
RUN flutter build web --release
