string GV_PriceLevels_Trigger_Name = "GV_PriceLevels_Trigger_" + Symbol();
string GV_PriceLevels_TriggerHit_Name = "GV_PriceLevels_TriggerHit_" + Symbol();
string GV_PriceLevels_TriggerHitTime_Name = "GV_PriceLevels_TriggerHitTime_" + Symbol();
string GV_PriceLevels_Auth_Name = "GV_PriceLevels_Auth_" + Symbol();

void GetPriceLevelsDataFromServer() {
   string query = "filter=symbol|" + Symbol();
   string url = "http://localhost:xx/[hidden]?" + query;
   int res = WebRequest("GET",url,cookie,NULL,timeout,post,0,result,headers);
   if (res == -1) {
      Print("Error in WebRequest. Error code: ",GetLastError());
   } else {
      parseJson(result);
      UpdateServerSignals();
      UpdateGVPriceLevels();
      TryResetServerPriceLevels();
   }
}

void UpdateServerSignals() {
   string bandsTrend = "0";
   if (Trend_BandsTouchStatus_H4("L")) bandsTrend = "L";
   if (Trend_BandsTouchStatus_H4("S")) bandsTrend = "S";
   
   string emaTrend = "0";
   if (Trend_EMA_H4("L")) emaTrend = "L";
   if (Trend_EMA_H4("S")) emaTrend = "S";
   
   string query = "filter=symbol|" + Symbol();
   query += "&target=bands|" + bandsTrend;
   query += ",ema|" + emaTrend;
   query += "&flag=silent";
   string url = "http://localhost:xx/[hidden]?" + query;
   int res = WebRequest("POST",url,cookie,NULL,timeout,post,0,result,headers);
   if (res == -1) {
      Print("Error in WebRequest. Error code: ",GetLastError());
   }
}

void UpdateGVPriceLevels() {
   string query = "filter=symbol|" + Symbol();
   string url = "http://localhost:xx/[hidden]?" + query;
   int res = WebRequest("GET",url,cookie,NULL,timeout,post,0,result,headers);
   if (res == -1) {
      Print("Error in WebRequest. Error code: ",GetLastError());
      ArrayFree(curKeys);
      ArrayFree(curValues);
   } else {
      parseJson(result);
      
      for (int i=0; i < ArraySize(curKeys); i++) {
         if (curKeys[i] == "trigger") {
            GlobalVariableSet(GV_PriceLevels_Trigger_Name, StringToDouble(curValues[i]));
         }
         //Print(curKeys[i]);
         if (curKeys[i] == "auth") GlobalVariableSet(GV_PriceLevels_Auth_Name, StringToDouble(curValues[i]));
      }
   }
}

void CheckGlobalVariables_PriceLevels() {
   if (!GlobalVariableCheck(GV_PriceLevels_Trigger_Name)) GlobalVariableSet(GV_PriceLevels_Trigger_Name, 0);
   if (!GlobalVariableCheck(GV_PriceLevels_Auth_Name)) GlobalVariableSet(GV_PriceLevels_Auth_Name, 0);
}

void ResetGVPriceLevels(string type) {
   if (type == "trigger" || type == "all") {
      GlobalVariableSet(GV_PriceLevels_Trigger_Name, 0);
      GlobalVariableSet(GV_PriceLevels_TriggerHit_Name, 0);  
   }   
   if (type == "auth" || type == "all") GlobalVariableSet(GV_PriceLevels_Auth_Name, 0); 
   
   string query = "filter=symbol|" + Symbol();
   if (type == "all") query += "&target=trigger|0,auth|0,rejected|0";
   if (type == "trigger") query += "&target=trigger|0,triggerHit|0";
   if (type == "auth") query += "&target=auth|0";
   if (type == "rejected") query += "&target=rejected|0";
   //query += "&flag=silent";
   string url = "http://localhost:xx/[hidden]?" + query;
   int res = WebRequest("POST",url,cookie,NULL,timeout,post,0,result,headers);
   if (res == -1) {
      Print("Error in WebRequest. Error code: ",GetLastError());
   }  
}

bool Trend_PriceLevels() {
   if (!appControlEnabled) return true;
   
   if (Trend_Auth() || Trend_Trigger()) return true;
   
   return false;
}

bool Trend_Auth() {
   double auth = GlobalVariableGet(GV_PriceLevels_Auth_Name);
   
   if (auth == 1) return true;
   
   return false;
}

bool Trend_Trigger() {
   double trigger = GlobalVariableGet(GV_PriceLevels_Trigger_Name);
   
   TrailTriggerHit(trigger);
   
   if (trigger == 0) return true;
   
   // When price crosses the trigger level.
   if (GlobalVariableGet(GV_PriceLevels_TriggerHit_Name) == 1) return true;
   
   return false;
}

void TrailTriggerHit(double trigger) {
   double curPrice = PRICE_Get(PERIOD_M15, 0);
   double prevPrice = PRICE_Get(PERIOD_M15, 1);
   
   // Set hit status to 0 if it has expired.
   double triggerHitTime = GlobalVariableGet(GV_PriceLevels_TriggerHitTime_Name);
   
   // When price crosses the trigger level.
   if ((prevPrice < trigger && curPrice >= trigger) || (prevPrice > trigger && curPrice <= trigger)) {
      GlobalVariableSet(GV_PriceLevels_TriggerHit_Name, 1);
      GlobalVariableSet(GV_PriceLevels_TriggerHitTime_Name, Time[0]);
      string query = "&target=triggerHit|1";
      string url = "http://localhost:xx/[hidden]?" + query;
      int res = WebRequest("POST",url,cookie,NULL,timeout,post,0,result,headers);
      if (res == -1) {
         Print("Error in WebRequest. Error code: ",GetLastError());
      } 
   }
   
   // Expires in 8h.
   if (Time[0] > triggerHitTime + 3600 * 8) {
      ResetGVPriceLevels("trigger");
   }
   
}

void TryResetServerPriceLevels() {
   // Doesn't reset triggers because these could be set even if Bands aren't trending.
   if (!Trend_BandsTouchStatus_H4("L") && !Trend_BandsTouchStatus_H4("S")) {
      ResetGVPriceLevels("auth");
      ResetGVPriceLevels("rejected");
   }
}
