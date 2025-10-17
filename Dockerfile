FROM ubuntu:24.04

# Install necessary tools
RUN apt-get update && apt-get install -y \
    dmg2img \
    p7zip-full
