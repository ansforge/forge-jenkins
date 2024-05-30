job "${nomad_namejob}" {

  datacenters = ["${datacenter}"]
  namespace = "${nomad_namespace}"

  type = "service"

  vault {
      policies = ["forge"]
      change_mode = "restart"
  }

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
                # Valeur à adapter
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

      #template {
      #  destination = "local/hosts"
      #  change_mode = "restart"
      #  data = <<EOH
#{{ with secret "forge/jenkins" }}{{ .Data.data.hosts }}{{ end }}
#EOH
      #}

      config {
        extra_hosts = [ "gitlab.internal qual.internal:$\u007Battr.unique.network.ip-address\u007D",
                        "${extra_host_artifactory}",
                        "${extra_host_controller_jenkins}",
                        "${extra_host_runner_java}",
                        "${extra_host_runner_proc64}",
                        "${extra_host_runner_puppet6}"
                      ]
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
                # Valeur à adapter
                size = 60
                repl = 2
              }
            }
          }
        }

       # mount {
       #   type = "bind"
       #   target = "/etc/hosts"
       #   source = "local/hosts"
       #   bind_options {
       #     propagation = "rshared"
       #   }
       # }
      }
      resources {
        cpu = ${jenkins_ressource_cpu}
        memory = ${jenkins_ressource_mem}
      }

      service {
        name = "${nomad_namespace}"
        tags = ["urlprefix-${jenkins_fqdn}/",
                "urlprefix-jenkins.internal/"
               ]
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
