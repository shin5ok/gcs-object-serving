FROM golang:1.21-alpine AS builder

WORKDIR /app

COPY go.mod ./
COPY go.sum ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -o main .

FROM alpine:latest

RUN apk update && apk add --no-cache ca-certificates

WORKDIR /app

COPY --from=builder /app/main .

ENTRYPOINT ["./main"]
