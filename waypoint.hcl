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
            extra_host_proxy_partenaire = var.extra_host_proxy_partenaire
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
    default = 5000
}

variable "jenkins_ressource_mem" {
    type    = number
    default = 8192
}

variable "extra_host_artifactory" {
    type    = string
    default = "forge-back12.asip.hst.fluxus.net st-forge.asipsante.fr forge-back12 st-forge:10.0.70.2"
}

variable "extra_host_proxy_partenaire" {
    type    = string
    default = ""
}

variable "extra_host_runner_java" {
    type    = string
    default = "forge-ci-java-back14.asip.hst.fluxus.net forge-ci-java-back14:10.0.65.196"
}

variable "extra_host_runner_proc64" {
    type    = string
    default = "forge-ci-proc-back06.forge.asip.hst.fluxus.net forge-ci-proc-back06:10.0.65.201"
}

variable "extra_host_runner_puppet6" {
    type    = string
    default = "forge-ci-puppet-back13.asip.hst.fluxus.net forge-ci-puppet-back13:10.0.65.198"
}
