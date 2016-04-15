# Repo Structure

**NOTE: Take note of the files in [.gitignore](../.gitignore) which will not be committed. These are indicated by angle brackets below. Some of them must be provided for deployment to succeed.**

	.
	├── ci                             # Continuous integration scripts
	├── docs                           # Misc images or supporting documentation
	├── etc                            # DCOS config templates
	├── examples                       # Example app/service definitions
	├── lib                            # DCOS Vagrant plugin source
	├── provision                      # Machine provisioning scripts and artifacts
	├── <dcos_generate_config.sh>      # (Required) DCOS installer
	├── LICENSE                        # Software license
	├── NOTICE                         # Non-license attributions
	├── README.md                      # Intro Documentation
	├── <VagrantConfig.yaml>           # (Required) Machine resource definitions
	├── VagrantConfig.yaml.example     # Used to define node types. Copy to VagrantConfig.yaml
	└── VagrantFile                    # Used to deploy nodes and install DCOS
