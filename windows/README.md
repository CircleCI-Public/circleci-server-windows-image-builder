# Quick rundown of the windows infra

The “ImageHelpers” folder are a set of powershell helper functions we pulled from the Azure pipeline image generation repo. They build a windows image much like we do for Azure pipelines.

The “default”,  “nvidia”, and “visual-studio” folders are various flavours of Windows images we currently offer. It’s likely that the “default” image will no longer exist in the future. More on each of these images later.

The “provision-scripts” folder contains a number of powershell scripts broken into software components.

The "CircleCIDSCResources" repo contains automation objects that tell windows how it should configure it's self for us. These are being migrated to https://github.com/CircleCI-Public/CircleCIDSC


## Custom Docker registry mirror

You may want to set up [a custom Docker registry mirror](https://docs.docker.com/registry/recipes/mirror/) within this Windows AMI.

To do so, you can simply:

1. Uncomment the specific code sections in packer.yaml file.
   * Look up the `# Uncomment below to enable Docker registry mirror` text.
2. Replace https://mirror.gcr.io with your custom registry's URL.
3. Ensure that this custom registry URL will will accessible for the Windows VM instances.
