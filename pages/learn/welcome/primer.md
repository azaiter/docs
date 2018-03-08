---
title: A resin.io primer
excerpt: How resin.io gets your code to your device fleet, from end to end
---

# A resin.io primer

The [resin.io](https://resin.io/) platform encompasses device, server, and client software, all designed to get your code securely deployed to a fleet of devices. The broad strokes are easy to grasp: once your device is set up with our [host OS](https://docs.resin.io/reference/resinOS/overview/2.x/), you can push code to the resin.io [build servers](https://docs.resin.io/learn/deploy/deployment/), where it will be packaged into containers and delivered to your fleet. All your devices and their running services can then be managed, monitored, and updated from your [web dashboard](https://dashboard.resin.io). 

If you're eager to learn more about the inner workings, you're in luck! We're eager to share. This guide covers the components and workflows involved in a typical resin.io deployment, with enough detail to answer the most common questions. If you're ready to dig in deeper, why not [get started](https://docs.resin.io/learn/getting-started/) with a project of your own?

## On your device

<img src="https://resin.io/blog/content/images/2017/12/Screen-Shot-2017-10-25-at-3-07-19-PM.png" width="60%">

Devices in the resin.io ecosystem run [resinOS](https://resinos.io/), a bare-bones, [Yocto Linux](https://www.yoctoproject.org/) based host OS, which comes packaged with [balena](https://www.balena.io/), our lightweight, [Docker](https://www.docker.com/)-compatible container engine. The host OS is responsible for kicking off the device supervisor, resin.io's agent on your device, as well as your containerized services. Within each service's container you can specify a base OS, which can come from any existing [Docker base image](https://hub.docker.com/u/resin/) that is compatible with your device architecture. The base OS shares a kernel with the host OS, but otherwise works independently. If you choose, your containers [can be configured](https://docs.resin.io/learn/develop/multicontainer/) to run as privileged, access hardware directly, and even inject modules into the kernel. The resin.io device supervisor runs in its own container, which allows us to continue running and pulling new code even if your application crashes.

### Host and kernel updates

Resin.io is built with the goal of 100% updatability. While the resin.io device supervisor and your application containers are easy to update without losing connection to the device, the [process for updating](https://docs.resin.io/reference/resinOS/updates/update-process/) the host OS involves a few more steps. To mitigate problems while updating, resin.io creates an additional partition of identical size to the boot partition. The supervisor downloads a new OS version and boots the device from the alternative boot partition. This way, we can ensure that the new version of the OS is downloaded and installed correctly before rebooting the device to the new version. Even if the new version fails to boot for some reason, our system is built in such a way that the next boot will bring the device back to the original working version of the host OS, operating and ready to download a correctly installed new version.

It is important to note that all resin.io devices, both those in production and development today, have the ability to have their host OS updated. For most devices, this can even be done directly [through the dashboard](https://docs.resin.io/reference/resinOS/updates/self-service/). 

### Device provisioning

So how are devices added to your resin.io applications? A key feature of resin.io is that a provisioning key for your application is embedded in the resinOS image download. When the device boots up for the first time, it uses the provisioning API to register itself with resin.io. A new device entry on the resin.io backend is created, and a device API key for this device is generated. Once the provisioning is successful, the provisioning API key is deleted from the device. Unless someone downloads the OS from your dashboard (or via the CLI), a device cannot enter your application. While the details of provisioning differ depending on the device type (does it have an SD card slot? Does it boot from on-board flash?), the following things always happen at first boot:

First, the device connects to the network and performs its early provisioning, which registers it on your dashboard. Then, the container partition is decompressed, and the device supervisor starts. This is the part that takes the most time. As soon as the supervisor starts, it registers onto the VPN and receives its unique resin.io API key. At that point, you will see the device as online in your dashboard and can use the device as normal. If the application that the device provisions into has already had code pushed to it, the new device downloads the latest version and begins operating as expected.

## Code deployment

Code deployment begins when you type `git push resin master` in your command line, moving your application code from a local repository to the resin.io platform. Here's what the process looks like:

<img src="https://resin.io/pages/how-it-works/how-it-works.jpg" width="80%">

Our git server receives the latest commits of your code at the remote git endpoint we’ve generated for your application. This remote repo serves as the source of truth for all devices in your fleet.  Any code pushed to the master branch is passed to our builders, which generate Docker images to be sent to your devices.

### Building containers

Your code is then built in an environment that matches the devices in your application. So if you’re pushing an app for BeagleBone Black devices, we’ll build your code in an ARMv7 environment. For Raspberry Pi 1, it's ARMv6. In fact, we provide native ARM builders for ARM images, just as we use x86 servers to build images for x86 devices.

For applications with [multiple containers](https://docs.resin.io/learn/develop/multicontainer/), a `docker-compose.yml` file will need to be included at the root of your project. This configuration file specifies the services that make up your application, as well as the system resources each service has access to. Applications with a single container will have a default `docker-compose.yml` file generated if none is included.

Most services will need to include a [Dockerfile](https://docs.resin.io/learn/develop/dockerfile/), which contains a list of commands for the builders. For each service, the builders will pull a base OS, install packages and dependencies, clone git repositories, and run any other steps you define for the setup and initialization of that service.

For Node.js services, you can use a package.json file without a Dockerfile. In this case, the builders create an implicit Dockerfile, which simulates the build process a Node.js/npm project expects. In this way, we are able to transparently run Node.js services on resin.io, while also taking advantage of some of Docker’s caching features. A Dockerfile will always give you more power to fine-tune, but you can start fast without and shift to a Dockerfile whenever you like.

### Getting to the devices

Once your Docker images are built, they are stored in our container registry, and the resin.io device supervisor is alerted that a new version of your application is ready. If a device is offline at the time, it will be made aware of the new containers when it comes back online. The communication between resin.io and your device is encrypted at all times, either through HTTPS or a VPN that we set up for the devices in your fleet. 

The device supervisor then downloads the changed layers of your container images, stops the old services, and starts the new ones. You can control the exact sequence by configuring the supervisor to use [different update strategies](https://docs.resin.io/learn/deploy/release-strategy/update-strategies/). To reduce download time and bandwidth consumption, you can also enable [delta updates](https://docs.resin.io/learn/deploy/delta/). This tells the supervisor to only download the binary differences between the old and the new images. The services themselves can also make use of [update locking](https://docs.resin.io/learn/deploy/release-strategy/update-locking) to block updates from happening during critical times (e.g. [a drone that is flying](https://www.youtube.com/watch?time_continue=1569&v=75vm6rRb6K0), or an industrial machine that is in the middle of an operation).

As the downloads proceed, you can watch the progress in the resin.io dashboard. You can click on any device to see more detailed information about the services being downloaded:

<img src="/img/common/device/device_summary.png" width="80%">

## Device management

Once your services are up and running, you can use the dashboard to monitor and interact with them. Messages from the device supervisor, as well as anything written by your services to `stdout` and `stderr`, will appear in the *Logs* window, which can be filtered by service. Our build-in [web terminal](https://docs.resin.io/learn/manage/ssh-access/) allows you to SSH into any running services, as well as the underlying host OS.

Much of the device, service, and application information provided by the dashboard is managed through the [resin.io API](https://docs.resin.io/reference/data-api/), and can also be viewed and modified using the [CLI](https://docs.resin.io/reference/cli/) or the [Node.js](https://docs.resin.io/reference/sdk/node-sdk/) and [Python](https://docs.resin.io/reference/sdk/python-sdk/) SDKs. Resin.io has been designed so users can build rich experiences, combining device-level data provided by resin.io with higher-level application-specific data that lives in other data domains.