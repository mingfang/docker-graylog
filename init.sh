until curl http://localhost:9200; do echo "waiting for ElasticSearch to come online..."; sleep 3; done 
curl -XGET 'http://localhost:9200/_cluster/health?wait_for_status=green&timeout=30s' 
until /usr/bin/curl http://127.0.0.1:12900/system/inputs; do echo "waiting for API server to come online..."; sleep 3; done 

curl -u admin:admin -X POST -H "Content-Type: application/json" -d @mycontentpack.json localhost:12900/system/bundles 
ID=`curl -u admin:admin -X GET -H 'Content-Type: application/json' --silent localhost:12900/system/bundles | jq -r .mycontentpack[].id`
curl -u admin:admin -X POST -H 'Content-Type: application/json' localhost:12900/system/bundles/$ID/apply
