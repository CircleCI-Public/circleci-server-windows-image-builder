#  Example Packer Config For building Windows On CircleCI

This folder contains everything you will need to build a Windows image, with the CircleCI dsc resources, on CircleCI. For more information on setting up VM service, which includes specifying your new Windows image for your users, see our [VM Service guide](https://circleci.com/docs/2.0/vm-service/#section=server-administration).

## Setting up on CircleCI
[Add your aws keys as env vars](https://circleci.com/docs/2.0/contexts/) to the build in the CircleCI using:
  * AWS_ACCESS_KEY_ID	    
  * AWS_DEFAULT_REGION		
  * AWS_SECRET_ACCESS_KEY

Update the owner in `windows/visual-studio/packer.yaml` if you configured the keys under a different account to the once your Circleci Server installation is under.

## What the packer job in this build does
* Sets up winrm.
* Adds scripts for removing winrm when we are ready to clean up.
* Copies over ImageHelpers and CircleDSCResources to the powershell module path.
* Runs some configuration to get the machine ready to use DSC and clean up some defaults that are not helpful.
* Runs DSC and restarts the machine a few times to let it continue through the configuration process.
* Runs Pester tests to validate that the image is configured correctly. These tests are designed to ensure that all of the software is actually callable not just “installed”.
* Reenables Windows Defender and runs the virus scanner. 
* Disables Windows Defender to improve performance.
* Copies: test results, the choco logs, and the software.md (a list of everything we install and test for the presence of) off of the host.
* Installs the SSH server and enables the cleanup script that runs on shutdown (check out the aws packer scripts for exactly *how* that works).
* Creates a Windows AMI.


