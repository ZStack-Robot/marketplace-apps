 variable "wait_for_migrate_health_cmd" { 
   description = "local-exec command to execute for determining if the migrate url is healthy. migrate endpoint will be available as an environment variable called ENDPOINT" 
   type        = string 
   default     = "start=$(date +%s); until curl -k -s $ENDPOINT >/dev/null; do sleep 4; now=$(date +%s); if [ $((now - start)) -ge 600 ]; then echo 'Timeout reached'; exit 1; fi; done" 
 } 