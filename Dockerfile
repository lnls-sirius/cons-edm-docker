# Author: Cláudio Ferreira Carneiro
# LNLS - Brazilian Synchrotron Light Source Laboratory
FROM ubuntu:18.04

LABEL maintainer="Claudio Carneiro <claudio.carneiro@lnls.br>"
WORKDIR /opt/

RUN apt-get update
RUN apt-get install -y          \
    build-essential             \
    git                         \
    iperf3                      \
    nmap                        \
    openssh-server              \
    vim                         \
    libreadline-gplv2-dev       \
    libgif-dev                  \
    libmotif-dev                \
    libxmu-dev                  \
    libxmu-headers              \
    libxt-dev                   \
    libxtst-dev                 \
    xfonts-100dpi               \
    xfonts-75dpi                \
    x11proto-print-dev

RUN mkdir -p /opt/epics-R3.15.5
WORKDIR /opt/epics-R3.15.5

COPY base-3.15.5.tar.gz                 .
COPY libxp6_1.0.2-1ubuntu1_amd64.deb    .
COPY libxp-dev_1.0.2-1ubuntu1_amd64.deb .
COPY extensionsTop_20120904.tar.gz      .

RUN tar -xvzf extensionsTop_20120904.tar.gz
RUN rm extensionsTop_20120904.tar.gz
RUN dpkg -i libxp6_1.0.2-1ubuntu1_amd64.deb libxp-dev_1.0.2-1ubuntu1_amd64.deb
RUN rm libxp6_1.0.2-1ubuntu1_amd64.deb libxp-dev_1.0.2-1ubuntu1_amd64.deb

ENV PATH /opt/epics-R3.15.5/base/bin/linux-x86_64:$PATH
ENV EPICS_BASE /opt/epics-R3.15.5/base
ENV EPICS_HOST_ARCH linux-x86_64
ENV EPICS_CA_AUTO_ADDR_LIST YES

ENV EPICS_EXTENSIONS /opt/epics-R3.15.5/extensions

ENV PATH $EPICS_EXTENSIONS/bin/$EPICS_HOST_ARCH:$PATH

ENV EDMPVOBJECTS $EPICS_EXTENSIONS/src/edm/setup
ENV EDMOBJECTS $EPICS_EXTENSIONS/src/edm/setup
ENV EDMHELPFILES $EPICS_EXTENSIONS/src/edm/helpFiles
ENV EDMFILES $EPICS_EXTENSIONS/src/edm/edmMain
ENV EDMLIBS $EPICS_EXTENSIONS/lib/$EPICS_HOST_ARCH

ENV LD_LIBRARY_PATH $EDMLIBS:$EPICS_BASE/lib/$EPICS_HOST_ARCH

# Epics Base
RUN cd /opt/epics-R3.15.5           &&\
    tar -xvzf base-3.15.5.tar.gz    &&\
    rm base-3.15.5.tar.gz           &&\
    mv base-3.15.5 base             &&\
    cd base                         &&\
    make

# EDM
RUN sed -i -e '21cEPICS_BASE=/opt/epics-R3.15.5/base' -e '25s/^/#/' extensions/configure/RELEASE
RUN sed -i -e '14cX11_LIB=/usr/lib/x86_64-linux-gnu' -e '18cMOTIF_LIB=/usr/lib/x86_64-linux-gnu' extensions/configure/os/CONFIG_SITE.linux-x86_64.linux-x86_64

COPY edm.tar.gz /opt/epics-R3.15.5/extensions/src/
RUN cd /opt/epics-R3.15.5/extensions/src/   &&\
    tar -zxvf edm.tar.gz                    &&\
    rm edm.tar.gz

RUN cd extensions/src                                                                                                               &&\
    sed -i -e '15s/$/ -DGIFLIB_MAJOR=5 -DGIFLIB_MINOR=1/' edm/giflib/Makefile                                                       &&\
    sed -i -e 's| ungif||g' edm/giflib/Makefile*                                                                                    &&\
    cd edm                                                                                                                          &&\
    make clean                                                                                                                      &&\
    make                                                                                                                            &&\
    cd setup                                                                                                                        &&\
    sed -i -e '53cfor libdir in baselib lib epicsPv locPv calcPv util choiceButton pnglib diamondlib giflib videowidget' setup.sh   &&\
    sed -i -e '79d' setup.sh                                                                                                        &&\
    sed -i -e '81i\ \ \ \ $EDM -add $EDMBASE/pnglib/O.$ODIR/lib57d79238-2924-420b-ba67-dfbecdf03fcd.so' setup.sh                    &&\
    sed -i -e '82i\ \ \ \ $EDM -add $EDMBASE/diamondlib/O.$ODIR/libEdmDiamond.so' setup.sh                                          &&\
    sed -i -e '83i\ \ \ \ $EDM -add $EDMBASE/giflib/O.$ODIR/libcf322683-513e-4570-a44b-7cdd7cae0de5.so' setup.sh                    &&\
    sed -i -e '84i\ \ \ \ $EDM -add $EDMBASE/videowidget/O.$ODIR/libTwoDProfileMonitor.so' setup.sh                                 &&\
    HOST_ARCH=linux-x86_64 sh setup.sh

CMD /opt/epics-R3.15.5/extensions/bin/linux-x86_64/edm
