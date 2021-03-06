# If you want to export PDF via latex, use pandoc/latex:2.9.2.1
FROM pandoc/core:2.9.2.1

LABEL maintainer='rebeam.org <pandocker@rebeam.org>'

# graphviz, fonts used by it, and pngcrush to set png dpi (and compress them)
RUN apk --no-cache add \
        graphviz \
        fontconfig \
        ttf-liberation \
        font-noto \
        pngcrush

# Puppeteer - info here 
# https://github.com/puppeteer/puppeteer/blob/master/docs/troubleshooting.md#running-puppeteer-in-docker

# Installs latest Chromium (81.0.4044.113) package.
RUN apk add --no-cache \
      chromium \
      nss \
      freetype \
      freetype-dev \
      harfbuzz \
      ca-certificates \
      ttf-freefont \
      nodejs \
      yarn \
      dumb-init

# Tell Puppeteer to skip installing Chrome. We'll be using the installed package.
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser

# Add user so we don't need --no-sandbox.
# Additional parts for this container: creating /pptr, and chown /data and /pptr
RUN addgroup -S pptruser && adduser -S -g pptruser pptruser \
    && mkdir -p /home/pptruser/Downloads /app \
    && chown -R pptruser:pptruser /home/pptruser \
    && chown -R pptruser:pptruser /app \
    && chown -R pptruser:pptruser /data \
    && mkdir /pptr \
    && chown -R pptruser:pptruser /pptr 

# Run everything after as non-privileged user.
USER pptruser

# See package.json - Puppeteer v3.0.1 works with Chromium 81 as provided by this image.
# Note - moved this after changing user so node_modules belong to pptruser
COPY pptr/package.json /pptr/
COPY pptr/yarn.lock /pptr/
RUN cd /pptr && yarn install

# filters and styles for use with pandoc
COPY filters /filters
COPY styles /styles

# Our main entrypoint, a node script that runs pandoc and then puppeteer as necessary
COPY pptr/pptr.js /pptr/pptr.js

# Use dumb-init as entrypoint, see https://github.com/Yelp/dumb-init
ENTRYPOINT ["/usr/bin/dumb-init", "--"]
