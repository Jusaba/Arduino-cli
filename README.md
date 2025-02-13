

# Programacion de **esp8266** con arduino-cli

Esta imagen ha sido creada para compilar un skecth de esp8266. En principio se creo para poder implementar compilación automática en bitbucket y poder actualizar el firmware de los dispositivos conectados a Serverpic aunque puede ser utilizado para cualquier otra aplicación

# Versiones

3.0 Arduino core 2.6.3

4.0 Arduino core 2.7.3


### Pre-requisitos 📋
---
Al instalar **Arduno-cli** en linux en **/home/bin** se crea una estructura de carpetas que tenemos que tener en cuenta para construir la imagen

```
├─── root
│     ├─── Arduino
│     │       └─── libraries
│     └─── .arduino15
│               ├─── packages
│               ├─── staging
│               .
│               .
│               └─── logs
.
.
└─── home
       └─── bin
              └─── <WORKDIR>
 ```

 **WORKDIR** es el directorio donde esta el **sketch** a compilar y, ambos, Directorio y Sketch deben tener el mismo nombre. Teniendo esto en cuenta, a la hora de crear la imagen crearemos el directorio de trabajo con el nombre de **esp8266**. A la hora de compilar, depositaremos el **skecht** en ese directorio y lo renombraremos como **esp8266.ino**.


## Como se ha construido la imagen 🛠️

La imagen se ha creado mediante el siguiente **Dockerfile**

```
FROM debian

ENV DIRPATH /home
WORKDIR $DIRPATH
RUN cd /home
RUN apt-get update
RUN cd /home
RUN apt-get install curl -y

RUN apt install python3 -y
RUN apt install python3-serial
RUN curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh | sh

COPY arduino-cli.yaml /root/.arduino15/

ENV DIRPATH /home/bin
WORKDIR $DIRPATH
ENV PATH="$PATH:/home/bin"
COPY  Compila.sh  /home/bin
RUN mkdir esp8266
RUN cd /home/bin/esp8266

RUN arduino-cli lib list
RUN arduino-cli core update-index
RUN arduino-cli core install esp8266:esp8266@2.7.3

ENTRYPOINT /bin/bash /home/bin/Compila.sh  $_fqbn $_xtal $_CrystalFreq $_lvl $_dbg $_wipe $_sdk $_exception $_FlashFreq $_FlashMode $_eesz $_ip $_ResetMethod $_ssl $_baud $_vt $_ino

```

La imagen esta creada sobre Debian, en primer lugar se instala curl para poder descargar seguidamente **python3** y **arduino-cli**. En el directorio /root/.arduino15/ de la imagen tenemos que incorporar el fichero **arduino-cli.yaml** con la información para descargar los packages de esp8266, para eso, debemos dejar en el directorio donde se ejecuta el Dockerfile el fichero **arduino-cli.yaml** con el siguiente contenido

```
board_manager:
  additional_urls:
  - http://arduino.esp8266.com/stable/package_esp8266com_index.json
daemon:
  port: "50051"
directories:
  data: /root/.arduino15
  downloads: /root/.arduino15/staging
  user: /root/Arduino
logging:
  file: ""
  format: text
  level: info

```

Solo contemplamos los packages de esp8266 por que son lo que en principio se van a utilizar. Si se necesitaran otros packages, se podria crear una nueva imagen actulizando este fichero. 

Luego, establecemos el path **/home/bin** como directorio de trabajo. 

En ese directorio  copiaremos el fichero bash **Compila.sh** que es el que realmente llama al compialdor y que deberemos tener en el diretorio donde se encuentre el Dockerfile para crear la imagen.

Inmediatamente después creamos el directorio **esp8266** que usaremos como volumen imagen de la carpeta con el **sketch** a compilar.  

Volviewndo a **Compila.sh**, es un bash  muy básico. Para ejecutarlo se le deben pasar dos parametros, el nombre del **sketch** original y el **fqbn** corrspondiente al modelo de esp utilizado. Con estos parametros, el bash,  renombra el **sketch** como **esp8266.ino** y  llama al compilador con el **fqbn** que se precisa. Una vez finalizada la compilación se vuelve a poner el nombre original al **sketch** y al fichero **bin** resultado de la compilación.

**Compila.sh** es muy básico, llama al compilador **Arduino-cli** con los parametros pasados en el fichero **parametros.env** en funcion del modelo de esp utilizado


```
  cd esp8266
  mv "${17}".ino esp8266.ino
  case $1 in
	  "esp8266:esp8266:generic")   	
                arduino-cli compile --output-dir . --fqbn $1:xtal=$2,CrystalFreq=$3,lvl=$4,dbg=$5,wipe=$6,sdk=$7,exception=$8,FlashFreq=$9,FlashMode="${10}",eesz="${11}",ip="${12}",ResetMethod="${13}",ssl="${14}",baud="${15}",vt="${16}"  -e
        ;;
      "esp8266:esp8266:nodemcu")
                arduino-cli compile --output-dir . --fqbn $1:xtal=$2,lvl=$4,dbg=$5,wipe=$6,exception=$8,eesz="${11}",ip="${12}",ssl="${14}",baud="${15}",vt="${16}"  -e
        ;;
      "esp8266:esp8266:esp8285")
                arduino-cli compile --output-dir . --fqbn $1:xtal=$2,lvl=$4,dbg=$5,wipe=$6,exception=$8,eesz="${11}",ResetMethod="${13}",ssl="${14}",baud="${15}",vt="${16}" -e 
        ;;        
  esac
  mv esp8266.ino "${17}".ino    
  mv esp8266.ino.bin "${17}".bin
  cd ..
```
Continuando con el **Dockerfile**, una vez copiado el fichero **Compila.sh**, se ejecutan cuatro comandos de arduino-cli para que se creen las estructuras de directorios y se cargen los packages de esp32 y la vesriosn deseada.

