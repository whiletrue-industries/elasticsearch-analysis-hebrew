#!/bin/bash
set -e

# Integration test script for Elasticsearch Hebrew Analysis Plugin
# This script builds the Docker image and runs integration tests

ES_VERSION=${ES_VERSION:-8.17.0}
PLUGIN_VERSION=${PLUGIN_VERSION:-8.17.0}
IMAGE_NAME="elasticsearch-hebrew-test:${ES_VERSION}"
CONTAINER_NAME="es-hebrew-test"

echo "========================================="
echo "Integration Test for Elasticsearch Hebrew Analysis Plugin"
echo "ES Version: ${ES_VERSION}"
echo "Plugin Version: ${PLUGIN_VERSION}"
echo "========================================="

# Clean up any existing container
echo "Cleaning up any existing containers..."
docker rm -f ${CONTAINER_NAME} 2>/dev/null || true

# Copy the built plugin to demo directory
echo "Copying plugin artifact to demo directory..."
cp build/distributions/analysis-hebrew-${PLUGIN_VERSION}.zip demo/elasticsearch-analysis-hebrew.zip

# Build Docker image
echo "Building Docker image..."
cd demo
docker build --build-arg ES_VERSION=${ES_VERSION} -t ${IMAGE_NAME} .
cd ..

# Start Elasticsearch container
echo "Starting Elasticsearch container..."
docker run -d --name ${CONTAINER_NAME} -p 9200:9200 -e "discovery.type=single-node" -e "xpack.security.enabled=false" ${IMAGE_NAME}

# Wait for Elasticsearch to be ready
echo "Waiting for Elasticsearch to be ready..."
timeout=120
counter=0
until curl -s http://localhost:9200/_cluster/health | grep -q '"status":"green"\|"status":"yellow"'; do
    sleep 2
    counter=$((counter + 2))
    if [ $counter -ge $timeout ]; then
        echo "ERROR: Elasticsearch failed to start within ${timeout} seconds"
        docker logs ${CONTAINER_NAME}
        docker rm -f ${CONTAINER_NAME}
        exit 1
    fi
    echo "Waiting... ($counter/${timeout}s)"
done

echo "Elasticsearch is ready! Waiting for full initialization..."
sleep 15

# Wait for cluster to be fully operational
echo "Checking cluster health..."
for i in {1..10}; do
    HEALTH=$(curl -s http://localhost:9200/_cluster/health)
    echo "Cluster health: $HEALTH"
    sleep 2
done

# Check if plugin is installed
echo "Checking if Hebrew analysis plugin is installed..."
PLUGINS=$(curl -s http://localhost:9200/_cat/plugins)
echo "Installed plugins:"
echo "$PLUGINS"

if echo "$PLUGINS" | grep -q "analysis-hebrew"; then
    echo "✓ Hebrew analysis plugin is installed"
else
    echo "✗ Hebrew analysis plugin NOT found"
    docker logs ${CONTAINER_NAME}
    docker rm -f ${CONTAINER_NAME}
    exit 1
fi

# Create test index with Hebrew analyzer
echo "Creating test index with Hebrew analyzer..."
curl -s -X PUT "http://localhost:9200/test-hebrew?wait_for_active_shards=1" -H 'Content-Type: application/json' -d'
{
  "settings": {
    "index": {
      "number_of_shards": 1,
      "number_of_replicas": 0
    }
  },
  "mappings": {
    "properties": {
      "content": {
        "type": "text",
        "analyzer": "hebrew_query",
        "search_analyzer": "hebrew_query"
      }
    }
  }
}' | jq '.'

# Wait for index and shards to be ready
echo "Waiting for index to be ready..."
sleep 5

# Wait for shards to be allocated
echo "Waiting for shards to be allocated..."
for i in {1..30}; do
    SHARDS_STATUS=$(curl -s "http://localhost:9200/_cluster/health/test-hebrew?wait_for_status=yellow&timeout=2s")
    if echo "$SHARDS_STATUS" | jq -e '.status == "yellow" or .status == "green"' > /dev/null 2>&1; then
        echo "Shards allocated successfully"
        break
    fi
    echo "Waiting for shards... attempt $i/30"
    sleep 2
done

# Index a test document
echo "Indexing test document..."
INDEXING_RESULT=$(curl -s -X PUT "http://localhost:9200/test-hebrew/_doc/1?refresh=true" -H 'Content-Type: application/json' -d'
{
  "content": "בדיקות"
}')

echo "$INDEXING_RESULT" | jq '.'

# Check if indexing was successful
if echo "$INDEXING_RESULT" | jq -e '.result == "created" or .result == "updated"' > /dev/null 2>&1; then
    echo "✓ Document indexed successfully"
else
    echo "✗ Failed to index document"
    echo "$INDEXING_RESULT"
    docker logs ${CONTAINER_NAME} | tail -50
    docker rm -f ${CONTAINER_NAME}
    exit 1
fi

# Search for the document
echo "Searching for 'בדיקה' (should match 'בדיקות')..."
RESULT=$(curl -s -X POST "http://localhost:9200/test-hebrew/_search" -H 'Content-Type: application/json' -d'
{
  "query": {
    "match": {
      "content": "בדיקה"
    }
  }
}')

echo "$RESULT" | jq '.'

# Check if we got a hit
HITS=$(echo "$RESULT" | jq -r '.hits.total.value')
if [ "$HITS" = "1" ]; then
    echo "✓ Search test PASSED - Found expected document"
else
    echo "✗ Search test FAILED - Expected 1 hit, got $HITS"
    docker rm -f ${CONTAINER_NAME}
    exit 1
fi

# Test the analyze API
echo "Testing analyze API with Hebrew analyzer..."
ANALYZE_RESULT=$(curl -s -X POST "http://localhost:9200/test-hebrew/_analyze" -H 'Content-Type: application/json' -d'
{
  "analyzer": "hebrew_query",
  "text": "בדיקה של מנתח עברי"
}')

echo "$ANALYZE_RESULT" | jq '.'

# Check if we got tokens
TOKEN_COUNT=$(echo "$ANALYZE_RESULT" | jq -r '.tokens | length')
if [ "$TOKEN_COUNT" -gt 0 ]; then
    echo "✓ Analyze API test PASSED - Generated $TOKEN_COUNT tokens"
else
    echo "✗ Analyze API test FAILED - No tokens generated"
    docker rm -f ${CONTAINER_NAME}
    exit 1
fi

# Clean up
echo "Cleaning up..."
docker rm -f ${CONTAINER_NAME}

echo "========================================="
echo "✓ All integration tests PASSED!"
echo "========================================="
