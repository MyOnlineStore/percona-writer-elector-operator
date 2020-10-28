FROM node:12-alpine

WORKDIR /srv/app

# You have to specify "--unsafe-perm" with npm ci
# when running as root.  Failing to do this can cause
# install to appear to succeed even if a preinstall
# script fails, and may have other adverse consequences
# as well.
# This command will also cat the npm-debug.log file after the
# build, if it exists.
COPY package.json package-lock.json tsconfig.json ./
RUN npm ci --unsafe-perm || \
  ((if [ -f npm-debug.log ]; then \
      cat npm-debug.log; \
    fi) && false)

COPY . ./
RUN npm run build

FROM node:12-alpine

WORKDIR /srv/app
EXPOSE 4000

COPY --chown=1001 --from=0 /srv/app/dist /srv/app/dist
COPY --chown=1001 --from=0 /srv/app/config /srv/app/config
COPY --chown=1001 --from=0 /srv/app/package.json /srv/app/package-lock.json /srv/app/
ENV NODE_ENV=production
RUN npm install --prod --save-exact

USER 1001
CMD ["node", "./dist/index.js"]
