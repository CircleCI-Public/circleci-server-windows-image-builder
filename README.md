#  Example Packer Config For building Windows On CircleCI

This folder contains everything you will need to build a Windows image with the CircleCI dsc resources, on CircleCI. For more information on setting up VM service, which includes specifying your new Windows image for your users, see our VM service guides for [server v4](https://circleci.com/docs/server/latest/operator/manage-virtual-machines-with-machine-provisioner/).

## Building a Windows Image to use with `machine` Executor

The following steps will guide you through building a Windows AMI, which you can then specify in the VM Service settings for your installation of CircleCI server, letting users of your installation run their builds in a Windows environment.

Please note that Windows images are built on CircleCI, so we suggest you run through this process once your installation is up and running. Alternatively you can use any other CircleCI account – including on our managed Cloud service.

### Step-by-step guide

You can use either AWS or GCP to build your Windows machine image. Choose the one your server instance is running in.

By default, these images now build on the minimum required dependencies. This allows for a shorter build time to verify that your CircleCI Server environment can run a Windows build. 

If you'd like to have additional dependencies installed, please uncomment anything necessary for [windows-2019](https://github.com/CircleCI-Public/circleci-server-windows-image-builder/blob/master/windows2019/provision-scripts/dscConfig.ps1) or [windows-2022](https://github.com/CircleCI-Public/circleci-server-windows-image-builder/blob/master/windows2022/software.yml).

#### For AWS

1. Prerequisites:

    1. Make sure that you have **your own copy of this repository** on your GitHub organization.

    2. Make sure that you have **an access key** for an AWS IAM User that has sufficient permission to create AMIs using Packer. Refer to [documentation of Packer](https://www.packer.io/docs/builders/amazon#authentication) for details.
    
    3. The minimum permissions required can be found in the `permissions` directory  

2. First, **configure `circleci-server-image-builder` context that contains a required AWS access key as env vars**. In the context, populate the env vars below:

    * `AWS_ACCESS_KEY_ID` (Access key ID of your access key)
    * `AWS_SECRET_ACCESS_KEY` (Secret access key of your access key)
    * `AWS_DEFAULT_REGION` (Region where your CircleCI server is hosted, e.g., `us-east-1`, `us-west-1`, `ap-noartheast-1`. Created AMI will be available only for this region.)

    [Our official document](https://circleci.com/docs/2.0/contexts/) would help you setting up contexts.

3. **Create a new project on your CircleCI server to connect your own repo** by clicking Set Up Project in the Add Projects page.

4. After project setup, the first build would run automatically. Wait for it to complete; it would take 2 - 3 hours to finish.

5. You will find your new Windows AMI ID at the end of the `summarize results` step in the job output.

#### For GCP

1. Prerequisites:

    1. Make sure that you have **your own copy of this repository** on your GitHub organization.

    2. Make sure that you have **a JSON-formatted key for a GCP service account** that has sufficient permission to create GCE images using Packer. Refer to [documentation of Packer](https://www.packer.io/docs/builders/googlecompute#running-outside-of-google-cloud) for details.

    3. Make sure that the `default` network for your working project (which is specified in `CLOUDSDK_CORE_PROJECT` as described below) has **a firewall rule that allows ingress connections to TCP port 5986 of machines with a `packer-winrm` tag**.

2. First, **configure `circleci-server-image-builder` context that contains credentials for GCE as env vars**. In the context, populate the env vars below:

    * `GCLOUD_SERVICE_KEY` (Base64-encoded service account key; the result of `base64 -w 0 your-key-file.json`)
    * `GOOGLE_PROJECT_ID` (Name of the project for which the image builder runs and the resulting image is saved)
    * `GOOGLE_COMPUTE_ZONE` (Zone where the image builder runs, e.g., `us-central1-a`, `asia-northeast1-a`.)

    [Our official document](https://circleci.com/docs/2.0/contexts/) would help you setting up contexts.

3. **Create a new project on your CircleCI server to connect your own repo** by clicking Set Up Project in the Add Projects page.

4. After project setup, the first build would run automatically. Wait for it to complete; it would take 2 - 3 hours to finish.

5. You will find your new Windows image ID at the end of the `summarize results` step in the job output.

### Image Size

By default the disk image is set to 160 GB, but it can be updated based on your requirements.
In the packer.yml, update the *launch_block_device_mappings* block for AWS and *disk_size* value for GCP

### Common troubleshooting

* If you get any errors around not being able to find a default VPC, you will need to specify `vpc_id`, `subnet_id` (both for AWS) or `subnetwork` (for GCP) in `windows/visual-studio/packer.yaml`.

### Ansible and Windows 2022

For Windows 2019 everything is configured using packer only. For Windows 2022 ansible is used for most of it. The base ansible repo is publicly available at [https://github.com/CircleCI-Public/ansible](https://github.com/CircleCI-Public/ansible) and the branch you should use is [*test/install-vs-asadmin*](https://github.com/CircleCI-Public/ansible/tree/test/install-vs-asadmin). If you need to modify the ansible playbook, you can fork this repo and modify that branch in your fork. Remember to update the repo URL within the `build_image_ansible` job.
You can customize the image as you want by changing the ansible playbooks. There are some important configurations to check:
- **User password**: The password in the ansible task in the packer file must be the same there is in *group_vars/windows_configure_vars.yml* in the ansible repo
- **Windows updates**: There are some updates that can be rejected when running windows update, you can enable or disable this, or add your own updates to reject. This is in the file *roles/windows/windows_updates/tasks/main.yml* on ansible repo.

### GC_OLD jobs

This jobs are commented by default, but you can uncomment if you prefer to run an scheduled validation for terminating packer instances.

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

## Minimum requirements for a working Windows image in CircleCI
For both Windows 2019 and Windows 2022, the minimum requirements for a succesful image:
* Git with Bash
* git-lfs
* 7zip
* Gzip
* Sysinternals

For Windows 2019, these are defined in the CircleCIDSC package [here](https://github.com/CircleCI-Public/CircleCIDSC/blob/main/DSCResources/CircleBuildAgentPreReq/CircleBuildAgentPreReq.schema.psm1).
For Windows 2022, these are defined in the `software.yml` [here](https://github.com/CircleCI-Public/circleci-server-windows-image-builder/blob/master/windows2022/software.yml)