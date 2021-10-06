

# Programacion de **esp8266** con arduino-cli

Esta imagen ha sido creada para compilar un skecth de esp8266. En principio se creo para poder implementar compilación automática en bitbucket y poder actualizar el firmware de los dispositivos conectados a Serverpic aunque puede ser utilizado para cualquier otra aplicación

# Versiones

3.0 Arduino core 2.6.3

4.0 Arduino core 2.7.3

### Instalación 🔧
---
_Para descargar la imagen_


```
docker push jusaba/esp8266-cli:latest
```
### Pre-requisitos 📋
---
_Antes de crear el contenedor, es necesario crear una carpeta llamada **esp8266** en el directorio donde se va a trabajar la compilación. En esa carpeta se debe dejar el 'ino' a compilar_

```
mkdir esp8266
```

_Si se necesitan librerias de usuario para compilar, deben dejarse antes en un directorio conocido, en nuestro caso las dejaremos en el directorio **librerias** que crearemos en nuestro directorio de trabajo_

```
mkdir librerias
```

## Ejecutando el compilador ⚙️
---
_Supongamos que vamos a trabajar en el directorio /home/serverpic y tenemos un programa Oulet.ino que queremos compilar y que este programa necesita de las librerias serverpic para funcionar_

_Supongamos igualmente que vamos a utilizar un ESP-01 con las siguientes caracteristicas_

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
| Flash Size | 1M(no SPIFFS)] |
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
| Flash Size | 4M(no SPIFFS)] |
| IwIP Variant | v2 Lower Memory |
| SSL SUport | ALL SSL chiphers (most compatible) |
| Upload Speed | 115200 |
| VTables | Flash |

Como que son muchas variables, optamos por incluirlas en el fichero **parametros.env** que crearemos en el directorio de trabajo

Ahora, para compilar el programa seguiremos estos pasos

* Crear directorio **esp8266** en /home/serverpic y copiar en el el fichero **Outle.ino**
* Crear directorio **librerias** en /home/serverpic y copiar en el la carpeta con las librerias de usuario, en este caso serverpic
* Crear el fichero **parametros.env** que en el caso de ESP-01 caso tendra el siguiente contenido
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

* Para nodemcu se deben dejar en blaco los parametros no utilizados, así, quedaría de la siguiente manera 
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
* Ejecutar el contenedor de la siguiente forma.

```
docker run -v /home/serverpic/librerias:/root/Arduino/libraries/serverpic  -v /home/serverpic/esp8266:/home/bin/esp8266 --env-file parametros.env  -i jusaba/esp8266-cli 
```

Tras unos segundos, en el direcotrio **/home/serverpic/esp8266** nos encontraremos con el fichero compilado **outlet.bin**

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
RUN arduino-cli core install esp8266:esp8266
RUN arduino-cli core install esp8266:esp8266@2.7.3


ENTRYPOINT /bin/bash Compila.sh $_fqbn $_xtal $_CrystalFreq $_lvl $_dbg $_wipe $_sdk $_exception $_FlashFreq $_FlashMode $_eesz $_ip $_ResetMethod $_ssl $_baud $_vt $_ino
```

La imagen esta creada sobre Debian, en primer lugar se instala curl para poder descargar seguidamente **arduino-cli**. En el directorio /root/.arduino15/ de la imagen tenemos que incorporar el fichero **arduino-cli.yaml** con la información para descargar los packages de esp8266, para eso, debemos dejar en el directorio donde se ejecuta el Dockerfile el fichero **arduino-cli.yaml** con el siguiente contenido

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

Luego, creamos el directorio de trabajo que tendra el contenedor en /home/bin y en el

En el directorio /home/bin  copiaremos el fichero bash **Compila.sh** que es el que realmente llama al compildaor y que deberemos tener en el diretorio donde se encuentre el Dockerfile para crear la imagen.
**Compila.sh** es muy básico, llama al compilador con los parametros pasados en el fichero **parametros.env** en funcion del modelo de esp utilizado


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

Por último, creamos el directorio /home/bin/esp8266 que se utilizará como volumen para depositar el **ino** y, tras la compilación, recoger el **bin**

Despues de crear ese direcotrio se ejecutan tres comandos de arduino-cli para que se creen las estructuras de directorios y se cargen los packages de esp8266 y la vesriosn deseada


```
RUN arduino-cli lib list
RUN arduino-cli core update-index
RUN arduino-cli core install esp8266:esp8266
RUN arduino-cli core install esp8266:esp8266@2.6.3

```
El Dockerfile lo ejecutamos como es costumbre

```
docker build -t jusaba/esp8266-cli:1.0 .
```


## Contribuyendo 🖇️


## Wiki 📖


## Versionado 📌

Usamos [SemVer](http://semver.org/) para el versionado. Para todas las versiones disponibles, mira los [tags en este repositorio](https://github.com/tu/proyecto/tags).

## Autores ✒️

* **Oscar Salas Mestres** Idea original 
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