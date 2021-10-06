FROM debian

ENV DIRPATH /home
WORKDIR $DIRPATH
RUN cd /home
RUN apt-get update 
RUN cd /home 
RUN apt-get install curl -y 
RUN curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh | sh 
RUN apt install python3 -y

COPY arduino-cli.yaml /root/.arduino15/
 

ENV DIRPATH /home/bin
WORKDIR $DIRPATH
COPY Compila.sh /home/bin/
ENV PATH="$PATH:/home/bin"
RUN mkdir esp8266
RUN arduino-cli lib list
RUN arduino-cli core update-index
RUN arduino-cli core install esp8266:esp8266@2.7.3



ENTRYPOINT /bin/bash Compila.sh $_fqbn $_xtal $_CrystalFreq $_lvl $_dbg $_wipe $_sdk $_exception $_FlashFreq $_FlashMode $_eesz $_ip $_ResetMethod $_ssl $_baud $_vt $_ino