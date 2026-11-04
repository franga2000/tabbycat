# Docker file lists all the commands needed to setup a fresh linux instance to run the application specified. docker-compose does not use this.
# It is split into two stages, each with a separate container:
# 1. (NodeJS) builds the static assets (Vue, SCSS) and is disarded after the assets are copied
# 2. (Django) installs the runtime dependencies and runs the application

########################
#                      #
#   NodeJS container   #
#                      #
########################

# Barebones NodeJS image
FROM node:26-alpine AS vue-build

WORKDIR /app

# Copy in dependency list and install the dependencies
# Note: This is copied separately from the rest of the code to take advantage of build caching
COPY ./package.json ./package-lock.json ./
RUN --mount=type=cache,target=/root/.npm npm ci

# Copy files, required for the build (skip Python files to avoid invalidating the cache)
COPY --exclude=*/*/*.py --exclude=*/*/*/*.py . ./

# Build the static files
RUN --mount=type=cache,target=/app/node_modules/.cache npm run build


########################
#                      #
#   Django container   #
#                      #
########################

# Grab a python image
FROM python:3.12-alpine

# Just needed for all things python (note this is setting an env variable)
ENV PYTHONUNBUFFERED 1
# Needed for correct settings input
ENV IN_DOCKER 1

# Copy all our files into the baseimage and cd to that directory
RUN mkdir /tcd
WORKDIR /tcd

# Install Nginx
RUN apk add nginx --no-cache

# Install Pipenv
RUN pip install pipenv

# Copy in dependency list and install the dependencies
# Note: This is copied separately from the rest of the code to take advantage of build caching
RUN mkdir -p ./config/
COPY ./Pipfile* ./
RUN pipenv install --system --deploy

# Copy the built JS files
RUN mkdir -p ./tabbycat/static/vue
COPY --from=vue-build /app/tabbycat/static/ /tcd/tabbycat/static/

COPY . /tcd/

RUN python ./tabbycat/manage.py collectstatic --noinput -v 0
