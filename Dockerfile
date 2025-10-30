ARG BASE_IMAGE="ruby:3.4.7-slim"
FROM ${BASE_IMAGE}

ARG USER_NAME="jekyll"
ARG USER_UID=1000
ARG USER_GID=1000

ENV LANG=ja_JP.UTF-8 \
    LC_ALL=ja_JP.UTF-8 \
    BUNDLE_PATH="/home/${USER_NAME}/.bundle" \
    APP_ROOT="/workspace"

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      build-essential \
      git \
      locales \
      nodejs \
      npm && \
    echo "ja_JP.UTF-8 UTF-8" >> /etc/locale.gen && \
    locale-gen ja_JP.UTF-8 && \
    rm -rf /var/lib/apt/lists/*

RUN groupadd --gid "${USER_GID}" "${USER_NAME}" && \
    useradd --uid "${USER_UID}" --gid "${USER_GID}" --create-home --shell /bin/bash "${USER_NAME}"

WORKDIR ${APP_ROOT}

COPY Gemfile* ${APP_ROOT}/

RUN chown -R "${USER_UID}:${USER_GID}" ${APP_ROOT}

USER ${USER_NAME}

RUN bundle config set path "${BUNDLE_PATH}" && \
    bundle install

EXPOSE 4000

CMD ["bundle", "exec", "jekyll", "serve", "--watch", "--host", "0.0.0.0"]
