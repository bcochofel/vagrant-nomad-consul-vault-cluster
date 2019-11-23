#!/bin/bash

cat <<EOF | curl --data-binary @- http://pushgateway.service.consul:9091/metrics/job/some_job/instance/`hostname`
# TYPE some_metric counter
some_metric{label="val1"} 42
# TYPE another_metric gauge
# HELP another_metric Just an example.
another_metric 2398.283
EOF

exit 0
