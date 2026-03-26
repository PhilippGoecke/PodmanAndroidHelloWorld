podman build --no-cache --rm --file Containerfile --tag android:demo .
podman run --interactive --tty --volume ./build/:/app/app/build/outputs/apk/ android:demo
# adb install build/release/app-release-unsigned.apk
