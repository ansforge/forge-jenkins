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
    default = "st-forge.asipsante.fr registry.repo.docker.henix.fr:1.1.1.1"
}
