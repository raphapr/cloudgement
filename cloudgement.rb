require 'yaml'
require 'fileutils'
require 'tempfile'
require "optparse"

# Cloudgement
# Author Raphael P. Ribeiro

#####################################################################################
# Parse Command Line

opt =   {
            :distro => nil,
            :vms => nil,
            :img => nil,
            :flavor => nil,
            :packs => nil
        }

parser = OptionParser.new do|opts|
    opts.banner = "Usage: ruby cloudgement.rb [options]"


    opts.on('-d', '--distro distro', 'Linux distribution (Fedora, Ubuntu, Debian, CentOS)') do |distro|
        opt[:distro] = distro;
    end

    opts.on('-v', '--vms vms', 'Amount of virtual machine instances') do |vms|
        opt[:vms] = vms;
    end

    opts.on('-i', '--image image', 'Image to use to boot server') do |img|
        opt[:img] = img;
    end

    opts.on('-f', '--flavor flavor', 'Flavor to use for server') do |flavor|
        opt[:flavor] = flavor;
    end

    opts.on('-p', '--packs packages', 'List of packages to be installed ("vim mysql")') do |packs|
        opt[:packs] = packs;
    end
    
    opts.on('-h', '--help', 'Displays Help') do
        puts opts
        exit
    end
end

parser.parse!

#####################################################################################

#opt[:vms] = 3
#opt[:distro] = 'fedora'
#opt[:img] = 'Fedora-x86_64-20-20140618-sda'
#opt[:flavor] = 'm1.tiny'
#opt[:packs] = 'vim mariadb mysql mysql-server'
path = File.expand_path(File.join(File.dirname(__FILE__), "template.yaml")) # relative path
ipInstances = []

#####################################################################################

if opt[:distro] == 'fedora' or opt[:distro] == 'centos'
    opt[:packs] = "#!/bin/bash\nyum -y install " + opt[:packs] + "\n"
elsif opt[:distro] == 'ubuntu' or opt[:distro] == 'debian'
    opt[:packs] = "#!/bin/bash\napt-get -y install " + opt[:packs] + "\n"
else
    opt[:packs] = ""
end

#####################################################################################

def hifensOut(path) ## Deleta as linhas "---" gerados no arquivo yaml

# Abre arquivo temporário
tmp = Tempfile.new("tmp")

# Escreve as linhas filtradas para o arquivo temporário
File.open(path, 'r').each { |l| tmp << l unless l.chomp == '---' }

# Fecha tmp
tmp.close

# Move arquivo temporário para original
FileUtils.mv(tmp.path,path)

end

#####################################################################################
# Criando Template

f = File.open(path,'w+') 

cabecalho = {
    'heat_template_version' => '2013-05-23',
    'description' => 'Generated template'
}

parameters = {
    'parameters' => {

        ## KeyName

        'key_name' => {
            'type' => 'string',
            'description' => 'Name of an existing key pair to use for the instance',
            'default' => 'default'
        },
       

        ## InstanceType

        'instance_type' => {
            'type' => 'string',
            'description' => 'Instance type for the instance to be created',
            'default' => opt[:flavor],
            'constraints' => [{
                'allowed_values' => ['m1.tiny','m1.small','m1.medium','m1.large'],
                'description' => 'instance_type must be a valid instance type'
                }]
        },

        ## ImageId

        'image_id' => {
            'type' => 'string',
            'description' => 'ID of the image to use for the instance',
            'default' => opt[:img]
        },

        ## db password

        'db_password' => {
            'type' => 'string',
            'description' => 'Database password',
            'hidden' => true,
            'default' => 'Test123',
            'constraints' => [{
                'length' => {'min' => 6, 'max' => 8}, # Password length must be between 6 and 8 characters
                #'allowed_pattern' => ["[a-zA-Z0-9]","[s]"] # Password must consist of characters and numbers only
                }]
        },
        
        ## db port

        'db_port' => {
            'type' => 'number',
            'description' => 'Database port number',
            'default' => 50000,
            'constraints' => [{
                'range' => {'min' => 40000, 'max' => 60000}, # Password length must be between 6 and 8 characters
                #'allowed_pattern' => ["[a-zA-Z0-9]","[s]"] # Password must consist of characters and numbers only
                'description' => 'Port number must be between 40000 and 60000'
                }]
        }

    }
}


resources = {
    'resources' => {

    }
}

outputs = {
    'outputs' => {
    }
}

opt[:vms].to_i.times do |i|
    instName = 'my_instance'+(i+1).to_s
    privateIp = 'server'+(i+1).to_s+'_private_ip'
    resourcesTMP = { instName => {
                'type' => 'OS::Nova::Server',
                'properties' => {
                    'image' => {
                        'get_param' => 'image_id'
                    },
                    'flavor' => {
                        'get_param' => 'instance_type'
                    },
                    'key_name' => {
                        'get_param' => 'key_name'
                    },
                    'user_data' => {
                        'str_replace' => {
                             'template' => opt[:packs],
                             'params' => {
                                'imageid' => { 'get_param' => 'image_id'  }
                             }
                        }
                    }
                }
            }
    }
    outputsTMP = {
        privateIp => {
            'description' => 'IP address of the server in the private network',
            'value' => {
                'get_attr' => [ instName, 'address'+(i+1).to_s ]
            }
        }
    }
    resources['resources'].merge!(resourcesTMP)
    outputs['outputs'].merge!(outputsTMP) 
end

f.write cabecalho.to_yaml
f.write parameters.to_yaml
f.write resources.to_yaml
f.write outputs.to_yaml

f.close

#####################################################################################

hifensOut(path)

#####################################################################################
