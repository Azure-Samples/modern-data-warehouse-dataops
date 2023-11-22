#!/usr/bin/env bash

# Install Delta JAR packages
# This is an alternative to configure_spark_with_delta_pip() to avoid downloading packages each time

set -eux

# defaults
scalaVersion=2.12

# get installed pip module information
read -r pysparkLocation deltaVersion <<<$(python -c "import pkg_resources; print(pkg_resources.get_distribution('pyspark').location, pkg_resources.get_distribution('delta-spark').version)")

cd "$pysparkLocation"/pyspark/jars

# make sure this is the correct directory containing pyspark jars.
# This command will cause the script to fail if no *.jar files are in the current directory.
ls *.jar > /dev/null

wget \
    https://repo1.maven.org/maven2/io/delta/delta-core_"$scalaVersion"/"$deltaVersion"/delta-core_"$scalaVersion"-"$deltaVersion".jar \
    https://repo1.maven.org/maven2/io/delta/delta-storage/"$deltaVersion"/delta-storage-"$deltaVersion".jar

