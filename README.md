#  Example Packer Config For building Windows On CircleCI

This folder contains everything you will need to build a Windows image, with the CircleCI dsc resources, on CircleCI. For more information on setting up VM service, which includes specifying your new Windows image for your users, see our [VM Service guide](https://circleci.com/docs/2.0/vm-service/#section=server-administration).

## Building a Windows Image to use with `machine` Executor

The following steps will guide you through building a Windows AMI, which you can then specify in the VM Service settings for your installation of CircleCI Server, letting users of your installation run their builds in a Windows environment.

Please note that Windows images are built on CircleCI, so we suggest you run through this process once your installation is up and running. Alternatively you can use any other CircleCI account – including on our managed Cloud service.

### Step-by-step guide

1. Prerequisites:

    1. Make sure that you have **your own copy of this repository** on your GitHub organization.

    2. Make sure that you have **an access key** for an AWS IAM User that has sufficient permission to create AMIs using Packer. Refer to [documentation of Packer](https://www.packer.io/docs/builders/amazon#authentication) for details.

2. First, **configure `ami-builder` context that contains a required AWS access key as env vars**. In `ami-builder` context, populate the env vars below:

    * `AWS_ACCESS_KEY_ID` (Access key ID of your access key)
    * `AWS_SECRET_ACCESS_KEY` (Secret access key of your access key)
    * `AWS_DEFAULT_REGION` (Region where your CircleCI Server is hosted, e.g. us-east-1, us-west-1, ap-noartheast-1. Created AMI will be available only for this region.)

    [Our official document](https://circleci.com/docs/2.0/contexts/) would help you setting up contexts.

3. **Create a new project on your CircleCI Server to connect your own repo** by clicking Set Up Project in the Add Projects page.

4. After project setup, the first build would run automatically. Wait for it to complete; it would take 2 - 3 hours to finish.

5. You will find your new Windows AMI ID at the end of the `summarize results` step in the job output.

### Common troubleshooting

* If you get any errors around not being able to find a default VPC, you will need to specify `vpc_id` and `subnet_id` in `windows/visual-studio/packer.yaml`.

## What the packer job in this build does
* Sets up winrm.
* Adds scripts for removing winrm when we are ready to clean up.
* Copies over ImageHelpers and CircleDSCResources to the powershell module path.
* Runs some configuration to get the machine ready to use DSC and clean up some defaults that are not helpful.
* Runs DSC and restarts the machine a few times to let it continue through the configuration process.
* Runs Pester tests to validate that the image is configured correctly. These tests are designed to ensure that all of the software is actually callable not just “installed”.
* Copies: test results, the choco logs, and the software.md (a list of everything we install and test for the presence of) off of the host.
* Installs the SSH server and enables the cleanup script that runs on shutdown (check out the aws packer scripts for exactly *how* that works).
* Creates a Windows AMI.
