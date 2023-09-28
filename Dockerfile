FROM python:3.11.5-slim-bookworm

ARG USER_ID
ARG GROUP_ID

RUN --mount=type=cache,target=/var/cache/apt \
    apt update && apt-get install -y --no-install-recommends gcc libc6-dev

RUN if [ ${USER_ID:-0} -ne 0 ] && [ ${GROUP_ID:-0} -ne 0 ]; then \
    userdel -f www-data &&\
    if getent group www-data ; then groupdel www-data; fi &&\
    groupadd -g ${GROUP_ID} www-data &&\
    useradd -l -u ${USER_ID} -g www-data www-data &&\
    install -d -m 0755 -o www-data -g www-data /home/www-data &&\
    chown --changes --silent --no-dereference --recursive \
          --from=33:33 ${USER_ID}:${GROUP_ID} \
        /home/www-data\
;fi

RUN --mount=type=cache,target=/root/.cache \
    pip install --upgrade pip \
    && pip install poetry==1.6.1

WORKDIR /home/www-data

ENV POETRY_CACHE_DIR=/home/www-data/.cache/pypoetry \
    POETRY_VIRTUALENVS_CREATE=1 \
    POETRY_VIRTUALENVS_IN_PROJECT=1 \
    POETRY_INSTALLER_MAX_WORKERS=12 \
    PYTHONUNBUFFERED=1

#RUN mkdir -p $POETRY_CACHE_DIR

COPY ./pyproject.toml ./poetry.lock ./
RUN --mount=type=cache,target=$POETRY_CACHE_DIR poetry install --no-root --no-interaction

USER www-data

ENTRYPOINT ["poetry", "run"]
