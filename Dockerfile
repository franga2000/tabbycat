# Docker file lists all the commands needed to setup a fresh linux instance to run the application specified
# It is split into two stages, each with a separate container:
# 1. (NodeJS) builds the static assets (Vue, SCSS) and is disarded after the assets are copied
# 2. (Django) installs the runtime dependencies and runs the application

########################
#                      #
#   NodeJS container   #
#                      #
########################

# Barebones NodeJS image
FROM node:10-alpine AS vue-build

WORKDIR /app

# Copy in dependency list and install the dependencies
# Note: This is copied separately from the rest of the code to take advantage of build caching
COPY ./package.json ./package-lock.json ./
RUN npm install --only=production

# Copy files, required for the build
COPY . ./

# Build the static files
RUN npm run build


########################
#                      #
#   Django container   #
#                      #
########################

# Barebones Python image (this time not Alpine, as wheels don't work)
FROM python:3.6-slim

WORKDIR /app

# Just needed for all things python (note this is setting an env variable)
ENV PYTHONUNBUFFERED 1

# Install libs that require build dependencies so we can remove them later
# TODO: How much of this can we drop if we switch to psycopg-binary?
RUN apt-get update && \
    apt-get install --no-install-recommends -y libpq-dev python3-dev gcc && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy in dependency list and install the dependencies
# Note: This is copied separately from the rest of the code to take advantage of build caching
RUN mkdir -p ./config/
COPY ./config/requirements_core.txt ./config/
RUN pip install --no-cache-dir -r ./config/requirements_core.txt

# Copy the built JS files
RUN mkdir -p ./tabbycat/static/vue
COPY --from=vue-build /app/tabbycat/static/vue/ /app/tabbycat/static/vue/

# Copy the rest of the source code
COPY . .

# Compile all the static files
RUN python ./tabbycat/manage.py collectstatic --noinput -v 0

CMD ./bin/docker-run.sh
