project = "${workspace.name}"
labels = { "domaine" = "forge" }
runner {
    enabled = true
    profile = "common-odr"
    data_source "git" {
        url  = "https://rhodecode.proxy.dev.forge.esante.gouv.fr/SandBox/QM/PFC/pfc-jenkins.git"
        ref  = "var.datacenter"
        # path = "jenkins"
        ignore_changes_outside_path = true
    }
    poll {
        enabled = false
    }
}
app "pfc-jenkins" {

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
            })
        }
    }
}


variable "nomad_namejob" {
    type = string
    default = "pfc-jenkins"
}

variable datacenter {
    type = string
    default = ""
    env     = ["NOMAD_DC"]
}
variable "image" {
    type    = string
    default = "jenkins/jenkins"
}

variable "tag" {
    type    = string
    default = "2.440.1-lts-jdk17"
}