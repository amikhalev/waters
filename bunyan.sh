#!/bin/bash
/usr/bin/node $@ | ./node_modules/.bin/bunyan --color
