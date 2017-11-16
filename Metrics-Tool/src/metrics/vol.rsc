module metrics::vol

import lang::java::jdt::m3::Core;
import String;
import IO;

public str getVolumeScore(int amountLines) {
	// reader score amount of lines * 1000 
	if(amountLines <= 66000) {
		return "++";
	} else if(amountLines <= 246000) {
		return "+";
	} else if(amountLines <= 665000) {
		return "o";
	} else if(amountLines <= 1310000) {
		return "-";
	}
	return "--";
}


public int calcVolume(list[loc] classes) {
	int n = 0;
	for(projectClass <- classes) {
		n += calcVolumeClass(projectClass);
	}
	return n;
}

public int calcVolumeClass(loc location){
 str file = replaceAll(readFile(location)," ","");
 int n = 0;
 int newline = 0;
 for(int i <- [0 .. size(file)-1]){
  if(file[i]+file[i+1] =="\r\n"){
   str line = substring(file,newline,i);
   newline = i+2;
   if(size(line)>1 && /\w/:=line[0]) n+=1;
  }
 }
 return n;
}