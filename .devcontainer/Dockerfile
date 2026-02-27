FROM mcr.microsoft.com/devcontainers/java:17-bullseye

# Instalar dependencias necesarias
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*

# Configurar variables de entorno
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV FLUTTER_HOME=/opt/flutter
ENV PATH=$PATH:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$FLUTTER_HOME/bin

# Instalar Android SDK Command-line tools
RUN mkdir -p $ANDROID_SDK_ROOT/cmdline-tools && \
    curl -o sdk.zip https://dl.google.com/android/repository/commandlinetools-linux-10406996_latest.zip && \
    unzip sdk.zip -d $ANDROID_SDK_ROOT/cmdline-tools && \
    rm sdk.zip && \
    mv $ANDROID_SDK_ROOT/cmdline-tools/cmdline-tools $ANDROID_SDK_ROOT/cmdline-tools/latest

# Aceptar licencias e instalar componentes necesarios
RUN yes | sdkmanager --licenses && \
    sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"

# Instalar Flutter
RUN git clone https://github.com/flutter/flutter.git -b stable $FLUTTER_HOME

# Configurar Flutter
RUN flutter config --no-analytics && \
    flutter doctor --android-licenses && \
    flutter doctor
