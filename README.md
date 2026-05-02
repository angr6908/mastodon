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

### Caddyfile
```
example.com {
	encode
	handle /api/v1/streaming* {
		reverse_proxy 127.0.0.1:4000
	}

	handle * {
		reverse_proxy 127.0.0.1:3000
	}

	header Strict-Transport-Security "max-age=63072000; includeSubDomains"

	@cache path /assets/* /avatars/* /emoji/* /headers/* /ocr/* /packs/* /sounds/*
	header @cache Cache-Control "public, max-age=2419200, must-revalidate"

	@system path /system/*
	header @system {
		Cache-Control "public, max-age=2419200, immutable"
		X-Content-Type-Options "nosniff"
		Content-Security-Policy "default-src 'none'; form-action 'none'"
	}
}
```
