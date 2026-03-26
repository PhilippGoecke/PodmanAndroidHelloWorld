FROM debian:trixie-slim as install

ARG DEBIAN_FRONTEND=noninteractive

# install dependencies
RUN apt update && apt upgrade -y \
  && apt install -y --no-install-recommends --no-install-suggests openjdk-21-jdk wget unzip git curl ca-certificates build-essential lib32stdc++6 lib32z1 \
  && cat /etc/apt/sources.list.d/debian.sources && sed -i 's/main/main contrib non-free/g' /etc/apt/sources.list.d/debian.sources && apt update \
  && apt install -y --no-install-recommends --no-install-suggests google-android-cmdline-tools-19.0-installer \
  && rm -rf "/var/lib/apt/lists/*" \
  && rm -rf /var/cache/apt/archives

ENV JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
ENV ANDROID_HOME=/usr/lib/android-sdk

RUN yes | sdkmanager --licenses \
  && sdkmanager "platforms;android-36" "build-tools;36.0.0" "platform-tools"

# Override these at build time via --build-arg to avoid baking default passwords into the image
ARG KEYSTORE_PASSWORD="your_KEYSTORE_PASSWORD"
ARG KEY_ALIAS="my-key-alias"
ARG KEY_PASSWORD="your_KEY_PASSWORD"

ENV KEYSTORE_PATH=/root/my-release-key.keystore
ENV KEYSTORE_PASSWORD=$KEYSTORE_PASSWORD
ENV KEY_ALIAS=$KEY_ALIAS
ENV KEY_PASSWORD=$KEY_PASSWORD

# Generate self-signed keystore non-interactively
RUN keytool -genkey -v \
  -keystore "$KEYSTORE_PATH" \
  -keyalg RSA -keysize 4096 -validity 10000 \
  -alias "$KEY_ALIAS" \
  -dname "CN=Android, OU=Android, O=Android, L=Unknown, ST=Unknown, C=US" \
  -storepass "$KEYSTORE_PASSWORD" \
  -keypass "$KEY_PASSWORD" \
  -noprompt

WORKDIR /app
COPY ./application /app

# Ensure gradlew is executable
RUN chmod +x ./gradlew

VOLUME /app/app/build/outputs/apk/release/

# Build the signed release APK; runs at container start so output is written to the mounted volume
CMD ["./gradlew", "assembleRelease", "--no-daemon"]
