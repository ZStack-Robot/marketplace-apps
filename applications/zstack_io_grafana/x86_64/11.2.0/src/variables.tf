 variable "wait_for_migrate_health_cmd" { 
   description = "local-exec command to execute for determining if the Grafana url is healthy. Grafana endpoint will be available as an environment variable called ENDPOINT" 
   type        = string 
   default     = "until curl -k -s $ENDPOINT >/dev/null; do sleep 4; done" 
 } 