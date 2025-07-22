FROM alpine:3.20
 
RUN apk add --no-cache curl jq
 
COPY fetch-and-push.sh /app.sh
 
RUN chmod +x /app.sh
 
CMD ["/app.sh"]
