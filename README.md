# mastodon-lite
Minimal Mastodon All-in-One Docker Image

### compose.yml
```
services:
  mastodon:
    image: docker.io/unmol637/mastodon:latest
    container_name: mastodon
    restart: always
    env_file: .env.production
    ports:
      - "127.0.0.1:3000:3000"
      - "127.0.0.1:4000:4000"
    volumes:
      - ./data:/mastodon/public/system
      - ./pgdata:/var/lib/postgresql/data
      - ./redis:/var/lib/redis
```
