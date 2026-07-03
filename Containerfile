FROM debian:bookworm AS builder

# Install build dependencies
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    build-essential \
    clang \
    gobjc \
    git \
    gnustep-devel \
    libgnustep-base-dev \
    libgnustep-dl2-dev \
    libpq-dev \
    libxml2-dev \
    libffi-dev \
    libgnutls28-dev \
    ca-certificates \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

# Symlink GCC's objc headers so Clang can find them natively on Debian
RUN ln -s /usr/lib/gcc/$(gcc -dumpmachine)/12/include/objc /usr/include/objc

# Set up GNUstep environment variables
ENV GNUSTEP_MAKEFILES=/usr/share/GNUstep/Makefiles
ENV CC=clang
ENV CXX=clang++

# Build and install GSWeb from source: needs my patched version
WORKDIR /src
RUN git clone https://github.com/gnustep/libs-gsweb.git && \
    cd libs-gsweb && \
    . /usr/share/GNUstep/Makefiles/GNUstep.sh && \
    ./configure && \
    make && \
    make install

# Build and install tools-xctest from source
WORKDIR /src
RUN git clone https://github.com/gnustep/tools-xctest.git && \
    cd tools-xctest && \
    . /usr/share/GNUstep/Makefiles/GNUstep.sh && \
    make && \
    make install

# Build and install libs-gdl2 from source: needs my patched version, which
# fixes EODatabaseContext permanently wedging after a save fails before a
# transaction begins (e.g. a DB connection failure) - see
# https://github.com/iamleeg/libs-gdl2/tree/fix-database-context-stuck-preparing-for-save
WORKDIR /src
RUN git clone https://github.com/iamleeg/libs-gdl2.git && \
    cd libs-gdl2 && \
    git switch fix-database-context-stuck-preparing-for-save && \
    . /usr/share/GNUstep/Makefiles/GNUstep.sh && \
    ./configure --disable-gui-projects --disable-gorm-palette && \
    make && \
    make install

# Build the OnTheWing application
WORKDIR /app
COPY . .
RUN . /usr/share/GNUstep/Makefiles/GNUstep.sh && \
    make clean && \
    make

# Run the test suite
RUN . /usr/share/GNUstep/Makefiles/GNUstep.sh && \
    make check

# -------------------------
# Stage 2: Runtime
# -------------------------
FROM debian:bookworm-slim AS runtime

# Install minimal runtime dependencies
# (libgnutls30 comes transitively via gnustep-base-runtime, no explicit entry needed)
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    gnustep-base-runtime \
    libpq5 \
    libxml2 \
    && rm -rf /var/lib/apt/lists/*

# Copy built GNUstep libraries (GSWeb and potentially others installed to /usr/local)
COPY --from=builder /usr/local/lib /usr/local/lib
COPY --from=builder /usr/local/bin /usr/local/bin

# Copy the built application from the builder stage
WORKDIR /app
COPY --from=builder /app/OnTheWing.gswa /app/OnTheWing.gswa

ENV LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
ENV GNUSTEP_MAKEFILES=/usr/share/GNUstep/Makefiles

EXPOSE 8080

# GSWeb apps usually take arguments like -WOPort 8080
ENTRYPOINT ["/app/OnTheWing.gswa/OnTheWing"]
CMD ["-WOPort", "8080", "-WOHost", "0.0.0.0", "-WOCGIAdaptorURL", "/WebObjects", "-WOApplicationName", "OnTheWing"]
