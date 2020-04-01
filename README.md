# vyos-builder
A Packer project to build a VyOS .iso image.

When you run this builder, it builds an Ubuntu 18.04 VM which is used to build a VyOS `.iso` file. The VyOS image is then extracted from the VM which gets shut down and then exported as a `.vmdk` and `.ovf`.

## Run it
```
git clone https://github.com/chrismarget/vyos-builder.git
cd vyos-builder
packer build vyos-builder.json
```

The project fetches the Ubuntu server installer iso, installs Ubuntu, installs Docker, fetches/builds (configurable) the VyOS build container, and builds the VyOS .ISO image.

When the build completes, you'll find a timestamped build directory with the following contents:
```
vyos-builder
└── build-33563159545451
    ├── vyos-1.2.0-amd64.iso
    ├── vyos-builder_0.0.1-33563159545451-disk001.vmdk
    ├── vyos-builder_0.0.1-33563159545451.ovf
    └── vyos-builder_0.0.1-33563159545451.sshkey
```

Those files are:
* The VyOS image (.iso)
* The build VM disk image (.vmdk)
* The build VM metadata (.ovf)
* A private key trusted by the `root` and `vyos` accounts (.sshkey)

The entire build takes 30-60 minutes on my 2012 MacBook, depending on whether I choose to fetch or build the VyOS build container. There's a ton of Internet traffic as it fetches the Ubuntu installer and containers.

## Dependencies
It runs on my MacBook. I tried to not introduce any platform-specific dependencies, so it might even run on Windows. Packer and Virtualbox must be installed.

## Options
The idea with this thing is that all configuration options are set in the `build-vyos.json` packer file. Ideally, there will be no need to touch anything else. Of particular interest in that file are the following:

```
  "variables": {
    "vyos_build_target": "vmware",        <- Set the build target vmware/iso/azure/AWS/GCE etc... See Makefile: https://github.com/vyos/vyos-build/blob/current/Makefile
    "vyos_version": "1.2.4",              <- Probably obviuos
    "container_tag": "crux",              <- Relevant if fetching the container. Must match the VyOS version. Naming scheme: https://blog.vyos.io/vyos-development-news-in-august-and-september
    "build_container": "false",           <- Controls whether you'll build (vs. fetch) the vyos/vyos-build docker container
    "vyos_arch": "amd64",                 <- Probably obvious
    "custom_pkgs": "tcpdump bc"           <- Space delimited list of custom packages to be included in the VyOS build
  }
````

The variables related to the actual VyOS build wind up in `/home/vyos/build-vyos.env` and are consumed by the build script `/home/vyos/build-vyos.sh`.

## Rebuilds
When building a second VyOS image you can, of course start from scratch. Probably faster would be a pattern like the following:
* Import the VM into Virtualbox or other hypervisor
* While waiting, `chmod 600 build-xxx/xxxxx.sshkey` (the file provisioner used for fetching the key doesn't supoprt permissions and I wanted to avoid platform-specific incantations)
* Use the ssh key to access the new VM: `ssh -i build-xxx/xxxxx.sshkey vyos@<ip-address>`
* Review/modify the contents of `build-vyos.env` and then run `./build-vyos.sh`
* After about 18 minutes (2012 MacBook), a VyOS image file appears in `/home/vyos/vyos-build/build`
