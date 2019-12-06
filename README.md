#  Example Packer Config For building Windows On CircleCI

This folder contains everything you will need to build a Windows image, with the CircleCI dsc resources, on CircleCI. For more information on setting up VM service, which includes specifying your new Windows image for your users, see our [VM Service guide](https://circleci.com/docs/2.0/vm-service/#section=server-administration).

## Building a Windows Image to use with `machine` Executor
The following steps will guide you through building a Windows AMI, which you can then specify in the VM Service settings for your installation of CircleCI Server, letting users of your installation run their builds in a Windows environment.

Please note Windows images are built on CircleCI, so we suggest you run through this process once your installation is up and running. Alternatively you can use any other CircleCI account – including on our managed Cloud service – to generate the image:

1. Create a new repository under your GitHub or GitHub Enterprise account.

2. Copy the contents of this repo into your new repo.

3. Open up your installation of CircleCI Server and [connect your new repo](https://circleci.com/docs/2.0/getting-started/#setting-up-your-build-on-circleci) by clicking Follow Project from the Add Projects page. Once you set up the project, the first build will get triggered automatically. It will fail because the AWS credentials are not configured yet — feel free to cancel the first build that gets created automatically.

4. Next, [add your aws keys as env vars](https://circleci.com/docs/2.0/contexts/) to the build in the CircleCI using:

  * AWS_ACCESS_KEY_ID	    
  * AWS_DEFAULT_REGION		
  * AWS_SECRET_ACCESS_KEY

5. Update the owner in `windows/visual-studio/packer.yaml` if you configured the keys under a different account to the once your Circleci Server installation is under.

6. Click Rerun Workflow from the job details page to rerun the Windows image buider

7. Your will find your new Windows AMI ID at the end of the `summarize results` step in the job output

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

