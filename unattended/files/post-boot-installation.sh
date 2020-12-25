#!/bin/bash
#
#
# This script is intended to execute once on the first boot of a newly
# installed system. It runs as a systemd service. It performs required
# post-install setup and then removes itself as a service.
#
# The real starting point is the main_actions function.

# This function cycles through a set of ansible scripts and invokes each in turn.
#
# $1, $2, ... $N: a set of ansible scripts to invoke 
#
run_ansible_playbooks() {
    for script in "$@"
    do
	echo "================================================================================"
	echo "          running ansible playbook ${script}"
	ansible-playbook  --connection=local -i 127.0.0.1, "/root/ansible/${script}"
	echo "================================================================================"
	echo "Playbook $1 completed"
    done
}

main_actions() {
    this_script="$0"
    echo "Running ${this_script}"

    touch /root/unattended.install.invoked

    echo "================================================================================"
    echo "Performing apt update"
    apt-get update

    # Install required packages to allow ansible to run for further configuration
    PACKAGES=""
    PACKAGES="${PACKAGES} openssh-server"                # Needed to access this host via ssh
    PACKAGES="${PACKAGES} git"                           # Needed to access GitHub
    PACKAGES="${PACKAGES} python3"                       # Needed for ansible (probably already installed)
    PACKAGES="${PACKAGES} software-properties-common"    # Needed for ansible PPA
    echo "================================================================================"
    echo "Installing packages: [${PACKAGES}]"
    # Note: It has to be ${PACKAGES} here without double quotes otherwise apt-get treats
    # the whole string as a name for one package.
    apt-get install -y --no-install-recommends ${PACKAGES}

    echo "================================================================================"
    echo "Downloading ansible playbooks"
    git clone https://github.com/AntonioCarlini/ansible /root/ansible

    # Install ansible
    # apt-add-repository --yes ppa:ansible/ansible # Does not seem to work on LM 20.1
    apt-get install -y --no-install-recommends ansible

    # Run suitable ansible scripts
    ANSIBLE_SCRIPTS=""
    ANSIBLE_SCRIPTS="${ANSIBLE_SCRIPTS} document-tools.yml"
    ANSIBLE_SCRIPTS="${ANSIBLE_SCRIPTS} work-station.yml"
    run_ansible_playbooks ${ANSIBLE_SCRIPTS}
    
    # Stop this from running again
    systemctl disable unattended-install.service

    rm "${this_script}"

    exit 0
}

# Invoke the main function.
main_actions >> /root/service.output 2>&1