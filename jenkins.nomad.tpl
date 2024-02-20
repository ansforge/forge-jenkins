job "${nomad_namejob}" {

  datacenters = ["${datacenter}"]
  namespace = "${nomad_namespace}"
  # namespace = "default"
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
                size = 10
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
    task "pfc-jenkins" {

      // user = "root"

      driver = "docker"

      template {
        destination = "local/jenkins.env"
        change_mode = "restart"
        env = true
        data = <<EOH
JENKINS_HOME = "/var/lib/jenkins/"
JENKINS_SLAVE_AGENT_PORT = 5050
EOH
      }

      template {
        destination = "local/proxy.xml"
        change_mode = "restart"
        env = true
        data = <<EOH
<?xml version='1.1' encoding='UTF-8'?>
<proxy>
  <name>10.0.49.163</name>
  <port>3128</port>
  <userName></userName>
  <noProxyHost>rhodecode.proxy.dev.forge.esante.gouv.fr
repo.proxy-dev-forge.asip.hst.fluxus.net
rhodecode.proxy-dev-forge.asip.hst.fluxus.net
forge-admin01.asip.hst.fluxus.net
forge-scm01.asip.hst.fluxus.net
forge-back01.asip.hst.fluxus.net
forge-back02.asip.hst.fluxus.net
forge-ci-java-back04.asip.hst.fluxus.net
forge-ci-proc-back06.forge.asip.hst.fluxus.net
forge-ci-puppet-back03.asip.hst.fluxus.net
forge-ci-build-rpms.forge.asip.hst.fluxus.net
st-forge.asipsante.fr
bu-forge.asipsante.fr
admin-forge.asipsante.fr
scm-forge.asipsante.fr
qual-forge.asipsante.fr
10.0.70.2
10.0.70.7
rhodecode.apache.forge.henix.asipsante.fr
rhodecode.forge.henix.asipsante.fr
rhodecode.forge.presta.henix.asipsante.fr
gitlab.forge.presta.henix.asipsante.fr
gitlab.forge.henix.asipsante.fr

10.0.0.0/8
*.forge.esante.gouv.fr

10.0.49.163:3128
10.0.49.163:3128
  </noProxyHost>
  <secretPassword></secretPassword>
  <testUrl>https://updates.jenkins.io/</testUrl>
</proxy>
EOH
      }

      config {
        image = "${image}:${tag}"
        ports   = ["jenkins-network"]
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
                size = 20
                repl = 2
              }
            }
          }
        }
      }

      mount {
          type = "bind"
          target = "/var/lib/jenkins_home/proy.xml"
          source = "local/proy.xml"
          bind_options {
              propagation = "rshared"
          }
      } 

      resources {
        cpu    = 2400 # MHz
        memory = 768 # MB
      }

      service {
        name = "${nomad_namespace}"
        tags = ["urlprefix-jenkins.pfcpxent.henix.asipsante.fr/"]
        port = "jenkins-network"
        check {
          name     = "alive"
          type     = "http"
          path     = "/login"
          interval = "30s"
          timeout  = "5s"
          port     = "jenkins-network"
        }
      }
    }
  }
}