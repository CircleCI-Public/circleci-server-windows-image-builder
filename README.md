#  Example Packer Config For building windows On CircleCI

This folder contains everythign you will need to build a windows image with the circleCI dsc resources on circleCI.


## To Setup on circleCI
Add your aws keys as env vars to the build job in the CircleCI using:
  * AWS_ACCESS_KEY_ID	    
  * AWS_DEFAULT_REGION		
  * AWS_SECRET_ACCESS_KEY
U&pdate the owner in `windows/visual-studio/packer.yaml` if the account that the keys that you configured not shared with the account your circleci server deploy is in.

## What the packer job in this build does
* Sets up winrm
* Adds scripts for removing winrm when we are ready to clean up
* Copies over ImageHelpers and CircleDSCResources to the powershell module path.
* Runs some configuration to get the machine ready to use DSC and clean up some defaults that are not helpful.
* Runs DSC and restarts the machine a few time to let it continue through configuration process.
* Runs Pester tests to validate that the image is configured correctly. These tests are designed to actually ensure that all of the software the customers are actually callable not just “installed”
* Reenables Windows Defender and runs the virus scanner. 
* Disables windows defender to make a much more performant experience for customers.
* Copies: test results, the choco logs, and the software.md (a list of everything we install and test for the presence of) off of the host.
* Installs the SSH server and enables the cleanup script that runs on shutdown (check out the aws packer scripts for exactly *how* that works).
* Creates an image.


