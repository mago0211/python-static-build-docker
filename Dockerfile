FROM docker.io/i386/debian

ARG PYTHON_PREFIX=/build/python-static

ENV PYTHON_LIB_VER 311
ENV PYTHON_VERSION 3.11.7
ENV COMPILER clang
ENV MUSL_PREFIX /build/musl

RUN apt update; \
    apt install -y python3-dev clang wget make libbz2-dev zip

RUN mkdir --parents /build
RUN mkdir --parents /build/dist

WORKDIR /build

# Download and build musl (static) with clang
RUN wget http://www.musl-libc.org/releases/musl-${MUSL_VERSION}.tar.gz
RUN tar -xzf musl-${MUSL_VERSION}.tar.gz
WORKDIR /build/musl-${MUSL_VERSION}
RUN export CC=${COMPILER}
RUN ./configure --prefix=${MUSL_PREFIX} --disable-shared
RUN make -j$(nproc)
RUN make install

WORKDIR /build

# Download and build python (static) with clang
RUN export CC=${MUSL_PREFIX}/bin/musl-${COMPILER}
RUN wget https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz
RUN tar -xzf Python-${PYTHON_VERSION}.tgz
ADD Setup.local /build/Python-${PYTHON_VERSION}/Modules
WORKDIR /build/Python-${PYTHON_VERSION}
RUN export CC=${COMPILER}
RUN ./configure --prefix="${PYTHON_PREFIX}" --disable-shared LDFLAGS="-static" CFLAGS="-static" CPPFLAGS="-static"
RUN make -j$(nproc) LDFLAGS="-static" LINKFORSHARED=" "

RUN cp /build/Python-${PYTHON_VERSION}/python /build/dist/
WORKDIR /build/Python-${PYTHON_VERSION}/Lib
RUN rm -rf __pycache__
RUN zip -r /build/dist/python${PYTHON_LIB_VER}.zip .

WORKDIR /build
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]