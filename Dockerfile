FROM scratch

COPY ./zig-out/bin/codeforces /app/run

EXPOSE 8080
ENTRYPOINT ["/app/run"]
