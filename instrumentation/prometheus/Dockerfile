FROM prom/prometheus:v3.15.0

COPY local.yml /etc/prometheus/local.yml

CMD ["--config.file=/etc/prometheus/local.yml", \
     "--storage.tsdb.path=/prometheus", \
     "--storage.tsdb.retention.size=800MB"]
