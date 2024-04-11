import processing.serial.*;

// The serial port:
Serial COMPort;
String connected_COMPort;

DropDown drop_ComPort = new DropDown();
DropDown drop_Channel = new DropDown();

String[] dropdown = {"Нет устройств!"};
String[] channelList = {"20 (433)МГц", "19 (432)МГц", "18 (431)МГц", "17 (430)МГц", "16 (429)МГц", "15 (428)МГц", "14 (427)МГц", "13 (426)МГц", "12 (425)МГц", "11 (424)МГц", "10 (424)МГц"};
String[] channelListHC = {"001", "002", "003", "004", "005", "006", "007", "008", "009", "010"};

String[] textLog = {"", "", "", "", "", "", "", "", "", "", ""};

boolean type = false;  

boolean isConnected = false;




void setup() {
  size(700, 500);
  surface.setTitle("SV610/HC-12 Tools by Arlycad");
  surface.setLocation(displayWidth-width-10,0);                          //Координаты появления окна
  refreshComportList();
}

void draw() {
  uiFill();
  //-------------------------------Если не подключено------------------------------//
  if (!isConnected) {
    if (Button("Подключить", 0, 0)) {
      connect();
    }
    type = Toggle("SV/HC", type, width-105, 0);
    drop_ComPort.draw(dropdown, 210, 0);
  }
  

  //-------------------------------Если подключено устройство------------------------------//
  if (isConnected) {
    if (Button("Инфо", 0, 0)) {
      info();
    }
    Toggle("SV/HC", type,  width-105, 0);

    if (Button("Записать", 0, s_height+5)) {
      write();
    }

    if (Button("Сброс", width-105, s_height+5)) {
      reset();
    }

    drawTextLog();
    drop_Channel.draw(!type?channelList:channelListHC, 105, s_height+5);
    //Button(, 0, s_height+5);
    drop_ComPort.draw(dropdown, 210, 0);
  }
    //-------------------------------Отображаются всегда------------------------------//
  if (Button("Отключить", 105, 0)) {
    disconnect();
  }

  refreshComportList();
  
}


void info() {
  log_print("|Инфо| ");
  if (!type) {
    COMPort.write(0xAA);
    COMPort.write(0xFA);
    COMPort.write(0x01);
  } else {
    COMPort.write("AT+RX");
  }
}

void write() {
  //println("Записать: ");
  log_print("|Записать| ");

  if (!type) {
    COMPort.write(0xAA);
    COMPort.write(0xFA);
    COMPort.write(0x03);
    
    String channel = channelList[drop_Channel.getSelected()].substring(0, 2);
    COMPort.write(int(channel)); //канал
    COMPort.write(0x01); //band
    COMPort.write(0x03); // 9600
    COMPort.write(0x07); // power
    //UART
    COMPort.write(0x03); // 9600
    COMPort.write(0x02); // 8 data bits
    COMPort.write(0x01); // 1 stop bit
    COMPort.write(0x01); // No parity
    //Net ID
    COMPort.write(0x00); //
    COMPort.write(0x00); //
    COMPort.write(0x00); //
    COMPort.write(0x00); //
    //Node ID
    COMPort.write(0x00); //
    COMPort.write(0x00); //
  } else {
    String channel = channelListHC[drop_Channel.getSelected()].substring(0, 3);
    String s = "AT+C" + channel;
    COMPort.write(s);
  }
}

void reset() {
  log_print("|Сброс| ");
  if (!type) {
    COMPort.write(0xAA);
    COMPort.write(0xFA);
    COMPort.write(0x02);
  } else {
    COMPort.write("AT+DEFAULT");
  }
}

void readTick() {
  if (COMPort.available() > 0) {
    byte[] buff = COMPort.readBytes();
    if (!type)
    {
      log_print("[INT] ");
      for (int i = 0; i < buff.length; i++) {
        log_print(buff[i]);
      }
      log_print("|");
    }
    for (int i = 0; i < buff.length; i++) {
      if (char(buff[i])=='\n')
      {
        println();
        log_println();
        log_print("[String] ");
      } else {
        print(char(buff[i]));
        log_print(char(buff[i]));
      }
    }
  }
}

void drawTextLog() {
  readTick();

  textAlign(LEFT);
  for (int i = 0; i<textLog.length; i++) {
    fill(c_mid);
    rect(20, 35+50+ i*35, width-40, 35);
    fill(c_text_color);
    text(textLog[i], 20, 35+65 + i*35, width-40, 35);
  }
}

void connect() {
  log_print("|Подключить| ");

  try {

    COMPort = new Serial(this, dropdown[drop_ComPort.getSelected()], 9600);
    isConnected = true;
    connected_COMPort = dropdown[drop_ComPort.getSelected()];
    for (int i = 0; i < textLog.length-1; i++) {
      textLog[i] = "";
    }
    if (!type) {
      COMPort.write(0xAA);
      COMPort.write(0xFA);
      COMPort.write(0xAA);
    } else {
      COMPort.write("AT+V");
    }
  }
  catch (RuntimeException e) {
    //println("Error opening serial port: Port not found");
    //log_println("Error opening serial port: Port not found");
    refreshComportList();
  }
}

void disconnect() {
  log_print("|Отключить| ");
  textLog[textLog.length-1] = "";
  isConnected = false;
  if (COMPort!=null)COMPort.stop();
  refreshComportList();
}



void log_print(String s) {
  textLog[textLog.length-1]+= s;
}
void log_print(byte s) {
  textLog[textLog.length-1]+= s;
}
void log_print(char s) {
  textLog[textLog.length-1]+= s;
}
void log_print(int s) {
  textLog[textLog.length-1]+= s;
}
void log_println(String s) {
  textLog[textLog.length-1] += s;
  for (int i = 0; i < textLog.length-1; i++) {
    textLog[i] = textLog[i+1];
  }
  textLog[textLog.length-1] = "";
}
void log_println(int s) {
  textLog[textLog.length-1] += s;
  for (int i = 0; i < textLog.length-1; i++) {
    textLog[i] = textLog[i+1];
  }
  textLog[textLog.length-1] = "";
}
void log_println() {
  for (int i = 0; i < textLog.length-1; i++) {
    textLog[i] = textLog[i+1];
  }
  textLog[textLog.length-1] = "";
}
void refreshComportList() {
  String[] buff = Serial.list();

  if (buff.length == 0) {
    //println("Нет устройств!");
    dropdown[0] = "Нет устройств!";
    if (COMPort!=null) {
      COMPort.stop();
    }
    isConnected = false;
  } else dropdown = buff;
  //printArray(buff);
}
