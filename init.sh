until curl http://localhost:9200; do echo "waiting for ElasticSearch to come online..."; sleep 3; done 
curl -XGET 'http://localhost:9200/_cluster/health?wait_for_status=green&timeout=30s' 
until /usr/bin/curl http://127.0.0.1:12900/system/inputs; do echo "waiting for API server to come online..."; sleep 3; done 

curl -u admin:admin -X POST -H "Content-Type: application/json" -d @syslogTCPInput514.json localhost:12900/system/inputs 
curl -u admin:admin -X POST -H "Content-Type: application/json" -d @gelfUDPInput12201.json localhost:12900/system/inputs 
curl -u admin:admin -X POST -H "Content-Type: application/json" -d @gelfTCPInput12201.json localhost:12900/system/inputs 
curl -u admin:admin -X POST -H "Content-Type: application/json" -d @rawTCPInput5555.json localhost:12900/system/inputs 