```
RUN arduino-cli lib list
RUN arduino-cli core update-index
RUN arduino-cli core install esp8266:esp8266@2.7.3
```

Por último, fijamos la entrada al contenedor con la llamada a **Compila.sh** pasandole los dos parametrosa necesarios que se transferiran en la llamada al contenedor con el fichero **parametros.env**.

```
ENTRYPOINT /bin/bash /home/bin/Compila.sh  $_fqbn $_xtal $_CrystalFreq $_lvl $_dbg $_wipe $_sdk $_exception $_FlashFreq $_FlashMode $_eesz $_ip $_ResetMethod $_ssl $_baud $_vt $_ino

```
El Dockerfile lo ejecutamos como es costumbre

```
docker build -t jusaba/esp8266-cli:<Tag> .
```

Para subir la imagen a **Docker Hub**

```
docker push jusaba/esp32_cli:<Tag>
```

Evidentemente, antes debe hacer **login** en **Docker Hub**

```
docker login -u "jusaba" -p "<PASSWORD>" docker.io 
```

### Instalación 🔧
---
Para descargar la imagen

```
docker push jusaba/esp8266-cli:latest
```

## Ejecutando el compilador ⚙️
---
Supongamos que vamos a trabajar en el directorio /home/serverpic y tenemos un programa Oulet.ino que queremos compilar y que este programa necesita de las librerias serverpic para funcionar y alguna otra especifica. 

Las librerias las dejaremos en  en el directorio  **/home/serverpic/Librerias** y al ejecutar el contenedor, crearemos un volumen para asociar ese directorio a **/root/Arduino/libraries** y el directorio de trabajo **/home/serverpic**, con otro volumen lo asociaremos a **/home/bin/esp8266**.

Supongamos igualmente que vamos a utilizar un ESP-01 con las siguientes caracteristicas

| Descipcion | Valor |
| ------ | ------ |
| Placa | Generic ESP8266 Module |
| CPU Frecuency| 80 MHZ |
| CRYSTAL Frecuency | 26 MHZ |
| Debug Level | none |
| Debug Pot | Disabled |
| Esase Flash | Only sketch |
| Expressid FW | nonos-sdk 2.2.1 (legacy) |
| Exceptions| Disabled |
| Flash Frecuency | 40 MHZ |
| Flash Mode | DOUT ( compatible ) |
| Flash Size | 1M(no SPIFFS) |
| IwIP Variant | v2 Lower Memory |
| Reset Method | ck |
| SSL SUport | ALL SSL chiphers (most compatible) |
| Upload Speed | 115200 |
| VTables | Flash |

Si utilizaramos un nodemcu v3 sería:

| Descipcion | Valor |
| ------ | ------ |
| Placa | Generic ESP8266 Module |
| CPU Frecuency| 80 MHZ |
| Debug Level | none |
| Debug Pot | Disabled |
| Esase Flash | Only sketch |
| Exceptions| Disabled |
| Flash Size | 4M(no SPIFFS) |
| IwIP Variant | v2 Lower Memory |
| SSL SUport | ALL SSL chiphers (most compatible) |
| Upload Speed | 115200 |
| VTables | Flash |

Como que son muchas variables, optamos por incluirlas en el fichero **parametros.env** que crearemos en el directorio de trabajo

Ese fichero **parametros.env** que en el caso de ESP-01 caso tendra el siguiente contenido

```
_ino=Outlet
_fqbn=esp8266:esp8266:generic
_xtal=80
_CrystalFreq=26
_lvl=None____
_dbg=Disabled
_wipe=none
_sdk=nonosdk221
_exception=disabled
_FlashFreq=40
_FlashMode=dout
_eesz=1M
_ip=lm2f
_ResetMethod=ck
_ssl=all
_baud=115200
_vt=flash 
```

 Para nodemcu se deben dejar en blaco los parametros no utilizados, así, quedaría de la siguiente manera 

```
_ino=pir
_fqbn=esp8266:esp8266:nodemcu
_xtal=80
_CrystalFreq=
_lvl=None____
_dbg=Disabled
_wipe=none
_sdk=
_exception=disabled
_FlashFreq=
_FlashMode=
_eesz=4M
_ip=lm2f
_ResetMethod=
_ssl=all
_baud=115200
_vt=flash 
```

Ya estamos en disposición de compilar

Ejecutar el contenedor de la siguiente forma.

```
docker run -v /home/serverpic/librerias:/root/Arduino/libraries/serverpic  -v /home/serverpic/esp8266:/home/bin/esp8266 --env-file parametros.env  -i jusaba/esp8266-cli.latest 
```

Tras unos segundos, en el direcotrio **/home/serverpic/esp8266** nos encontraremos con el fichero compilado **outlet.bin**



## Contribuyendo 🖇️


## Wiki 📖


## Versionado 📌

Usamos [SemVer](http://semver.org/) para el versionado. Para todas las versiones disponibles, mira los [tags en este repositorio](https://github.com/tu/proyecto/tags).

## Autores ✒️

* **Julián Salas Barolome** Desarrollo y documentación



## Licencia 📄

Este proyecto es libre para utilizarlo en Serverpic

## Expresiones de Gratitud 🎁

* Comenta a otros sobre este proyecto 📢
* Invita una cerveza 🍺 o un café ☕ a alguien del equipo. 
* Da las gracias públicamente 🤓.
* etc.



---
⌨️ La presentación de esta documentación ha sido posible gracias a  [Villanuevand](https://github.com/Villanuevand) 😊