# Hebrew analyzer for Elasticsearch

Originally powered by HebMorph (https://github.com/synhershko/HebMorph) and licensed under the AGPL3, currently using this [fork](https://github.com/Immanuelbh/HebMorph) for latest version updates.

[![Download](https://img.shields.io/badge/Download-7.16.1-blue) ](https://github.com/Immanuelbh/elasticsearch-analysis-hebrew/releases/download/elasticsearch-analysis-hebrew-7.16.1/elasticsearch-analysis-hebrew-7.16.1.zip)

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

Alternatively, install the plugin manually by invoking the command which fits your elasticsearch version (older versions can be found at the bottom):

```shell
./bin/elasticsearch-plugin install --batch https://github.com/Immanuelbh/elasticsearch-analysis-hebrew/releases/download/elasticsearch-analysis-hebrew-7.16.1/elasticsearch-analysis-hebrew-7.16.1.zip
```

### Earlier versions
#### v5.x
For earlier versions (5.x), there is no need for the batch flag.

#### v2.x and earlier
For even earlier versions (2.x and before) the installation looks a bit different:
```shell
./bin/plugin install https://bintray.com/synhershko/elasticsearch-analysis-hebrew/download_file?file_path=elasticsearch-analysis-hebrew-2.4.2
```

During installation, you may be prompted for additional permissions:

```shell
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@     WARNING: plugin requires additional permissions     @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* java.io.FilePermission /var/lib/hebmorph/dictionary.dict read
* java.io.FilePermission /var/lib/hspell-data-files read
* java.io.FilePermission /var/lib/hspell-data-files/* read
* java.lang.RuntimePermission accessClassInPackage.sun.reflect.generics.reflectiveObjects
See http://docs.oracle.com/javase/8/docs/technotes/guides/security/permissions.html
for descriptions of what these permissions allow and the associated risks.

Continue with installation? [y/N]y
```

This is normal - please confirm by typing y and hitting Enter.

Then be sure to restart the ElasticSearch service.

## Dictionaries

This plugin uses dictionary files for its operation. The open-source version is using hspell data files. In the 7.x version, and the 5.x versions, the dictionaries are bundled in the plugin download itself.

For earlier versions, you will need to obtain the Hebrew dictionary files yourself. The open-sourced hspell files can be downloaded here: https://github.com/synhershko/HebMorph/tree/master/hspell-data-files. Download the entire folder and copy it to be either in the plugin's folder (meaning, `plugins/analysis-hebrew/hspell-data-files`) or under `/var/lib/hspell-data-files`.

Elasticsearch can also be configured to load the dictionary from another folder, this is done by adding the following line to elasticsearch.yml file:

```yml
hebrew.dict.path: /PATH/TO/HSPELL/FOLDER
```

You will also need to edit `plugin-security.policy` accordingly.

The dictionary used in by the commercial version follows a similar pattern.

You can confirm installation by launching elasticsearch and seeing the following in the logs:

```shell
[2017-03-22T15:43:05,927][INFO ][c.c.e.HebrewAnalysisPlugin] Defaulting to HSpell dictionary loader
[2017-03-22T15:43:07,751][INFO ][c.c.e.HebrewAnalysisPlugin] Trying to load hspell from path plugins/analysis-hebrew/hspell-data-files/
[2017-03-22T15:43:07,751][INFO ][c.c.e.HebrewAnalysisPlugin] Dictionary 'hspell' loaded successfully from path plugins/analysis-hebrew/hspell-data-files/
```

The easiest way to make sure the plugin is installed correctly is to request `/_hebrew/check-word/בדיקה` on your server (for example: browse to http://localhost:9200/_hebrew/check-word/בדיקה). If it loads, it means everything is set up, and you are good to go.

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

## Older Versions

Elasticsearch versions 1.4.0 - 1.7.3:

```shell
bin/plugin --install analysis-hebrew --url https://bintray.com/artifact/download/synhershko/elasticsearch-analysis-hebrew/elasticsearch-analysis-hebrew-1.7.zip
```

Even older versions:

~/elasticsearch-0.90.11$ bin/plugin --install analysis-hebrew --url https://bintray.com/artifact/download/synhershko/elasticsearch-analysis-hebrew/elasticsearch-analysis-hebrew-1.0.zip

~/elasticsearch-1.0.0$ bin/plugin --install analysis-hebrew --url https://bintray.com/artifact/download/synhershko/elasticsearch-analysis-hebrew/elasticsearch-analysis-hebrew-1.2.zip

~/elasticsearch-1.2.1$ bin/plugin --install analysis-hebrew --url https://bintray.com/artifact/download/synhershko/elasticsearch-analysis-hebrew/elasticsearch-analysis-hebrew-1.4.zip

~/elasticsearch-1.3.2$ bin/plugin --install analysis-hebrew --url https://bintray.com/artifact/download/synhershko/elasticsearch-analysis-hebrew/elasticsearch-analysis-hebrew-1.5.zip

## Development
Get the matching version.properties file from Elasticsearch:
```shell
curl https://raw.githubusercontent.com/elastic/elasticsearch/7.10/buildSrc/version.properties -O version.properties
```

** Notice for this version (7.16.1) you should downgrade from 7.10.3 => 7.16.1

Build the plugin:
```shell
gradle task build
```

** Note the build creates analysis-hebrew jar file. Not elasticsearch-analysis-hebrew.zip, which is built manually.

## License

AGPL3, see LICENSE
