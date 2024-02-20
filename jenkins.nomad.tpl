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
      leader = true # log-shipper
      template {
        destination = "local/jenkins.env"
        change_mode = "restart"
        env = true
        data = <<EOH
JENKINS_HOME = "/var/lib/jenkins/"
JENKINS_SLAVE_AGENT_PORT = 5050
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