# Repo Structure

**NOTE: Take note of the files in [.gitignore](../.gitignore) which will not be committed. These are indicated by angle brackets below. Some of them must be provided for deployment to succeed.**

	.
	├── ci                             # Continuous integration scripts
	├── docs                           # Misc images or supporting documentation
	├── etc                            # DC/OS config templates
	├── examples                       # Example app/service definitions
	├── installers                     # Location where DC/OS releases are downloaded
	├── lib                            # DC/OS Vagrant plugin source
	├── patch                          # Patches for buggy Vagrant versions
	├── provision                      # Machine provisioning scripts and artifacts
	├── LICENSE                        # Software license
	├── NOTICE                         # Non-license attributions
	├── README.md                      # Intro Documentation
	├── <VagrantConfig.yaml>           # (Required) Machine resource definitions
	├── VagrantConfig-*.yaml           # Example machine configs. Copy to VagrantConfig.yaml
	└── VagrantFile                    # Used to deploy nodes and install DC/OS
