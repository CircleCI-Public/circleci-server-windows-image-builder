# Quick rundown of the windows infra

The “ImageHelpers” folder are a set of powershell helper functions we pulled from the Azure pipeline image generation repo. They build a windows image much like we do for Azure pipelines.

The “default”,  “nvidia”, and “visual-studio” folders are various flavours of Windows images we currently offer. It’s likely that the “default” image will no longer exist in the future. More on each of these images later.

The “provision-scripts” folder contains a number of powershell scripts broken into software components.

The "CircleCIDSCResources" repo contains automation objects that tell windows how it should configure it's self for us. These are being migrated to https://github.com/CircleCI-Public/CircleCIDSC
