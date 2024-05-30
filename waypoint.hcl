project = "${workspace.name}"
labels = { "domaine" = "forge" }
runner {
    enabled = true
    profile = "common-odr"
    data_source "git" {
        url  = "https://github.com/ansforge/forge-jenkins.git"
        ref  = "var.datacenter"
        ignore_changes_outside_path = true
    }
    poll {
        enabled = false
    }
}
app "forge-jenkins" {

    build {
        use "docker-ref" {
            image = var.image
            tag   = var.tag
            # disable_entrypoint = true
        }
    }
    deploy{
        use "nomad-jobspec" {
            jobspec = templatefile("${path.app}/jenkins.nomad.tpl", {
            image   = var.image
            tag     = var.tag
            datacenter = var.datacenter

            nomad_namespace = "${workspace.name}"
            nomad_namejob = var.nomad_namejob
            jenkins_fqdn = var.jenkins_fqdn
            jenkins_ressource_cpu = var.jenkins_ressource_cpu
            jenkins_ressource_mem = var.jenkins_ressource_mem
            extra_host_artifactory = var.extra_host_artifactory
            extra_host_controller_jenkins = var.extra_host_controller_jenkins
            extra_host_runner_java = var.extra_host_runner_java
            extra_host_runner_proc64 = var.extra_host_runner_proc64
            extra_host_runner_puppet6 = var.extra_host_runner_puppet6
            })
        }
    }
}


variable "nomad_namejob" {
    type = string
    default = "forge-jenkins"
}

variable datacenter {
    type = string
    default = ""
    env     = ["NOMAD_DC"]
}
variable "image" {
    type    = string
    default = "ans/jenkins-controller"
}

variable "tag" {
    type    = string
    default = "2.440.2-lts-jdk17"
}
variable "jenkins_fqdn" {
     type    = string
     default = "ci.forge.henix.asipsante.fr"
}

variable "jenkins_ressource_cpu" {
    type    = number
    default = 3500
}

variable "jenkins_ressource_mem" {
    type    = number
    default = 4096
}

variable "extra_host_artifactory" {
    type    = string
    default = "st-forge.asipsante.fr registry.repo.docker.henix.fr:10.3.9.2"
}

variable "extra_host_controller_jenkins" {
    type    = string
    default = "ci.forge.presta.henix.asipsante.fr:10.3.8.58"
}

variable "extra_host_runner_java" {
    type    = string
    default = "ci-java-forge.henix.asipsante.fr forge-ci-java-back04.asip.hst.fluxus.net vm368a675773.qual.henix.asip.hst.fluxus.net:10.3.9.120"
}

variable "extra_host_runner_proc64" {
    type    = string
    default = "forge-ci-proc-back06.forge.asip.hst.fluxus.net:10.3.9.53"
}

variable "extra_host_runner_puppet6" {
    type    = string
    default = "slave-jenkins-puppet6.henix.asipsante.fr forge-ci-puppet-back07.asip.hst.fluxus.net:10.3.9.45"
}
