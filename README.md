cloudgement
===========
Description
-----------

A tool that generates HOT Heat template to OpenStack

Usage
-----

Available options can be displayed by using `ruby cloudgement.rb -h`:

    $ruby cloudgement.rb  --help
    Usage: ruby cloudgement.rb [options]
    -d, --distro distro              Linux distribution (Fedora, Ubuntu, Debian, CentOS)
    -v, --vms vms                    Amount of virtual machine instances
    -i, --image image                Image to use to boot server
    -f, --flavor flavor              Flavor to use for server
    -p, --packs packages             List of packages to be installed ("vim mysql")
    -h, --help                       Displays Help

Example
-----
    $ruby cloudgement.rb --distro Ubuntu --vms 2 --image Ubuntu-x86_64 \
    --flavor m1.medium --packs "mysql mysql-server ssh"
