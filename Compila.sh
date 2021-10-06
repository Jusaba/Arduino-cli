   
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
   