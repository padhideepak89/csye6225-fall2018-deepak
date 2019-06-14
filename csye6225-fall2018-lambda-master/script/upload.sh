#!/bin/bash
cd ..
cd Lambda/build/distributions
aws lambda update-function-code \
--zip-file=fileb://lamdafunction-1.0-SNAPSHOT.zip \
--region=us-east-1 \
--function-name=MyFunction
