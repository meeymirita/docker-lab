# Образ-«терминал» для сборки методички: docker CLI + compose + bash/curl/jq.
# Демон — отдельный (docker:dind), см. tools/build-manual.py и docker/src/run.json
FROM docker:cli
RUN apk add --no-cache bash curl jq git
WORKDIR /work
CMD ["bash"]
