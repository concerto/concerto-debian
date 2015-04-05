#!/bin/bash
# Move build artifacts for CircleCI to publish.
mv debs $CIRCLE_ARTIFACTS
mkdir $CIRCLE_ARTIFACTS/logs
mv lite_lintian.log $CIRCLE_ARTIFACTS/logs/concerto-lite.lintian.log
mv full_lintian.log $CIRCLE_ARTIFACTS/logs/concerto-full.lintian.log