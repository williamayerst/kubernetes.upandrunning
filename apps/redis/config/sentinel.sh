#!/bin/bash
while ! ping -c 1 redis-0.redis;
do
  echo 'Waiting for server'
  sleep 1
done
mkdir /local-redis
cp /redis-config/sentinel.conf /local-redis/sentinel.conf
redis-sentinel /local-redis/sentinel.conf
