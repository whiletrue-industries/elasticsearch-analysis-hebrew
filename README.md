# Hebrew analyzer for Elasticsearch

Originally powered by HebMorph (https://github.com/synhershko/HebMorph) and licensed under the AGPL3, currently using this [fork](https://github.com/Immanuelbh/HebMorph) for latest version updates.

[![Version](https://img.shields.io/badge/Version-8.17.0-blue)](https://github.com/whiletrue-industries/elasticsearch-analysis-hebrew)
[![Docker](https://img.shields.io/badge/Docker-Available-green)](https://github.com/whiletrue-industries/elasticsearch-analysis-hebrew/pkgs/container/elasticsearch-analysis-hebrew)

## Requirements

- Elasticsearch 8.17.0
- Java 17 or higher
- Hebrew dictionary files (bundled in the plugin)

## Installation

### Using Docker (Recommended)

The easiest way to use Elasticsearch with the Hebrew analysis plugin is via the pre-built Docker images:

```shell
docker pull ghcr.io/whiletrue-industries/elasticsearch-analysis-hebrew:latest
docker run -d -p 9200:9200 -e "discovery.type=single-node" -e "xpack.security.enabled=false" \
  ghcr.io/whiletrue-industries/elasticsearch-analysis-hebrew:latest
```

Available tags:
- `latest` - Latest version from master branch
- `8.17.0` - Specific plugin version
- `sha-{hash}` - Specific commit

Images are available at: https://github.com/whiletrue-industries/elasticsearch-analysis-hebrew/pkgs/container/elasticsearch-analysis-hebrew

### Manual Plugin Installation

For Elasticsearch 8.17.0, build the plugin from source:

```shell
git clone https://github.com/whiletrue-industries/elasticsearch-analysis-hebrew.git
cd elasticsearch-analysis-hebrew
./gradlew assemble
./bin/elasticsearch-plugin install file:///path/to/build/distributions/analysis-hebrew-8.17.0.zip
```

During installation, you will be prompted for additional permissions:

```shell
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@     WARNING: plugin requires additional permissions     @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* java.io.FilePermission /var/lib/hspell-data-files read
* java.io.FilePermission /var/lib/hspell-data-files/* read
See https://docs.oracle.com/javase/8/docs/technotes/guides/security/permissions.html
for descriptions of what these permissions allow and the associated risks.

Continue with installation? [y/N]y
```

Confirm by typing `y` and pressing Enter, then restart Elasticsearch.

## Dictionaries

This plugin uses dictionary files for its operation. The open-source version uses hspell data files, which are **bundled in the plugin** (versions 5.x, 7.x, and 8.x).

### Custom Dictionary Path

To load the dictionary from a custom location, add this to `elasticsearch.yml`:

```yml
hebrew.dict.path: /PATH/TO/HSPELL/FOLDER
```

You will also need to edit `plugin-security.policy` to grant read permissions to that path.

The dictionary used by the commercial version follows a similar pattern.

### Verification

Confirm installation by checking the logs for:

```json
{"log.level": "INFO", "message":"Defaulting to HSpell dictionary loader", ...}
{"log.level": "INFO", "message":"Trying to load hspell from path /usr/share/elasticsearch/plugins/analysis-hebrew/hspell-data-files", ...}
{"log.level": "INFO", "message":"Dictionary 'hspell' loaded successfully from path /usr/share/elasticsearch/plugins/analysis-hebrew/hspell-data-files", ...}
{"log.level": "INFO", "message":"loaded plugin [analysis-hebrew]", ...}
```

Test the plugin:

```bash
curl http://localhost:9200/_hebrew/check-word/בדיקה
```

If you get a response, the plugin is working correctly.

## Commercial

Hebmorph is released open-sourced, alongside with hspell dictionary files. The Commercial option will grant you further support in making Hebrew search even better, and it comes with a proprietary dictionary. For more information, check out http://code972.com/hebmorph.

## Usage

Use "hebrew" as analyzer name for fields containing Hebrew text

Query using "hebrew_query" or "hebrew_query_light" to enable exact matches support. "hebrew_exact" analyzer is available for query_string / match queries to be searched exact without lemma expansion.

Because Hebrew uses quote marks to mark acronyms, it is recommended to use the match family queries and not query_string. This is the official recommendation anyway. This plugin does not currently ship with a QueryParser implementation that can be used to power query_string queries.

Here is a sample Sense / Console syntax demonstrating usage of the analyzers in this plugin:

```
GET /_hebrew/check-word/בדיקה

PUT test-hebrew
{
    "mappings": {
        "properties": {
            "content": {
                "type": "text",
                "analyzer": "hebrew"
            }
        }
    }
}

PUT test-hebrew/_doc/1
{
    "content": "בדיקות"
}

POST test-hebrew/_search
{
    "query": {
        "match": {
           "content": "בדיקה"
        }
    }
}

# or for multiply fields
POST test-hebrew/_search
{
    "query": {
        "multi_match": {
           "query": "בדיקה",
           "fields": [
                "*",
                "content"
           ]
        }
    }
}
```

## Development

### Requirements
- Java 17 or higher
- Gradle 8.5+ (included via wrapper)

### Building from Source

```shell
git clone https://github.com/whiletrue-industries/elasticsearch-analysis-hebrew.git
cd elasticsearch-analysis-hebrew
./gradlew build
```

The plugin ZIP will be in `build/distributions/analysis-hebrew-8.17.0.zip`.

### Running Tests

```shell
# Unit tests
./gradlew test

# Integration tests (requires Docker)
./test-integration.sh
```

### Contributing

Contributions are welcome! Please ensure:
1. All tests pass (`./gradlew build`)
2. Integration tests pass (`./test-integration.sh`)
3. Code follows existing style
4. Commit messages are descriptive

## License

AGPL3, see LICENSE
