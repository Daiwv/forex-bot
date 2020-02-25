// Parse json string and store results in {curKeys} and {curValues} arrays.
void parseJson(char &jsonChar[]) {
   ArrayFree(curKeys);
   ArrayFree(curValues);
   string json = CharArrayToString(jsonChar,0,WHOLE_ARRAY,CP_ACP);
   string curString;
   int pairCount;
   bool isReadingKeys = true;
   
   // Append comma to the json string so that the last value can be read.
   json += ",";
   
   for (int i=0; i < StringLen(json); i++) {
      string character = CharToStr(StringGetCharacter(json,i));

      // Ignore these characters.
      if (character == "[" || character == "{" || character == "\"" || character == "}" || character == "]") continue;
      
      // Store current key and start reading values.
      if (character == ":" && isReadingKeys) {
         ArrayResize(curKeys,pairCount+1);
         curKeys[pairCount] = curString;
         Print(curString);
         curString = "";
         isReadingKeys = false;
         continue;
      }
      
      // Store current value and start reading keys.
      if (character == "," && !isReadingKeys) {
         ArrayResize(curValues,pairCount+1);
         curValues[pairCount] = curString;
         curString = "";
         isReadingKeys = true;
         pairCount++;
         continue;
      }
      
      // Append letter to the currently stored string.
      curString += character;
   }
}

// Parse check results and store them in {curKeys} and {curValues} arrays.
void parseTickets(char &ticketsChar[]) {
   ArrayFree(curNodeTickets);
   string ticketsStr = CharArrayToString(ticketsChar,0,WHOLE_ARRAY,CP_ACP);
   string curString;
   int ticketCount;
   
   // Append comma to the tickets string so that the last value can be read.
   ticketsStr += ",";
   
   for (int i=0; i < StringLen(ticketsStr); i++) {
      string character = CharToStr(StringGetCharacter(ticketsStr,i));
      
      // Ignore these characters.
      if (character == "[" || character == "]" || character == "\"") continue;
      
      if (character == ",") {
         ArrayResize(curNodeTickets,ticketCount+1);
         curNodeTickets[ticketCount] = StrToDouble(curString);
         curString = "";
         ticketCount++;
         continue;
      }
      
      curString += character;
   }
}

void parseColor(string rgb) {

   ArrayFree(clrArr);
   ArrayResize(clrArr, 3);

   string clrCode;
   int iterator;
   
   for (int i=0; i < StringLen(rgb); i++) {
      string character = CharToStr(StringGetCharacter(rgb,i));
      
      if (character != "$") {
         clrCode += character;
      } else {
         clrArr[iterator] = StringToDouble(clrCode);
         clrCode = "";
         iterator++;
      }
   }
}