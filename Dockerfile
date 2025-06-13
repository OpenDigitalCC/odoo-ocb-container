#FROM debian:trixie-slim
# Comes with Python-3.13 which is too new for Odoo
FROM python:3.12-slim

## 
## # Build arguments
ARG ODOO_UID
ARG ODOO_USER
ARG ODOO_BASE_DIR
ARG ODOO_REPO
ARG ODOO_BRANCH
ARG ODOO_SRC_DIR
ARG ODOO_DATA_DIR
## 
## # Convert ARGs to ENV for runtime
ENV ODOO_UID=${ODOO_UID}
ENV ODOO_USER=${ODOO_USER}
ENV ODOO_BASE_DIR=${ODOO_BASE_DIR}
ENV ODOO_SRC_DIR=${ODOO_SRC_DIR}
ENV ODOO_REPO=${ODOO_REPO}
ENV ODOO_BRANCH=${ODOO_BRANCH}
ENV ODOO_DATA_DIR=${ODOO_DATA_DIR}

WORKDIR ${ODOO_BASE_DIR}

# Install system dependencies for Odoo and wkhtmltopdf
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
	tini \
	openssl \
        git \
        python3 \
        python3-pip \
        python3-venv \
	postgresql-client \
	libpq-dev \
        build-essential \
        libxml2-dev \
        libxslt1-dev \
        libzip-dev \
        libldap2-dev \
        libsasl2-dev \
        libssl-dev \
        wget \
        fontconfig \
        libfreetype6 \
        libjpeg62-turbo \
        libpng16-16 \
        libx11-6 \
        libxcb1 \
        libxext6 \
        libxrender1 \
        xfonts-75dpi \
        xfonts-base \
	gosu \
        && \
    rm -rf /var/lib/apt/lists/*

RUN pip install --upgrade pip

# Install wkhtmltopdf from official Debian package
RUN wget -qO /tmp/wkhtmltox.deb https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-3/wkhtmltox_0.12.6.1-3.bookworm_amd64.deb && \
    apt-get install -y /tmp/wkhtmltox.deb && \
    rm /tmp/wkhtmltox.deb

# Create odoo user and directories
RUN useradd --uid "${ODOO_UID}" --user-group --system --no-create-home ${ODOO_USER} 

# Make build-time paths and set perms
#RUN mkdir -p "${ODOO_BASE_DIR}" "${ODOO_DATA_DIR}"
#RUN chown -R "$ODOO_UID" "${ODOO_BASE_DIR}" "${ODOO_DATA_DIR}" 

# Clone the Odoo code
RUN git clone --depth 1 -b ${ODOO_BRANCH} ${ODOO_REPO} ${ODOO_SRC_DIR}/${ODOO_BRANCH}/

# Install deps as listed by odoo
RUN pip install -r ${ODOO_SRC_DIR}/${ODOO_BRANCH}/requirements.txt

# Copy the entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Set user to run as - this is now done with gosu in entrypoint
#USER ${ODOO_USER}

# use tini to manage init
ENTRYPOINT ["tini", "--"]
CMD ["/entrypoint.sh"]

