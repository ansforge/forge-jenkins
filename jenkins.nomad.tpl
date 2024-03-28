job "${nomad_namejob}" {

  datacenters = ["${datacenter}"]
  namespace = "${nomad_namespace}"

  type = "service"

  group "jenkins" {
    count = 1

    restart {
      attempts = 3
      delay = "60s"
      interval = "1h"
      mode = "fail"
    }

    network {
      port "jenkins-network" { static = 8080 }
      port "slave" { static = 5050 }
    }
    #########################################################
    # Creation du disk persistant avec les droits ouverts
    task "prep-disk" {
      driver = "docker"
      config {
        image = "busybox:latest"
        mount {
          type = "volume"
          target = "/var/lib/jenkins/"
          source = "jenkins_home"
          readonly = false
          volume_options {
            no_copy = false
            driver_config {
              name = "pxd"
              options {
                io_priority = "high"
                size = 60
                repl = 2
              }
            }
          }
        }
        command = "sh"
        args = ["-c", "chown -R 1000:1000 /var/lib/jenkins/"]
      }
      resources {
        cpu = 50
        memory = 64
      }
      lifecycle {
        hook = "prestart"
        sidecar = "false"
      }
    }
    
    #########################################################
    task "forge-jenkins" {
      driver = "docker"
      leader = true # log-shipper
      template {
        destination = "local/jenkins.env"
        change_mode = "restart"
        env = true
        data = <<EOH
JENKINS_HOME = "/var/lib/jenkins/"
JENKINS_SLAVE_AGENT_PORT = 5050
JENKINS_OPTS="--prefix=/jenkins"
EOH
      }

      template {
        destination = "local/hosts"
        change_mode = "restart"
        data = <<EOH
127.0.0.1       localhost.asip.hst.fluxus.net             localhost
10.3.9.247      ci.proxy-dev-forge.asip.hst.fluxus.net forge-back11-btts422639.qual.henix.asip.hst.fluxus.net        forge-back11-btts422639
10.3.9.120      ci-java-forge.henix.asipsante.fr forge-ci-java-back04.asip.hst.fluxus.net vm368a675773.qual.henix.asip.hst.fluxus.net
10.3.9.85       slave-jenkins.henix.asipsante.fr forge-ci-puppet-back03.asip.hst.fluxus.net vmfb464052.qual.henix.asip.hst.fluxus.net
10.3.9.245      FORGE-CI-BUILD-RPMS.asip.hst.fluxus.net forge-ci-proc-back06.forge.asip.hst.fluxus.net
10.3.9.53       forge-ci-proc-back06.forge.asip.hst.fluxus.net
10.3.9.242      forge-qualim01.asip.hst.fluxus.net FORGE-Qualim01.asip.hst.fluxus.net qual-forge.asipsante.fr
10.3.9.2        st-forge.asipsante.fr registry.repo.docker.henix.fr
10.3.9.45       slave-jenkins-puppet6.henix.asipsante.fr forge-ci-puppet-back07.asip.hst.fluxus.net
10.3.9.241      scm-forge.asipsante.fr
10.3.8.47       rhodecode.forge.henix.asipsante.fr
10.3.8.58       ci.forge.presta.henix.asipsante.fr rhodecode.forge.presta.henix.asipsante.fr gitlab.forge.presta.henix.asipsante.fr
10.3.8.44       admin-forge.asipsante.fr admin-forge.asip.hst.fluxus.net FORGE-Admin01.asip.hst.fluxus.net admin-forge
10.3.8.165      qual.forge.henix.asipsante.fr
10.3.8.47       gitlab.forge.henix.asipsante.fr
EOH
      }

      config {
        image = "${image}:${tag}"
        ports   = ["jenkins-network","slave"]
        # MONTAGE DU DISK PERSISTANT
        mount {
          type = "volume"
          target = "/var/lib/jenkins/"
          source = "jenkins_home"
          readonly = false
          volume_options {
            no_copy = false
            driver_config {
              name = "pxd"
              options {
                io_priority = "high"
                size = 60
                repl = 2
              }
            }
          }
        }

        mount {
          type = "bind"
          target = "/etc/hosts"
          source = "local/hosts"
          bind_options {
            propagation = "rshared"
          }
        }
      }
      resources {
        cpu = ${jenkins_ressource_cpu}
        memory = ${jenkins_ressource_mem}
      }

      service {
        name = "${nomad_namespace}"
        tags = ["urlprefix-${jenkins_fqdn}/"]
        port = "jenkins-network"
        check {
          name     = "alive"
          type     = "http"
          path     = "jenkins/login"
          interval = "30s"
          timeout  = "5s"
          port     = "jenkins-network"
        }
      }
    }
    #########################################################
    # log-shipper
    task "log-shipper" {
        driver = "docker"
        restart {
            interval = "3m"
            attempts = 5
            delay    = "15s"
            mode     = "delay"
        }
        meta {
            INSTANCE = "$\u007BNOMAD_ALLOC_NAME\u007D"
        }
        template {
            data = <<EOH
  REDIS_HOSTS = {{ range service "PileELK-redis" }}{{ .Address }}:{{ .Port }}{{ end }}
  PILE_ELK_APPLICATION = JENKINS
  EOH
            destination = "local/file.env"
            change_mode = "restart"
            env = true
        }
        config {
            image = "ans/nomad-filebeat:8.2.3-2.0"
        }
        resources {
            cpu    = 100
            memory = 150
        }
    } #end log-shipper 
    #########################################################
  }
}