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
  && sdkmanager "platforms;android-34" "build-tools;34.0.0" "platform-tools"

WORKDIR /app
COPY ./application /app

# Ensure gradlew is executable
RUN chmod +x ./gradlew

# Build the project
RUN ./gradlew build --no-daemon

VOLUME /app/app/build/outputs/apk/

#CMD ["./gradlew", "assembleDebug"]

ENV KEYSTORE_PASSWORD="your_KEYSTORE_PASSWORD"
ENV KEY_ALIAS="my-key-alias"
ENV KEY_PASSWORD="your_KEY_PASSWORD"
RUN keytool -genkey -v -keystore ~/my-release-key.keystore -keyalg RSA -keysize 4096 -validity 10000 -alias "$KEY_ALIAS"

CMD ["./gradlew", "assembleRelease"]
